//
//  ChapterSelectViewModel.swift
//  Blocode
//
//  Created by 조준희 on 5/19/26.
//

import SwiftUI   // ChapterInfo가 Color(UI 표현값)를 포함하므로 필요
import Combine

// MARK: - ChapterSelectViewModel
/// 챕터 선택 화면(ChapterSelectView)의 상태/로직 담당 ViewModel
/// 챕터 목록 데이터와 잠금/별점 계산을 보유한다.
///
/// 동작 보존 메모: ProgressService의 `objectWillChange`를 그대로 전파하므로
/// 기존 화면 자동 갱신 타이밍과 100% 동일하다.
final class ChapterSelectViewModel: ObservableObject {

    // 진행도 서비스 (데이터 소스)
    private let progress = ProgressService.shared
    private var cancellables = Set<AnyCancellable>()

    /// 챕터 목록 — 순서대로 잠금/해제 상태 계산
    /// (색상 등 UI 표현값을 포함한 ChapterInfo는 화면 구성용 메타데이터)
    let chapters: [ChapterInfo]

    init() {
        // 챕터 메타데이터 정의
        // requiredStarsFromPrev: 이전 챕터 최대 별점의 약 2/3 수준으로 설정
        // 스테이지 추가 시 stageCount만 수정 (ChapterViewModel.stageCount(for:)와 일치시킬 것)
        self.chapters = [
            ChapterInfo(id: 1, title: "기본기",  stageCount: 6,
                        color: Color(red: 0.576, green: 0.788, blue: 0.671), // #93c9ab
                        requiredStarsFromPrev: 0),  // 챕터 1은 항상 개방
            ChapterInfo(id: 2, title: "반복",   stageCount: 8,
                        color: Color(red: 0.58, green: 0.76, blue: 0.88),
                        requiredStarsFromPrev: 12), // 챕터 1 최대 18개 중 12개 (67%)
            ChapterInfo(id: 3, title: "조건문", stageCount: 8,
                        color: Color(red: 0.93, green: 0.62, blue: 0.42),
                        requiredStarsFromPrev: 16), // 챕터 2 최대 24개 중 16개 (67%)
            ChapterInfo(id: 4, title: "함수",   stageCount: 7,
                        color: Color(red: 0.45, green: 0.78, blue: 0.62),
                        requiredStarsFromPrev: 16), // 챕터 3 최대 24개 중 16개 (67%)
            ChapterInfo(id: 5, title: "심화",   stageCount: 6,
                        color: Color(red: 0.88, green: 0.50, blue: 0.68),
                        requiredStarsFromPrev: 14), // 챕터 4 최대 21개 중 14개 (67%)
        ]

        // ProgressService 변경을 그대로 전파 → 뷰 자동 갱신 유지
        progress.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - 잠금/진행 계산

    /// 챕터 잠금 해제 여부 확인
    /// 아래 두 조건 중 하나를 만족하면 해금:
    ///   1. 이전 챕터 총 별점이 requiredStarsFromPrev 이상
    ///   2. 이전 챕터 마지막 스테이지(종합)를 별 3개로 클리어
    func isUnlocked(_ chapter: ChapterInfo) -> Bool {
        if chapter.number == 1 { return true }  // 챕터 1은 항상 열림
        guard chapter.stageCount > 0 else { return false }  // 스테이지 없으면 항상 잠김

        // 이전 챕터 정보를 chapters 배열에서 조회 (stageCount 하드코딩 제거)
        let prevChapter = chapters.first { $0.number == chapter.number - 1 }
        let prevStageCount = prevChapter?.stageCount ?? 0
        guard prevStageCount > 0 else { return false }

        // 조건 1: 이전 챕터 총 별점 임계치 이상
        let prevStars = progress.totalStars(chapter: chapter.number - 1, stageCount: prevStageCount)
        if prevStars >= chapter.requiredStarsFromPrev { return true }

        // 조건 2: 이전 챕터 마지막 스테이지(종합)를 별 3개로 클리어
        let lastStageId = "ch\(chapter.number - 1)_stage\(prevStageCount)"
        return progress.stars(for: lastStageId) == 3
    }

    /// 챕터에서 획득한 총 별점 반환
    func chapterStars(_ chapter: ChapterInfo) -> Int {
        guard chapter.stageCount > 0 else { return 0 }
        return progress.totalStars(chapter: chapter.number, stageCount: chapter.stageCount)
    }

    /// 챕터에서 클리어한 스테이지 수 반환
    func clearedStageCount(_ chapter: ChapterInfo) -> Int {
        guard chapter.stageCount > 0 else { return 0 }
        return (1...chapter.stageCount).filter {
            progress.isCleared("ch\(chapter.number)_stage\($0)")
        }.count
    }
}
