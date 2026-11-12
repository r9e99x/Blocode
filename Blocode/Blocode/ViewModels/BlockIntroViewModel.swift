//
//  BlockIntroViewModel.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import Foundation
import Combine

// MARK: - BlockIntro
/// 화면에 띄울 블럭 설명 한 장
struct BlockIntro: Equatable {
    let block: BlockType  // 아이콘과 강조 색을 정함 (색 변환은 View 계층)
    let title: String     // 예: "새 블럭 · 반복"
    let message: String   // 한 줄 요약 + 쉬운 설명 + 저장 안내
}

// MARK: - BlockIntroViewModel
/// 스테이지에 처음 나오는 블럭의 설명을 한 번에 하나씩 차례로 띄우는 상태
/// 보여 주는 순간 수집으로 기록하므로 같은 설명이 다시 나오지 않고, 개념 카드 모음에서 그 카드가 열림
/// (게임 실행을 맡는 GameViewModel과는 책임이 달라 따로 둠 — 게임 화면이 둘을 함께 씀)
final class BlockIntroViewModel: ObservableObject {

    /// 지금 띄울 설명 — nil이면 띄울 것이 없음
    @Published private(set) var current: BlockIntro?

    /// 아직 안 보여 준 블럭 (팔레트 순서)
    private var queue: [BlockType] = []
    /// 이 스테이지에서 이미 확인했는지 — 화면이 다시 나타나도 한 번만 확인
    private var hasStarted = false

    // 보관함·진행도 저장소 — 테스트는 격리된 저장소를 주입
    private let learning: LearningService
    private let progress: ProgressService

    init(learning: LearningService? = nil, progress: ProgressService = .shared) {
        self.learning = learning ?? .shared
        self.progress = progress
    }

    /// 이 스테이지에 처음 나오는 블럭을 모아 첫 번째 설명을 띄움
    func start(for stage: Stage) {
        guard !hasStarted else { return }
        hasStarted = true
        // 이미 진행한 사용자가 지나온 블럭 설명을 다시 보지 않도록 진도에서 먼저 채움
        learning.syncFromProgress(progress)
        queue = learning.unseenBlocks(for: stage)
        advance()
    }

    /// 지금 설명을 닫고 다음 것을 띄움 — 보여 주는 순간 수집으로 기록해 한 번만 나오게 함
    func advance() {
        while !queue.isEmpty {
            let block = queue.removeFirst()
            learning.markSeen(block)
            // 설명 카드가 없는 블럭은 기록만 하고 건너뜀 (모든 블럭에 카드가 있는지는 테스트가 확인)
            guard let card = LearningCatalog.card(for: block) else { continue }
            current = BlockIntro(block: block, title: "새 블럭 · \(card.title)",
                                 message: "\(card.summary)\n\n\(card.body)\n\n개념 카드 모음에 저장했어요.")
            return
        }
        current = nil
    }
}
