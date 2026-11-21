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
@testable import Blocode

extension ProgressService {
    /// 테스트 전용 — 메모리 저장소 + 테스트마다 새로운 UserDefaults
    static func makeForTesting(defaults: UserDefaults = isolatedDefaults()) -> ProgressService {
        ProgressService(isStoredInMemoryOnly: true, defaults: defaults)
    }
}

/// 실행이 끝날 때까지 기다림 — 여러 테스트 파일이 함께 씀 (예전엔 같은 반복문이 파일마다 있었고 제한 시간도 제각각이었음)
/// 제한 시간은 무한 대기를 막는 넉넉한 상한일 뿐 — 같이 도는 테스트와 메인 액터를 나눠 써서 부하가 걸리면 오래 걸릴 수 있고, 끝나면 바로 빠져나옴
@MainActor
func waitWhileRunning(_ viewModel: GameViewModel, timeout: TimeInterval = 60) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while viewModel.gameState == .running, Date() < deadline {
        try await Task.sleep(for: .milliseconds(5))
    }
    if viewModel.gameState == .running {
        Issue.record("실행이 \(timeout)초 안에 끝나지 않음 (gameState=\(viewModel.gameState))")
    }
}

/// 테스트가 직접 풀어 주는 애니메이션 대기 — GameViewModel(sleep:)에 `gate.sleep`을 넣으면
/// 블럭 하나의 애니메이션마다 여기서 멈추므로, "첫 이동 도중" 같은 상태를 시간에 기대지 않고 정확히 만들 수 있음
@MainActor
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

/// 변경 신호를 받았는지 담아 두는 상자 — Observation의 onChange는 바꾸는 쪽 스레드에서 바로 불려서
/// 테스트(메인 액터) 안에서만 쓰면 안전함
private final class ObservationFlag: @unchecked Sendable {
    var fired = false
}

/// @Observable 객체에서 `read`가 읽은 값이 `change` 동안 바뀌어 화면 갱신 신호가 나가는지 확인
/// (ObservableObject 시절 objectWillChange 구독으로 하던 "화면에 변경을 알림" 검사를 대신함)
func observationFires(reading read: () -> Void, when change: () -> Void) -> Bool {
    let flag = ObservationFlag()
    withObservationTracking(read, onChange: { flag.fired = true })
    change()
    return flag.fired
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

        viewModel.codeBlocks = [Block(type: .moveForward)]
        viewModel.run()
        try await waitWhileRunning(viewModel)
        #expect(viewModel.gameState == .success)
        #expect(progress.stars(for: stage.id) == 3)
        #expect(ProgressService.shared.isCleared(stage.id) == false)
    }
}

// MARK: - 스테이지 불러오기 경계

@MainActor
@Suite("스테이지 불러오기 경계")
struct StageLoaderEdgeTests {

    @Test("스테이지가 없는 챕터를 불러와도 죽지 않고 빈 목록")
    func emptyChapterLoadsNothing() {
        #expect(StageLoader.loadChapter(1, stageCount: 0).isEmpty)
        #expect(ChapterViewModel(chapter: 999, progress: .makeForTesting()).stages.isEmpty)  // 없는 챕터 번호
    }

    @Test("컨테이너 블럭은 반복·만약에·함수뿐")
    func containerTypes() {
        #expect(BlockType.allCases.filter(\.isContainer) == [.repeatBlock, .ifBlock, .functionBlock])
    }
}
