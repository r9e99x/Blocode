//
//  GameBoardTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/1/26.
//
//  게임 판 규칙(이동·회전·조건·보석·스위치·포탈·리셋) 검증.
//  GameBoard는 순수 값 타입이라 SpriteKit 씬 없이 바로 확인한다.

import Testing
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
