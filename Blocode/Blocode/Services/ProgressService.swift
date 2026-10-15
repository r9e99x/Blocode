//
//  ProgressService.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation
import Combine
import SwiftData
import os

// MARK: - StageResult
/// 스테이지 하나의 클리어 기록을 뷰에 전달하기 위한 경량 값 타입(DTO)
/// 실제 영속 저장은 SwiftData의 `StageProgress` 모델이 담당하며,
/// 이 구조체는 SwiftData 모델을 뷰가 그대로 쓰지 않도록 감싸는 읽기 전용 미러임
struct StageResult: Codable {
    var isCleared: Bool       // 클리어 여부
    var stars: Int            // 획득 별 수 0~3
    var bestBlockCount: Int   // 지금까지 사용한 최소 블럭 수
}

// MARK: - ProgressService
/// 스테이지 클리어 기록을 SwiftData(`StageProgress`)에 저장/불러오는 서비스
/// 앱 전역에서 `@ObservedObject ProgressService.shared` 로 주입하여 사용
///
/// 설계 메모:
/// - 저장소는 SwiftData이지만, 외부 공개 API와 `@Published` 프로퍼티는
///   기존(UserDefaults 시절)과 100% 동일하게 유지함 → 뷰/뷰모델 변경 없음
/// - SwiftData 모델 변화를 뷰가 즉시 감지하도록, 메모리 미러(`results`)를
///   `@Published`로 두고 쓰기 후 매번 다시 채움(=동기 읽기 API 유지)
/// - 모든 호출은 메인 스레드 가정(뷰 body / MainActor.run / 설정 화면) →
///   SwiftData `mainContext`를 안전하게 사용
///
/// iCloud 동기화: 현재 의도적으로 비활성(CloudKit 미연결). Apple Developer
/// 등록이 필요한 기능이라, 등록 완료 후 ModelConfiguration에 CloudKit
/// 컨테이너를 연결하면 별도 코드 변경 없이 동기화가 활성화됨.
final class ProgressService: ObservableObject {

    // MARK: 싱글톤
    static let shared = ProgressService()

    /// 저장 오류 로그 — print 대신 os.Logger 사용 (릴리즈 빌드에서도 Console.app에서 필터링 가능)
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Blocode",
                                category: "ProgressService")

    // MARK: SwiftData 컨테이너 / 컨텍스트
    /// 앱 전역에서 공유하는 단일 ModelContainer
    /// (BlocodeApp의 `.modelContainer(...)`도 이 인스턴스를 주입받아 사용 →
    ///  스토어가 하나로 일원화되고, 추후 커스텀 맵 @Query도 같은 컨테이너 사용)
    let modelContainer: ModelContainer
    /// 메인 스레드 전용 컨텍스트 (모든 호출이 메인이라 안전)
    private var context: ModelContext { modelContainer.mainContext }

    // MARK: Published — 뷰가 감지하는 진행도 미러
    /// key: stageId (예: "ch1_stage1"), value: StageResult
    /// SwiftData가 원본(source of truth)이고, 이 딕셔너리는 읽기 가속용 미러
    @Published private(set) var results: [String: StageResult] = [:]

    // 연속 클리어 일수 — 단일 스칼라값이라 SwiftData가 아닌 UserDefaults 유지
    // (관계형 데이터가 아니고 작아서, 작은 설정성 값은 UserDefaults가 적합)
    @Published private(set) var streak: Int = 0

    // UserDefaults 저장 키 (streak 전용)
    private let streakKey        = "blocode_streak"
    private let lastClearDateKey = "blocode_last_clear_date"

    // MARK: 초기화

    /// 초기화 시 SwiftData 컨테이너를 생성하고 저장된 진행도를 미러로 로드
    private init() {
        // 진행도 모델 스키마로 컨테이너 생성
        let schema = Schema([StageProgress.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false  // 영구 저장 (앱 종료 후에도 유지)
            // 주의: iCloud 동기화 시 여기에 cloudKitDatabase 옵션 추가 예정
            //       (Apple Developer 등록 필요 → 현재는 비활성)
        )
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // 컨테이너 생성 실패 시 앱 종료 (치명적 오류)
            fatalError("SwiftData 컨테이너 생성 실패: \(error)")
        }

        // SwiftData → 메모리 미러 채우기
        reloadMirror()
        // streak는 UserDefaults에서 로드
        streak = UserDefaults.standard.integer(forKey: streakKey)
    }

    // MARK: - 미러 동기화

    /// SwiftData에 저장된 모든 StageProgress를 읽어 `results` 미러를 재구성
    /// (쓰기 직후 호출하여 @Published 변경 → 뷰 자동 갱신)
    private func reloadMirror() {
        let all = (try? context.fetch(FetchDescriptor<StageProgress>())) ?? []
        var dict: [String: StageResult] = [:]
        for p in all {
            dict[p.stageId] = StageResult(
                isCleared: p.isCleared,
                stars: p.stars,
                bestBlockCount: p.bestBlockCount
            )
        }
        results = dict  // @Published 할당 → 뷰 갱신
    }

    // MARK: - 읽기

    /// 특정 스테이지의 클리어 기록 반환 (없으면 nil)
    func result(for stageId: String) -> StageResult? {
        results[stageId]
    }

    /// 특정 스테이지가 클리어됐는지 여부 반환 (기록 없으면 false)
    func isCleared(_ stageId: String) -> Bool {
        results[stageId]?.isCleared ?? false
    }

    /// 특정 스테이지의 현재 별점 반환 (0~3, 기록 없으면 0)
    func stars(for stageId: String) -> Int {
        results[stageId]?.stars ?? 0
    }

    /// 특정 챕터의 총 획득 별점 합산
    /// - Parameters:
    ///   - chapter: 챕터 번호
    ///   - stageCount: 챕터 내 스테이지 총 개수
    func totalStars(chapter: Int, stageCount: Int) -> Int {
        guard stageCount > 0 else { return 0 }
        // 1번부터 stageCount까지 각 스테이지 별점 합산
        return (1...stageCount).reduce(0) { total, stageNum in
            total + stars(for: "ch\(chapter)_stage\(stageNum)")
        }
    }

    // MARK: - 잠금 조건

    /// 스테이지 잠금 여부 확인 (false = 플레이 가능)
    func isLocked(chapter: Int, stageNumber: Int) -> Bool {
        // 1스테이지는 항상 개방
        if stageNumber == 1 { return false }

        // 모든 스테이지(종합 포함)는 직전 스테이지를 클리어하면 개방
        // 스테이지가 순차 진행이므로 "직전 클리어" = "이전 스테이지 전부 클리어"와 동일
        let prevId = "ch\(chapter)_stage\(stageNumber - 1)"
        return !isCleared(prevId)
    }

    // MARK: - 홈 화면용 헬퍼

    /// 전체 획득 별 수 (모든 챕터 합산)
    func totalEarnedStars(chapters: [(id: Int, stageCount: Int)]) -> Int {
        chapters.reduce(0) { total, ch in
            total + totalStars(chapter: ch.id, stageCount: ch.stageCount)
        }
    }

    /// 완료된 챕터 수 (해당 챕터의 모든 스테이지를 클리어한 경우)
    func completedChapterCount(chapters: [(id: Int, stageCount: Int)]) -> Int {
        chapters.filter { ch in
            guard ch.stageCount > 0 else { return false }
            return (1...ch.stageCount).allSatisfy { stageNum in
                isCleared("ch\(ch.id)_stage\(stageNum)")
            }
        }.count
    }

    /// 챕터 해금 여부 — 진행 규칙(아래 static 함수)에 현재 진행도를 넘겨 계산
    func isChapterUnlocked(_ chapter: ChapterInfo, chapters: [ChapterInfo] = ChapterCatalog.all) -> Bool {
        Self.isChapterUnlocked(chapter, chapters: chapters, results: results)
    }

    /// 홈 "이어서 하기"가 보낼 스테이지 — 진행 규칙(아래 static 함수)에 현재 진행도를 넘겨 계산
    func nextStage(chapters: [ChapterInfo] = ChapterCatalog.all) -> (chapter: Int, stage: Int)? {
        Self.nextStage(chapters: chapters, results: results)
    }

    // MARK: - 진행 규칙 (순수 함수)
    // 저장소(SwiftData) 없이 진행도 딕셔너리만으로 계산 → 실제 진행도를 건드리지 않고 테스트 가능

    /// 챕터 해금 조건 (B안) — 아래 두 조건을 모두 만족해야 해금 (AND)
    ///   1. 이전 챕터 총 별점이 requiredStarsFromPrev 이상
    ///   2. 이전 챕터 마지막 스테이지(종합)를 클리어 (별 수 무관)
    static func isChapterUnlocked(_ chapter: ChapterInfo, chapters: [ChapterInfo],
                                  results: [String: StageResult]) -> Bool {
        if chapter.number == 1 { return true }               // 챕터 1은 항상 열림
        guard chapter.stageCount > 0 else { return false }   // 스테이지 없으면 항상 잠김
        guard let prev = chapters.first(where: { $0.number == chapter.number - 1 }),
              prev.stageCount > 0 else { return false }
        let prevStars = (1...prev.stageCount).reduce(0) { total, stageNum in
            total + (results["ch\(prev.number)_stage\(stageNum)"]?.stars ?? 0)
        }
        let finalCleared = results["ch\(prev.number)_stage\(prev.stageCount)"]?.isCleared ?? false
        return prevStars >= chapter.requiredStarsFromPrev && finalCleared
    }

    /// 이어서 할 다음 스테이지 — 첫 번째 미클리어 스테이지 (모두 완료면 nil)
    /// 다음 챕터가 잠겨 있으면(이전 챕터는 다 깼지만 별이 부족) 그 챕터로 보내지 않고,
    /// 이전 챕터에서 별 3개 미만인 첫 스테이지로 보내 별 모으기를 유도 — 홈 버튼이 챕터 잠금을 우회하지 못하게 함
    static func nextStage(chapters: [ChapterInfo],
                          results: [String: StageResult]) -> (chapter: Int, stage: Int)? {
        for ch in chapters {
            guard ch.stageCount > 0 else { continue }  // 빈 챕터는 건너뜀 (존재하지 않는 스테이지 반환 방지)

            if !isChapterUnlocked(ch, chapters: chapters, results: results) {
                // 여기까지 왔다면 이전 챕터는 전부 클리어된 상태 → 잠긴 이유는 별 부족
                guard let prev = chapters.first(where: { $0.number == ch.number - 1 }) else { return nil }
                let lowStar = (1...prev.stageCount).first { stageNum in
                    (results["ch\(prev.number)_stage\(stageNum)"]?.stars ?? 0) < 3
                }
                return (prev.number, lowStar ?? prev.stageCount)
            }

            // 해금된 챕터의 첫 미클리어 스테이지 — 앞 스테이지가 전부 클리어라 항상 플레이 가능
            if let stageNum = (1...ch.stageCount).first(where: { results["ch\(ch.number)_stage\($0)"]?.isCleared != true }) {
                return (ch.number, stageNum)
            }
        }
        return nil
    }

    // MARK: - 쓰기

    /// 스테이지 클리어 기록 저장 (별점/블럭수가 기존보다 좋을 때만 갱신)
    /// SwiftData에 upsert(있으면 갱신, 없으면 생성) 후 미러를 다시 채움
    func recordClear(stageId: String, stars: Int, blockCount: Int) {
        // 동일 stageId의 기존 기록 조회
        let descriptor = FetchDescriptor<StageProgress>(
            predicate: #Predicate { $0.stageId == stageId }
        )
        let existing = (try? context.fetch(descriptor))?.first

        let progress: StageProgress
        if let existing {
            progress = existing
        } else {
            // 신규 기록 생성 후 컨텍스트에 삽입
            progress = StageProgress(stageId: stageId)
            context.insert(progress)
        }

        // 더 좋은 기록(별 최댓값 / 블럭 최솟값)으로만 갱신 — 기존 로직과 동일
        progress.update(stars: stars, blockCount: blockCount)

        // 변경 사항 영속화 (실패 시 로그 — 진행도 유실 원인 추적용)
        do {
            try context.save()
        } catch {
            logger.error("진행도 저장 실패(recordClear): \(String(describing: error), privacy: .public)")
        }
        // 메모리 미러 재구성 → @Published 변경으로 뷰 자동 갱신
        reloadMirror()
        // 연속 일수 갱신
        updateStreak()
    }

    /// 오늘 처음 클리어 시 streak 증가, 하루 넘기면 리셋
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = UserDefaults.standard.object(forKey: lastClearDateKey) as? Date
        let lastDay  = lastDate.map { Calendar.current.startOfDay(for: $0) }

        if lastDay == today {
            // 오늘 이미 클리어 기록 있음 — streak 유지
            return
        } else if let last = lastDay,
                  Calendar.current.dateComponents([.day], from: last, to: today).day == 1 {
            // 어제 클리어 — 연속 증가
            streak += 1
        } else {
            // 하루 이상 비었음 — 리셋
            streak = 1
        }
        UserDefaults.standard.set(today, forKey: lastClearDateKey)
        UserDefaults.standard.set(streak, forKey: streakKey)
    }

    // MARK: - 개발자 전용 (설정 화면 개발자 섹션 — 테스트 편의)

    /// 지정 챕터까지(포함) 모든 스테이지를 3별로 강제 클리어 처리 — 정식 플레이 경로를 건너뛰고
    /// 진행 기록을 직접 기록해 해당 챕터를 바로 플레이 가능한 상태로 만듦
    /// (chapter/stage 잠금 조건이 전부 "직전 스테이지·직전 챕터 클리어" 기준이라, 1번 챕터부터
    ///  순서대로 전부 기록해야 목표 챕터까지 해금 체인이 끊기지 않음)
    func devUnlock(throughChapter chapterNumber: Int, chapters: [(id: Int, stageCount: Int)]) {
        for ch in chapters where ch.id <= chapterNumber {
            guard ch.stageCount > 0 else { continue }
            for stageNum in 1...ch.stageCount {
                recordClear(stageId: "ch\(ch.id)_stage\(stageNum)", stars: 3, blockCount: 1)
            }
        }
    }

    // MARK: - 진행도 초기화 (설정 화면 / 테스트 편의)

    /// 모든 스테이지 클리어 기록 초기화 — SwiftData에서도 전부 삭제
    /// (streak는 기존 동작과 동일하게 건드리지 않음)
    func resetAll() {
        // SwiftData의 StageProgress 전체 삭제 (실패 시 로그)
        do {
            try context.delete(model: StageProgress.self)
            try context.save()
        } catch {
            logger.error("진행도 초기화 실패(resetAll): \(String(describing: error), privacy: .public)")
        }
        // 메모리 미러 비우기 → @Published 변경으로 뷰 자동 갱신
        results = [:]
    }
}
