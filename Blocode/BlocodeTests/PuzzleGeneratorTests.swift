//
//  PuzzleGeneratorTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/12/26.
//
//  일일·랜덤 퍼즐 생성 검증 — 같은 씨앗이면 같은 퍼즐, 항상 풀 수 있음, 재미 조건,
//  요일별 테마, 기록 규칙. 무거운 반복은 중간에 양보해 같이 도는 실행 테스트를 막지 않는다.

import Testing
import Foundation
@testable import Blocode

@MainActor
@Suite("퍼즐 생성")
struct PuzzleGeneratorTests {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    /// 맵을 비교 가능한 문자열로
    private func fingerprint(_ stage: Stage) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys  // 키 순서가 매번 달라지지 않게
        let data = (try? encoder.encode(stage.mapData)) ?? Data()
        return String(decoding: data, as: UTF8.self) + stage.paletteBlocks.map(\.rawValue).joined(separator: ",")
    }

    // MARK: - 날짜와 테마

    @Test("날짜는 yyyyMMdd 숫자가 되고 요일별 테마가 정해짐")
    func dailyKeyAndThemes() {
        #expect(PuzzleGenerator.dailyKey(for: date(2026, 11, 12), calendar: calendar) == 20261112)
        #expect(PuzzleGenerator.dailyKey(for: date(2026, 1, 5), calendar: calendar) == 20260105)
        // 1=일 2=월 3=화 4=수 5=목 6=금 7=토
        #expect(PuzzleGenerator.theme(forWeekday: 2) == .basic)
        #expect(PuzzleGenerator.theme(forWeekday: 3) == .basic)
        #expect(PuzzleGenerator.theme(forWeekday: 4) == .gems)
        #expect(PuzzleGenerator.theme(forWeekday: 5) == .switches)
        #expect(PuzzleGenerator.theme(forWeekday: 6) == .portals)
        #expect(PuzzleGenerator.theme(forWeekday: 7) == .mixed)
        #expect(PuzzleGenerator.theme(forWeekday: 1) == .mixed)
    }

    @Test("같은 날은 같은 퍼즐이고 다음 날은 다름")
    func dailyIsDeterministic() {
        let today = PuzzleGenerator.dailyStage(for: date(2026, 11, 12), calendar: calendar)
        let again = PuzzleGenerator.dailyStage(for: date(2026, 11, 12), calendar: calendar)
        let tomorrow = PuzzleGenerator.dailyStage(for: date(2026, 11, 13), calendar: calendar)
        #expect(today.id == "daily_20261112")
        #expect(fingerprint(today) == fingerprint(again))
        #expect(fingerprint(today) != fingerprint(tomorrow))
        #expect(today.name == "오늘의 퍼즐")
    }

    @Test("씨앗 20개 × 테마를 두 번씩 만들어도 항상 같음 (집합 순서에 기대지 않음)")
    func repeatedGenerationIsIdentical() async {
        for theme in PuzzleTheme.allCases {
            for seed in 0..<20 {
                let first = PuzzleGenerator.stage(id: "random_\(seed)", name: "t", seed: UInt64(seed), theme: theme)
                let second = PuzzleGenerator.stage(id: "random_\(seed)", name: "t", seed: UInt64(seed), theme: theme)
                #expect(fingerprint(first) == fingerprint(second), "\(theme) 씨앗 \(seed)")
            }
            try? await Task.sleep(for: .milliseconds(1))
        }
    }

    @Test("랜덤 퍼즐도 씨앗이 같으면 같고 ID에 씨앗이 들어감")
    func randomIsDeterministic() {
        let a = PuzzleGenerator.randomStage(seed: 42)
        let b = PuzzleGenerator.randomStage(seed: 42)
        let c = PuzzleGenerator.randomStage(seed: 43)
        #expect(a.id == "random_42")
        #expect(fingerprint(a) == fingerprint(b))
        #expect(fingerprint(a) != fingerprint(c))
    }

    // MARK: - 품질

    /// 퍼즐이 검증을 통과하고 재미 조건을 지키는지
    private func checkQuality(_ stage: Stage, theme: PuzzleTheme?, label: String) {
        let map = stage.mapData
        let result = MapValidator.validate(map, palette: stage.paletteBlocks)
        #expect(result.isValid, "\(label): 검증 실패 \(result.issues)")
        #expect(map.width <= MapValidator.maxSize && map.height <= MapValidator.maxSize, "\(label): 맵이 큼")
        guard let shortest = result.shortestSolution else { return }
        #expect(stage.starThresholds.threeStar == shortest.count, "\(label): 별 3개 기준이 최단 풀이와 다름")
        #expect(stage.starThresholds.twoStar == shortest.count + 4, "\(label): 별 2개 기준")
        #expect(map.start != map.goal)
        guard let theme else { return }
        switch theme {
        case .basic:
            #expect(map.items == nil && map.switches == nil && map.portals == nil, "\(label): 기믹이 있음")
        case .gems:
            #expect(!(map.items ?? []).isEmpty, "\(label): 보석이 없음")
        case .switches:
            #expect(!(map.switches ?? []).isEmpty, "\(label): 스위치가 없음")
        case .portals:
            #expect(!(map.portals ?? []).isEmpty, "\(label): 포탈이 없음")
        case .mixed:
            #expect(!(map.items ?? []).isEmpty && (!(map.switches ?? []).isEmpty || !(map.portals ?? []).isEmpty),
                    "\(label): 섞인 구성이 아님")
        }
    }

    @Test("모든 테마에서 씨앗 25개가 풀 수 있고 조건을 지킴")
    func everyThemeIsValid() async {
        for theme in PuzzleTheme.allCases {
            for seed in 0..<25 {
                let stage = PuzzleGenerator.stage(id: "random_\(seed)", name: "t", seed: UInt64(seed), theme: theme)
                checkQuality(stage, theme: theme, label: "\(theme) 씨앗 \(seed)")
                try? await Task.sleep(for: .milliseconds(1))  // 양보 — 같이 도는 실행 테스트의 대기 시간이 넘어가지 않게
            }
        }
    }

    @Test("앞으로 10주 일일 퍼즐이 모두 유효함")
    func nextYearOfDailyPuzzles() async {
        let start = date(2026, 11, 12)
        for offset in 0..<70 {
            let day = calendar.date(byAdding: .day, value: offset, to: start)!
            let stage = PuzzleGenerator.dailyStage(for: day, calendar: calendar)
            checkQuality(stage, theme: PuzzleGenerator.theme(forWeekday: calendar.component(.weekday, from: day)),
                         label: stage.id)
            try? await Task.sleep(for: .milliseconds(1))  // 양보 — 같이 도는 실행 테스트의 대기 시간이 넘어가지 않게
        }
    }

    @Test("랜덤 퍼즐 씨앗 40개가 모두 유효함")
    func randomSeedsAreValid() async {
        for seed in 1000..<1040 {
            checkQuality(PuzzleGenerator.randomStage(seed: UInt64(seed)), theme: nil, label: "랜덤 \(seed)")
            try? await Task.sleep(for: .milliseconds(1))  // 양보 — 같이 도는 실행 테스트의 대기 시간이 넘어가지 않게
        }
    }

    @Test("퍼즐의 최단 풀이를 실제 엔진으로 실행하면 별 3개로 클리어")
    func solutionClearsWithThreeStars() async throws {
        for stage in [PuzzleGenerator.dailyStage(for: date(2026, 11, 14), calendar: calendar),   // 토: 섞기
                      PuzzleGenerator.dailyStage(for: date(2026, 11, 12), calendar: calendar),   // 목: 스위치
                      PuzzleGenerator.randomStage(seed: 7)] {
            let solution = try #require(MapValidator.validate(stage.mapData, palette: stage.paletteBlocks).shortestSolution)
            let vm = GameViewModel(stage: stage, progress: .makeForTesting(), executionSpeed: { 1000 })
            vm.codeBlocks = solution.map { Block(type: $0) }
            vm.run()
            let deadline = Date().addingTimeInterval(10)
            while vm.gameState == .running, Date() < deadline { try await Task.sleep(for: .milliseconds(5)) }
            #expect(vm.gameState == .success, "\(stage.id): 클리어 못 함")
            #expect(vm.clearedStars == 3, "\(stage.id): 별 \(vm.clearedStars)개")
        }
    }

    // MARK: - 기록 규칙

    @Test("일일 퍼즐만 진행도에 기록하고 랜덤·내 맵은 기록하지 않음")
    func recordingRules() {
        let daily = PuzzleGenerator.dailyStage(for: date(2026, 11, 12), calendar: calendar)
        let random = PuzzleGenerator.randomStage(seed: 1)
        #expect(daily.isDailyPuzzle && daily.recordsProgress)
        #expect(random.isRandomPuzzle && !random.recordsProgress)
        let custom = Stage(id: "custom_abc", chapter: 0, stageNumber: 0, name: "c", mapData: daily.mapData,
                           starThresholds: daily.starThresholds)
        #expect(custom.isCustomMap && !custom.recordsProgress)
        let normal = Stage.placeholder(chapter: 1, stageNumber: 1)
        #expect(!normal.isDailyPuzzle && !normal.isRandomPuzzle && normal.recordsProgress)
    }

    @Test("일일 퍼즐을 클리어하면 연속 일수는 오르고 챕터 별 합계는 그대로, 랜덤은 아무것도 안 남음")
    func dailyCountsForStreakOnly() async throws {
        let progress = ProgressService.makeForTesting()
        let home = HomeViewModel(progress: progress)
        let starsBefore = home.earnedStars

        func clear(_ stage: Stage) async throws {
            let solution = try #require(MapValidator.validate(stage.mapData, palette: stage.paletteBlocks).shortestSolution)
            let vm = GameViewModel(stage: stage, progress: progress, executionSpeed: { 1000 })
            vm.codeBlocks = solution.map { Block(type: $0) }
            vm.run()
            let deadline = Date().addingTimeInterval(10)
            while vm.gameState == .running, Date() < deadline { try await Task.sleep(for: .milliseconds(5)) }
            #expect(vm.gameState == .success)
        }

        try await clear(PuzzleGenerator.randomStage(seed: 5))
        #expect(progress.results.isEmpty)
        #expect(progress.streak == 0)

        let daily = PuzzleGenerator.dailyStage(for: date(2026, 11, 12), calendar: calendar)
        try await clear(daily)
        #expect(progress.isCleared(daily.id))
        #expect(progress.stars(for: daily.id) == 3)
        #expect(progress.streak == 1)
        #expect(home.earnedStars == starsBefore)
    }
}
