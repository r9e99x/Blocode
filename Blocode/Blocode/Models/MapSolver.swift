//
//  MapSolver.swift
//  Blocode
//
//  Created by 조준희 on 11/11/26.
//

import Foundation

// MARK: - MapSolver
/// 맵을 팔레트의 기본 블럭만으로 깰 수 있는지 너비 우선 탐색으로 확인하는 규칙
/// 컨테이너(반복·만약에·함수)는 안에 넣은 기본 블럭을 실행할 뿐이라, 기본 블럭만 탐색해도 갈 수 있는 곳이 같음
/// 판의 규칙은 GameBoard를 그대로 써서 실제 게임과 같은 결과를 냄
/// 쓰는 곳: 사용자 맵 저장 검증(MapValidator), 스테이지 풀이 가능 여부 테스트
enum MapSolver {

    /// 탐색 결과
    enum Outcome: Equatable {
        case solved([BlockType])  // 가장 짧은 기본 블럭 풀이
        case unsolvable           // 어떻게 해도 못 깸
        case tooComplex           // 확인할 상태가 너무 많아 중단
    }

    /// 탐색할 상태 수 한도 — 10×10 맵에 보석·문이 많아도 화면이 멈추지 않도록 제한
    static let defaultStateLimit = 400_000

    /// 탐색에 쓰는 기본 블럭
    private static let basicBlocks: Set<BlockType> = [
        .moveForward, .moveBackward, .turnLeft, .turnRight, .collectItem, .activateSwitch
    ]

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

    /// 탐색 한 칸 — 어느 상태에서 어떤 블럭으로 왔는지 기록해 풀이를 거꾸로 복원
    private struct Node {
        let board: GameBoard
        let parent: Int       // 부모 노드 번호 (시작은 -1)
        let block: BlockType? // 이 노드를 만든 블럭 (시작은 nil)
    }

    /// 블럭 하나를 실행한 뒤의 판 — 실패하는 블럭이면 nil (GameViewModel.executeBlocks와 같은 순서)
    private static func apply(_ type: BlockType, to board: GameBoard) -> GameBoard? {
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
            return nil
        }
        return next
    }

    /// 가장 짧은 풀이를 찾음
    /// - Parameters:
    ///   - collectingAllItems: true면 보석을 전부 모은 뒤 목표에 도착하는 풀이만 인정
    ///   - stateLimit: 이 수보다 많은 상태를 봐야 하면 tooComplex로 중단
    static func solve(_ map: MapData, palette: [BlockType], collectingAllItems: Bool = false,
                      stateLimit: Int = defaultStateLimit) -> Outcome {
        let usable = palette.filter { basicBlocks.contains($0) }
        let itemCount = map.items?.count ?? 0
        let start = GameBoard(map: map)

        var nodes = [Node(board: start, parent: -1, block: nil)]
        var visited: Set<BoardKey> = [BoardKey(start)]
        var head = 0  // removeFirst는 매번 배열을 당겨 느리므로 위치만 옮김

        while head < nodes.count {
            let board = nodes[head].board
            for type in usable {
                guard let next = apply(type, to: board) else { continue }
                if next.isAtGoal {
                    // 실제 게임은 목표에 닿는 순간 끝나므로, 조건이 안 맞아도 여기서 더 나아가지 않음
                    if !collectingAllItems || next.collectedItems.count == itemCount {
                        return .solved(path(to: head, nodes: nodes) + [type])
                    }
                    continue
                }
                if visited.insert(BoardKey(next)).inserted {
                    if visited.count > stateLimit { return .tooComplex }
                    nodes.append(Node(board: next, parent: head, block: type))
                }
            }
            head += 1
        }
        return .unsolvable
    }

    /// 시작부터 해당 노드까지 실행한 블럭 목록
    private static func path(to index: Int, nodes: [Node]) -> [BlockType] {
        var blocks: [BlockType] = []
        var current = index
        while let block = nodes[current].block {
            blocks.append(block)
            current = nodes[current].parent
        }
        return blocks.reversed()
    }
}
