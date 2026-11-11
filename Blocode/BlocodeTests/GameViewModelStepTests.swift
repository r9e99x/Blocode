//
//  GameViewModelStepTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/12/26.
//
//  단계별 실행(한 칸씩) 검증 — 누를 때마다 강조된 블럭 하나만 실행되는지,
//  계속·리셋·실패가 정상인지, 일반 실행에는 영향이 없는지 확인.

import Testing
import Foundation
@testable import Blocode

@MainActor
@Suite("단계별 실행")
struct GameViewModelStepTests {

    private func makeStage(grid: [[Int]], goal: Position) -> Stage {
        let map = MapData(grid: grid, start: Position(x: 0, y: 0), startDirection: .right, goal: goal)
        return Stage(id: "unittest_step_\(UUID().uuidString)", chapter: 0, stageNumber: 0, name: "Step Test",
                     mapData: map, starThresholds: StarThresholds(threeStar: 9, twoStar: 9))
    }

    /// 한 줄짜리 길 — 시작 (0,0) 오른쪽, 목표는 끝 칸
    private func makeVM(length: Int = 6, grid: [[Int]]? = nil, goal: Position? = nil) -> GameViewModel {
        let stage = makeStage(grid: grid ?? [Array(repeating: 1, count: length)],
                              goal: goal ?? Position(x: length - 1, y: 0))
        return GameViewModel(stage: stage, progress: .makeForTesting(), executionSpeed: { 1000 })
    }

    private func forward(_ count: Int) -> [Block] {
        Array(repeating: Block(type: .moveForward), count: count)
    }

    /// 조건이 참이 될 때까지 기다림 — 5초 안에 안 되면 false
    private func wait(_ condition: () -> Bool) async throws -> Bool {
        let deadline = Date().addingTimeInterval(15)
        while !condition(), Date() < deadline { try await Task.sleep(for: .milliseconds(5)) }
        return condition()
    }

    @Test("누를 때마다 강조된 블럭 하나만 실행")
    func oneBlockPerStep() async throws {
        let vm = makeVM()
        vm.codeBlocks = forward(3)

        vm.step()
        #expect(try await wait { vm.isWaitingForStep })
        #expect(vm.isStepping)
        #expect(vm.currentBlockPath == [0])
        #expect(vm.board.position == Position(x: 0, y: 0))  // 아직 실행 전
        #expect(vm.attemptCount == 1)

        vm.step()
        #expect(try await wait { vm.isWaitingForStep && vm.currentBlockPath == [1] })
        #expect(vm.board.position == Position(x: 1, y: 0))

        vm.step()
        #expect(try await wait { vm.isWaitingForStep && vm.currentBlockPath == [2] })
        #expect(vm.board.position == Position(x: 2, y: 0))

        vm.step()  // 마지막 블럭 실행 — 목표에 못 닿고 끝나면 처음 상태로 돌아옴
        #expect(try await wait { vm.gameState == .idle })
        #expect(vm.board.position == Position(x: 3, y: 0))
        #expect(!vm.isStepping)
    }

    @Test("연달아 눌러도 한 단계만 진행")
    func doublePressIgnored() async throws {
        let vm = makeVM()
        vm.codeBlocks = forward(3)
        vm.step()
        #expect(try await wait { vm.isWaitingForStep })

        vm.step()
        vm.step()  // 실행 중에 또 누른 입력은 무시
        #expect(try await wait { vm.isWaitingForStep && vm.currentBlockPath == [1] })
        #expect(vm.board.position == Position(x: 1, y: 0))
    }

    @Test("계속을 누르면 남은 블럭을 한 번에 실행해 클리어")
    func continueFinishesRun() async throws {
        let vm = makeVM()
        vm.codeBlocks = forward(5)
        vm.step()
        #expect(try await wait { vm.isWaitingForStep })

        vm.continueRun()
        #expect(try await wait { vm.gameState == .success })
        #expect(!vm.isStepping)
        #expect(vm.board.isAtGoal)
    }

    @Test("기다리는 중에 리셋하면 멈추고, 이어서 일반 실행도 정상")
    func resetWhileWaiting() async throws {
        let vm = makeVM()
        vm.codeBlocks = forward(5)
        vm.step()
        #expect(try await wait { vm.isWaitingForStep })
        vm.step()
        #expect(try await wait { vm.isWaitingForStep && vm.currentBlockPath == [1] })

        vm.reset()
        #expect(vm.gameState == .idle)
        #expect(!vm.isStepping && !vm.isWaitingForStep)
        #expect(vm.currentBlockPath == nil)
        #expect(vm.board.position == Position(x: 0, y: 0))

        vm.run()
        #expect(try await wait { vm.gameState == .success })
        #expect(vm.attemptCount == 2)
    }

    @Test("반복 블럭은 반복 자체와 안쪽 블럭을 차례로 한 단계씩 실행")
    func containerSteps() async throws {
        let vm = makeVM()
        vm.codeBlocks = [Block(type: .repeatBlock, repeatCount: 2, children: forward(1))]

        vm.step()
        #expect(try await wait { vm.isWaitingForStep && vm.currentBlockPath == [0] })

        vm.step()  // 반복 블럭 실행 → 안쪽 첫 블럭에서 멈춤
        #expect(try await wait { vm.isWaitingForStep && vm.currentBlockPath == [0, 0] })
        #expect(vm.board.position == Position(x: 0, y: 0))

        vm.step()
        #expect(try await wait { vm.isWaitingForStep && vm.board.position == Position(x: 1, y: 0) })
        #expect(vm.currentBlockPath == [0, 0])  // 두 번째 반복의 같은 블럭

        vm.step()
        #expect(try await wait { vm.gameState == .idle })
        #expect(vm.board.position == Position(x: 2, y: 0))
    }

    @Test("벽에 부딪히면 단계별 실행도 실패 처리")
    func failureEndsStepping() async throws {
        let vm = makeVM(grid: [[1, 1, 0, 1]], goal: Position(x: 3, y: 0))
        vm.codeBlocks = forward(3)
        vm.step()
        #expect(try await wait { vm.isWaitingForStep })
        vm.step()  // 첫 블럭은 (1,0)으로 이동
        #expect(try await wait { vm.isWaitingForStep && vm.currentBlockPath == [1] })
        vm.step()  // 두 번째 블럭은 벽 (2,0)에 부딪힘
        #expect(try await wait { vm.gameState == .failure })
        #expect(vm.failedBlockPath == [1])
        #expect(!vm.isStepping)
    }

    @Test("한 칸씩 버튼은 시작 전과 대기 중에만 눌림")
    func canStepStates() async throws {
        let vm = makeVM()
        #expect(!vm.canStep)  // 블럭이 없음

        vm.codeBlocks = forward(3)
        #expect(vm.canStep)

        vm.step()
        #expect(try await wait { vm.isWaitingForStep })
        #expect(vm.canStep)

        vm.step()
        #expect(!vm.canStep)  // 블럭을 실행하는 동안
        #expect(try await wait { vm.canStep })
    }

    @Test("일반 실행은 단계별 상태가 아니고 멈추지 않음")
    func normalRunIsNotStepping() async throws {
        let vm = makeVM()
        vm.codeBlocks = forward(5)
        vm.run()
        #expect(!vm.isStepping)
        #expect(!vm.canStep)
        #expect(try await wait { vm.gameState == .success })
        vm.step()  // 클리어 뒤에는 무시
        #expect(vm.gameState == .success)
    }
}
