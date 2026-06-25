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
        // 챕터 메타데이터는 ChapterCatalog(단일 원본)에서 가져옴
        // (제목·스테이지 수·색상·해금 기준을 한 곳에서 관리 → 화면 간 불일치 방지)
        self.chapters = ChapterCatalog.all

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

        // 다음 챕터 해금 = 아래 둘을 모두 만족해야 함 (AND)
        //   조건 1: 이전 챕터 총 별점이 기준(requiredStarsFromPrev) 이상
        //   조건 2: 이전 챕터 마지막 스테이지(종합)를 클리어 (별 수 무관)
        let prevStars = progress.totalStars(chapter: chapter.number - 1, stageCount: prevStageCount)
        let lastStageId = "ch\(chapter.number - 1)_stage\(prevStageCount)"
        let finalCleared = progress.isCleared(lastStageId)
        return prevStars >= chapter.requiredStarsFromPrev && finalCleared
    }

    /// 챕터에서 획득한 총 별점 반환
    func chapterStars(_ chapter: ChapterInfo) -> Int {
        guard chapter.stageCount > 0 else { return 0 }
        return progress.totalStars(chapter: chapter.number, stageCount: chapter.stageCount)
    }

    /// 잠긴 챕터의 해금 조건 안내 문구 (B안: 별 합 AND 종합 클리어)
    func lockMessage(for chapter: ChapterInfo) -> String {
        "이전 챕터에서 별 \(chapter.requiredStarsFromPrev)개를 모으고\n종합 스테이지를 클리어하면 열려요"
    }

    /// 챕터에서 클리어한 스테이지 수 반환
    func clearedStageCount(_ chapter: ChapterInfo) -> Int {
        guard chapter.stageCount > 0 else { return 0 }
        return (1...chapter.stageCount).filter {
            progress.isCleared("ch\(chapter.number)_stage\($0)")
        }.count
    }
}
