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
        // 챕터 메타데이터 정의 (기존 ChapterSelectView의 값과 동일)
        self.chapters = [
            ChapterInfo(id: 1, title: "기본기",  stageCount: 6,
                        color: Color(red: 0.576, green: 0.788, blue: 0.671), // #93c9ab
                        requiredStarsFromPrev: 0),  // 챕터 1은 잠금 없음
            ChapterInfo(id: 2, title: "변수",   stageCount: 0,
                        color: Color(red: 0.58, green: 0.76, blue: 0.88),
                        requiredStarsFromPrev: 12), // 챕터 1에서 별 12개 이상 필요
            ChapterInfo(id: 3, title: "조건문", stageCount: 0,
                        color: Color(red: 0.93, green: 0.62, blue: 0.42),
                        requiredStarsFromPrev: 0),
            ChapterInfo(id: 4, title: "반복문", stageCount: 0,
                        color: Color(red: 0.45, green: 0.78, blue: 0.62),
                        requiredStarsFromPrev: 0),
            ChapterInfo(id: 5, title: "함수",   stageCount: 0,
                        color: Color(red: 0.88, green: 0.50, blue: 0.68),
                        requiredStarsFromPrev: 0),
        ]

        // ProgressService 변경을 그대로 전파 → 뷰 자동 갱신 유지
        progress.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - 잠금/진행 계산

    /// 챕터 잠금 해제 여부 확인
    func isUnlocked(_ chapter: ChapterInfo) -> Bool {
        if chapter.number == 1 { return true }  // 챕터 1은 항상 열림
        // 이전 챕터의 별점이 requiredStarsFromPrev 이상이고 스테이지가 있을 때 열림
        let prevStars = progress.totalStars(chapter: chapter.number - 1, stageCount: 6)
        return prevStars >= chapter.requiredStarsFromPrev && chapter.stageCount > 0
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
