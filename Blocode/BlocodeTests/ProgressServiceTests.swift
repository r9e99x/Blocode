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
import Observation
import Synchronization
import SwiftData
@testable import Blocode

extension ProgressService {
    /// 테스트 전용 — 메모리 저장소 + 테스트마다 새로운 UserDefaults
    static func makeForTesting(defaults: UserDefaults = isolatedDefaults()) -> ProgressService {
        ProgressService(isStoredInMemoryOnly: true, defaults: defaults)
    }
}

/// 실행이 끝날 때까지 기다림 — 여러 테스트 파일이 함께 씀
/// Observations(Swift 6.2): gameState가 바뀌는 순간 깨어남 — 예전엔 0.005초마다 확인하는 반복이라 메인 액터를 같이 쓰는 다른 테스트와 경쟁했음
/// 무한 대기는 각 스위트의 .timeLimit이 막아 줌 (시간이 다 되면 작업이 취소되어 아래 확인에서 실패로 기록)
func waitWhileRunning(_ viewModel: GameViewModel) async throws {
    for await state in Observations({ viewModel.gameState }) where state != .running { return }
    Issue.record("실행이 끝나지 않음 (gameState=\(viewModel.gameState))")
}

/// 테스트가 직접 풀어 주는 애니메이션 대기 — GameViewModel(sleep:)에 `gate.sleep`을 넣으면
/// 블럭 하나의 애니메이션마다 여기서 멈추므로, "첫 이동 도중" 같은 상태를 시간에 기대지 않고 정확히 만들 수 있음
final class AnimationGate {
    private var waiting: [CheckedContinuation<Void, Never>] = []

    /// 지금 멈춰 있는 애니메이션 수
    var waitingCount: Int { waiting.count }

    /// GameViewModel에 넘길 대기 함수
    func sleep(_ seconds: Double) async {
        await withCheckedContinuation { waiting.append($0) }
    }

    /// 멈춰 있는 애니메이션을 모두 풀어 줌
    func releaseAll() {
        let pending = waiting
        waiting = []
        pending.forEach { $0.resume() }
    }

    /// 조건이 참이 될 때까지 다른 작업에 차례를 넘김 — 실제 시간 대기 없이 실행 Task가 진행되게 함
    func yield(until condition: () -> Bool, limit: Int = 1_000) async {
        var count = 0
        while !condition(), count < limit {
            await Task.yield()
            count += 1
        }
    }

    /// 실행이 끝날 때까지 애니메이션을 하나씩 풀어 줌
    func runToEnd(_ viewModel: GameViewModel, limit: Int = 1_000) async {
        var count = 0
        while viewModel.gameState == .running, count < limit {
            releaseAll()
            await Task.yield()
            count += 1
        }
        // 이미 취소된 이전 실행이 남아 있으면 마저 풀어 끝까지 돌게 함
        for _ in 0..<20 { releaseAll(); await Task.yield() }
    }
}

/// 다른 테스트·실제 앱 설정과 섞이지 않는 UserDefaults
func isolatedDefaults() -> UserDefaults {
    UserDefaults(suiteName: "test_\(UUID().uuidString)")!
}

/// 변경 신호를 받았는지 담아 두는 상자 — Observation의 onChange는 @Sendable이고 바꾸는 쪽 스레드에서 바로 불려서
/// Mutex(Synchronization)로 감싸 안전하게 씀 (예전엔 @unchecked Sendable로 컴파일러의 동시성 검사를 껐음)
nonisolated private final class ObservationFlag: Sendable {
    let fired = Mutex(false)
}

/// @Observable 객체에서 `read`가 읽은 값이 `change` 동안 바뀌어 화면 갱신 신호가 나가는지 확인
/// (ObservableObject 시절 objectWillChange 구독으로 하던 "화면에 변경을 알림" 검사를 대신함)
func observationFires(reading read: () -> Void, when change: () -> Void) -> Bool {
    let flag = ObservationFlag()
    withObservationTracking(read, onChange: { flag.fired.withLock { $0 = true } })
    change()
    return flag.fired.withLock { $0 }
}

@Suite("진행도 저장", .timeLimit(.minutes(1)))
struct ProgressServiceTests {

    @Test("클리어를 저장하면 메모리 미러가 저장소 내용과 똑같음 (바뀐 한 줄만 고쳐도)")
    func mirrorMatchesStoreAfterRecords() throws {
        let progress = ProgressService.makeForTesting()
        progress.recordClear(stageId: "ch1_stage1", stars: 2, blockCount: 9)
        progress.recordClear(stageId: "ch1_stage1", stars: 3, blockCount: 7)   // 더 좋은 기록 — 갱신
        progress.recordClear(stageId: "ch1_stage1", stars: 1, blockCount: 12)  // 더 나쁜 기록 — 별·블럭은 그대로
        progress.recordClear(stageId: "ch2_stage3", stars: 1, blockCount: 20)

        let rows = try progress.modelContainer.mainContext.fetch(FetchDescriptor<StageProgress>())
        #expect(rows.count == progress.results.count)
        for row in rows {
            let mirror = try #require(progress.results[row.stageId])
            #expect(mirror.isCleared == row.isCleared && mirror.stars == row.stars && mirror.bestBlockCount == row.bestBlockCount,
                    "\(row.stageId): 미러와 저장소가 다름")
        }
        #expect(progress.stars(for: "ch1_stage1") == 3)
        #expect(progress.result(for: "ch1_stage1")?.bestBlockCount == 7)
    }

    @Test("저장소를 열 수 없으면 앱을 끄지 않고 메모리 저장소로 대신함")
    func unopenableStoreFallsBackToMemory() throws {
        let schema = Schema([StageProgress.self, CustomMap.self])
        // 데이터베이스가 아닌 내용으로 채운 손상된 저장소 파일 — 열기가 반드시 실패함
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("broken-\(UUID().uuidString).store")
        try Data("이건 데이터베이스가 아님".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let broken = ModelConfiguration(schema: schema, url: url)
        let (container, usedFallback) = ProgressService.makeContainer(schema: schema, configuration: broken)
        #expect(usedFallback)
        // 대신 만든 저장소에도 정상적으로 쓰고 읽을 수 있음
        container.mainContext.insert(StageProgress(stageId: "ch1_stage1"))
        try container.mainContext.save()
        #expect(try container.mainContext.fetch(FetchDescriptor<StageProgress>()).count == 1)
    }

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

    @Test("켜 둔 채 날짜가 지나 다시 화면에 오면 끊긴 연속 일수가 0으로 바뀜")
    func streak_refreshedWhenReturning() {
        let defaults = isolatedDefaults()
        defaults.set(4, forKey: streakKey)
        defaults.set(startOfDay(daysAgo: 1), forKey: lastClearDateKey)
        let progress = ProgressService.makeForTesting(defaults: defaults)
        #expect(progress.streak == 4)
        // 백그라운드에 있는 동안 하루가 더 지난 것과 같은 상태
        defaults.set(startOfDay(daysAgo: 2), forKey: lastClearDateKey)
        progress.refreshStreak()
        #expect(progress.streak == 0)
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

        viewModel.codeBlocks = [Block(type: .moveForward)]
        viewModel.run()
        try await waitWhileRunning(viewModel)
        #expect(viewModel.gameState == .success)
        #expect(progress.stars(for: stage.id) == 3)
        #expect(ProgressService.shared.isCleared(stage.id) == false)
    }
}

// MARK: - 스테이지 불러오기 경계

@Suite("스테이지 불러오기 경계")
struct StageLoaderEdgeTests {

    @Test("스테이지가 없는 챕터를 불러와도 죽지 않고 빈 목록")
    func emptyChapterLoadsNothing() {
        #expect(StageLoader.loadChapter(1, stageCount: 0).isEmpty)
        #expect(ChapterViewModel(chapter: 999, progress: .makeForTesting()).stages.isEmpty)  // 없는 챕터 번호
    }

    @Test("다시 불러온 스테이지는 처음과 같고, ID 표는 직접 만든 목록과 같음")
    func cachedLoadsAndIDTableMatch() throws {
        let first = try #require(StageLoader.load(chapter: 3, stage: 2))
        let again = try #require(StageLoader.load(chapter: 3, stage: 2))  // 두 번째는 캐시에서
        #expect(again.id == first.id && again.mapData.grid == first.mapData.grid)
        #expect(StageLoader.load(chapter: 99, stage: 1) == nil)  // 없는 파일은 캐시와 상관없이 nil

        for chapter in ChapterCatalog.all {
            let made = (0..<chapter.stageCount).map { Stage.makeID(chapter: chapter.number, number: $0 + 1) }
            #expect(ProgressService.stageIDs(chapter: chapter.number, count: chapter.stageCount) == made)
        }
        // 카탈로그와 개수가 다르면 표 대신 직접 만듦
        #expect(ProgressService.stageIDs(chapter: 1, count: 2) == ["ch1_stage1", "ch1_stage2"])
        #expect(ProgressService.stageIDs(chapter: 1, count: 0).isEmpty)
    }

    @Test("컨테이너 블럭은 반복·만약에·함수뿐")
    func containerTypes() {
        #expect(BlockType.allCases.filter(\.isContainer) == [.repeatBlock, .ifBlock, .functionBlock])
    }
}
