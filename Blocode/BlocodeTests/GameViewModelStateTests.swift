//
//  GameViewModelStateTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 10/15/26.
//
//  재도전(retry) · 걸린 시간 · 실행 중 리셋 등 실행 전후 상태 검증.
//  클리어 기록은 메모리 저장소에만 남으므로 실제 진행도와 연속 일수에 영향이 없다.

import Testing
import Foundation
@testable import Blocode

@MainActor
@Suite("GameViewModel 상태 — 재도전·시간·중단")
struct GameViewModelStateTests {

    /// 3x3 세로 통로: (1,2)에서 위로 두 칸 가면 (1,0) 골인
    private func makeFixture() -> GameViewModel {
        let mapData = MapData(grid: [[0, 1, 0], [0, 1, 0], [0, 1, 0]],
                              start: Position(x: 1, y: 2), startDirection: .up, goal: Position(x: 1, y: 0))
        let stage = Stage(id: "unittest_\(UUID().uuidString)", chapter: 0, stageNumber: 0,
                          name: "State Test", mapData: mapData,
                          starThresholds: StarThresholds(threeStar: 99, twoStar: 99))
        return GameViewModel(stage: stage, progress: .makeForTesting(), executionSpeed: { 1 })
    }

    private func waitUntilFinished(_ viewModel: GameViewModel, timeout: TimeInterval = 15) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while viewModel.gameState == .running {
            if Date() > deadline {
                Issue.record("실행이 \(timeout)초 안에 끝나지 않음")
                return
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    @Test("retry()는 블럭을 유지하고 도전 횟수만 새로 시작 (B2)")
    func retry_keepsBlocks_resetsAttempts() async throws {
        let vm = makeFixture()
        vm.codeBlocks = [Block(type: .moveForward), Block(type: .moveForward)]
        vm.run()
        try await waitUntilFinished(vm)
        #expect(vm.gameState == .success)
        #expect(vm.attemptCount == 1)

        vm.retry()
        #expect(vm.gameState == .idle)
        #expect(vm.codeBlocks.count == 2)  // 예전엔 fullReset()이라 블럭이 전부 지워졌음
        #expect(vm.attemptCount == 0)
        #expect(vm.board.position == Position(x: 1, y: 2))
    }

    @Test("걸린 시간은 실행 시간이 아니라 화면 진입부터 잼 (B3)")
    func elapsedTime_countsFromStageEntry() async throws {
        let vm = makeFixture()
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1초 동안 "고민"
        vm.codeBlocks = [Block(type: .moveForward), Block(type: .moveForward)]
        vm.run()  // 실행 자체는 약 0.6초
        try await waitUntilFinished(vm)
        #expect(vm.gameState == .success)
        #expect(vm.elapsedTime >= 1.0)  // 예전 방식이면 실행 시간(약 0.6초)만 나왔음
    }

    @Test("실행 중 리셋하면 실패로 바뀌지 않고 멈춤 (B8 — 화면 이탈 시 onDisappear가 하는 일)")
    func resetWhileRunning_doesNotFail() async throws {
        let vm = makeFixture()
        vm.codeBlocks = [Block(type: .moveForward), Block(type: .moveForward)]
        vm.run()
        try await Task.sleep(nanoseconds: 100_000_000)  // 첫 이동 애니메이션 도중
        vm.reset()
        vm.renderer = nil  // 화면이 사라지며 그리기 담당도 해제되는 상황 재현
        try await Task.sleep(nanoseconds: 800_000_000)  // 남은 이동 대기 시간이 다 지나도록
        #expect(vm.gameState == .idle)
        #expect(vm.failedBlockPath == nil)
        #expect(vm.failureMessage.isEmpty)
    }

    @Test("실행 중 리셋 후 바로 재실행해도 이전 실행이 이어지지 않음")
    func resetThenRunAgain_doesNotRunTwice() async throws {
        let vm = makeFixture()
        vm.codeBlocks = [Block(type: .turnLeft), Block(type: .turnLeft)]
        vm.run()
        try await Task.sleep(nanoseconds: 50_000_000)  // 첫 회전 대기 중
        vm.reset()
        vm.run()
        try await waitUntilFinished(vm)
        try await Task.sleep(nanoseconds: 500_000_000)  // 이전 실행이 남아 있다면 움직일 시간
        #expect(vm.board.direction == .down)  // 위에서 왼쪽 2번 — 이전 실행이 이어지면 더 돌아감
        #expect(vm.gameState == .idle)
    }

    @Test("다음 스테이지 번호 — 마지막 스테이지와 없는 챕터는 nil")
    func nextStageNumber_followsCatalog() throws {
        let first = try #require(ChapterCatalog.chapter(1))
        func viewModel(chapter: Int, stage: Int) -> GameViewModel {
            let mapData = MapData(grid: [[1]], start: Position(x: 0, y: 0), startDirection: .up, goal: Position(x: 0, y: 0))
            return GameViewModel(stage: Stage(id: "unittest_next", chapter: chapter, stageNumber: stage, name: "Next",
                                              mapData: mapData, starThresholds: StarThresholds(threeStar: 1, twoStar: 1)),
                                 progress: .makeForTesting(), executionSpeed: { 1 })
        }
        #expect(viewModel(chapter: 1, stage: 1).nextStageNumber == 2)
        #expect(viewModel(chapter: 1, stage: first.stageCount).nextStageNumber == nil)
        #expect(viewModel(chapter: 0, stage: 1).nextStageNumber == nil)
    }

    @Test("편집 가능 여부 — 실행 중에는 불가, 리셋하면 다시 가능")
    func canEdit_followsState() {
        let vm = makeFixture()
        #expect(vm.canEdit)
        vm.codeBlocks = [Block(type: .moveForward)]
        vm.run()
        #expect(vm.canEdit == false)
        vm.reset()
        #expect(vm.canEdit)
    }

    @Test("실행 강조 — 자식이 실행 중이면 부모 행과 자식 경로가 함께 강조됨")
    func activeHighlight_followsCurrentPath() async throws {
        let vm = makeFixture()
        vm.codeBlocks = [Block(type: .functionBlock, children: [Block(type: .moveForward)]), Block(type: .moveForward)]
        vm.run()
        try await Task.sleep(nanoseconds: 50_000_000)  // 첫 이동 애니메이션 도중
        #expect(vm.isRowActive(0))
        #expect(vm.isRowActive(1) == false)
        #expect(vm.activeChildPath(inRow: 0) == [0])
        #expect(vm.activeChildPath(inRow: 1).isEmpty)
        vm.reset()
        #expect(vm.isRowActive(0) == false)  // 실행이 끝나면 강조 없음
        #expect(vm.activeChildPath(inRow: 0).isEmpty)
    }

    @Test("실패 강조 — 자식이 실패하면 부모 행과 자식 경로가 함께 표시됨")
    func failedHighlight_followsFailedPath() async throws {
        let vm = makeFixture()
        vm.codeBlocks = [Block(type: .functionBlock, children: [Block(type: .collectItem)])]  // 보석이 없어 실패
        vm.run()
        try await waitUntilFinished(vm)
        #expect(vm.gameState == .failure)
        #expect(vm.isRowFailed(0))
        #expect(vm.isRowFailed(1) == false)
        #expect(vm.failedChildPath(inRow: 0) == [0])
        #expect(vm.failedChildPath(inRow: 1).isEmpty)
    }

    @Test("되돌리기 버튼 — 캐릭터가 움직였으면 블럭 유지, 안 움직였으면 전체 초기화")
    func resetOrClear_dependsOnCharacterMoved() {
        let vm = makeFixture()
        vm.codeBlocks = [Block(type: .moveForward)]
        vm.run()  // 실행을 시작하면 캐릭터가 움직인 상태가 됨
        #expect(vm.characterMoved)
        vm.resetOrClear()
        #expect(vm.codeBlocks.count == 1)
        #expect(vm.characterMoved == false)
        vm.resetOrClear()
        #expect(vm.codeBlocks.isEmpty)
    }

    @Test("실행 버튼 — 블럭이 없거나 실행 중일 때만 누를 수 없음")
    func canPressRun_rules() async throws {
        let vm = makeFixture()
        #expect(vm.canPressRun == false)  // 블럭 없음
        vm.codeBlocks = [Block(type: .moveBackward)]  // 뒤는 맵 밖이라 바로 실패 상태가 됨
        #expect(vm.canPressRun == true)
        vm.run()
        #expect(vm.canPressRun == false)  // 실행 중
        try await waitUntilFinished(vm)
        #expect(vm.gameState == .failure)
        #expect(vm.canPressRun == true)   // 실패한 뒤에도 누를 수 있음 — 누르면 캐릭터를 되돌리고 다시 실행
    }
}
