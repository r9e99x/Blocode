//
//  ChapterViewModel.swift
//  Blocode
//
//  Created by 조준희 on 5/19/26.
//

import Foundation
import Combine

// MARK: - ChapterViewModel
/// 챕터 스테이지 목록 화면(ChapterView)의 상태/로직 담당 ViewModel
/// 스테이지 데이터 로딩, 진행 위치 계산, 스테이지별 잠금/클리어/별점을 보유한다.
///
/// 동작 보존 메모: ProgressService의 `objectWillChange`를 그대로 전파하므로
/// 기존 화면 자동 갱신 타이밍과 100% 동일하다.
/// (색상 등 순수 UI 매핑은 View에 그대로 둔다 — VM은 UI 타입 비의존)
final class ChapterViewModel: ObservableObject {

    /// 현재 챕터 번호
    let chapter: Int

    /// 챕터 내 모든 스테이지 데이터 (JSON 로딩 — 데이터 접근은 Service 위임)
    let stages: [Stage]

    // 진행도 서비스 (데이터 소스)
    private let progress = ProgressService.shared
    private var cancellables = Set<AnyCancellable>()

    init(chapter: Int) {
        self.chapter = chapter
        // 챕터 JSON 파일에서 스테이지 목록 로드 (챕터별 스테이지 수는 헬퍼로 관리)
        self.stages  = StageLoader.loadChapter(chapter, stageCount: ChapterViewModel.stageCount(for: chapter))

        // ProgressService 변경을 그대로 전파 → 뷰 자동 갱신 유지
        progress.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    /// 챕터 번호에 따른 한국어 제목 반환 (ChapterCatalog 단일 원본에서 조회)
    var chapterTitle: String {
        ChapterCatalog.chapter(chapter)?.title ?? "챕터 \(chapter)"
    }

    /// 챕터별 스테이지 수 (ChapterCatalog 단일 원본에서 조회)
    static func stageCount(for chapter: Int) -> Int {
        ChapterCatalog.chapter(chapter)?.stageCount ?? 0
    }

    /// 아직 클리어하지 않은 첫 번째 스테이지 번호 (현재 진행 위치)
    /// — "지금 여기" 레이블을 이 스테이지에 표시
    var currentStageNumber: Int? {
        stages.first {
            !progress.isLocked(chapter: $0.chapter, stageNumber: $0.stageNumber) &&
            !progress.isCleared($0.id)
        }?.stageNumber
    }

    /// 챕터 전체 획득 별점 / 최대 별점
    func totalStars() -> Int {
        progress.totalStars(chapter: chapter, stageCount: stages.count)
    }

    /// 특정 스테이지 잠금 여부
    func isLocked(_ stage: Stage) -> Bool {
        progress.isLocked(chapter: stage.chapter, stageNumber: stage.stageNumber)
    }

    /// 특정 스테이지 클리어 여부
    func isCleared(_ stage: Stage) -> Bool {
        progress.isCleared(stage.id)
    }

    /// 특정 스테이지 획득 별점 (0~3)
    func stars(_ stage: Stage) -> Int {
        progress.stars(for: stage.id)
    }

    /// 특정 스테이지가 현재 진행 위치인지 여부
    func isCurrent(_ stage: Stage) -> Bool {
        stage.stageNumber == currentStageNumber
    }
}
