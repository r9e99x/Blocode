//
//  LearningService.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import Foundation
import Combine

// MARK: - LearningService
/// 학습 보관함 상태 — 처음 만난 블럭(= 수집된 블럭 개념 카드)을 UserDefaults에 저장
/// 코딩·CS 기초 카드는 처음부터 열려 있어서 저장할 것이 없음
final class LearningService: ObservableObject {

    /// 앱 전역에서 공유
    static let shared = LearningService()

    private let defaults: UserDefaults
    private let seenKey = "learningSeenBlocks"

    /// 처음 만난 블럭들 — 이 블럭의 개념 카드가 열림
    @Published private(set) var seenBlocks: Set<BlockType>

    /// 테스트만 격리된 UserDefaults를 주입
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let raw = defaults.stringArray(forKey: seenKey) ?? []
        self.seenBlocks = Set(raw.compactMap { BlockType(rawValue: $0) })
    }

    // MARK: - 열림 여부

    func isUnlocked(_ card: LearningCard) -> Bool {
        switch card.unlock {
        case .alwaysOpen:        return true
        case .block(let block):  return seenBlocks.contains(block)
        }
    }

    /// 열린 카드 수 / 전체 카드 수 — 탭 위 "수집 n/m" 표시용
    func progress(in category: LearningCategory) -> (unlocked: Int, total: Int) {
        let cards = LearningCatalog.cards(in: category)
        return (cards.filter(isUnlocked).count, cards.count)
    }

    // MARK: - 수집

    /// 블럭을 처음 만났다고 기록 — 이미 만났으면 false (설명을 한 번만 띄우는 판단에 사용)
    @discardableResult
    func markSeen(_ block: BlockType) -> Bool {
        guard !seenBlocks.contains(block) else { return false }
        seenBlocks.insert(block)
        defaults.set(seenBlocks.map(\.rawValue).sorted(), forKey: seenKey)
        return true
    }

    /// 이 스테이지에 처음 나오는 블럭들 — 아직 못 만난 블럭만, 팔레트 순서대로
    /// 사용자가 만든 맵·에디터 테스트는 제외 (거기선 모든 블럭이 한꺼번에 나와서 설명이 쏟아지지 않도록)
    func unseenBlocks(for stage: Stage) -> [BlockType] {
        guard !stage.isCustomMap else { return [] }
        return (stage.availableBlocks ?? []).filter { !seenBlocks.contains($0) }
    }

    /// 이미 진행한 사용자를 위한 채우기 — 어떤 블럭이 처음 나오는 스테이지(또는 그 뒤 스테이지)를 클리어했다면 만난 것으로 침
    func syncFromProgress(_ progress: ProgressService) {
        for block in BlockType.allCases {
            guard let first = FirstAppearance.stage(of: block) else { continue }
            if FirstAppearance.hasPassed(first, progress: progress) { markSeen(block) }
        }
    }

    /// 진행도를 초기화하면 수집도 함께 비움
    func reset() {
        seenBlocks = []
        defaults.removeObject(forKey: seenKey)
    }
}

// MARK: - FirstAppearance
/// 각 블럭이 처음 팔레트에 나오는 스테이지 — 스테이지 JSON의 availableBlocks에서 계산해 한 번만 캐시
enum FirstAppearance {

    struct Position: Equatable {
        let chapter: Int
        let stage: Int
    }

    /// 블럭 → 처음 나오는 위치 (챕터·스테이지 순서대로 훑어 처음 만난 곳)
    private static let table: [BlockType: Position] = {
        var result: [BlockType: Position] = [:]
        for chapter in ChapterCatalog.all where chapter.stageCount > 0 {
            for number in 1...chapter.stageCount {
                guard let stage = StageLoader.load(chapter: chapter.number, stage: number) else { continue }
                // availableBlocks가 없으면 모든 블럭이 나오는 스테이지지만 기본 스테이지는 모두 목록이 있음
                for block in stage.availableBlocks ?? [] where result[block] == nil {
                    result[block] = Position(chapter: chapter.number, stage: number)
                }
            }
        }
        return result
    }()

    static func stage(of block: BlockType) -> Position? { table[block] }

    /// 사용자가 그 위치 이후를 한 번이라도 클리어했는지
    static func hasPassed(_ position: Position, progress: ProgressService) -> Bool {
        for chapter in ChapterCatalog.all where chapter.number >= position.chapter && chapter.stageCount > 0 {
            let start = chapter.number == position.chapter ? position.stage : 1
            guard start <= chapter.stageCount else { continue }
            for number in start...chapter.stageCount
            where progress.isCleared(Stage.makeID(chapter: chapter.number, number: number)) {
                return true
            }
        }
        return false
    }
}
