//
//  ProgressRulesTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 10/15/26.
//
//  챕터 해금 · 홈 "이어서 하기" 규칙 검증.
//  ProgressService의 static 진행 규칙 함수에 진행도 딕셔너리를 직접 넘겨서 계산하므로
//  실제 SwiftData 저장소나 UserDefaults(연속 일수)를 전혀 건드리지 않는다.

import Testing
@testable import Blocode

@MainActor
@Suite("진행 규칙 — 챕터 해금·이어서 하기")
struct ProgressRulesTests {

    /// 실제 챕터 구성 (챕터1 = 6스테이지, 챕터2 해금 기준 별 12개)
    private let chapters = ChapterCatalog.all

    /// "chN_stageM" → 별 수 목록으로 클리어 기록 딕셔너리 생성 (별 수가 있으면 클리어로 간주)
    private func results(_ chapter: Int, stars: [Int]) -> [String: StageResult] {
        var dict: [String: StageResult] = [:]
        for (i, s) in stars.enumerated() {
            dict["ch\(chapter)_stage\(i + 1)"] = StageResult(isCleared: true, stars: s, bestBlockCount: 1)
        }
        return dict
    }

    private func next(_ results: [String: StageResult]) -> (chapter: Int, stage: Int)? {
        ProgressService.nextStage(chapters: chapters, results: results)
    }

    private func isUnlocked(_ number: Int, _ results: [String: StageResult]) -> Bool {
        ProgressService.isChapterUnlocked(chapters[number - 1], chapters: chapters, results: results)
    }

    @Test("기록이 없으면 1-1부터 시작")
    func emptyProgress_startsAtFirstStage() {
        let n = next([:])
        #expect(n?.chapter == 1 && n?.stage == 1)
        #expect(isUnlocked(1, [:]))
    }

    @Test("챕터1을 별 1개씩 전부 깨면 챕터2는 잠기고, 이어서 하기는 별 부족한 1-1로 보냄")
    func chapterLockedByStars_redirectsToLowStarStage() {
        let r = results(1, stars: [1, 1, 1, 1, 1, 1])  // 6개 < 기준 12개
        #expect(!isUnlocked(2, r))
        let n = next(r)
        #expect(n?.chapter == 1 && n?.stage == 1)  // 예전엔 잠긴 2-1을 돌려줬음 (B1 버그)
    }

    @Test("별 3개 미만인 첫 스테이지로 보냄")
    func redirect_picksFirstStageBelowThreeStars() {
        let r = results(1, stars: [3, 3, 1, 1, 1, 1])  // 10개 < 12개
        let n = next(r)
        #expect(n?.chapter == 1 && n?.stage == 3)
    }

    @Test("별 기준은 넘었지만 종합 스테이지를 안 깼으면 종합 스테이지로 보냄")
    func finalStageNotCleared_returnsFinalStage() {
        let r = results(1, stars: [3, 3, 3, 3, 3])  // 1~5만 클리어, 별 15개
        #expect(!isUnlocked(2, r))  // 종합 미클리어라 AND 조건 불충족
        let n = next(r)
        #expect(n?.chapter == 1 && n?.stage == 6)
    }

    @Test("별 기준과 종합 클리어를 모두 만족하면 다음 챕터 1스테이지로")
    func chapterUnlocked_movesToNextChapter() {
        let r = results(1, stars: [3, 3, 2, 2, 2, 2])  // 14개 ≥ 12개 + 종합 클리어
        #expect(isUnlocked(2, r))
        let n = next(r)
        #expect(n?.chapter == 2 && n?.stage == 1)
    }

    @Test("모든 챕터를 만점으로 깨면 nil (모두 완료)")
    func allCleared_returnsNil() {
        var r: [String: StageResult] = [:]
        for ch in chapters {
            r.merge(results(ch.number, stars: Array(repeating: 3, count: ch.stageCount))) { _, new in new }
        }
        #expect(next(r) == nil)
    }
}
