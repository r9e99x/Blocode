//
//  MapValidator.swift
//  Blocode
//
//  Created by 조준희 on 11/11/26.
//

import Foundation

// MARK: - MapValidation
/// 맵 검증 결과 — 문제가 없으면 저장할 수 있음
struct MapValidation: Equatable {
    /// 사용자에게 보여 줄 문제 목록 (없으면 저장 가능)
    var issues: [String]

    /// 가장 짧은 기본 블럭 풀이 — 풀 수 있다고 확인된 경우에만 있음
    var shortestSolution: [BlockType]?

    var isValid: Bool { issues.isEmpty }
}

// MARK: - MapValidator
/// 사용자가 만든 맵이 저장해도 되는 맵인지 검사하는 규칙
/// 구조(크기·배치·기믹 짝)를 먼저 보고, 문제가 없을 때만 자동 탐색으로 실제로 깰 수 있는지 확인함
/// 기본 스테이지의 데이터 무결성 테스트와 같은 기준을 사용자 맵에도 적용
enum MapValidator {

    static let minSize = 3        // 가로·세로 최소 칸 수
    static let maxSize = 10       // 가로·세로 최대 칸 수 (기본 스테이지 최대와 같음)
    static let maxItems = 6       // 탐색이 멈추지 않도록 기믹 개수 제한
    static let maxSwitches = 4
    static let maxPortalPairs = 4

    /// 별 기준 기본값 — 3개는 최단 기본 블럭 수라 컨테이너 없이도 항상 달성 가능, 2개는 거기에 4를 더함
    static func defaultThresholds(shortest: Int) -> StarThresholds {
        StarThresholds(threeStar: shortest, twoStar: shortest + 4)
    }

    static func validate(_ map: MapData, palette: [BlockType]) -> MapValidation {
        var issues: [String] = []

        // 크기와 격자 모양 — 어긋나면 좌표를 믿을 수 없어 여기서 멈춤
        let width = map.width
        let height = map.height
        let sizeRange = minSize...maxSize
        guard sizeRange.contains(width), sizeRange.contains(height), map.grid.allSatisfy({ $0.count == width }) else {
            return MapValidation(issues: ["맵 크기는 가로·세로 모두 \(minSize)~\(maxSize)칸이어야 해요."])
        }
        if map.grid.contains(where: { $0.contains { TileType(rawValue: $0) == nil } }) {
            return MapValidation(issues: ["맵 데이터가 올바르지 않아요."])
        }

        // 시작과 목표
        if !map.isFloor(map.start) { issues.append("시작 위치가 바닥이 아니에요.") }
        if !map.isFloor(map.goal) { issues.append("목표 위치가 바닥이 아니에요.") }
        if map.start == map.goal { issues.append("시작과 목표가 같은 칸이에요.") }

        // 보석 — 목표에 닿는 순간 게임이 끝나므로 목표 칸의 보석은 모을 수 없음
        let items = map.items ?? []
        if items.count > maxItems { issues.append("보석은 최대 \(maxItems)개까지 놓을 수 있어요.") }
        if Set(items).count != items.count { issues.append("같은 칸에 보석이 두 개 있어요.") }
        if items.contains(where: { !map.isFloor($0) }) { issues.append("보석은 바닥 위에만 놓을 수 있어요.") }
        if items.contains(map.goal) { issues.append("목표 칸에는 보석을 놓을 수 없어요.") }

        // 스위치와 문
        let switches = map.switches ?? []
        if switches.count > maxSwitches { issues.append("스위치는 최대 \(maxSwitches)개까지 놓을 수 있어요.") }
        let switchCells = switches.map(\.switchAt)
        let gateCells = switches.map(\.gateAt)
        if Set(switchCells).count != switchCells.count || Set(gateCells).count != gateCells.count {
            issues.append("같은 칸에 스위치나 문이 겹쳐 있어요.")
        }
        if switchCells.contains(where: { !map.isFloor($0) }) { issues.append("스위치는 바닥 위에만 놓을 수 있어요.") }
        if switchCells.contains(map.goal) { issues.append("목표 칸에는 스위치를 놓을 수 없어요.") }
        // 문은 열리기 전까지 벽이어야 함 — 격자 안의 벽 칸만 허용
        if gateCells.contains(where: { !map.isInBounds($0) || map.isFloor($0) }) {
            issues.append("문은 벽 칸에만 놓을 수 있어요.")
        }

        // 포탈 — 밟는 순간 이동하므로 다른 요소와 칸을 나눌 수 없음
        let portals = map.portals ?? []
        if portals.count > maxPortalPairs { issues.append("포탈은 최대 \(maxPortalPairs)쌍까지 놓을 수 있어요.") }
        let portalCells = portals.flatMap { [$0.a, $0.b] }
        if portals.contains(where: { $0.a == $0.b }) || Set(portalCells).count != portalCells.count {
            issues.append("포탈은 서로 다른 두 칸을 짝지어야 해요.")
        }
        if portalCells.contains(where: { !map.isFloor($0) }) { issues.append("포탈은 바닥 위에만 놓을 수 있어요.") }
        let otherCells = Set([map.start, map.goal] + items + switchCells)
        if portalCells.contains(where: { otherCells.contains($0) }) {
            issues.append("포탈은 시작·목표·보석·스위치와 같은 칸에 놓을 수 없어요.")
        }

        // 팔레트 — 기믹 블럭은 해당 기믹이 있을 때만, 있으면 반드시 필요
        if items.isEmpty == palette.contains(.collectItem) {
            issues.append(items.isEmpty ? "보석이 없는데 '보석 획득' 블럭이 있어요." : "보석이 있으면 '보석 획득' 블럭이 필요해요.")
        }
        if switches.isEmpty == palette.contains(.activateSwitch) {
            issues.append(switches.isEmpty ? "스위치가 없는데 '스위치 작동' 블럭이 있어요." : "스위치가 있으면 '스위치 작동' 블럭이 필요해요.")
        }

        // 구조에 문제가 있으면 탐색은 하지 않음
        guard issues.isEmpty else { return MapValidation(issues: issues) }

        // 실제로 깰 수 있는지 — 보석은 전부 모아야 별 3개가 되므로 전부 모으는 풀이를 찾음
        switch MapSolver.solve(map, palette: palette, collectingAllItems: true) {
        case .solved(let path):
            return MapValidation(issues: [], shortestSolution: path)
        case .unsolvable:
            if !items.isEmpty, case .solved = MapSolver.solve(map, palette: palette) {
                return MapValidation(issues: ["보석을 전부 모으고 목표에 도착할 수 없어요."])
            }
            return MapValidation(issues: ["선택한 블럭으로는 목표에 도착할 수 없어요."])
        case .tooComplex:
            return MapValidation(issues: ["맵이 너무 복잡해서 확인하지 못했어요. 보석이나 문을 줄여 보세요."])
        }
    }
}
