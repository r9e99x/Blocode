//
//  HomeViewModel.swift
//  Blocode
//
//  Created by 조준희 on 5/19/26.
//

import Foundation
import Combine

// MARK: - DailyPuzzleInfo
/// 홈 카드에 보여 줄 오늘의 퍼즐 정보
struct DailyPuzzleInfo: Equatable {
    let key: Int            // yyyyMMdd — 플레이 경로에 실리는 값
    let dateText: String    // 예: "11월 12일 목요일"
    let themeTitle: String  // 예: "보석 수집"
    let isCleared: Bool
    let stars: Int
}

// MARK: - HomeViewModel
/// 홈 화면(ContentView)의 상태/로직을 담당하는 ViewModel
/// 진행도(ProgressService)를 읽어 통계·다음 스테이지·동적 문구를 가공한다.
///
/// 동작 보존 메모: ProgressService의 `objectWillChange`를 그대로 전파하므로,
/// 기존(View가 ProgressService를 직접 @ObservedObject 하던 시절)과
/// 화면 자동 갱신 타이밍이 100% 동일하다.
final class HomeViewModel: ObservableObject {

    // 진행도 서비스 (데이터 소스) — 테스트는 메모리 저장소를 주입
    private let progress: ProgressService
    /// 현재 시각 — 테스트는 날짜를 고정해 주입
    private let now: () -> Date
    private let calendar: Calendar
    // ProgressService 변경 구독 해제용
    private var cancellables = Set<AnyCancellable>()

    /// 홈 화면에서 사용할 챕터 목록 (id, stageCount)
    /// ChapterCatalog(단일 원본)에서 파생 — 진행도 계산 헬퍼가 요구하는 튜플 형태로 변환
    let chapters: [(id: Int, stageCount: Int)] = ChapterCatalog.all.map {
        (id: $0.number, stageCount: $0.stageCount)
    }

    init(progress: ProgressService = .shared, now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.progress = progress
        self.now = now
        self.calendar = calendar
        // ProgressService가 바뀌면 이 VM도 변경 알림을 그대로 전파 → 뷰 자동 갱신 유지
        progress.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - 파생 값 (뷰가 표시용으로 사용)

    /// 전체 획득 가능 별 수 (모든 챕터 합산)
    var totalPossibleStars: Int {
        ChapterCatalog.all.reduce(0) { $0 + $1.maxStars }
    }

    /// 현재까지 획득한 총 별 수
    var earnedStars: Int {
        progress.totalEarnedStars(chapters: chapters)
    }

    /// 완료한 챕터 수
    var completedChapters: Int {
        progress.completedChapterCount(chapters: chapters)
    }

    /// 전체 챕터 개수
    var chapterCount: Int {
        chapters.count
    }

    /// 연속 학습 일수
    var streak: Int {
        progress.streak
    }

    // MARK: - 오늘의 퍼즐

    /// 기능이 열렸는지 — 필요한 챕터를 모두 클리어했는지
    func isUnlocked(_ feature: UnlockableFeature) -> Bool { progress.isUnlocked(feature) }

    /// 잠긴 기능을 눌렀을 때 보여 줄 해금 조건 문구와 강조할 챕터
    func lockHint(for feature: UnlockableFeature) -> (message: String, chapter: ChapterInfo?) {
        let chapter = ChapterCatalog.all.first { $0.number == feature.requiredChapter }
        let name = chapter.map { "챕터 \($0.number) \"\($0.title)\"" } ?? "챕터 \(feature.requiredChapter)"
        return ("\(name)의 모든 스테이지를\n클리어하면 열려요", chapter)
    }

    /// 홈 "오늘의 퍼즐" 카드에 보여 줄 정보
    var dailyPuzzle: DailyPuzzleInfo {
        let date = now()
        let key = PuzzleGenerator.dailyKey(for: date, calendar: calendar)
        let theme = PuzzleGenerator.theme(forWeekday: calendar.component(.weekday, from: date))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = calendar
        formatter.dateFormat = "M월 d일 EEEE"
        let stageID = "\(PuzzleGenerator.dailyIDPrefix)\(key)"
        return DailyPuzzleInfo(key: key,
                               dateText: formatter.string(from: date),
                               themeTitle: Self.title(of: theme),
                               isCleared: progress.isCleared(stageID),
                               stars: progress.stars(for: stageID))
    }

    private static func title(of theme: PuzzleTheme) -> String {
        switch theme {
        case .basic: return "미로 길 찾기"
        case .gems: return "보석 수집"
        case .switches: return "스위치와 문"
        case .portals: return "포탈 지름길"
        case .mixed: return "기믹 섞기"
        }
    }

    /// 진행 기록이 전혀 없는 첫 실행 상태인지 여부
    var isFirstTime: Bool {
        earnedStars == 0
    }

    /// 이어서 할 다음 스테이지 (없으면 모두 완료)
    var nextStage: (chapter: Int, stage: Int)? {
        progress.nextStage()  // 챕터 잠금까지 반영 (ChapterCatalog 기준)
    }

    /// 진행 상황에 따라 달라지는 서브타이틀 문구
    var dynamicSubtitle: String {
        let earned    = earnedStars
        let total     = totalPossibleStars
        let completed = completedChapters

        if earned == 0 {
            // 아직 시작 전
            return "첫 번째 블럭을 놓아볼까요?"
        } else if completed == chapters.count {
            // 모든 챕터 완료
            return "모든 챕터를 완료했어요! 대단해요 🎉"
        } else if progress.streak >= 7 {
            // 연속 7일 이상
            return "\(progress.streak)일 연속! 꾸준함이 실력이 돼요."
        } else if earned >= total / 2 {
            // 절반 이상 달성
            return "절반을 넘었어요! 계속 달려봐요."
        } else {
            // 일반 진행 중
            return "오늘도 한 스테이지씩 나아가요."
        }
    }
}
