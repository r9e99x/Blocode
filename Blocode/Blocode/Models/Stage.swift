//
//  Stage.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation

// MARK: - StarThresholds
/// 스테이지별 별점 기준
/// 사용한 블럭 수를 기준으로 별 1~3개 결정
struct StarThresholds: Codable {
    /// 이 블럭 수 이하면 별 3개 (최적 풀이)
    var threeStar: Int

    /// 이 블럭 수 이하면 별 2개
    var twoStar: Int

    /// twoStar 초과면 별 1개 (클리어만 한 상태)

    /// 사용한 블럭 수로 별점 계산
    /// - Parameter blockCount: 실행에 사용한 총 블럭 수 (flatCount 기준)
    /// - Returns: 1~3 사이의 별 개수
    func stars(for blockCount: Int) -> Int {
        if blockCount <= threeStar { return 3 }  // 최적 풀이 — 별 3개
        if blockCount <= twoStar  { return 2 }   // 준최적 풀이 — 별 2개
        return 1                                  // 클리어 — 별 1개
    }
}

// MARK: - Stage
/// 하나의 스테이지 데이터
/// JSON 파일에서 로드하여 사용
struct Stage: Codable, Identifiable {
    /// 고유 식별자 (예: "ch1_stage1") — ProgressService 키로도 사용
    var id: String

    /// 챕터 번호 (1~5)
    var chapter: Int

    /// 스테이지 번호 (챕터 내 순서)
    var stageNumber: Int

    /// 스테이지 이름 (예: "첫 걸음")
    var name: String

    /// 맵 데이터 (타일 격자, 시작/목표 위치, 시작 방향)
    var mapData: MapData

    /// 별점 기준 (블럭 수 기준)
    var starThresholds: StarThresholds

    /// 이 스테이지 팔레트에 표시할 블럭 타입 목록
    /// nil이면 모든 블럭 표시 (하위 호환성 유지 — JSON에 필드 없을 때)
    var availableBlocks: [BlockType]?

    // MARK: - 헬퍼

    /// 팔레트에 실제로 표시할 블럭 목록
    /// availableBlocks가 nil이면 전체 블럭 (BlockType.allCases) 반환
    var paletteBlocks: [BlockType] {
        availableBlocks ?? BlockType.allCases
    }

    /// 로딩 실패 시 타입 불변식(비옵셔널 Stage)을 유지하기 위한 안전 플레이스홀더
    /// (실제 화면에는 표시되지 않음 — View가 loadFailed로 폴백 UI를 띄움)
    static func placeholder(chapter: Int, stageNumber: Int) -> Stage {
        Stage(
            id: "ch\(chapter)_stage\(stageNumber)",
            chapter: chapter,
            stageNumber: stageNumber,
            name: "스테이지를 불러올 수 없어요",
            mapData: MapData(
                grid: [[1]],                       // 최소 유효 맵 (1×1 바닥)
                start: Position(x: 0, y: 0),
                startDirection: .up,
                goal: Position(x: 0, y: 0)
            ),
            starThresholds: StarThresholds(threeStar: 1, twoStar: 1)
        )
    }
}

// 참고: StageLoader(JSON 데이터 접근 계층)는 Services/StageLoader.swift로 이동함
//       (MVVM — 데이터 소스 접근은 Service 계층 책임)
