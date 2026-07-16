//
//  HomeViewModel.swift
//  Blocode
//
//  Created by 조준희 on 5/19/26.
//

import Foundation
import Combine

// MARK: - HomeViewModel
/// 홈 화면(ContentView)의 상태/로직을 담당하는 ViewModel
/// 진행도(ProgressService)를 읽어 통계·다음 스테이지·동적 문구를 가공한다.
///
/// 동작 보존 메모: ProgressService의 `objectWillChange`를 그대로 전파하므로,
/// 기존(View가 ProgressService를 직접 @ObservedObject 하던 시절)과
/// 화면 자동 갱신 타이밍이 100% 동일하다.
final class HomeViewModel: ObservableObject {

    // 진행도 서비스 (데이터 소스)
    private let progress = ProgressService.shared
    // ProgressService 변경 구독 해제용
    private var cancellables = Set<AnyCancellable>()

    /// 홈 화면에서 사용할 챕터 목록 (id, stageCount)
    /// ChapterCatalog(단일 원본)에서 파생 — 진행도 계산 헬퍼가 요구하는 튜플 형태로 변환
    let chapters: [(id: Int, stageCount: Int)] = ChapterCatalog.all.map {
        (id: $0.number, stageCount: $0.stageCount)
    }

    init() {
        // ProgressService가 바뀌면 이 VM도 변경 알림을 그대로 전파 → 뷰 자동 갱신 유지
        progress.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - 파생 값 (뷰가 표시용으로 사용)

    /// 전체 획득 가능 별 수 (모든 챕터 합산)
    var totalPossibleStars: Int {
        chapters.reduce(0) { $0 + $1.stageCount * 3 }
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

    /// 진행 기록이 전혀 없는 첫 실행 상태인지 여부
    var isFirstTime: Bool {
        earnedStars == 0
    }

    /// 이어서 할 다음 스테이지 (없으면 모두 완료)
    var nextStage: (chapter: Int, stage: Int)? {
        progress.nextStage(chapters: chapters)
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
