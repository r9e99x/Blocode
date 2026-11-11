//
//  GameBoardTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/1/26.
//
//  게임 판 규칙(이동·회전·조건·보석·스위치·포탈·리셋) 검증.
//  GameBoard는 순수 값 타입이라 SpriteKit 씬 없이 바로 확인한다.

import Testing
import Foundation
import SpriteKit
@testable import Blocode

@Suite("게임 판 규칙")
struct GameBoardTests {

    /// 가운데 세로 통로: (1,2)에서 위로 두 칸 가면 (1,0) 골인
    private func corridor() -> GameBoard {
        GameBoard(map: MapData(grid: [[0, 1, 0], [0, 1, 0], [0, 1, 0]],
                               start: Position(x: 1, y: 2), startDirection: .up,
                               goal: Position(x: 1, y: 0)))
    }

    /// 가로 한 줄 맵 — 기믹 테스트용 (0번 칸 시작, 오른쪽을 봄)
    private func row(_ cells: [Int], goal: Int? = nil, items: [Int]? = nil,
                     switches: [(at: Int, gate: Int)]? = nil, portals: [(a: Int, b: Int)]? = nil) -> GameBoard {
        func position(_ x: Int) -> Position { Position(x: x, y: 0) }
        return GameBoard(map: MapData(
            grid: [cells], start: position(0), startDirection: .right,
            goal: position(goal ?? cells.count - 1),
            items: items?.map(position),
            switches: switches?.map { SwitchGate(switchAt: position($0.at), gateAt: position($0.gate)) },
            portals: portals?.map { PortalPair(a: position($0.a), b: position($0.b)) }
        ))
    }

    // MARK: - 시작 상태

    @Test("맵의 시작 위치와 방향에서 시작")
    func startsAtMapStart() {
        let board = corridor()
        #expect(board.position == Position(x: 1, y: 2))
        #expect(board.direction == .up)
        #expect(board.hasGimmickChanges == false)
        #expect(board.isAtGoal == false)
    }

    // MARK: - 이동·회전

    @Test("앞으로 이동하면 위치가 바뀌고 목표에 도달")
    func moveForward_reachesGoal() {
        var board = corridor()
        let result1 = board.move(.forward)
        #expect(result1)
        #expect(board.position == Position(x: 1, y: 1))
        #expect(board.isAtGoal == false)
        let result2 = board.move(.forward)
        #expect(result2)
        #expect(board.isAtGoal)
    }

    @Test("뒤로 이동은 바라보는 방향을 유지한 채 반대로 이동")
    func moveBackward_keepsDirection() {
        var board = corridor()
        _ = board.move(.forward)
        let result3 = board.move(.backward)
        #expect(result3)
        #expect(board.position == Position(x: 1, y: 2))
        #expect(board.direction == .up)
    }

    @Test("벽과 맵 밖으로는 이동하지 않음")
    func move_blockedByWallAndBounds() {
        var board = corridor()
        let result4 = board.move(.backward)  // 맵 아래쪽 밖
        #expect(result4 == false)
        #expect(board.position == Position(x: 1, y: 2))

        board.turn(left: true)
        let result5 = board.move(.forward)   // 왼쪽은 벽
        #expect(result5 == false)
        #expect(board.position == Position(x: 1, y: 2))
    }

    @Test("회전은 90도씩 바뀌고 위치는 그대로")
    func turn_changesDirectionOnly() {
        var board = corridor()
        board.turn(left: true)
        #expect(board.direction == .left)
        board.turn(left: false)
        board.turn(left: false)
        #expect(board.direction == .right)
        #expect(board.position == Position(x: 1, y: 2))
    }

    // MARK: - 조건

    @Test("if 조건은 앞 칸 기준")
    func conditions_lookAtFrontTile() {
        var board = corridor()
        #expect(board.satisfies(.pathClear))
        #expect(board.satisfies(.pathBlocked) == false)

        board.turn(left: true)  // 왼쪽은 벽
        #expect(board.satisfies(.pathClear) == false)
        #expect(board.satisfies(.pathBlocked))
    }

    // MARK: - 보석

    @Test("보석은 그 칸에서 한 번만 획득")
    func collectItem_onlyOnceOnItemTile() {
        var board = row([1, 1, 1], items: [1])
        let result6 = board.collectItem()  // 보석 없는 칸
        #expect(result6 == false)
        _ = board.move(.forward)
        let result7 = board.collectItem()
        #expect(result7)
        #expect(board.collectedItems == [Position(x: 1, y: 0)])
        #expect(board.hasGimmickChanges)
        let result8 = board.collectItem()  // 이미 모음
        #expect(result8 == false)
    }

    // MARK: - 스위치

    @Test("스위치를 작동하면 문이 열려 지나갈 수 있음")
    func activateSwitch_opensGate() {
        var board = row([1, 0, 1], switches: [(at: 0, gate: 1)])
        let result9 = board.move(.forward)  // 닫힌 문
        #expect(result9 == false)
        #expect(board.satisfies(.pathBlocked))

        let result10 = board.activateSwitch()
        #expect(result10 == .opened(Position(x: 1, y: 0)))
        #expect(board.hasGimmickChanges)
        #expect(board.satisfies(.pathClear))
        let result11 = board.move(.forward)
        #expect(result11)
    }

    @Test("스위치 재작동은 성공이지만 변화 없음, 스위치 없는 칸은 실패")
    func activateSwitch_repeatAndMissing() {
        var board = row([1, 1, 1], switches: [(at: 0, gate: 2)])
        _ = board.activateSwitch()
        let result12 = board.activateSwitch()
        #expect(result12 == .alreadyOpen)
        #expect(board.openedGates.count == 1)

        _ = board.move(.forward)
        let result13 = board.activateSwitch()
        #expect(result13 == .noSwitch)
    }

    // MARK: - 포탈

    @Test("포탈은 양방향으로 짝 칸에 순간이동")
    func enterPortal_movesToPair() {
        var board = row([1, 1, 1, 1], portals: [(a: 1, b: 3)])
        _ = board.move(.forward)
        let result14 = board.enterPortal()
        #expect(result14 == Position(x: 3, y: 0))
        #expect(board.position == Position(x: 3, y: 0))

        let result15 = board.enterPortal()  // 반대 방향
        #expect(result15 == Position(x: 1, y: 0))
        #expect(board.position == Position(x: 1, y: 0))
    }

    @Test("포탈이 없는 칸에서는 이동 없음")
    func enterPortal_noPortal() {
        var board = row([1, 1, 1], portals: [(a: 1, b: 2)])
        let result16 = board.enterPortal()
        #expect(result16 == nil)
        #expect(board.position == Position(x: 0, y: 0))
    }

    // MARK: - 리셋

    @Test("리셋하면 위치·방향·보석·문이 모두 시작 상태로")
    func reset_restoresEverything() {
        var board = row([1, 1, 0, 1], items: [1], switches: [(at: 1, gate: 2)])
        _ = board.move(.forward)
        _ = board.collectItem()
        _ = board.activateSwitch()
        board.turn(left: true)

        board.reset()
        #expect(board.position == Position(x: 0, y: 0))
        #expect(board.direction == .right)
        #expect(board.collectedItems.isEmpty)
        #expect(board.openedGates.isEmpty)
        #expect(board.hasGimmickChanges == false)
    }
}

// MARK: - VM ↔ 화면 연결

/// 판 변화를 기록만 하는 가짜 화면 — 어떤 순서로 무엇을 알리는지 확인
@MainActor
private final class RecordingRenderer: GameBoardRendering {
    var events: [BoardEvent] = []
    var speeds: [Double] = []
    var lastBoard: GameBoard?

    func update(board: GameBoard, event: BoardEvent, speed: Double) {
        events.append(event)
        speeds.append(speed)
        lastBoard = board
    }
}

@MainActor
@Suite("게임 판과 화면 연결")
struct GameBoardRenderingTests {

    /// 가로 한 줄 맵: 0 시작 / 1 보석 / 2 스위치 / 3 문 / 4↔5 포탈 / 6 골
    private let gimmickMap = MapData(
        grid: [[1, 1, 1, 0, 1, 1, 1]],
        start: Position(x: 0, y: 0), startDirection: .right, goal: Position(x: 6, y: 0),
        items: [Position(x: 1, y: 0)],
        switches: [SwitchGate(switchAt: Position(x: 2, y: 0), gateAt: Position(x: 3, y: 0))],
        portals: [PortalPair(a: Position(x: 4, y: 0), b: Position(x: 5, y: 0))]
    )

    /// 위 맵을 처음부터 끝까지 푸는 프로그램
    private let solution: [Block] = [
        Block(type: .turnLeft), Block(type: .turnRight),
        Block(type: .moveForward), Block(type: .collectItem),
        Block(type: .moveForward), Block(type: .activateSwitch),
        Block(type: .moveForward), Block(type: .moveForward), Block(type: .moveForward)
    ]

    private func makeViewModel(map: MapData) -> GameViewModel {
        let stage = Stage(id: "unittest_\(UUID().uuidString)", chapter: 0, stageNumber: 0, name: "Rendering",
                          mapData: map, starThresholds: StarThresholds(threeStar: 99, twoStar: 99))
        return GameViewModel(stage: stage, progress: .makeForTesting(), executionSpeed: { 4 })
    }

    private func waitUntilFinished(_ viewModel: GameViewModel) async throws {
        let deadline = Date().addingTimeInterval(15)
        while viewModel.gameState == .running, Date() < deadline {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    @Test("실행하면 변화를 순서대로 알리고 실행 속도도 함께 전달")
    func run_notifiesEventsInOrder() async throws {
        let vm = makeViewModel(map: gimmickMap)
        let renderer = RecordingRenderer()
        vm.renderer = renderer
        vm.codeBlocks = solution
        vm.run()
        try await waitUntilFinished(vm)

        #expect(vm.gameState == .success)
        let expected: [BoardEvent] = [
            .turned, .turned,
            .moved, .itemCollected(Position(x: 1, y: 0)),
            .moved, .gateOpened,
            .moved,            // 열린 문으로 이동
            .moved, .teleported,  // 포탈 칸 도착 → 짝으로 이동
            .moved             // 골
        ]
        #expect(renderer.events == expected)
        #expect(renderer.speeds.allSatisfy { $0 == 4 })
        #expect(renderer.lastBoard?.isAtGoal == true)

        vm.reset()
        #expect(renderer.events.last == .reset)
        #expect(renderer.lastBoard?.position == gimmickMap.start)
    }

    @Test("화면이 없어도 규칙대로 실행돼 클리어됨")
    func run_worksWithoutRenderer() async throws {
        let vm = makeViewModel(map: gimmickMap)
        vm.codeBlocks = solution
        vm.run()
        try await waitUntilFinished(vm)
        #expect(vm.gameState == .success)
        #expect(vm.collectedItems == [Position(x: 1, y: 0)])
        #expect(vm.board.openedGates == [Position(x: 3, y: 0)])
    }

    @Test("이동 대기 중 리셋하면 포탈이 작동하지 않음")
    func reset_cancelsPendingPortal() async throws {
        let map = MapData(grid: [[1, 1, 1]], start: Position(x: 0, y: 0), startDirection: .right, goal: Position(x: 2, y: 0),
                          portals: [PortalPair(a: Position(x: 1, y: 0), b: Position(x: 2, y: 0))])
        let vm = makeViewModel(map: map)
        let renderer = RecordingRenderer()
        vm.renderer = renderer
        vm.codeBlocks = [Block(type: .moveForward)]
        vm.run()
        try await Task.sleep(nanoseconds: 20_000_000)  // 포탈 칸에 도착해 애니메이션 대기 중
        vm.reset()
        try await Task.sleep(nanoseconds: 200_000_000)  // 이전 실행이 남아 있다면 움직일 시간

        #expect(renderer.events.contains(.teleported) == false)
        #expect(vm.board.position == map.start)
        #expect(vm.gameState == .idle)
    }

    @Test("진짜 GameScene도 VM과 같은 상태를 유지하고 리셋·크기 변경에 안전함")
    func gameScene_followsBoard() async throws {
        let vm = makeViewModel(map: gimmickMap)
        let scene = GameScene(mapData: gimmickMap)
        scene.size = CGSize(width: 400, height: 400)
        scene.setupMap()
        vm.renderer = scene
        vm.codeBlocks = solution
        vm.run()
        try await waitUntilFinished(vm)

        #expect(vm.gameState == .success)
        #expect(scene.board.position == vm.board.position)
        #expect(scene.board.collectedItems == vm.board.collectedItems)
        #expect(scene.board.openedGates == vm.board.openedGates)

        scene.size = CGSize(width: 300, height: 300)  // 크기 변경 — 맵 재구성 때 저장된 상태 사용
        #expect(scene.board.openedGates == vm.board.openedGates)

        vm.reset()
        #expect(scene.board.position == gimmickMap.start)
        #expect(scene.board.hasGimmickChanges == false)
        _ = scene  // weak 참조 — 테스트 끝까지 붙잡음
    }
}
