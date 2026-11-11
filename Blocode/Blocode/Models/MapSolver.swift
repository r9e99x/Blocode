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
/// 판의 규칙(이동·회전·보석·스위치·포탈)은 GameBoard와 똑같이 옮겨 정수 상태로 빠르게 탐색함 —
/// GameBoard를 쓴 기준 탐색과 결과가 같은지는 MapSolverEquivalenceTests가 모든 스테이지와 무작위 맵으로 확인
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

    /// 상태 공간이 이 크기를 넘으면 탐색하지 않고 tooComplex (보석+문 20개 이하, 칸 수×4×2^개수)
    private static let maxStateSpace = 16_000_000

    /// 방향 순서 — 위, 오른쪽, 아래, 왼쪽 (오른쪽 회전은 +1, 왼쪽 회전은 +3)
    private static let dx = [0, 1, 0, -1]
    private static let dy = [-1, 0, 1, 0]

    private static func directionIndex(_ direction: Direction) -> Int {
        switch direction {
        case .up: return 0
        case .right: return 1
        case .down: return 2
        case .left: return 3
        }
    }

    /// 가장 짧은 풀이를 찾음
    /// 상태 = (칸, 방향, 모은 보석, 열린 문)을 정수 하나로 담고, 방문 표시는 배열로 해 해시 비용이 없음
    /// - Parameters:
    ///   - collectingAllItems: true면 보석을 전부 모은 뒤 목표에 도착하는 풀이만 인정
    ///   - stateLimit: 이 수보다 많은 상태를 봐야 하면 tooComplex로 중단
    static func solve(_ map: MapData, palette: [BlockType], collectingAllItems: Bool = false,
                      stateLimit: Int = defaultStateLimit) -> Outcome {
        search(map, palette: palette, collectingAllItems: collectingAllItems, stateLimit: stateLimit).outcome
    }

    /// solve와 같은 탐색 — 보석을 전부 모으는 조건에서 풀이가 없을 때, 보석 조건만 빼면 목표에 갈 수 있었는지도 함께 알려 줌
    /// (저장 검증이 "보석을 다 못 모아요"와 "목표에 못 가요"를 한 번의 탐색으로 구분하려고 사용)
    static func search(_ map: MapData, palette: [BlockType], collectingAllItems: Bool,
                       stateLimit: Int = defaultStateLimit) -> (outcome: Outcome, reachesGoalWithoutAllItems: Bool) {
        let actions = palette.filter { basicBlocks.contains($0) }
        let width = map.width
        let height = map.height
        guard width > 0, height > 0, !actions.isEmpty else { return (.unsolvable, false) }
        let cellCount = width * height

        func index(_ position: Position) -> Int? {
            map.isInBounds(position) ? position.y * width + position.x : nil
        }

        // 바닥
        var isFloor = [Bool](repeating: false, count: cellCount)
        for y in 0..<height {
            for x in 0..<width { isFloor[y * width + x] = map.isFloor(Position(x: x, y: y)) }
        }

        // 보석 — 칸마다 비트 번호 (밖에 있는 보석은 모을 수 없지만 전체 개수에는 들어감)
        var itemBit = [Int](repeating: -1, count: cellCount)
        var itemBits = 0
        for position in map.items ?? [] {
            if let cell = index(position), itemBit[cell] < 0 {
                itemBit[cell] = itemBits
                itemBits += 1
            }
        }
        let itemTarget = map.items?.count ?? 0

        // 스위치와 문 — 문 칸마다 비트 번호, 스위치 칸은 같은 칸의 첫 스위치가 연 문을 가리킴 (-2는 열 문이 없는 스위치)
        var gateBitOfCell = [Int](repeating: -1, count: cellCount)
        var switchGate = [Int](repeating: -1, count: cellCount)
        var gateBits = 0
        for pair in map.switches ?? [] {
            guard let switchCell = index(pair.switchAt), switchGate[switchCell] == -1 else { continue }
            if let gateCell = index(pair.gateAt) {
                if gateBitOfCell[gateCell] < 0 {
                    gateBitOfCell[gateCell] = gateBits
                    gateBits += 1
                }
                switchGate[switchCell] = gateBitOfCell[gateCell]
            } else {
                switchGate[switchCell] = -2
            }
        }

        // 포탈 — 칸마다 도착 칸 (같은 칸이 여러 짝에 있으면 먼저 나온 짝)
        var portalTo = [Int](repeating: -1, count: cellCount)
        for pair in map.portals ?? [] {
            guard let a = index(pair.a), let b = index(pair.b) else { continue }
            if portalTo[a] < 0 { portalTo[a] = b }
            if portalTo[b] < 0 { portalTo[b] = a }
        }

        guard itemBits + gateBits <= 20 else { return (.tooComplex, false) }
        let itemStates = 1 << itemBits
        let gateStates = 1 << gateBits
        let stateSpace = cellCount * 4 * itemStates * gateStates
        guard stateSpace <= maxStateSpace else { return (.tooComplex, false) }

        guard let startCell = index(map.start) else { return (.unsolvable, false) }
        let goalCell = index(map.goal) ?? -1

        func encode(_ cell: Int, _ direction: Int, _ items: Int, _ gates: Int) -> Int {
            (((cell << 2) | direction) * itemStates + items) * gateStates + gates
        }

        let start = encode(startCell, directionIndex(map.startDirection), 0, 0)
        var visited = [Bool](repeating: false, count: stateSpace)
        visited[start] = true
        var states = [Int32(start)]
        var parents: [Int32] = [-1]
        var actionOf: [UInt8] = [0]
        var visitedCount = 1
        var reachedGoal = false
        var head = 0  // removeFirst는 매번 배열을 당겨 느리므로 위치만 옮김

        while head < states.count {
            let state = Int(states[head])
            let gates = state % gateStates
            let rest = state / gateStates
            let items = rest % itemStates
            let rest2 = rest / itemStates
            let direction = rest2 & 3
            let cell = rest2 >> 2

            for (actionIndex, action) in actions.enumerated() {
                var nextCell = cell
                var nextDirection = direction
                var nextItems = items
                var nextGates = gates

                switch action {
                case .moveForward, .moveBackward:
                    let sign = action == .moveForward ? 1 : -1
                    let x = cell % width + dx[direction] * sign
                    let y = cell / width + dy[direction] * sign
                    guard x >= 0, x < width, y >= 0, y < height else { continue }
                    let target = y * width + x
                    let gateBit = gateBitOfCell[target]
                    guard isFloor[target] || (gateBit >= 0 && gates & (1 << gateBit) != 0) else { continue }
                    nextCell = portalTo[target] >= 0 ? portalTo[target] : target
                case .turnLeft:
                    nextDirection = (direction + 3) & 3
                case .turnRight:
                    nextDirection = (direction + 1) & 3
                case .collectItem:
                    let bit = itemBit[cell]
                    guard bit >= 0, items & (1 << bit) == 0 else { continue }
                    nextItems = items | (1 << bit)
                case .activateSwitch:
                    let gate = switchGate[cell]
                    guard gate != -1 else { continue }
                    if gate >= 0 { nextGates = gates | (1 << gate) }
                default:
                    continue
                }

                // 실제 게임은 목표에 닿는 순간 끝나므로, 조건이 안 맞아도 여기서 더 나아가지 않음
                if nextCell == goalCell {
                    if !collectingAllItems || nextItems.nonzeroBitCount == itemTarget {
                        let solution = path(to: head, parents: parents, actionOf: actionOf, actions: actions) + [action]
                        return (.solved(solution), true)
                    }
                    reachedGoal = true
                    continue
                }

                let next = encode(nextCell, nextDirection, nextItems, nextGates)
                if !visited[next] {
                    visited[next] = true
                    visitedCount += 1
                    if visitedCount > stateLimit { return (.tooComplex, reachedGoal) }
                    states.append(Int32(next))
                    parents.append(Int32(head))
                    actionOf.append(UInt8(actionIndex))
                }
            }
            head += 1
        }
        return (.unsolvable, reachedGoal)
    }

    /// 시작부터 해당 노드까지 실행한 블럭 목록
    private static func path(to index: Int, parents: [Int32], actionOf: [UInt8], actions: [BlockType]) -> [BlockType] {
        var blocks: [BlockType] = []
        var current = index
        while parents[current] >= 0 {
            blocks.append(actions[Int(actionOf[current])])
            current = Int(parents[current])
        }
        return blocks.reversed()
    }
}
