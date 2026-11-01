//
//  ProgressServiceTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/1/26.
//
//  ProgressService의 저장 규칙(기록 갱신·연속 일수·초기화) 검증.
//  메모리 저장소와 격리된 UserDefaults만 사용하므로 실제 진행도에 영향이 없다.

import Testing
import Foundation
@testable import Blocode

extension ProgressService {
    /// 테스트 전용 — 메모리 저장소 + 테스트마다 새로운 UserDefaults
    static func makeForTesting(defaults: UserDefaults = isolatedDefaults()) -> ProgressService {
        ProgressService(isStoredInMemoryOnly: true, defaults: defaults)
    }
}

/// 다른 테스트·실제 앱 설정과 섞이지 않는 UserDefaults
func isolatedDefaults() -> UserDefaults {
    UserDefaults(suiteName: "test_\(UUID().uuidString)")!
}

@MainActor
@Suite("진행도 저장")
struct ProgressServiceTests {

    private let streakKey = "blocode_streak"
    private let lastClearDateKey = "blocode_last_clear_date"

    /// 오늘로부터 며칠 전의 시작 시각
    private func startOfDay(daysAgo: Int) -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
    }

    // MARK: - 저장 키

    @Test("스테이지 ID 형식은 저장된 진행도 키와 같아야 함 — 바뀌면 기존 기록을 못 찾음")
    func stageID_formatIsStable() {
        #expect(Stage.makeID(chapter: 1, number: 2) == "ch1_stage2")
        #expect(Stage.makeID(chapter: 10, number: 6) == "ch10_stage6")
    }

    // MARK: - 기록 갱신

    @Test("더 좋은 기록만 남음 — 별은 최댓값, 블럭 수는 최솟값")
    func recordClear_keepsBestResult() {
        let progress = ProgressService.makeForTesting()
        progress.recordClear(stageId: "ch1_stage1", stars: 2, blockCount: 5)
        progress.recordClear(stageId: "ch1_stage1", stars: 1, blockCount: 9)
        #expect(progress.stars(for: "ch1_stage1") == 2)
        #expect(progress.result(for: "ch1_stage1")?.bestBlockCount == 5)

        progress.recordClear(stageId: "ch1_stage1", stars: 3, blockCount: 3)
        #expect(progress.stars(for: "ch1_stage1") == 3)
        #expect(progress.result(for: "ch1_stage1")?.bestBlockCount == 3)
        #expect(progress.isCleared("ch1_stage1"))
    }

    @Test("저장소를 주입하면 다른 저장소에 기록이 섞이지 않음")
    func injectedStores_areIsolated() {
        let first = ProgressService.makeForTesting()
        let second = ProgressService.makeForTesting()
        first.recordClear(stageId: "unittest_isolated", stars: 3, blockCount: 1)
        #expect(first.isCleared("unittest_isolated"))
        #expect(second.isCleared("unittest_isolated") == false)
        #expect(ProgressService.shared.isCleared("unittest_isolated") == false)
    }

    @Test("초기화하면 기록은 지워지고 연속 일수는 유지")
    func resetAll_clearsResultsButKeepsStreak() {
        let progress = ProgressService.makeForTesting()
        progress.recordClear(stageId: "ch1_stage1", stars: 3, blockCount: 1)
        progress.resetAll()
        #expect(progress.results.isEmpty)
        #expect(progress.isCleared("ch1_stage1") == false)
        #expect(progress.streak == 1)
    }

    // MARK: - 연속 일수

    @Test("첫 클리어는 1일, 같은 날 또 클리어해도 그대로")
    func streak_firstClearAndSameDay() {
        let progress = ProgressService.makeForTesting()
        progress.recordClear(stageId: "ch1_stage1", stars: 3, blockCount: 1)
        #expect(progress.streak == 1)
        progress.recordClear(stageId: "ch1_stage2", stars: 3, blockCount: 1)
        #expect(progress.streak == 1)
    }

    @Test("어제 클리어했으면 하루 늘어남")
    func streak_increasesAfterYesterday() {
        let defaults = isolatedDefaults()
        defaults.set(4, forKey: streakKey)
        defaults.set(startOfDay(daysAgo: 1), forKey: lastClearDateKey)
        let progress = ProgressService.makeForTesting(defaults: defaults)
        progress.recordClear(stageId: "ch1_stage1", stars: 3, blockCount: 1)
        #expect(progress.streak == 5)
    }

    @Test("이틀 이상 쉬고 클리어하면 1일부터 다시 시작")
    func streak_restartsAfterGap() {
        let defaults = isolatedDefaults()
        defaults.set(4, forKey: streakKey)
        defaults.set(startOfDay(daysAgo: 3), forKey: lastClearDateKey)
        let progress = ProgressService.makeForTesting(defaults: defaults)
        progress.recordClear(stageId: "ch1_stage1", stars: 3, blockCount: 1)
        #expect(progress.streak == 1)
    }

    @Test("앱을 켤 때 이틀 이상 쉬었으면 연속 일수는 0으로 표시")
    func streak_showsZeroAfterGapOnLaunch() {
        let defaults = isolatedDefaults()
        defaults.set(4, forKey: streakKey)
        defaults.set(startOfDay(daysAgo: 2), forKey: lastClearDateKey)
        #expect(ProgressService.makeForTesting(defaults: defaults).streak == 0)
    }

    @Test("앱을 켤 때 오늘이나 어제 클리어했으면 연속 일수 유지")
    func streak_keptOnLaunchWhenRecent() {
        for daysAgo in [0, 1] {
            let defaults = isolatedDefaults()
            defaults.set(4, forKey: streakKey)
            defaults.set(startOfDay(daysAgo: daysAgo), forKey: lastClearDateKey)
            #expect(ProgressService.makeForTesting(defaults: defaults).streak == 4)
        }
    }

    // MARK: - GameViewModel 연결

    @Test("클리어 기록은 주입한 저장소에 남음")
    func clear_recordsToInjectedProgress() async throws {
        let mapData = MapData(grid: [[1, 1]], start: Position(x: 0, y: 0), startDirection: .right, goal: Position(x: 1, y: 0))
        let stage = Stage(id: "unittest_\(UUID().uuidString)", chapter: 0, stageNumber: 0, name: "Progress Test",
                          mapData: mapData, starThresholds: StarThresholds(threeStar: 1, twoStar: 2))
        let progress = ProgressService.makeForTesting()
        let viewModel = GameViewModel(stage: stage, progress: progress, executionSpeed: { 2 })
        let scene = GameScene(mapData: mapData)
        scene.size = CGSize(width: 400, height: 400)
        scene.setupMap()
        viewModel.scene = scene  // weak 참조 — scene을 테스트 끝까지 붙잡아야 함
        #expect(scene.executionSpeed() == 2)  // VM에 주입한 속도가 씬까지 전달됨

        viewModel.codeBlocks = [Block(type: .moveForward)]
        viewModel.run()
        let deadline = Date().addingTimeInterval(5)
        while viewModel.gameState == .running, Date() < deadline {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        #expect(viewModel.gameState == .success)
        #expect(progress.stars(for: stage.id) == 3)
        #expect(ProgressService.shared.isCleared(stage.id) == false)
    }
}
