//
//  StageSolvabilityTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/2/26.
//
//  앱에 들어 있는 모든 스테이지를 실제로 깰 수 있는지 검증.
//  JSON에 정답이 없으므로 팔레트의 기본 블럭으로 갈 수 있는 상태를 전부 탐색해 풀이를 찾고,
//  찾은 풀이를 실제 실행 엔진(GameViewModel)에 넣어 클리어되는지 확인한다.
//  별 3개 기준(블럭 수)을 달성할 수 있는지와 난이도는 검증하지 않는다.

import Testing
import Foundation
@testable import Blocode

@MainActor
@Suite("스테이지 풀이 가능 여부")
struct StageSolvabilityTests {

    /// 탐색 중 같은 상태를 다시 보지 않기 위한 열쇠 — 판의 상태 전부
    private struct BoardKey: Hashable {
        let position: Position
        let direction: Direction
        let collectedItems: Set<Position>
        let openedGates: Set<Position>

        init(_ board: GameBoard) {
            position = board.position
            direction = board.direction
            collectedItems = board.collectedItems
            openedGates = board.openedGates
        }
    }

    /// 앱에 들어 있는 모든 스테이지 (개수는 StageDataIntegrityTests가 따로 검증)
    private var allStages: [Stage] {
        ChapterCatalog.all.flatMap { StageLoader.loadChapter($0.number, stageCount: $0.stageCount) }
    }

    /// 블럭 하나를 실행한 뒤의 판 — 실패하는 블럭이면 nil (GameViewModel.executeBlocks와 같은 순서)
    private func apply(_ type: BlockType, to board: GameBoard) -> GameBoard? {
        var next = board
        switch type {
        case .moveForward:
            guard next.move(.forward) else { return nil }
            _ = next.enterPortal()
        case .moveBackward:
            guard next.move(.backward) else { return nil }
            _ = next.enterPortal()
        case .turnLeft:
            next.turn(left: true)
        case .turnRight:
            next.turn(left: false)
        case .collectItem:
            guard next.collectItem() else { return nil }
        case .activateSwitch:
            guard next.activateSwitch() != .noSwitch else { return nil }
        case .repeatBlock, .ifBlock, .functionBlock:
            // 컨테이너는 안에 넣은 기본 블럭을 실행할 뿐이라, 기본 블럭만 탐색해도 갈 수 있는 곳이 같음
            return nil
        }
        return next
    }

    /// 가장 짧은 풀이를 너비 우선 탐색으로 찾음 — 없으면 nil
    /// - Parameter collectingAllItems: true면 보석을 전부 모은 뒤 목표에 도착하는 풀이만 인정
    private func shortestSolution(for stage: Stage, collectingAllItems: Bool = false) -> [BlockType]? {
        let itemCount = stage.mapData.items?.count ?? 0
        let start = GameBoard(map: stage.mapData)
        var queue: [(board: GameBoard, path: [BlockType])] = [(start, [])]
        var visited: Set<BoardKey> = [BoardKey(start)]
        var head = 0  // removeFirst는 매번 배열을 당겨 느리므로 위치만 옮김

        while head < queue.count {
            let (board, path) = queue[head]
            head += 1
            for type in stage.paletteBlocks {
                guard let next = apply(type, to: board) else { continue }
                if next.isAtGoal {
                    // 실제 게임은 목표에 닿는 순간 끝나므로, 조건이 안 맞아도 여기서 더 나아가지 않음
                    if !collectingAllItems || next.collectedItems.count == itemCount {
                        return path + [type]
                    }
                    continue
                }
                if visited.insert(BoardKey(next)).inserted {
                    queue.append((next, path + [type]))
                }
            }
        }
        return nil
    }

    /// 풀이를 실제 실행 엔진으로 끝까지 실행 — 시간 안에 안 끝나면 running 상태로 돌아옴
    private func run(_ solution: [BlockType], on stage: Stage) async throws -> GameViewModel {
        let vm = GameViewModel(stage: stage, progress: .makeForTesting(), executionSpeed: { 1000 })
        vm.codeBlocks = solution.map { Block(type: $0) }
        vm.run()
        let deadline = Date().addingTimeInterval(10)
        while vm.gameState == .running, Date() < deadline {
            try await Task.sleep(for: .milliseconds(5))
        }
        return vm
    }

    /// 탐색기 검증용 작은 스테이지
    private func makeStage(grid: [[Int]], goal: Position, items: [Position]? = nil,
                           switches: [SwitchGate]? = nil, portals: [PortalPair]? = nil,
                           palette: [BlockType]) -> Stage {
        let map = MapData(grid: grid, start: Position(x: 0, y: 0), startDirection: .right, goal: goal,
                          items: items, switches: switches, portals: portals)
        return Stage(id: "unittest_\(UUID().uuidString)", chapter: 0, stageNumber: 0, name: "Solver Test",
                     mapData: map, starThresholds: StarThresholds(threeStar: 99, twoStar: 99),
                     availableBlocks: palette)
    }

    // MARK: - 실제 스테이지

    @Test("모든 스테이지를 클리어할 수 있음")
    func everyStage_canBeCleared() async throws {
        let stages = allStages
        #expect(!stages.isEmpty)
        for stage in stages {
            guard let solution = shortestSolution(for: stage) else {
                Issue.record("\(stage.id): 팔레트 블럭으로 목표까지 갈 방법이 없음")
                continue
            }
            let vm = try await run(solution, on: stage)
            #expect(vm.gameState == .success, "\(stage.id): 찾은 풀이가 실제 실행에서 클리어되지 않음 \(solution)")
        }
    }

    @Test("보석 스테이지는 보석을 전부 모으고 클리어할 수 있음")
    func gemStages_canBeClearedWithAllItems() async throws {
        let stages = allStages.filter { !($0.mapData.items ?? []).isEmpty }
        #expect(!stages.isEmpty)
        for stage in stages {
            guard let solution = shortestSolution(for: stage, collectingAllItems: true) else {
                Issue.record("\(stage.id): 보석을 전부 모으고 목표까지 갈 방법이 없음 (별 3개 불가능)")
                continue
            }
            let vm = try await run(solution, on: stage)
            #expect(vm.gameState == .success, "\(stage.id): 찾은 풀이가 실제 실행에서 클리어되지 않음 \(solution)")
            #expect(vm.collectedItems.count == stage.mapData.items?.count, "\(stage.id): 보석을 다 모으지 못함")
        }
    }

    // MARK: - 탐색기 자체 검증

    @Test("막힌 맵과 블럭이 부족한 맵은 풀이 없음으로 판정")
    func solver_reportsUnsolvableMaps() {
        // 벽으로 막힘
        #expect(shortestSolution(for: makeStage(grid: [[1, 0, 1]], goal: Position(x: 2, y: 0),
                                                palette: [.moveForward, .turnLeft, .turnRight])) == nil)
        // 꺾어야 하는데 회전 블럭이 팔레트에 없음
        let corner: [[Int]] = [[1, 1], [0, 1]]
        #expect(shortestSolution(for: makeStage(grid: corner, goal: Position(x: 1, y: 1),
                                                palette: [.moveForward])) == nil)
        #expect(shortestSolution(for: makeStage(grid: corner, goal: Position(x: 1, y: 1),
                                                palette: [.moveForward, .turnRight]))
                == [.moveForward, .turnRight, .moveForward])
    }

    @Test("보석이 목표 뒤에 있으면 목표에서 게임이 끝나 전부 모을 수 없음")
    func solver_stopsAtGoal() {
        let stage = makeStage(grid: [[1, 1, 1, 1]], goal: Position(x: 2, y: 0), items: [Position(x: 3, y: 0)],
                              palette: [.moveForward, .collectItem])
        #expect(shortestSolution(for: stage) == [.moveForward, .moveForward])
        #expect(shortestSolution(for: stage, collectingAllItems: true) == nil)
    }

    @Test("탐색기가 스위치와 포탈 규칙을 따름")
    func solver_usesGimmicks() {
        // 문은 스위치를 작동해야 열림
        let gate = SwitchGate(switchAt: Position(x: 0, y: 0), gateAt: Position(x: 1, y: 0))
        #expect(shortestSolution(for: makeStage(grid: [[1, 0, 1]], goal: Position(x: 2, y: 0), switches: [gate],
                                                palette: [.moveForward, .activateSwitch]))
                == [.activateSwitch, .moveForward, .moveForward])
        // 포탈을 밟으면 짝으로 순간이동해 벽을 건너뜀
        let portal = PortalPair(a: Position(x: 1, y: 0), b: Position(x: 3, y: 0))
        #expect(shortestSolution(for: makeStage(grid: [[1, 1, 0, 1]], goal: Position(x: 3, y: 0), portals: [portal],
                                                palette: [.moveForward])) == [.moveForward])
    }
}
