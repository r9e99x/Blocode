//
//  MapData.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation

// MARK: - Direction
/// 캐릭터가 현재 바라보고 있는 방향
/// 2D 탑뷰 기준 (위쪽이 up)
enum Direction: String, Codable {
    case up    // 위
    case down  // 아래
    case left  // 왼쪽
    case right // 오른쪽

    /// 오른쪽으로 90도 회전한 방향 반환
    var turnedRight: Direction {
        switch self {
        case .up:    return .right  // 위 → 오른쪽
        case .right: return .down   // 오른쪽 → 아래
        case .down:  return .left   // 아래 → 왼쪽
        case .left:  return .up     // 왼쪽 → 위
        }
    }

    /// 왼쪽으로 90도 회전한 방향 반환
    var turnedLeft: Direction {
        switch self {
        case .up:    return .left   // 위 → 왼쪽
        case .left:  return .down   // 왼쪽 → 아래
        case .down:  return .right  // 아래 → 오른쪽
        case .right: return .up     // 오른쪽 → 위
        }
    }
}

// MARK: - Position
/// 타일 맵 위의 좌표 (열, 행)
struct Position: Codable, Equatable {
    var x: Int  // 열 (왼→오른쪽, 0부터 시작)
    var y: Int  // 행 (위→아래, 0부터 시작)

    /// 현재 방향으로 한 칸 이동했을 때의 다음 좌표 반환
    func next(direction: Direction) -> Position {
        switch direction {
        case .up:    return Position(x: x,     y: y - 1)  // 위: y 감소
        case .down:  return Position(x: x,     y: y + 1)  // 아래: y 증가
        case .left:  return Position(x: x - 1, y: y)      // 왼쪽: x 감소
        case .right: return Position(x: x + 1, y: y)      // 오른쪽: x 증가
        }
    }

    /// 현재 방향의 반대 방향으로 한 칸 이동했을 때의 좌표 반환 (뒤로 이동)
    /// 180도 회전(turnedRight × 2)한 방향으로 next를 호출하여 뒤 좌표 계산
    func previous(direction: Direction) -> Position {
        return next(direction: direction.turnedRight.turnedRight)
    }
}

// MARK: - TileType
/// 타일 맵의 각 칸 종류 — grid 배열의 Int 값과 1:1 매핑
enum TileType: Int, Codable {
    case wall  = 0  // 벽 (이동 불가)
    case floor = 1  // 바닥 (이동 가능)
}

// MARK: - MapData
/// 스테이지 맵의 데이터 구조
/// JSON 파일에서 디코딩하여 사용
struct MapData: Codable {
    /// 타일 격자: grid[row][col] → row = y, col = x
    /// 0 = 벽, 1 = 이동 가능한 바닥
    var grid: [[Int]]

    /// 캐릭터 시작 위치 (x: 열, y: 행)
    var start: Position

    /// 캐릭터 시작 방향
    var startDirection: Direction

    /// 목표 지점 위치 (여기 도달하면 클리어)
    var goal: Position

    // MARK: - 헬퍼

    /// 맵의 가로 칸 수 — grid 첫 행의 열 수
    var width: Int {
        return grid.first?.count ?? 0
    }

    /// 맵의 세로 칸 수 — grid의 행 수
    var height: Int {
        return grid.count
    }

    /// 특정 좌표가 맵 범위 안에 있는지 확인 (경계 검사)
    func isInBounds(_ position: Position) -> Bool {
        return position.x >= 0 && position.x < width &&
               position.y >= 0 && position.y < height
    }

    /// 특정 좌표가 이동 가능한 바닥 타일인지 확인
    /// 범위 밖이면 false 반환 (벽으로 처리)
    func isFloor(_ position: Position) -> Bool {
        guard isInBounds(position) else { return false }
        return grid[position.y][position.x] == TileType.floor.rawValue
    }

    /// 특정 좌표가 목표 지점인지 확인 — 클리어 판정에 사용
    func isGoal(_ position: Position) -> Bool {
        return position == goal
    }
}
