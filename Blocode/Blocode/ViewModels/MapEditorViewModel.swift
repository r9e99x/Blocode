//
//  MapEditorViewModel.swift
//  Blocode
//
//  Created by 조준희 on 11/11/26.
//

import Foundation
import Combine

// MARK: - MapEditorTool
/// 에디터에서 칸을 누를 때 쓰는 도구
enum MapEditorTool: CaseIterable {
    case floor       // 바닥 칠하기
    case wall        // 벽 칠하기
    case start       // 시작 위치 (시작 칸을 다시 누르면 방향 회전)
    case goal        // 목표 위치
    case item        // 보석 (다시 누르면 지움)
    case switchGate  // 스위치 놓고 → 그 스위치로 열 문 놓기
    case portal      // 포탈 두 칸 짝짓기
    case eraser      // 보석·스위치·문·포탈 지우기
}

// MARK: - EditorCell
/// 화면이 칸 하나를 그리는 데 필요한 정보
struct EditorCell: Equatable {
    var isFloor = false
    var isStart = false
    var isGoal = false
    var hasItem = false
    var switchPair: Int?   // 이 칸이 스위치면 몇 번째 스위치-문 짝인지
    var gatePair: Int?     // 이 칸이 문이면 몇 번째 짝인지
    var portalPair: Int?   // 이 칸이 포탈이면 몇 번째 포탈 짝인지
    var isPending = false  // 짝을 기다리는 첫 칸
}

// MARK: - MapEditorViewModel
/// 맵 에디터의 상태와 규칙 — 칠하기, 요소 배치, 짝 맺기, 크기 변경, 팔레트 선택, 되돌리기, 검증과 저장
/// 화면은 이 ViewModel의 값을 그리기만 하고, 모든 배치 규칙은 여기서 처리함
/// 규칙은 MapValidator와 같은 기준이라, 에디터로 만든 맵은 구조 검사를 대부분 통과함
final class MapEditorViewModel: ObservableObject {

    /// 짝을 맺는 도중 첫 칸 — 스위치는 문을, 포탈은 두 번째 칸을 기다림
    enum Pending: Equatable {
        case switchCell(Position)
        case portalEnd(Position)

        var position: Position {
            switch self {
            case .switchCell(let p), .portalEnd(let p): return p
            }
        }
    }

    /// 되돌리기 한 단계 — 맵과 팔레트 선택
    private struct Snapshot {
        let map: MapData
        let enabledBlocks: Set<BlockType>
    }

    /// 만드는 사람이 켜고 끌 수 있는 블럭 — 보석 획득·스위치 작동은 맵의 요소에 따라 자동으로 정해짐
    static let optionalBlocks: [BlockType] = [
        .moveForward, .moveBackward, .turnLeft, .turnRight, .repeatBlock, .ifBlock, .functionBlock
    ]
    static let defaultBlocks: Set<BlockType> = [.moveForward, .turnLeft, .turnRight, .repeatBlock, .ifBlock]
    static let defaultSize = 7
    private static let maxHistory = 50
    /// 별 2개 기준은 3개 기준에 이만큼 더함
    private static let twoStarMargin = 4

    // MARK: 상태

    @Published private(set) var map: MapData
    @Published var name: String
    @Published private(set) var tool: MapEditorTool = .floor
    @Published private(set) var pending: Pending?
    @Published private(set) var enabledBlocks: Set<BlockType>
    /// 마지막 확인 결과 — 맵이나 팔레트를 고치면 nil로 돌아감
    @Published private(set) var validation: MapValidation?
    /// 만든 사람이 테스트 플레이로 클리어한 가장 적은 블럭 수 — 맵을 고치면 사라짐
    @Published private(set) var testClearBlockCount: Int?
    /// 배치가 거부됐을 때 화면에 보여 줄 짧은 안내
    @Published private(set) var message: String?
    @Published private(set) var isDirty = false
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false

    /// 이미 저장된 맵을 고치는 중이면 그 맵의 번호
    private(set) var editingID: UUID?

    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []
    private var strokeBase: Snapshot?
    private var strokeChanged = false
    /// 한 번의 도구 적용에서 맵이 실제로 바뀌었는지 — 바뀐 곳에서만 true로 올림
    private var touched = false

    // MARK: 초기화

    /// 새 맵 — 가운데 줄만 바닥인 7×7, 시작에서 목표까지 곧장 가는 맵이라 바로 저장할 수 있음
    init() {
        map = Self.defaultMap()
        name = ""
        enabledBlocks = Self.defaultBlocks
    }

    /// 저장된 맵 고치기 — 데이터가 손상됐으면 nil
    init?(editing saved: CustomMap) {
        guard let data = saved.mapData else { return nil }
        map = data
        name = saved.name
        enabledBlocks = Set(saved.palette).intersection(Self.optionalBlocks)
        editingID = saved.id
    }

    private static func defaultMap() -> MapData {
        let size = defaultSize
        let middle = size / 2
        var grid = Array(repeating: Array(repeating: TileType.wall.rawValue, count: size), count: size)
        grid[middle] = Array(repeating: TileType.floor.rawValue, count: size)
        return MapData(grid: grid, start: Position(x: 0, y: middle), startDirection: .right,
                       goal: Position(x: size - 1, y: middle))
    }

    // MARK: - 읽기

    var width: Int { map.width }
    var height: Int { map.height }

    /// 칸 하나의 표시 정보
    func cell(at p: Position) -> EditorCell {
        guard map.isInBounds(p) else { return EditorCell() }
        return EditorCell(
            isFloor: map.isFloor(p),
            isStart: p == map.start,
            isGoal: p == map.goal,
            hasItem: items.contains(p),
            switchPair: switches.firstIndex { $0.switchAt == p },
            gatePair: switches.firstIndex { $0.gateAt == p },
            portalPair: portals.firstIndex { $0.a == p || $0.b == p },
            isPending: pending?.position == p
        )
    }

    /// 지금 맵에 쓰이는 팔레트 — 켜 둔 블럭과 맵 요소에 필요한 기믹 블럭
    var palette: [BlockType] {
        BlockType.allCases.filter { type in
            switch type {
            case .collectItem: return !items.isEmpty
            case .activateSwitch: return !switches.isEmpty
            default: return enabledBlocks.contains(type)
            }
        }
    }

    /// 확인을 통과했을 때의 별 기준 — 3개는 최단 블럭 수, 테스트 플레이로 더 적게 깼으면 그 수
    var thresholds: StarThresholds? {
        guard let shortest = validation?.shortestSolution?.count else { return nil }
        let three = max(1, min(shortest, testClearBlockCount ?? shortest))
        return StarThresholds(threeStar: three, twoStar: three + Self.twoStarMargin)
    }

    /// 테스트 플레이에 쓸 스테이지 — 확인을 통과한 상태에서만 만들어짐
    var previewStage: Stage? {
        guard let thresholds else { return nil }
        return Stage(id: "\(CustomMap.stageIDPrefix)preview", chapter: 0, stageNumber: 0,
                     name: name.isEmpty ? "테스트" : name, mapData: map,
                     starThresholds: thresholds, availableBlocks: palette)
    }

    // MARK: - 요소 접근

    private var items: [Position] {
        get { map.items ?? [] }
        set { map.items = newValue.isEmpty ? nil : newValue }
    }

    private var switches: [SwitchGate] {
        get { map.switches ?? [] }
        set { map.switches = newValue.isEmpty ? nil : newValue }
    }

    private var portals: [PortalPair] {
        get { map.portals ?? [] }
        set { map.portals = newValue.isEmpty ? nil : newValue }
    }

    // MARK: - 도구

    func selectTool(_ newTool: MapEditorTool) {
        tool = newTool
        pending = nil  // 도구를 바꾸면 짝 맺던 것은 취소
        message = nil
    }

    // MARK: - 칠하기 (한 번 누름 또는 끌기 한 획)

    /// 한 획의 시작 — 끝날 때 바뀐 게 있으면 되돌리기 한 단계로 묶음
    func beginStroke() {
        strokeBase = snapshot
        strokeChanged = false
        message = nil
    }

    /// 칸에 현재 도구 적용 — 화면에 보이는 변화가 있으면 true
    @discardableResult
    func paint(at p: Position) -> Bool {
        guard map.isInBounds(p) else { return false }
        touched = false
        let before = pending
        let visible = applyTool(at: p)
        if touched {
            strokeChanged = true
            invalidateCheckResults()
        }
        return visible || touched || before != pending
    }

    func endStroke() {
        if strokeChanged, let base = strokeBase { commit(base) }
        strokeBase = nil
        strokeChanged = false
    }

    /// 한 번 누르기 — 한 획짜리 칠하기
    @discardableResult
    func tap(at p: Position) -> Bool {
        beginStroke()
        let changed = paint(at: p)
        endStroke()
        return changed
    }

    /// 도구별 배치 규칙 — 거부하면 message를 남기고 false
    private func applyTool(at p: Position) -> Bool {
        switch tool {
        case .floor:      return paintFloor(p)
        case .wall:       return paintWall(p)
        case .start:      return placeStart(p)
        case .goal:       return placeGoal(p)
        case .item:       return toggleItem(p)
        case .switchGate: return placeSwitchOrGate(p)
        case .portal:     return placePortal(p)
        case .eraser:     return erase(p)
        }
    }

    private func refuse(_ text: String) -> Bool {
        message = text
        return false
    }

    private func paintFloor(_ p: Position) -> Bool {
        removeSwitchPairs { $0.gateAt == p }  // 문 칸이 바닥이 되면 문은 사라짐
        setFloor(p, true)
        return touched
    }

    private func paintWall(_ p: Position) -> Bool {
        if p == map.start || p == map.goal { return refuse("시작과 목표 칸은 벽으로 만들 수 없어요.") }
        removeItem(at: p)
        removeSwitchPairs { $0.switchAt == p }
        removePortalPairs { $0.a == p || $0.b == p }
        if pending?.position == p { pending = nil }
        setFloor(p, false)
        return touched
    }

    private func placeStart(_ p: Position) -> Bool {
        if p == map.goal { return refuse("시작과 목표를 같은 칸에 둘 수 없어요.") }
        if p == map.start {  // 시작 칸을 다시 누르면 방향을 오른쪽으로 90도 돌림
            map.startDirection = map.startDirection.turnedRight
            touched = true
            return true
        }
        removePortalPairs { $0.a == p || $0.b == p }
        removeSwitchPairs { $0.gateAt == p }
        setFloor(p, true)
        map.start = p
        touched = true
        return true
    }

    private func placeGoal(_ p: Position) -> Bool {
        if p == map.start { return refuse("시작과 목표를 같은 칸에 둘 수 없어요.") }
        if p == map.goal { return false }
        removeItem(at: p)
        removeSwitchPairs { $0.switchAt == p || $0.gateAt == p }
        removePortalPairs { $0.a == p || $0.b == p }
        setFloor(p, true)
        map.goal = p
        touched = true
        return true
    }

    private func toggleItem(_ p: Position) -> Bool {
        if items.contains(p) {
            removeItem(at: p)
            return true
        }
        if p == map.goal { return refuse("목표 칸에는 보석을 놓을 수 없어요.") }
        if items.count >= MapValidator.maxItems { return refuse("보석은 최대 \(MapValidator.maxItems)개까지 놓을 수 있어요.") }
        removePortalPairs { $0.a == p || $0.b == p }
        removeSwitchPairs { $0.gateAt == p }
        setFloor(p, true)
        items.append(p)
        touched = true
        return true
    }

    /// 첫 번째 누름은 스위치, 두 번째 누름은 그 스위치로 열 문 — 이미 놓은 스위치·문을 누르면 그 짝을 지움
    private func placeSwitchOrGate(_ p: Position) -> Bool {
        let existing = switches.contains { $0.switchAt == p || $0.gateAt == p }

        guard case .switchCell(let first)? = pending else {
            if existing {
                removeSwitchPairs { $0.switchAt == p || $0.gateAt == p }
                return true
            }
            if p == map.goal { return refuse("목표 칸에는 스위치를 놓을 수 없어요.") }
            if switches.count >= MapValidator.maxSwitches {
                return refuse("스위치는 최대 \(MapValidator.maxSwitches)개까지 놓을 수 있어요.")
            }
            removePortalPairs { $0.a == p || $0.b == p }
            setFloor(p, true)
            pending = .switchCell(p)
            return true
        }

        if p == first {  // 같은 칸을 다시 누르면 취소
            pending = nil
            return true
        }
        let occupied = existing || p == map.start || p == map.goal || items.contains(p)
            || portals.contains { $0.a == p || $0.b == p }
        if occupied { return refuse("문은 비어 있는 칸이나 벽 칸에만 놓을 수 있어요.") }
        setFloor(p, false)  // 문은 열리기 전까지 벽
        switches.append(SwitchGate(switchAt: first, gateAt: p))
        pending = nil
        touched = true
        return true
    }

    /// 첫 번째 누름은 한쪽 칸, 두 번째 누름은 짝 칸 — 이미 놓은 포탈을 누르면 그 짝을 지움
    private func placePortal(_ p: Position) -> Bool {
        if portals.contains(where: { $0.a == p || $0.b == p }) {
            removePortalPairs { $0.a == p || $0.b == p }
            return true
        }
        if case .portalEnd(let first)? = pending, p == first {  // 같은 칸을 다시 누르면 취소
            pending = nil
            return true
        }
        if p == map.start || p == map.goal || items.contains(p) || switches.contains(where: { $0.switchAt == p || $0.gateAt == p }) {
            return refuse("포탈은 시작·목표·보석·스위치·문과 같은 칸에 놓을 수 없어요.")
        }
        if pending == nil, portals.count >= MapValidator.maxPortalPairs {
            return refuse("포탈은 최대 \(MapValidator.maxPortalPairs)쌍까지 놓을 수 있어요.")
        }
        setFloor(p, true)
        if case .portalEnd(let first)? = pending {
            portals.append(PortalPair(a: first, b: p))
            pending = nil
            touched = true
        } else {
            pending = .portalEnd(p)
        }
        return true
    }

    private func erase(_ p: Position) -> Bool {
        if p == map.start || p == map.goal { return refuse("시작과 목표는 지울 수 없어요. 다른 칸에 놓아서 옮겨 주세요.") }
        if items.contains(p) {
            removeItem(at: p)
            return true
        }
        if switches.contains(where: { $0.switchAt == p || $0.gateAt == p }) {
            removeSwitchPairs { $0.switchAt == p || $0.gateAt == p }
            return true
        }
        if portals.contains(where: { $0.a == p || $0.b == p }) {
            removePortalPairs { $0.a == p || $0.b == p }
            return true
        }
        return false
    }

    // MARK: - 맵 수정 도우미 (바뀌면 touched를 올림)

    private func setFloor(_ p: Position, _ isFloor: Bool) {
        let value = isFloor ? TileType.floor.rawValue : TileType.wall.rawValue
        guard map.grid[p.y][p.x] != value else { return }
        map.grid[p.y][p.x] = value
        touched = true
    }

    private func removeItem(at p: Position) {
        guard items.contains(p) else { return }
        items.removeAll { $0 == p }
        touched = true
    }

    private func removeSwitchPairs(where match: (SwitchGate) -> Bool) {
        guard switches.contains(where: match) else { return }
        switches.removeAll(where: match)
        touched = true
    }

    private func removePortalPairs(where match: (PortalPair) -> Bool) {
        guard portals.contains(where: match) else { return }
        portals.removeAll(where: match)
        touched = true
    }

    // MARK: - 시작 방향·크기

    func setStartDirection(_ direction: Direction) {
        guard direction != map.startDirection else { return }
        let base = snapshot
        map.startDirection = direction
        didEditOutsideStroke(base: base)
    }

    /// 가로·세로 칸 수 변경 — 늘어난 칸은 벽, 줄어들어 밖으로 나간 요소는 지움
    /// 시작이나 목표가 밖으로 나가면 거부 (먼저 옮겨야 함)
    @discardableResult
    func resize(width newWidth: Int, height newHeight: Int) -> Bool {
        let range = MapValidator.minSize...MapValidator.maxSize
        guard range.contains(newWidth), range.contains(newHeight) else {
            message = "맵 크기는 \(MapValidator.minSize)~\(MapValidator.maxSize)칸이에요."
            return false
        }
        guard newWidth != width || newHeight != height else { return false }
        let inside = { (p: Position) in p.x < newWidth && p.y < newHeight }
        guard inside(map.start), inside(map.goal) else {
            message = "시작이나 목표가 새 크기 밖에 있어요. 먼저 안쪽으로 옮겨 주세요."
            return false
        }

        let base = snapshot
        var grid = Array(repeating: Array(repeating: TileType.wall.rawValue, count: newWidth), count: newHeight)
        for y in 0..<min(height, newHeight) {
            for x in 0..<min(width, newWidth) { grid[y][x] = map.grid[y][x] }
        }
        map.grid = grid
        items = items.filter(inside)
        switches = switches.filter { inside($0.switchAt) && inside($0.gateAt) }
        portals = portals.filter { inside($0.a) && inside($0.b) }
        if let first = pending, !inside(first.position) { pending = nil }
        message = nil
        didEditOutsideStroke(base: base)
        return true
    }

    // MARK: - 팔레트

    /// 블럭 켜고 끄기 — 보석 획득·스위치 작동은 맵 요소에 따라 자동이라 바꿀 수 없음
    func toggleBlock(_ type: BlockType) {
        guard Self.optionalBlocks.contains(type) else { return }
        let base = snapshot
        if enabledBlocks.contains(type) {
            enabledBlocks.remove(type)
        } else {
            enabledBlocks.insert(type)
        }
        didEditOutsideStroke(base: base)
    }

    // MARK: - 되돌리기

    private var snapshot: Snapshot { Snapshot(map: map, enabledBlocks: enabledBlocks) }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(snapshot)
        restore(previous)
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(snapshot)
        restore(next)
    }

    private func restore(_ state: Snapshot) {
        map = state.map
        enabledBlocks = state.enabledBlocks
        pending = nil
        message = nil
        isDirty = true
        invalidateCheckResults()
        refreshHistoryFlags()
    }

    private func commit(_ base: Snapshot) {
        undoStack.append(base)
        if undoStack.count > Self.maxHistory { undoStack.removeFirst() }
        redoStack.removeAll()
        isDirty = true
        refreshHistoryFlags()
    }

    /// 칠하기 획을 거치지 않는 수정(크기·방향·팔레트) — 한 번에 되돌리기 한 단계
    private func didEditOutsideStroke(base: Snapshot) {
        invalidateCheckResults()
        commit(base)
    }

    private func refreshHistoryFlags() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }

    private func invalidateCheckResults() {
        validation = nil
        testClearBlockCount = nil
    }

    // MARK: - 확인과 저장

    /// 저장해도 되는 맵인지 확인 — 풀 수 있는지 자동 탐색까지 함
    @discardableResult
    func validate() -> MapValidation {
        let result = MapValidator.validate(map, palette: palette)
        validation = result
        return result
    }

    /// 만든 사람이 테스트 플레이로 클리어한 블럭 수를 기록 — 더 적게 깬 기록만 남음
    func recordTestClear(blockCount: Int) {
        guard blockCount > 0, validation?.isValid == true else { return }
        testClearBlockCount = min(testClearBlockCount ?? blockCount, blockCount)
    }

    /// 확인을 통과해야 저장됨 — 짝을 기다리던 칸은 저장되지 않음
    /// - Throws: CustomMapService.SaveError
    @discardableResult
    func save(to service: CustomMapService) throws -> CustomMap {
        let result = validation ?? validate()
        guard result.isValid, let thresholds else {
            throw CustomMapService.SaveError.invalidMap(result.issues)
        }
        let saved = try service.save(id: editingID, name: name, map: map, palette: palette, thresholds: thresholds)
        editingID = saved.id
        isDirty = false
        return saved
    }
}
