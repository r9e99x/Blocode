//
//  GameBoard.swift
//  Blocode
//
//  Created by 조준희 on 11/1/26.
//

import Foundation

// MARK: - GameBoard
/// 게임 진행 상태의 원본과 판 위의 규칙 — 캐릭터 위치·방향, 모은 보석, 열린 문
/// UI를 모르는 순수 값 타입이라 화면 없이 규칙만 검증할 수 있음
struct GameBoard {

    /// 캐릭터 이동 방향 — 앞으로/뒤로만 구분 (회전은 turn으로 처리)
    enum MoveDirection {
        case forward   // 바라보는 방향으로 이동
        case backward  // 바라보는 반대 방향으로 이동
    }

    /// 스위치 작동 결과
    enum SwitchResult: Equatable {
        case noSwitch           // 현재 칸에 스위치가 없음 (실패)
        case alreadyOpen        // 이미 열린 문의 스위치를 다시 작동 (성공, 변화 없음)
        case opened(Position)   // 연결된 문을 새로 염
    }

    let map: MapData
    private(set) var position: Position              // 캐릭터 현재 칸
    private(set) var direction: Direction            // 캐릭터가 바라보는 방향
    private(set) var collectedItems: Set<Position> = []  // 이미 모은 보석
    private(set) var openedGates: Set<Position> = []     // 이미 열린 문

    init(map: MapData) {
        self.map = map
        position = map.start
        direction = map.startDirection
    }

    // MARK: - 판정

    /// 목표 지점에 도착했는지
    var isAtGoal: Bool { map.isGoal(position) }

    /// 시작 상태에서 달라진 기믹이 있는지 — 있으면 리셋 때 맵을 다시 그려야 함
    var hasGimmickChanges: Bool { !collectedItems.isEmpty || !openedGates.isEmpty }

    /// 지나갈 수 있는 칸인지 — 바닥이거나 열린 문
    func isWalkable(_ target: Position) -> Bool {
        map.isFloor(target) || openedGates.contains(target)
    }

    /// if 블럭 조건 판정 — 바라보는 방향의 앞 칸 기준
    func satisfies(_ condition: IfCondition) -> Bool {
        let frontIsWalkable = isWalkable(position.next(direction: direction))
        switch condition {
        case .pathClear:   return frontIsWalkable
        case .pathBlocked: return !frontIsWalkable
        }
    }

    // MARK: - 이동

    /// 한 칸 이동 — 벽이면 그대로 두고 false 반환
    mutating func move(_ moveDirection: MoveDirection) -> Bool {
        let target: Position
        switch moveDirection {
        case .forward:  target = position.next(direction: direction)
        case .backward: target = position.previous(direction: direction)
        }
        guard isWalkable(target) else { return false }
        position = target
        return true
    }

    /// 왼쪽 또는 오른쪽으로 90도 회전
    mutating func turn(left: Bool) {
        direction = left ? direction.turnedLeft : direction.turnedRight
    }

    // MARK: - 기믹

    /// 현재 칸이 포탈이면 짝으로 순간이동하고 도착 칸 반환 (도착 칸에서 다시 이동하지 않도록 이동 후 1회만 호출)
    mutating func enterPortal() -> Position? {
        guard let pair = map.portals?.first(where: { $0.a == position || $0.b == position }) else {
            return nil
        }
        position = pair.a == position ? pair.b : pair.a
        return position
    }

    /// 현재 칸의 보석 획득 — 보석이 없거나 이미 모았으면 false (보석은 1회성)
    mutating func collectItem() -> Bool {
        guard map.items?.contains(position) == true, !collectedItems.contains(position) else {
            return false
        }
        collectedItems.insert(position)
        return true
    }

    /// 현재 칸의 스위치 작동 — 연결된 문을 열기
    mutating func activateSwitch() -> SwitchResult {
        guard let gate = map.switches?.first(where: { $0.switchAt == position })?.gateAt else {
            return .noSwitch
        }
        guard !openedGates.contains(gate) else { return .alreadyOpen }
        openedGates.insert(gate)
        return .opened(gate)
    }

    // MARK: - 리셋

    /// 시작 상태로 되돌림 — 위치·방향과 기믹 상태 모두
    mutating func reset() {
        self = GameBoard(map: map)
    }
}
