//
//  ScreenViewModelTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/1/26.
//
//  홈·챕터 선택·스테이지 목록 ViewModel의 표시 값 검증.
//  메모리 저장소만 사용하므로 실제 진행도에 영향이 없다.

import Testing
import Foundation
import Combine
@testable import Blocode

// MARK: - HomeViewModel

@MainActor
@Suite("홈 ViewModel")
struct HomeViewModelTests {

    @Test("기록이 없으면 첫 실행 문구와 1-1 이어하기")
    func firstRun() {
        let vm = HomeViewModel(progress: .makeForTesting())
        #expect(vm.isFirstTime)
        #expect(vm.earnedStars == 0)
        #expect(vm.dynamicSubtitle == "첫 번째 블럭을 놓아볼까요?")
        #expect(vm.nextStage?.chapter == 1)
        #expect(vm.nextStage?.stage == 1)
    }

    @Test("한 스테이지를 깨면 통계와 이어하기 위치가 바뀜")
    func statsAfterOneClear() {
        let progress = ProgressService.makeForTesting()
        let vm = HomeViewModel(progress: progress)
        progress.recordClear(stageId: "ch1_stage1", stars: 3, blockCount: 1)
        #expect(vm.isFirstTime == false)
        #expect(vm.earnedStars == 3)
        #expect(vm.completedChapters == 0)
        #expect(vm.nextStage?.stage == 2)
        #expect(vm.dynamicSubtitle == "오늘도 한 스테이지씩 나아가요.")
    }

    @Test("연속 7일 이상이면 연속 일수 문구")
    func subtitleForLongStreak() {
        let defaults = isolatedDefaults()
        defaults.set(7, forKey: "blocode_streak")
        defaults.set(Calendar.current.startOfDay(for: Date()), forKey: "blocode_last_clear_date")
        let progress = ProgressService.makeForTesting(defaults: defaults)
        let vm = HomeViewModel(progress: progress)
        progress.recordClear(stageId: "ch1_stage1", stars: 3, blockCount: 1)
        #expect(vm.streak == 7)
        #expect(vm.dynamicSubtitle == "7일 연속! 꾸준함이 실력이 돼요.")
    }

    @Test("별을 절반 이상 모으면 격려 문구")
    func subtitleAfterHalf() {
        let progress = ProgressService.makeForTesting()
        let vm = HomeViewModel(progress: progress)
        progress.devUnlock(throughChapter: 5, chapters: vm.chapters)  // 챕터 1~5 = 별 105개 / 전체 207개
        #expect(vm.completedChapters == 5)
        #expect(vm.dynamicSubtitle == "절반을 넘었어요! 계속 달려봐요.")
    }

    @Test("모두 완료하면 완료 문구, 이어할 스테이지 없음")
    func allCompleted() {
        let progress = ProgressService.makeForTesting()
        let vm = HomeViewModel(progress: progress)
        progress.devUnlock(throughChapter: vm.chapterCount, chapters: vm.chapters)
        #expect(vm.completedChapters == vm.chapterCount)
        #expect(vm.earnedStars == vm.totalPossibleStars)
        #expect(vm.nextStage == nil)
        #expect(vm.dynamicSubtitle == "모든 챕터를 완료했어요! 대단해요 🎉")
    }
}

// MARK: - ChapterSelectViewModel

@MainActor
@Suite("챕터 선택 ViewModel")
struct ChapterSelectViewModelTests {

    /// 챕터 1 — 스테이지 6개, 최대 별 18개
    private var firstChapter: ChapterInfo { ChapterCatalog.all[0] }

    private func clear(_ progress: ProgressService, stages: ClosedRange<Int>, stars: Int) {
        for number in stages {
            progress.recordClear(stageId: "ch1_stage\(number)", stars: stars, blockCount: 1)
        }
    }

    @Test("별 표시 환산 — 없으면 0개, 하나라도 있으면 최소 1개, 최대 3개")
    func displayStarCount_scalesToThree() {
        let progress = ProgressService.makeForTesting()
        let vm = ChapterSelectViewModel(progress: progress)
        #expect(vm.displayStarCount(firstChapter) == 0)

        clear(progress, stages: 1...1, stars: 1)  // 18개 중 1개 — 반올림하면 0이지만 최소 1개
        #expect(vm.displayStarCount(firstChapter) == 1)

        clear(progress, stages: 1...3, stars: 3)  // 18개 중 9개
        #expect(vm.displayStarCount(firstChapter) == 2)

        clear(progress, stages: 1...6, stars: 3)  // 18개 전부
        #expect(vm.displayStarCount(firstChapter) == 3)
    }

    @Test("챕터별 별 합계와 클리어 스테이지 수")
    func chapterTotals() {
        let progress = ProgressService.makeForTesting()
        let vm = ChapterSelectViewModel(progress: progress)
        clear(progress, stages: 1...2, stars: 2)
        #expect(vm.chapterStars(firstChapter) == 4)
        #expect(vm.clearedStageCount(firstChapter) == 2)
    }

    @Test("이전 챕터를 끝내면 다음 챕터가 열림")
    func unlockFollowsProgress() {
        let progress = ProgressService.makeForTesting()
        let vm = ChapterSelectViewModel(progress: progress)
        let second = vm.chapters[1]
        #expect(vm.isUnlocked(firstChapter))
        #expect(vm.isUnlocked(second) == false)

        clear(progress, stages: 1...6, stars: 3)
        #expect(vm.isUnlocked(second))
    }

    @Test("잠금 문구에 필요한 별 수가 들어감")
    func lockMessage_mentionsRequiredStars() {
        let vm = ChapterSelectViewModel(progress: .makeForTesting())
        let second = vm.chapters[1]
        #expect(vm.lockMessage(for: second).contains("별 \(second.requiredStarsFromPrev)개"))
    }
}

// MARK: - ChapterViewModel

@MainActor
@Suite("스테이지 목록 ViewModel")
struct ChapterViewModelTests {

    @Test("챕터 데이터 로드 — 제목과 스테이지 수")
    func loadsChapter() {
        let vm = ChapterViewModel(chapter: 1, progress: .makeForTesting())
        #expect(vm.chapterTitle == ChapterCatalog.all[0].title)
        #expect(vm.stages.count == ChapterCatalog.all[0].stageCount)
    }

    @Test("현재 위치는 첫 미클리어 스테이지, 모두 깨면 없음")
    func currentStage_followsProgress() {
        let progress = ProgressService.makeForTesting()
        let vm = ChapterViewModel(chapter: 1, progress: progress)
        #expect(vm.currentStageNumber == 1)
        #expect(vm.isCurrent(vm.stages[0]))

        progress.recordClear(stageId: vm.stages[0].id, stars: 3, blockCount: 1)
        #expect(vm.currentStageNumber == 2)
        #expect(vm.isCurrent(vm.stages[0]) == false)

        for stage in vm.stages {
            progress.recordClear(stageId: stage.id, stars: 3, blockCount: 1)
        }
        #expect(vm.currentStageNumber == nil)
    }

    @Test("직전 스테이지를 깨면 다음 스테이지가 열림")
    func lockFollowsPreviousStage() {
        let progress = ProgressService.makeForTesting()
        let vm = ChapterViewModel(chapter: 1, progress: progress)
        #expect(vm.isLocked(vm.stages[0]) == false)
        #expect(vm.isLocked(vm.stages[1]))

        progress.recordClear(stageId: vm.stages[0].id, stars: 1, blockCount: 9)
        #expect(vm.isLocked(vm.stages[1]) == false)
    }

    @Test("스테이지 기록 — 클리어 여부·별·최고 기록·챕터 합계")
    func stageResults() {
        let progress = ProgressService.makeForTesting()
        let vm = ChapterViewModel(chapter: 1, progress: progress)
        let stage = vm.stages[0]
        #expect(vm.isCleared(stage) == false)
        #expect(vm.bestBlockCount(stage) == 0)

        progress.recordClear(stageId: stage.id, stars: 2, blockCount: 5)
        #expect(vm.isCleared(stage))
        #expect(vm.stars(stage) == 2)
        #expect(vm.bestBlockCount(stage) == 5)
        #expect(vm.totalStars() == 2)
    }

    @Test("잠금 문구 — 마지막 스테이지만 다른 안내")
    func lockMessage_differsForFinalStage() throws {
        let vm = ChapterViewModel(chapter: 1, progress: .makeForTesting())
        let last = try #require(vm.stages.last)
        #expect(vm.lockMessage(for: vm.stages[1]).contains("이전 스테이지"))
        #expect(vm.lockMessage(for: last).contains("앞 스테이지를 모두"))
    }
}

// MARK: - 변경 알림 전파

@MainActor
@Suite("ViewModel 변경 알림")
struct ViewModelChangeForwardingTests {

    /// 진행도가 바뀌면 VM이 화면 갱신 알림을 보내는지 확인
    /// VM은 진행도를 약한 참조로 구독하므로, 확인이 끝날 때까지 VM을 붙잡아 둠 (앱에선 @StateObject가 붙잡음)
    private func forwards<VM: ObservableObject>(_ vm: VM, from progress: ProgressService) -> Bool
    where VM.ObjectWillChangePublisher == ObservableObjectPublisher {
        withExtendedLifetime(vm) {
            var received = false
            let subscription = vm.objectWillChange.sink { received = true }
            progress.recordClear(stageId: "ch1_stage1", stars: 3, blockCount: 1)
            subscription.cancel()
            return received
        }
    }

    @Test("진행도가 바뀌면 VM 3개 모두 화면 갱신 알림을 보냄")
    func forwardsProgressChanges() {
        let homeProgress = ProgressService.makeForTesting()
        #expect(forwards(HomeViewModel(progress: homeProgress), from: homeProgress))

        let selectProgress = ProgressService.makeForTesting()
        #expect(forwards(ChapterSelectViewModel(progress: selectProgress), from: selectProgress))

        let chapterProgress = ProgressService.makeForTesting()
        #expect(forwards(ChapterViewModel(chapter: 1, progress: chapterProgress), from: chapterProgress))
    }
}
