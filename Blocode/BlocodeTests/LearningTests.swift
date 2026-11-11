//
//  LearningTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/12/26.
//

import Foundation
import Testing
@testable import Blocode

/// 학습 보관함 — 카드 목록·수집·처음 등장 계산 검증
@MainActor
@Suite("학습 보관함")
struct LearningTests {

    @Test("카드 id가 겹치지 않고 모든 필드가 채워져 있음")
    func catalogIsValid() {
        let ids = LearningCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(LearningCatalog.all.allSatisfy { !$0.title.isEmpty && !$0.summary.isEmpty && !$0.body.isEmpty })
    }

    @Test("모든 블럭 종류에 그 블럭을 설명하는 카드가 있음")
    func everyBlockHasCard() {
        for block in BlockType.allCases {
            #expect(LearningCatalog.card(for: block) != nil, "\(block) 카드 없음")
        }
    }

    @Test("블럭 개념 카드는 12장")
    func blockCardCount() {
        #expect(LearningCatalog.cards(in: .block).count == 12)
    }

    @Test("블럭 카드의 코드 예시가 다섯 언어 모두로 만들어짐")
    func examplesRender() {
        for card in LearningCatalog.cards(in: .block) {
            guard card.example != nil else { continue }
            for language in CodeLanguage.allCases {
                #expect(!(card.exampleCode(in: language) ?? "").isEmpty, "\(card.id) \(language)")
            }
        }
    }

    @Test("코딩 기초 11장, CS 기초 10장이고 처음부터 열려 있음")
    func basicsCards() {
        #expect(LearningCatalog.cards(in: .coding).count == 11)
        #expect(LearningCatalog.cards(in: .cs).count == 10)
        let service = LearningService(defaults: isolatedDefaults())
        for card in LearningCatalog.cards(in: .coding) + LearningCatalog.cards(in: .cs) {
            #expect(card.unlock == .alwaysOpen)
            #expect(service.isUnlocked(card))
        }
        #expect(service.progress(in: .coding) == (11, 11))
    }

    @Test("모든 카드의 코드 예시가 다섯 언어 모두 비어 있지 않음")
    func allExamplesCompleteInEveryLanguage() {
        for card in LearningCatalog.all {
            guard card.example != nil else { continue }
            for language in CodeLanguage.allCases {
                let code = card.exampleCode(in: language) ?? ""
                #expect(!code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(card.id) \(language)")
            }
        }
    }

    @Test("카드 글에 이스케이프가 새거나 앞뒤 공백이 남지 않음")
    func textIsClean() {
        for card in LearningCatalog.all {
            for text in [card.title, card.summary, card.body, card.tip ?? ""] {
                #expect(!text.contains("\\"), "\(card.id)에 역슬래시")
                #expect(text == text.trimmingCharacters(in: .whitespacesAndNewlines), "\(card.id) 공백")
            }
        }
    }

    @Test("블럭이 처음 나오는 챕터가 진도 순서와 맞음")
    func firstAppearanceMatchesProgression() {
        #expect(FirstAppearance.stage(of: .moveForward) == FirstAppearance.Position(chapter: 1, stage: 1))
        #expect((FirstAppearance.stage(of: .repeatBlock)?.chapter ?? 99) <= 2)
        #expect((FirstAppearance.stage(of: .ifBlock)?.chapter ?? 99) <= 3)
        #expect((FirstAppearance.stage(of: .functionBlock)?.chapter ?? 99) <= 4)
        #expect(FirstAppearance.stage(of: .collectItem)?.chapter == 6)
        #expect(FirstAppearance.stage(of: .activateSwitch)?.chapter == 7)
        for block in BlockType.allCases {
            #expect(FirstAppearance.stage(of: block) != nil, "\(block)이 어느 스테이지에도 안 나옴")
        }
    }

    @Test("처음 만난 블럭은 한 번만 true, 저장되어 다시 불러와도 유지됨")
    func markSeenPersists() {
        let defaults = isolatedDefaults()
        let service = LearningService(defaults: defaults)
        #expect(service.markSeen(.repeatBlock))
        #expect(!service.markSeen(.repeatBlock))
        let reloaded = LearningService(defaults: defaults)
        #expect(reloaded.seenBlocks == [.repeatBlock])
    }

    @Test("블럭 개념 카드는 그 블럭을 만나야 열리고 코딩·CS 카드는 처음부터 열림")
    func unlockRules() throws {
        let service = LearningService(defaults: isolatedDefaults())
        let repeatCard = try #require(LearningCatalog.card(for: .repeatBlock))
        #expect(!service.isUnlocked(repeatCard))
        service.markSeen(.repeatBlock)
        #expect(service.isUnlocked(repeatCard))
        let open = LearningCard(id: "x", category: .coding, title: "t", summary: "s", body: "b",
                                tip: nil, unlock: .alwaysOpen, example: nil)
        #expect(service.isUnlocked(open))
    }

    @Test("이미 진행한 사용자는 클리어한 스테이지까지 나온 블럭이 채워짐")
    func syncFromProgress() {
        let progress = ProgressService.makeForTesting()
        let service = LearningService(defaults: isolatedDefaults())
        service.syncFromProgress(progress)
        #expect(service.seenBlocks.isEmpty)  // 아무것도 안 깼으면 비어 있음 (첫 등장 설명이 정상으로 뜸)

        progress.recordClear(stageId: Stage.makeID(chapter: 1, number: 1), stars: 3, blockCount: 1)
        service.syncFromProgress(progress)
        #expect(service.seenBlocks.contains(.moveForward))
        #expect(!service.seenBlocks.contains(.collectItem))
    }

    @Test("초기화하면 수집이 비워짐")
    func resetClears() {
        let service = LearningService(defaults: isolatedDefaults())
        service.markSeen(.ifBlock)
        service.reset()
        #expect(service.seenBlocks.isEmpty)
    }
}

// MARK: - 처음 만나는 블럭

@MainActor
@Suite("처음 만나는 블럭")
struct FirstEncounterTests {

    private func stage(id: String, blocks: [BlockType]?) -> Stage {
        let map = MapData(grid: [[1, 1, 1]], start: Position(x: 0, y: 0), startDirection: .right, goal: Position(x: 2, y: 0))
        return Stage(id: id, chapter: 1, stageNumber: 1, name: "t", mapData: map,
                     starThresholds: StarThresholds(threeStar: 2, twoStar: 3), availableBlocks: blocks)
    }

    @Test("아직 못 만난 블럭만 팔레트 순서대로 나옴")
    func onlyUnseen() {
        let service = LearningService(defaults: isolatedDefaults())
        let stage = stage(id: "ch1_stage9", blocks: [.moveForward, .turnRight, .repeatBlock])
        #expect(service.unseenBlocks(for: stage) == [.moveForward, .turnRight, .repeatBlock])
        service.markSeen(.moveForward)
        #expect(service.unseenBlocks(for: stage) == [.turnRight, .repeatBlock])
    }

    @Test("한 번 보여 준 블럭은 다시 나오지 않음")
    func onlyOnce() {
        let service = LearningService(defaults: isolatedDefaults())
        let stage = stage(id: "ch1_stage9", blocks: [.moveForward])
        #expect(service.markSeen(.moveForward))
        #expect(service.unseenBlocks(for: stage).isEmpty)
    }

    @Test("사용자 맵과 블럭 목록이 없는 스테이지는 설명을 띄우지 않음")
    func skipsCustomAndUnlisted() {
        let service = LearningService(defaults: isolatedDefaults())
        #expect(service.unseenBlocks(for: stage(id: "\(CustomMap.stageIDPrefix)abc", blocks: [.moveForward, .repeatBlock])).isEmpty)
        #expect(service.unseenBlocks(for: stage(id: "ch1_stage9", blocks: nil)).isEmpty)
    }
}

@MainActor
@Suite("진도에서 채우기")
struct SyncThroughChaptersTests {
    @Test("챕터 5까지 클리어하면 반복·조건·함수·뒤로까지 채워지고 보석·스위치는 비어 있음")
    func throughChapterFive() {
        let progress = ProgressService.makeForTesting()
        progress.devUnlock(throughChapter: 5, chapters: ChapterCatalog.all.map { (id: $0.number, stageCount: $0.stageCount) })
        let service = LearningService(defaults: isolatedDefaults())
        service.syncFromProgress(progress)
        for block in [BlockType.moveForward, .moveBackward, .turnLeft, .turnRight, .repeatBlock, .ifBlock, .functionBlock] {
            #expect(service.seenBlocks.contains(block), "\(block)")
        }
        #expect(!service.seenBlocks.contains(.collectItem))
        #expect(!service.seenBlocks.contains(.activateSwitch))
    }
}
