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

    // MARK: - 헬퍼

    /// 챕터와 스테이지 번호로 표시할 문자열 (예: "STAGE 1-3")
    var displayTitle: String {
        return "STAGE \(chapter)-\(stageNumber)"
    }
}

// MARK: - StageLoader
/// JSON 파일에서 스테이지 데이터를 로드하는 유틸리티
enum StageLoader {
    /// 특정 챕터와 스테이지 번호의 JSON 파일을 로드하여 Stage 반환
    /// - Parameters:
    ///   - chapter: 챕터 번호
    ///   - stage: 스테이지 번호
    /// - Returns: 파싱 성공 시 Stage, 실패 시 nil
    static func load(chapter: Int, stage: Int) -> Stage? {
        // 파일명 형식: chapter1_stage1.json
        let fileName = "chapter\(chapter)_stage\(stage)"

        // 번들에서 JSON 파일 URL 조회
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("❌ 스테이지 파일을 찾을 수 없음: \(fileName).json")
            return nil
        }

        do {
            // 파일 데이터 로드 후 JSON 디코딩
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let stage = try decoder.decode(Stage.self, from: data)
            return stage
        } catch {
            print("❌ 스테이지 파싱 실패: \(error)")
            return nil
        }
    }

    /// 챕터의 모든 스테이지를 로드하여 배열로 반환
    /// - Parameters:
    ///   - chapter: 챕터 번호
    ///   - stageCount: 로드할 스테이지 총 개수
    /// - Returns: 로드 성공한 스테이지 배열 (실패한 스테이지는 제외)
    static func loadChapter(_ chapter: Int, stageCount: Int) -> [Stage] {
        // 1번부터 stageCount까지 순서대로 로드, nil은 compactMap으로 제거
        return (1...stageCount).compactMap { load(chapter: chapter, stage: $0) }
    }
}
