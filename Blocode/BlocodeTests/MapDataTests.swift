//
//  MapDataTests.swift
//  BlocodeTests
//

import Testing
@testable import Blocode

@Suite("MapData — 방향·좌표·타일 판정")
struct MapDataTests {

    // MARK: - Direction 회전

    @Test("turnedRight는 시계방향으로 순환")
    func turnedRight_cyclesClockwise() {
        #expect(Direction.up.turnedRight == .right)
        #expect(Direction.right.turnedRight == .down)
        #expect(Direction.down.turnedRight == .left)
        #expect(Direction.left.turnedRight == .up)
    }

    @Test("turnedLeft는 반시계방향으로 순환")
    func turnedLeft_cyclesCounterClockwise() {
        #expect(Direction.up.turnedLeft == .left)
        #expect(Direction.left.turnedLeft == .down)
        #expect(Direction.down.turnedLeft == .right)
        #expect(Direction.right.turnedLeft == .up)
    }

    @Test("오른쪽 돈 뒤 왼쪽으로 돌면 원래 방향으로 복귀", arguments: [Direction.up, .down, .left, .right])
    func turnedRightThenLeft_returnsToOriginal(direction: Direction) {
        #expect(direction.turnedRight.turnedLeft == direction)
    }

    // MARK: - Position 이동

    @Test("next는 바라보는 방향으로 한 칸 이동")
    func next_movesOneTileInFacingDirection() {
        let pos = Position(x: 2, y: 2)
        #expect(pos.next(direction: .up)    == Position(x: 2, y: 1))
        #expect(pos.next(direction: .down)  == Position(x: 2, y: 3))
        #expect(pos.next(direction: .left)  == Position(x: 1, y: 2))
        #expect(pos.next(direction: .right) == Position(x: 3, y: 2))
    }

    @Test("previous는 바라보는 반대 방향으로 이동")
    func previous_movesOppositeOfFacingDirection() {
        let pos = Position(x: 2, y: 2)
        #expect(pos.previous(direction: .up)    == pos.next(direction: .down))
        #expect(pos.previous(direction: .right) == pos.next(direction: .left))
    }

    // MARK: - MapData 경계/타일 판정

    private func makeMap(grid: [[Int]], start: Position = Position(x: 0, y: 0), goal: Position = Position(x: 0, y: 0)) -> MapData {
        MapData(grid: grid, start: start, startDirection: .up, goal: goal)
    }

    @Test("격자 안이면 true, 밖이면 false")
    func isInBounds_trueInsideGridFalseOutside() {
        let map = makeMap(grid: [[1, 1], [1, 1]])
        #expect(map.isInBounds(Position(x: 0, y: 0)))
        #expect(map.isInBounds(Position(x: 1, y: 1)))
        #expect(!map.isInBounds(Position(x: 2, y: 0)))
        #expect(!map.isInBounds(Position(x: 0, y: -1)))
    }

    @Test("isFloor는 grid 값과 일치")
    func isFloor_matchesGridValue() {
        let map = makeMap(grid: [[0, 1], [1, 0]])
        #expect(!map.isFloor(Position(x: 0, y: 0)))  // 벽
        #expect(map.isFloor(Position(x: 1, y: 0)))   // 바닥
        #expect(map.isFloor(Position(x: 0, y: 1)))   // 바닥
        #expect(!map.isFloor(Position(x: 1, y: 1)))  // 벽
    }

    @Test("범위 밖은 항상 isFloor false")
    func isFloor_outOfBoundsIsFalse() {
        let map = makeMap(grid: [[1, 1], [1, 1]])
        #expect(!map.isFloor(Position(x: 5, y: 5)))
    }

    @Test("isGoal은 목표 위치에서만 true")
    func isGoal_matchesGoalPositionOnly() {
        let map = makeMap(grid: [[1, 1], [1, 1]], goal: Position(x: 1, y: 1))
        #expect(map.isGoal(Position(x: 1, y: 1)))
        #expect(!map.isGoal(Position(x: 0, y: 0)))
    }

    @Test("width/height는 grid 차원과 일치")
    func widthAndHeight_matchGridDimensions() {
        let map = makeMap(grid: [[1, 1, 1], [1, 1, 1]])
        #expect(map.width == 3)
        #expect(map.height == 2)
    }
}
