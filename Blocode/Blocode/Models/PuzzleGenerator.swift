//
//  PuzzleGenerator.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import Foundation

// MARK: - SeededGenerator
/// 같은 씨앗이면 항상 같은 값이 나오는 난수 — 같은 날의 일일 퍼즐이 모든 기기에서 같도록 함
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - PuzzleTheme
/// 퍼즐에 들어가는 기믹 구성
enum PuzzleTheme: CaseIterable {
    case basic      // 기믹 없음 — 미로 길 찾기
    case gems       // 보석
    case switches   // 스위치와 문
    case portals    // 포탈
    case mixed      // 보석 + 스위치 또는 포탈
}

// MARK: - PuzzleDifficulty
/// 퍼즐 난이도 — 일일 퍼즐은 표준, 랜덤 퍼즐은 어렵게
enum PuzzleDifficulty {
    case standard
    case hard

    /// 가장 짧은 풀이 블럭 수 범위 — 너무 쉽거나 너무 길지 않게
    var shortestRange: ClosedRange<Int> {
        switch self {
        case .standard: return 10...48
        case .hard:     return 34...64
        }
    }

    /// 테마를 고려한 범위 — 포탈은 지름길이라 풀이가 짧아지므로 어려운 쪽에서도 하한을 낮춤
    func shortestRange(for theme: PuzzleTheme) -> ClosedRange<Int> {
        if self == .hard && theme == .portals { return 22...64 }
        return shortestRange
    }

    /// 풀이에 들어가는 회전 블럭 최소 개수 — 어려운 쪽은 길이 더 많이 꺾임
    var minimumTurns: Int { self == .standard ? 3 : 6 }

    /// 조건에 맞는 퍼즐을 찾으려고 씨앗을 바꿔 가며 시도하는 횟수 — 조건이 빡빡한 어려운 쪽은 더 많이
    var attempts: Int { self == .standard ? 120 : 250 }

    /// 보석 최대 개수
    func maxItems(mixed: Bool) -> Int {
        switch self {
        case .standard: return mixed ? 2 : 3
        case .hard:     return mixed ? 3 : 4
        }
    }
}

// MARK: - PuzzleGenerator
/// 일일 퍼즐과 랜덤 퍼즐을 만드는 규칙
/// 미로를 파서 시작과 목표를 가장 멀리 두고, 테마에 맞는 기믹을 놓은 뒤 MapValidator·MapSolver로
/// 풀 수 있는지와 재미 조건(길이, 꺾임, 기믹이 실제로 필요한지)을 확인함 — 조건을 못 맞추면 다른 씨앗으로 다시 시도
/// 같은 씨앗·테마면 언제나 같은 퍼즐이 나옴
enum PuzzleGenerator {

    static let dailyIDPrefix = "daily_"
    static let randomIDPrefix = "random_"

    /// 맵 한 변 — 4×4 방이 복도로 이어진 미로 (9칸이면 가장자리 벽 포함)
    static let size = 9

    /// 퍼즐 기본 팔레트 — 기믹 블럭은 맵 요소에 따라 추가됨
    private static let basePalette: [BlockType] = [.moveForward, .turnLeft, .turnRight, .repeatBlock, .ifBlock]

    // MARK: - 일일 퍼즐

    /// 날짜를 숫자 하나로 (예: 20261112) — 일일 퍼즐의 씨앗이자 ID에 들어감
    static func dailyKey(for date: Date, calendar: Calendar = .current) -> Int {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return (parts.year ?? 0) * 10_000 + (parts.month ?? 0) * 100 + (parts.day ?? 0)
    }

    /// 요일별 테마 — 월·화 기본, 수 보석, 목 스위치, 금 포탈, 주말 섞기 (weekday는 Calendar 기준 1=일요일 … 7=토요일)
    static func theme(forWeekday weekday: Int) -> PuzzleTheme {
        switch weekday {
        case 2, 3: return .basic
        case 4: return .gems
        case 5: return .switches
        case 6: return .portals
        default: return .mixed
        }
    }

    /// 그날의 퍼즐 — 같은 날짜면 언제나 같음
    static func dailyStage(for date: Date, calendar: Calendar = .current) -> Stage {
        let key = dailyKey(for: date, calendar: calendar)
        let theme = theme(forWeekday: calendar.component(.weekday, from: date))
        return stage(id: "\(dailyIDPrefix)\(key)", name: "오늘의 퍼즐", seed: UInt64(key), theme: theme)
    }

    /// 날짜 숫자(yyyyMMdd)로 그날의 퍼즐 — 숫자가 날짜가 아니면 nil (플레이 화면이 자정을 넘겨도 같은 퍼즐을 유지하려고 사용)
    static func dailyStage(forKey key: Int, calendar: Calendar = .current) -> Stage? {
        let components = DateComponents(year: key / 10_000, month: key / 100 % 100, day: key % 100, hour: 12)
        guard let date = calendar.date(from: components), dailyKey(for: date, calendar: calendar) == key else { return nil }
        return dailyStage(for: date, calendar: calendar)
    }

    // MARK: - 랜덤 퍼즐

    /// 랜덤 퍼즐이 고르는 테마 — 기믹 없는 기본은 빼고, 기믹이 섞인 쪽을 두 배로 자주
    private static let randomThemes: [PuzzleTheme] = [.gems, .switches, .portals, .mixed, .mixed]

    /// 씨앗에 해당하는 랜덤 퍼즐 — 테마도 씨앗으로 정해지고, 일일 퍼즐보다 어렵게 만듦
    static func randomStage(seed: UInt64) -> Stage {
        var rng = SeededGenerator(seed: seed)
        let theme = randomThemes.randomElement(using: &rng) ?? .mixed
        return stage(id: "\(randomIDPrefix)\(seed)", name: "랜덤 퍼즐", seed: seed, theme: theme, difficulty: .hard)
    }

    // MARK: - 만들기

    /// 씨앗과 테마로 퍼즐 스테이지를 만듦 — 조건을 맞춘 퍼즐을 못 찾으면 항상 풀 수 있는 기본 맵을 돌려줌
    static func stage(id: String, name: String, seed: UInt64, theme: PuzzleTheme,
                      difficulty: PuzzleDifficulty = .standard) -> Stage {
        for attempt in 0..<difficulty.attempts {
            var rng = SeededGenerator(seed: seed &* 0x2545F4914F6CDD1D &+ UInt64(attempt) &+ 1)
            if let puzzle = makePuzzle(theme: theme, difficulty: difficulty, rng: &rng) {
                return Stage(id: id, chapter: 0, stageNumber: 0, name: name, mapData: puzzle.map,
                             starThresholds: MapValidator.defaultThresholds(shortest: puzzle.shortest),
                             availableBlocks: puzzle.palette)
            }
        }
        // 어려운 조건을 못 맞췄으면 표준 난이도로 한 번 더 — 그래도 못 찾을 때만 뱀길
        if difficulty == .hard {
            return stage(id: id, name: name, seed: seed, theme: theme, difficulty: .standard)
        }
        return fallbackStage(id: id, name: name)
    }

    private struct Puzzle {
        let map: MapData
        let palette: [BlockType]
        let shortest: Int
    }

    private static let directions = [Position(x: 0, y: -1), Position(x: 1, y: 0), Position(x: 0, y: 1), Position(x: -1, y: 0)]

    /// 맵의 모든 칸
    private static var allCells: [Position] {
        var cells: [Position] = []
        for y in 0..<size {
            for x in 0..<size { cells.append(Position(x: x, y: y)) }
        }
        return cells
    }

    private static func neighbors(of p: Position) -> [Position] {
        directions.map { Position(x: p.x + $0.x, y: p.y + $0.y) }
    }

    private static func isFloor(_ grid: [[Int]], _ p: Position) -> Bool {
        p.y >= 0 && p.y < grid.count && p.x >= 0 && p.x < grid[0].count && grid[p.y][p.x] == 1
    }

    /// 미로 — 방(홀수 칸)을 깊이 우선으로 이어 복도를 팜
    private static func carveMaze(rng: inout SeededGenerator) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: size), count: size)
        let rooms = (size - 1) / 2
        var visited = Set<Position>()
        var stack = [Position(x: Int.random(in: 0..<rooms, using: &rng), y: Int.random(in: 0..<rooms, using: &rng))]
        visited.insert(stack[0])
        grid[stack[0].y * 2 + 1][stack[0].x * 2 + 1] = 1
        while let current = stack.last {
            let options = neighbors(of: current).filter {
                $0.x >= 0 && $0.x < rooms && $0.y >= 0 && $0.y < rooms && !visited.contains($0)
            }
            guard let next = options.randomElement(using: &rng) else {
                stack.removeLast()
                continue
            }
            // 두 방 사이 칸과 새 방을 바닥으로
            grid[current.y + next.y + 1][current.x + next.x + 1] = 1
            grid[next.y * 2 + 1][next.x * 2 + 1] = 1
            visited.insert(next)
            stack.append(next)
        }
        return grid
    }

    /// 벽 몇 개를 허물어 돌아가는 길을 만듦 — 방 사이 벽만 대상
    private static func addLoops(_ grid: inout [[Int]], count: Int, rng: inout SeededGenerator) {
        var walls: [Position] = []
        for cell in allCells where (cell.x + cell.y) % 2 == 1 && cell.x > 0 && cell.y > 0
            && cell.x < size - 1 && cell.y < size - 1 && grid[cell.y][cell.x] == 0 {
            walls.append(cell)
        }
        for wall in walls.shuffled(using: &rng).prefix(count) { grid[wall.y][wall.x] = 1 }
    }

    /// 위에서 아래, 왼쪽에서 오른쪽 순서로 정렬 — 집합·딕셔너리는 실행마다 순서가 달라서 난수로 고르기 전에 순서를 고정해야 같은 씨앗이 같은 퍼즐을 냄
    private static func inReadingOrder<S: Sequence>(_ cells: S) -> [Position] where S.Element == Position {
        cells.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
    }

    /// 거리가 가장 먼 칸 — 같은 거리면 읽는 순서에서 앞선 칸
    private static func farthestCell(in distance: [Position: Int]) -> Position? {
        var best: Position?
        for cell in inReadingOrder(distance.keys) where best == nil || distance[cell]! > distance[best!]! {
            best = cell
        }
        return best
    }

    /// 시작에서 닿는 칸까지의 거리와 부모 — blocked는 지나갈 수 없는 칸
    private static func distances(_ grid: [[Int]], from start: Position, blocked: Set<Position>)
        -> (distance: [Position: Int], parent: [Position: Position]) {
        var distance = [start: 0]
        var parent: [Position: Position] = [:]
        var queue = [start]
        var head = 0
        while head < queue.count {
            let current = queue[head]
            head += 1
            for next in neighbors(of: current) where isFloor(grid, next) && !blocked.contains(next) && distance[next] == nil {
                distance[next] = distance[current]! + 1
                parent[next] = current
                queue.append(next)
            }
        }
        return (distance, parent)
    }

    private static func path(from start: Position, to end: Position, parent: [Position: Position]) -> [Position] {
        var cells = [end]
        var current = end
        while current != start, let previous = parent[current] {
            cells.append(previous)
            current = previous
        }
        return cells.reversed()
    }

    private static func direction(from a: Position, to b: Position) -> Direction {
        if b.x > a.x { return .right }
        if b.x < a.x { return .left }
        return b.y > a.y ? .down : .up
    }

    private static func makePuzzle(theme: PuzzleTheme, difficulty: PuzzleDifficulty, rng: inout SeededGenerator) -> Puzzle? {
        var grid = carveMaze(rng: &rng)
        // 어려운 쪽은 돌아가는 길을 더 많이 만들어 갈림길을 늘림
        let loopRange = difficulty == .hard ? 1...3 : (theme == .basic ? 1 : 0)...2
        addLoops(&grid, count: Int.random(in: loopRange, using: &rng), rng: &rng)

        // 시작과 목표 — 미로에서 가장 먼 두 방
        let floors = allCells.filter { isFloor(grid, $0) }
        guard let seed = floors.randomElement(using: &rng) else { return nil }
        let firstSweep = distances(grid, from: seed, blocked: [])
        guard let far = farthestCell(in: firstSweep.distance) else { return nil }
        let secondSweep = distances(grid, from: far, blocked: [])
        guard let farthest = farthestCell(in: secondSweep.distance) else { return nil }
        let reversed = Bool.random(using: &rng)
        let start = reversed ? farthest : far
        let goal = reversed ? far : farthest
        let route = path(from: start, to: goal, parent: distances(grid, from: start, blocked: []).parent)
        guard route.count >= 6 else { return nil }
        let routeSet = Set(route)

        var used: Set<Position> = [start, goal]
        var items: [Position] = []
        var switches: [SwitchGate] = []
        var portals: [PortalPair] = []

        let wantsItems = theme == .gems || theme == .mixed
        // 어려운 섞기는 스위치와 포탈을 함께 넣음 (표준은 둘 중 하나)
        let mixedSwitch = theme == .mixed && (difficulty == .hard || Bool.random(using: &rng))
        let wantsSwitch = theme == .switches || mixedSwitch
        let wantsPortal = theme == .portals || (theme == .mixed && (difficulty == .hard || !wantsSwitch))

        // 문 — 가는 길 가운데의 복도 칸을 벽으로 막고, 스위치는 문 앞쪽의 곁길에 둠
        if wantsSwitch {
            let middle = Array(route[(route.count / 4)...(route.count * 3 / 4)])
            let corridors = middle.filter { cell in
                cell != start && cell != goal && neighbors(of: cell).filter { isFloor(grid, $0) }.count == 2
            }
            guard let gate = corridors.randomElement(using: &rng) else { return nil }
            grid[gate.y][gate.x] = 0
            let reachable = inReadingOrder(distances(grid, from: start, blocked: []).distance.keys).filter { !used.contains($0) }
            let sideCells = reachable.filter { !routeSet.contains($0) }
            guard let switchCell = (sideCells.isEmpty ? Array(reachable) : sideCells).randomElement(using: &rng) else { return nil }
            switches = [SwitchGate(switchAt: switchCell, gateAt: gate)]
            used.insert(switchCell)
        }

        // 보석 — 곁길에 놓아 돌아가야 하게 함
        if wantsItems {
            let sideCells = floors.filter { isFloor(grid, $0) && !routeSet.contains($0) && !used.contains($0) }
            guard !sideCells.isEmpty else { return nil }
            let count = min(sideCells.count, Int.random(in: 1...difficulty.maxItems(mixed: theme == .mixed), using: &rng))
            items = Array(sideCells.shuffled(using: &rng).prefix(count))
            used.formUnion(items)
        }

        // 포탈 — 가는 길 앞쪽과 뒤쪽을 이어 지름길을 만듦
        if wantsPortal {
            let firstThird = route[1..<max(2, route.count * 2 / 5)].filter { isFloor(grid, $0) && !used.contains($0) }
            let lastThird = route[(route.count * 3 / 5)..<(route.count - 1)].filter { isFloor(grid, $0) && !used.contains($0) }
            guard let a = firstThird.randomElement(using: &rng), let b = lastThird.randomElement(using: &rng) else { return nil }
            portals = [PortalPair(a: a, b: b)]
        }

        var palette = basePalette
        if !items.isEmpty { palette.append(.collectItem) }
        if !switches.isEmpty { palette.append(.activateSwitch) }

        let map = MapData(grid: grid, start: start, startDirection: direction(from: start, to: route[1]), goal: goal,
                          items: items.isEmpty ? nil : items,
                          switches: switches.isEmpty ? nil : switches,
                          portals: portals.isEmpty ? nil : portals)

        // 풀 수 있고, 적당히 길고, 꺾임이 있어야 함
        let validation = MapValidator.validate(map, palette: palette)
        guard validation.isValid, let solution = validation.shortestSolution,
              difficulty.shortestRange(for: theme).contains(solution.count),
              solution.filter({ $0 == .turnLeft || $0 == .turnRight }).count >= difficulty.minimumTurns else { return nil }

        // 기믹이 실제로 필요해야 함 — 문은 스위치 없이 못 지나가고, 포탈은 지름길이고, 보석은 돌아가야 함
        if !switches.isEmpty {
            var withoutSwitch = map
            withoutSwitch.switches = nil
            guard MapSolver.solve(withoutSwitch, palette: palette, collectingAllItems: true) == .unsolvable else { return nil }
        }
        if !portals.isEmpty {
            var withoutPortal = map
            withoutPortal.portals = nil
            if case .solved(let longer) = MapSolver.solve(withoutPortal, palette: palette, collectingAllItems: true),
               longer.count < solution.count + 3 { return nil }
        }
        if !items.isEmpty {
            var withoutItems = map
            withoutItems.items = nil
            let plain = basePalette + (switches.isEmpty ? [] : [.activateSwitch])
            guard case .solved(let shorter) = MapSolver.solve(withoutItems, palette: plain),
                  shorter.count < solution.count else { return nil }
        }

        return Puzzle(map: map, palette: palette, shortest: solution.count)
    }

    /// 조건을 맞춘 퍼즐을 못 찾았을 때 쓰는 뱀길 — 항상 풀 수 있음
    private static func fallbackStage(id: String, name: String) -> Stage {
        var grid = Array(repeating: Array(repeating: 0, count: size), count: size)
        for row in [1, 3, 5, 7] { for x in 1...(size - 2) { grid[row][x] = 1 } }
        grid[2][size - 2] = 1
        grid[4][1] = 1
        grid[6][size - 2] = 1
        let map = MapData(grid: grid, start: Position(x: 1, y: 1), startDirection: .right, goal: Position(x: 1, y: 7))
        // 별 기준은 실제 최단 풀이로 계산 (손으로 적은 숫자는 맵을 고치면 어긋남)
        let shortest = MapValidator.validate(map, palette: basePalette).shortestSolution?.count ?? 36
        return Stage(id: id, chapter: 0, stageNumber: 0, name: name, mapData: map,
                     starThresholds: MapValidator.defaultThresholds(shortest: shortest), availableBlocks: basePalette)
    }
}
