//
//  LearningLibraryViewModel.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import Foundation
import Observation

// MARK: - LearningLibraryViewModel
/// 학습 보관함 화면(LearningLibraryView)의 상태/로직 담당 ViewModel
/// 탭별 카드, 열림 여부, 수집 수, 잠긴 카드의 해금 안내 문구를 가공한다.
/// 화면이 이 ViewModel을 거쳐 보관함(LearningService, @Observable)의 수집 상태를 읽으면
/// Observation이 그 읽기를 추적해서, 수집이 바뀔 때 화면이 자동으로 다시 그려짐 (따로 알림을 전달할 필요 없음)
@Observable
final class LearningLibraryViewModel {

    // 보관함·진행도 저장소 — 테스트는 격리된 저장소를 주입
    private let learning: LearningService
    private let progress: ProgressService

    init(learning: LearningService? = nil, progress: ProgressService = .shared) {
        let learning = learning ?? .shared
        self.learning = learning
        self.progress = progress
    }

    // MARK: - 카드 목록

    /// 탭에 들어 있는 카드 (카탈로그 순서)
    func cards(in category: LearningCategory) -> [LearningCard] {
        LearningCatalog.cards(in: category)
    }

    /// 탭 안에서 갈래(코딩·CS)별로 묶은 카드 한 묶음 — 갈래가 없는 탭(블럭 개념)은 머리글 없는 한 묶음
    struct Section: Identifiable {
        let topic: LearningTopic?
        let cards: [LearningCard]
        var id: String { topic?.rawValue ?? "all" }
    }

    /// 탭의 카드를 갈래 순서(코딩 → CS)로 묶음 — 갈래가 없는 카드만 있는 탭은 한 묶음
    func sections(in category: LearningCategory) -> [Section] {
        let all = cards(in: category)
        guard all.contains(where: { $0.topic != nil }) else {
            return all.isEmpty ? [] : [Section(topic: nil, cards: all)]
        }
        return LearningTopic.allCases.compactMap { topic in
            let group = all.filter { $0.topic == topic }
            return group.isEmpty ? nil : Section(topic: topic, cards: group)
        }
    }

    /// 카드가 열렸는지
    func isUnlocked(_ card: LearningCard) -> Bool {
        learning.isUnlocked(card)
    }

    /// 탭의 열린 카드 수 / 전체 카드 수 — 탭 위 "수집 n/m" 표시용
    func progress(in category: LearningCategory) -> (unlocked: Int, total: Int) {
        learning.progress(in: category)
    }

    // MARK: - 수집 채우기

    /// 이미 진행한 사용자의 수집을 진행도에서 채움 — 화면이 나타날 때 호출 (가벼운 계산)
    func syncCollection() {
        learning.syncFromProgress(progress)
    }

    // MARK: - 잠금 안내

    /// 잠긴 카드가 열리는 챕터 — 그 카드의 블럭이 처음 나오는 챕터 (조건이 없는 카드는 nil)
    private func unlockChapter(for card: LearningCard) -> ChapterInfo? {
        guard case .block(let block) = card.unlock, let first = FirstAppearance.stage(of: block) else { return nil }
        return ChapterCatalog.chapter(first.chapter)
    }

    /// 잠긴 카드 행에 보여 줄 한 줄 안내
    func unlockHint(for card: LearningCard) -> String {
        guard let chapter = unlockChapter(for: card) else { return "아직 열리지 않았어요" }
        return "챕터 \(chapter.number) \"\(chapter.title)\"에서 처음 만나면 열려요"
    }

    /// 잠긴 카드를 눌렀을 때 팝업에 보여 줄 안내(두 줄)와 강조할 챕터
    func lockHint(for card: LearningCard) -> (message: String, chapter: ChapterInfo?) {
        guard let chapter = unlockChapter(for: card) else { return ("아직 열리지 않았어요", nil) }
        return ("챕터 \(chapter.number) \"\(chapter.title)\"에서\n처음 만나면 열려요", chapter)
    }
}
