//
//  CustomMapTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/11/26.
//
//  사용자 맵 만들기의 기반 검증 — 맵 풀이 탐색(MapSolver), 저장 검증(MapValidator),
//  저장 모델(CustomMap), 저장 서비스(CustomMapService).
//  메모리 저장소만 사용하므로 실제 맵과 진행도에 영향이 없다.

import Testing
import Foundation
@testable import Blocode

// MARK: - 테스트용 맵 만들기

/// 글자로 맵을 그림 — # 벽, . 바닥, S 시작, G 목표, * 보석, a·b 스위치, A·B 같은 글자의 문(벽 칸), 1·2·3 같은 숫자끼리 포탈 짝
private func makeMap(_ rows: [String], direction: Direction = .right) -> MapData {
    var grid: [[Int]] = []
    var start = Position(x: 0, y: 0)
    var goal = start
    var items: [Position] = []
    var switchCells: [Character: Position] = [:]
    var gateCells: [Character: Position] = [:]
    var portalCells: [Character: [Position]] = [:]

    for (y, row) in rows.enumerated() {
        var line: [Int] = []
        for (x, ch) in row.enumerated() {
            let p = Position(x: x, y: y)
            switch ch {
            case "#":
                line.append(0)
            case "A", "B":
                line.append(0)
                gateCells[Character(ch.lowercased())] = p
            default:
                line.append(1)
                switch ch {
                case "S": start = p
                case "G": goal = p
                case "*": items.append(p)
                case "a", "b": switchCells[ch] = p
                case "1", "2", "3": portalCells[ch, default: []].append(p)
                default: break
                }
            }
        }
        grid.append(line)
    }

    let switches = switchCells.keys.sorted().compactMap { key in
        gateCells[key].map { SwitchGate(switchAt: switchCells[key]!, gateAt: $0) }
    }
    let portals = portalCells.keys.sorted().compactMap { key -> PortalPair? in
        guard let cells = portalCells[key], cells.count == 2 else { return nil }
        return PortalPair(a: cells[0], b: cells[1])
    }
    return MapData(grid: grid, start: start, startDirection: direction, goal: goal,
                   items: items.isEmpty ? nil : items,
                   switches: switches.isEmpty ? nil : switches,
                   portals: portals.isEmpty ? nil : portals)
}

/// 검증을 통과하는 가장 단순한 맵 — 직선 4칸 (앞으로 4번)
private let straightRows = ["S...G", "#####", "#####"]

// MARK: - MapSolver

@MainActor
@Suite("맵 풀이 탐색")
struct MapSolverTests {

    @Test("직선은 앞으로 이동만으로 풂")
    func straightLine() {
        let outcome = MapSolver.solve(makeMap(["S.G"]), palette: [.moveForward])
        #expect(outcome == .solved([.moveForward, .moveForward]))
    }

    @Test("벽으로 막히면 풀 수 없음")
    func blockedByWall() {
        #expect(MapSolver.solve(makeMap(["S#G"]), palette: [.moveForward, .turnLeft, .turnRight]) == .unsolvable)
    }

    @Test("보석을 전부 모으는 조건을 지킴")
    func collectingAllItems() {
        let map = makeMap(["S*.G"])
        let palette: [BlockType] = [.moveForward, .collectItem]
        #expect(MapSolver.solve(map, palette: palette) == .solved([.moveForward, .moveForward, .moveForward]))
        #expect(MapSolver.solve(map, palette: palette, collectingAllItems: true)
                == .solved([.moveForward, .collectItem, .moveForward, .moveForward]))
        // 획득 블럭이 없으면 전부 모으는 풀이는 없음
        #expect(MapSolver.solve(map, palette: [.moveForward], collectingAllItems: true) == .unsolvable)
    }

    @Test("컨테이너 블럭만으로는 풀 수 없음")
    func containersOnly() {
        #expect(MapSolver.solve(makeMap(["S.G"]), palette: [.repeatBlock, .ifBlock, .functionBlock]) == .unsolvable)
    }

    @Test("확인할 상태가 한도를 넘으면 중단")
    func stateLimit() {
        // 목표가 막혀 전부 탐색해야 하는 열린 방
        let open = ["S........G"] + Array(repeating: "..........", count: 4)
        var map = makeMap(open)
        map.grid[0][8] = 0  // 목표 앞을 벽으로 막음 (윗줄은 이어져 있지만 한도를 낮춰 중단시킴)
        #expect(MapSolver.solve(map, palette: [.moveForward, .turnLeft, .turnRight], stateLimit: 10) == .tooComplex)
    }
}

// MARK: - MapValidator

@MainActor
@Suite("맵 저장 검증")
struct MapValidatorTests {

    private func issues(_ map: MapData, palette: [BlockType] = [.moveForward]) -> [String] {
        MapValidator.validate(map, palette: palette).issues
    }

    @Test("단순한 맵은 통과하고 최단 풀이를 알려 줌")
    func validMap() {
        let result = MapValidator.validate(makeMap(straightRows), palette: [.moveForward])
        #expect(result.isValid)
        #expect(result.shortestSolution?.count == 4)
    }

    @Test("크기가 범위를 벗어나면 거부")
    func sizeLimits() {
        #expect(!issues(makeMap(["S.G", "###"])).isEmpty)  // 세로 2칸
        let wide = ["S" + String(repeating: ".", count: 9) + "G", String(repeating: "#", count: 11), String(repeating: "#", count: 11)]
        #expect(!issues(makeMap(wide)).isEmpty)  // 가로 11칸
        // 행마다 길이가 다른 격자
        var ragged = makeMap(straightRows)
        ragged.grid[1].removeLast()
        #expect(!issues(ragged).isEmpty)
    }

    @Test("시작·목표가 바닥이 아니거나 같으면 거부")
    func startAndGoal() {
        var onWall = makeMap(straightRows)
        onWall.grid[0][0] = 0
        #expect(issues(onWall).contains("시작 위치가 바닥이 아니에요."))

        var same = makeMap(straightRows)
        same.goal = same.start
        #expect(issues(same).contains("시작과 목표가 같은 칸이에요."))
    }

    @Test("목표 칸에 보석이나 스위치를 놓으면 거부")
    func goalCellRules() {
        var map = makeMap(straightRows)
        map.items = [map.goal]
        #expect(issues(map, palette: [.moveForward, .collectItem]).contains("목표 칸에는 보석을 놓을 수 없어요."))

        var withSwitch = makeMap(["S..AG", "#####", "#####"])
        withSwitch.switches = [SwitchGate(switchAt: withSwitch.goal, gateAt: Position(x: 3, y: 0))]
        #expect(issues(withSwitch, palette: [.moveForward, .activateSwitch]).contains("목표 칸에는 스위치를 놓을 수 없어요."))
    }

    @Test("문은 벽 칸에만 놓을 수 있음")
    func gateOnFloor() {
        var map = makeMap(["Sa..G", "#####", "#####"])
        map.switches = [SwitchGate(switchAt: Position(x: 1, y: 0), gateAt: Position(x: 2, y: 0))]  // 바닥 칸
        #expect(issues(map, palette: [.moveForward, .activateSwitch]).contains("문은 벽 칸에만 놓을 수 있어요."))
    }

    @Test("포탈은 다른 요소와 칸을 나눌 수 없음")
    func portalPlacement() {
        var map = makeMap(["S.1.2.G", "#######", "#######"])
        map.portals = [PortalPair(a: map.start, b: Position(x: 4, y: 0))]
        #expect(issues(map).contains("포탈은 시작·목표·보석·스위치와 같은 칸에 놓을 수 없어요."))

        map.portals = [PortalPair(a: Position(x: 2, y: 0), b: Position(x: 2, y: 0))]
        #expect(issues(map).contains("포탈은 서로 다른 두 칸을 짝지어야 해요."))
    }

    @Test("기믹이 있으면 해당 블럭이 필요하고, 없으면 있으면 안 됨")
    func paletteMatchesGimmicks() {
        let withItem = makeMap(["S*..G", "#####", "#####"])
        #expect(issues(withItem, palette: [.moveForward]).contains("보석이 있으면 '보석 획득' 블럭이 필요해요."))
        #expect(issues(makeMap(straightRows), palette: [.moveForward, .collectItem])
                    .contains("보석이 없는데 '보석 획득' 블럭이 있어요."))
        #expect(issues(makeMap(straightRows), palette: [.moveForward, .activateSwitch])
                    .contains("스위치가 없는데 '스위치 작동' 블럭이 있어요."))
    }

    @Test("개수 제한을 넘으면 거부")
    func countLimits() {
        var map = makeMap(["S.......G", "..*.*.*.*", "........."])
        map.items = (1...7).map { Position(x: $0, y: 1) }  // 보석 7개 (최대 6개)
        #expect(issues(map, palette: [.moveForward, .collectItem]).contains("보석은 최대 \(MapValidator.maxItems)개까지 놓을 수 있어요."))
    }

    @Test("깰 수 없는 맵은 이유와 함께 거부")
    func unsolvable() {
        #expect(issues(makeMap(["S.#.G", "#####", "#####"])) == ["선택한 블럭으로는 목표에 도착할 수 없어요."])
        // 보석이 목표 너머에 갇혀 있어 목표만 갈 수 있음
        #expect(issues(makeMap(["S.G#*", "#####", "#####"]), palette: [.moveForward, .collectItem])
                == ["보석을 전부 모으고 목표에 도착할 수 없어요."])
    }

    @Test("스위치로 문을 열어야 하는 맵과 포탈 맵을 풀 수 있다고 확인")
    func gimmickMapsAreSolvable() {
        let door = MapValidator.validate(makeMap(["S.aA.G", "######", "######"]), palette: [.moveForward, .activateSwitch])
        #expect(door.isValid)
        #expect(door.shortestSolution == [.moveForward, .moveForward, .activateSwitch, .moveForward, .moveForward, .moveForward])

        let portal = MapValidator.validate(makeMap(["S1.#1G", "######", "######"]), palette: [.moveForward])
        #expect(portal.isValid)
        #expect(portal.shortestSolution == [.moveForward, .moveForward])
    }

    @Test("별 기준 기본값은 최단 블럭 수와 거기에 4를 더한 값")
    func defaultThresholds() {
        let thresholds = MapValidator.defaultThresholds(shortest: 6)
        #expect(thresholds.threeStar == 6)
        #expect(thresholds.twoStar == 10)
    }
}

// MARK: - CustomMap 모델

@MainActor
@Suite("사용자 맵 모델")
struct CustomMapModelTests {

    @Test("스테이지로 바꾸면 저장한 내용이 그대로 들어감")
    func stageConversion() {
        let map = makeMap(["S1.#1G", "######", "######"])
        let saved = CustomMap.make(name: "내 맵", map: map, palette: [.moveForward, .turnLeft],
                              thresholds: StarThresholds(threeStar: 2, twoStar: 6))
        let stage = saved.stage
        #expect(stage?.id == "custom_\(saved.id.uuidString)")
        #expect(stage?.chapter == 0)
        #expect(stage?.name == "내 맵")
        #expect(stage?.paletteBlocks == [.moveForward, .turnLeft])
        #expect(stage?.starThresholds.threeStar == 2)
        #expect(stage?.starThresholds.twoStar == 6)
        #expect(stage?.mapData.grid == map.grid)
        #expect(stage?.mapData.portals == map.portals)
    }

    @Test("손상된 데이터는 스테이지가 되지 않음")
    func corruptedData() {
        let saved = CustomMap.make(name: "깨진 맵", map: makeMap(straightRows), palette: [.moveForward],
                              thresholds: StarThresholds(threeStar: 4, twoStar: 8))
        saved.mapJSON = Data("not json".utf8)
        #expect(saved.stage == nil)
    }

    @Test("고쳐도 번호와 만든 시각은 유지되고 고친 시각만 바뀜")
    func updateKeepsIdentity() async throws {
        let saved = CustomMap.make(name: "처음", map: makeMap(straightRows), palette: [.moveForward],
                              thresholds: StarThresholds(threeStar: 4, twoStar: 8))
        let id = saved.id
        let created = saved.createdAt
        let firstUpdate = saved.updatedAt
        try await Task.sleep(for: .milliseconds(5))
        saved.update(name: "나중", map: makeMap(straightRows), palette: [.moveForward],
                     thresholds: StarThresholds(threeStar: 4, twoStar: 8))
        #expect(saved.id == id)
        #expect(saved.createdAt == created)
        #expect(saved.updatedAt > firstUpdate)
        #expect(saved.name == "나중")
    }
}

// MARK: - CustomMapService

@MainActor
@Suite("사용자 맵 저장 서비스")
struct CustomMapServiceTests {

    private let thresholds = StarThresholds(threeStar: 4, twoStar: 8)

    /// 메모리 저장소 — progress를 함께 돌려줘야 컨테이너가 유지됨
    private func makeService() -> (service: CustomMapService, progress: ProgressService) {
        let progress = ProgressService.makeForTesting()
        return (CustomMapService(container: progress.modelContainer), progress)
    }

    private func save(_ service: CustomMapService, name: String = "맵", id: UUID? = nil) throws -> CustomMap {
        try service.save(id: id, name: name, map: makeMap(straightRows), palette: [.moveForward], thresholds: thresholds)
    }

    @Test("저장하면 목록에 생기고 이름 앞뒤 공백은 지움")
    func saveNew() throws {
        let (service, progress) = makeService()
        let saved = try save(service, name: "  내 첫 맵  ")
        #expect(saved.name == "내 첫 맵")
        #expect(service.maps.count == 1)
        #expect(service.map(withID: saved.id) === saved)
        _ = progress
    }

    @Test("이름이 비었거나 너무 길면 거부")
    func invalidName() {
        let (service, progress) = makeService()
        #expect(throws: CustomMapService.SaveError.invalidName) { try save(service, name: "   ") }
        #expect(throws: CustomMapService.SaveError.invalidName) { try save(service, name: String(repeating: "가", count: 21)) }
        #expect(service.maps.isEmpty)
        _ = progress
    }

    @Test("깰 수 없는 맵은 저장되지 않음")
    func invalidMapIsNotSaved() {
        let (service, progress) = makeService()
        #expect(throws: CustomMapService.SaveError.invalidMap(["선택한 블럭으로는 목표에 도착할 수 없어요."])) {
            try service.save(name: "막힌 맵", map: makeMap(["S.#.G", "#####", "#####"]),
                             palette: [.moveForward], thresholds: thresholds)
        }
        #expect(service.maps.isEmpty)
        _ = progress
    }

    @Test("별 기준이 올바르지 않으면 거부")
    func invalidThresholds() {
        let (service, progress) = makeService()
        for bad in [StarThresholds(threeStar: 0, twoStar: 4), StarThresholds(threeStar: 5, twoStar: 3)] {
            #expect(throws: CustomMapService.SaveError.invalidThresholds) {
                try service.save(name: "맵", map: makeMap(straightRows), palette: [.moveForward], thresholds: bad)
            }
        }
        #expect(service.maps.isEmpty)
        _ = progress
    }

    @Test("같은 번호로 저장하면 새로 만들지 않고 고침")
    func saveWithIDUpdates() throws {
        let (service, progress) = makeService()
        let first = try save(service, name: "처음")
        let second = try save(service, name: "고침", id: first.id)
        #expect(second.id == first.id)
        #expect(service.maps.count == 1)
        #expect(service.maps.first?.name == "고침")
        _ = progress
    }

    @Test("목록은 최근에 고친 맵이 앞")
    func sortedByUpdate() async throws {
        let (service, progress) = makeService()
        let a = try save(service, name: "A")
        try await Task.sleep(for: .milliseconds(5))
        _ = try save(service, name: "B")
        #expect(service.maps.map(\.name) == ["B", "A"])
        try await Task.sleep(for: .milliseconds(5))
        _ = try save(service, name: "A 수정", id: a.id)
        #expect(service.maps.map(\.name) == ["A 수정", "B"])
        _ = progress
    }

    @Test("삭제하면 목록에서 사라짐")
    func deleteMap() throws {
        let (service, progress) = makeService()
        let saved = try save(service)
        service.delete(saved)
        #expect(service.maps.isEmpty)
        _ = progress
    }

    @Test("새 서비스로 다시 읽어도 저장된 맵이 있음")
    func persistsInContainer() throws {
        let (service, progress) = makeService()
        let saved = try save(service, name: "남는 맵")
        let reopened = CustomMapService(container: progress.modelContainer)
        #expect(reopened.maps.map(\.id) == [saved.id])
        #expect(reopened.maps.first?.stage != nil)
    }

    @Test("진행도를 초기화해도 만든 맵은 남음")
    func progressResetKeepsMaps() throws {
        let (service, progress) = makeService()
        _ = try save(service)
        progress.recordClear(stageId: "ch1_stage1", stars: 3, blockCount: 1)
        progress.resetAll()
        #expect(progress.results.isEmpty)
        #expect(CustomMapService(container: progress.modelContainer).maps.count == 1)
    }

    @Test("저장된 맵을 실제 게임 엔진으로 클리어할 수 있음")
    func savedMapIsPlayable() async throws {
        let (service, progress) = makeService()
        let saved = try service.save(name: "문 맵", map: makeMap(["S.aA.G", "######", "######"]),
                                     palette: [.moveForward, .activateSwitch], thresholds: thresholds)
        let validation = MapValidator.validate(saved.mapData!, palette: saved.palette)
        let stage = try #require(saved.stage)

        let vm = GameViewModel(stage: stage, progress: .makeForTesting(), executionSpeed: { 1000 })
        vm.codeBlocks = (validation.shortestSolution ?? []).map { Block(type: $0) }
        vm.run()
        let deadline = Date().addingTimeInterval(10)
        while vm.gameState == .running, Date() < deadline {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(vm.gameState == .success)
        _ = progress
    }
}
