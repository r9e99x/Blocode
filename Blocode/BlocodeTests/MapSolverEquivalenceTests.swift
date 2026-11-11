//
//  MapSolverEquivalenceTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/12/26.
//
//  빠른 정수 상태 탐색(MapSolver)이 GameBoard 규칙을 그대로 옮긴 것인지 확인.
//  테스트 안의 기준 탐색은 GameBoard로 직접 판을 굴리는 느리지만 단순한 구현이고,
//  모든 스테이지와 무작위 맵에서 풀이 가능 여부와 가장 짧은 길이가 같아야 한다.
//  또 최악의 크기(10×10, 보석 6·문 4)에서 화면이 멈추지 않을 만큼 빠른지 확인한다.

import Testing
import Foundation
@testable import Blocode

@MainActor
@Suite("맵 풀이 탐색 동등성")
struct MapSolverEquivalenceTests {

    // MARK: - 기준 탐색 (GameBoard 사용)

    private struct BoardKey: Hashable {
        let position: Position
        let direction: Direction
        let items: Set<Position>
        let gates: Set<Position>
        init(_ board: GameBoard) {
            position = board.position
            direction = board.direction
            items = board.collectedItems
            gates = board.openedGates
        }
    }

    private func apply(_ type: BlockType, to board: GameBoard) -> GameBoard? {
        var next = board
        switch type {
        case .moveForward:
            guard next.move(.forward) else { return nil }
            _ = next.enterPortal()
        case .moveBackward:
            guard next.move(.backward) else { return nil }
            _ = next.enterPortal()
        case .turnLeft: next.turn(left: true)
        case .turnRight: next.turn(left: false)
        case .collectItem:
            guard next.collectItem() else { return nil }
        case .activateSwitch:
            guard next.activateSwitch() != .noSwitch else { return nil }
        default: return nil
        }
        return next
    }

    /// 가장 짧은 풀이 길이 — 없으면 nil
    private func referenceLength(_ map: MapData, palette: [BlockType], collectingAll: Bool) -> Int? {
        let itemCount = map.items?.count ?? 0
        let start = GameBoard(map: map)
        var queue: [(board: GameBoard, length: Int)] = [(start, 0)]
        var visited: Set<BoardKey> = [BoardKey(start)]
        var head = 0
        while head < queue.count {
            let (board, length) = queue[head]
            head += 1
            for type in palette {
                guard let next = apply(type, to: board) else { continue }
                if next.isAtGoal {
                    if !collectingAll || next.collectedItems.count == itemCount { return length + 1 }
                    continue
                }
                if visited.insert(BoardKey(next)).inserted { queue.append((next, length + 1)) }
            }
        }
        return nil
    }

    /// 풀이를 GameBoard로 그대로 실행해 목표에 도착하는지 (보석 조건 포함)
    private func replays(_ blocks: [BlockType], on map: MapData, collectingAll: Bool) -> Bool {
        var board = GameBoard(map: map)
        for block in blocks {
            guard let next = apply(block, to: board) else { return false }
            board = next
            if board.isAtGoal {
                return !collectingAll || board.collectedItems.count == (map.items?.count ?? 0)
            }
        }
        return false
    }

    private func expectSame(_ map: MapData, palette: [BlockType], label: String) {
        for collectingAll in [false, true] {
            let reference = referenceLength(map, palette: palette, collectingAll: collectingAll)
            let outcome = MapSolver.solve(map, palette: palette, collectingAllItems: collectingAll)
            switch outcome {
            case .solved(let path):
                #expect(reference == path.count, "\(label): 길이 다름 기준 \(String(describing: reference)) 빠른 \(path.count)")
                #expect(replays(path, on: map, collectingAll: collectingAll), "\(label): 풀이가 실제로는 실패")
            case .unsolvable:
                #expect(reference == nil, "\(label): 기준은 풀었는데 빠른 탐색은 못 품 (\(String(describing: reference)))")
            case .tooComplex:
                Issue.record("\(label): 작은 맵인데 tooComplex")
            }
        }
    }

    // MARK: - 실제 스테이지

    @Test("모든 스테이지에서 기준 탐색과 결과가 같음")
    func sameOnEveryStage() async {
        let stages = ChapterCatalog.all.flatMap { StageLoader.loadChapter($0.number, stageCount: $0.stageCount) }
        #expect(stages.count == 104)
        for stage in stages {
            expectSame(stage.mapData, palette: stage.paletteBlocks, label: stage.id)
            await Task.yield()  // 메인을 오래 붙잡으면 같이 도는 실행 테스트의 대기 시간이 넘어감
        }
    }

    // MARK: - 무작위 맵

    /// 같은 값이 나오는 난수 — 실패해도 같은 맵으로 다시 확인할 수 있음
    private struct SeededRandom: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }

    private func randomMap(_ random: inout SeededRandom) -> (MapData, [BlockType]) {
        let width = Int.random(in: 4...6, using: &random)
        let height = Int.random(in: 4...6, using: &random)
        var grid = (0..<height).map { _ in (0..<width).map { _ in Int.random(in: 0...9, using: &random) < 6 ? 1 : 0 } }
        var cells = (0..<height).flatMap { y in (0..<width).map { x in Position(x: x, y: y) } }
        cells.shuffle(using: &random)
        func take() -> Position { cells.removeLast() }

        let start = take()
        let goal = take()
        grid[start.y][start.x] = 1
        grid[goal.y][goal.x] = 1
        // 보석·스위치·포탈은 서로 겹치거나 목표·시작과 겹쳐도 됨 (규칙이 같은지 보려는 것이라 일부러 거칠게)
        var items: [Position] = []
        for _ in 0..<Int.random(in: 0...2, using: &random) {
            let p = take()
            grid[p.y][p.x] = 1
            items.append(p)
        }
        var switches: [SwitchGate] = []
        for _ in 0..<Int.random(in: 0...2, using: &random) {
            let s = take(), g = take()
            grid[s.y][s.x] = 1
            grid[g.y][g.x] = 0
            switches.append(SwitchGate(switchAt: s, gateAt: g))
        }
        var portals: [PortalPair] = []
        if Bool.random(using: &random) {
            let a = take(), b = take()
            grid[a.y][a.x] = 1
            grid[b.y][b.x] = 1
            portals.append(PortalPair(a: a, b: b))
        }
        let direction = [Direction.up, .down, .left, .right].randomElement(using: &random)!
        let map = MapData(grid: grid, start: start, startDirection: direction, goal: goal,
                          items: items.isEmpty ? nil : items,
                          switches: switches.isEmpty ? nil : switches,
                          portals: portals.isEmpty ? nil : portals)
        var palette: [BlockType] = [.moveForward, .collectItem, .activateSwitch]
        for extra in [BlockType.moveBackward, .turnLeft, .turnRight] where Bool.random(using: &random) {
            palette.append(extra)
        }
        return (map, palette)
    }

    @Test("무작위 맵 300개에서 기준 탐색과 결과가 같음")
    func sameOnRandomMaps() async {
        var random = SeededRandom(state: 20261112)
        for index in 0..<300 {
            let (map, palette) = randomMap(&random)
            expectSame(map, palette: palette, label: "무작위 맵 \(index)")
            await Task.yield()
        }
    }

    // MARK: - 속도

    @Test("가장 큰 맵(10×10, 보석 6, 문 4)도 화면이 멈추지 않을 만큼 빠름")
    func worstCaseIsFast() {
        var grid = Array(repeating: Array(repeating: 1, count: 10), count: 10)
        let items = (0..<6).map { Position(x: 2 + $0, y: 2) }
        var switches: [SwitchGate] = []
        for i in 0..<4 {
            grid[0][i * 2] = 0
            switches.append(SwitchGate(switchAt: Position(x: i + 1, y: 5), gateAt: Position(x: i * 2, y: 0)))
        }
        // 목표를 벽으로 막아 모든 상태를 끝까지 탐색하게 함
        grid[8][9] = 0
        grid[9][8] = 0
        let map = MapData(grid: grid, start: Position(x: 0, y: 9), startDirection: .right,
                          goal: Position(x: 9, y: 9), items: items, switches: switches, portals: nil)
        let palette: [BlockType] = [.moveForward, .moveBackward, .turnLeft, .turnRight, .collectItem, .activateSwitch]

        let started = Date()
        let result = MapValidator.validate(map, palette: palette)
        let elapsed = Date().timeIntervalSince(started)
        #expect(result.issues == ["선택한 블럭으로는 목표에 도착할 수 없어요."])
        #expect(elapsed < 4, "검증에 \(elapsed)초 걸림")  // 디버그 빌드 기준 — 이전 구현은 13초
    }
}
