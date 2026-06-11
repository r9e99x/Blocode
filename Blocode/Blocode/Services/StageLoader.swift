//
//  StageLoader.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation

// MARK: - StageLoader
/// JSON 파일에서 스테이지 데이터를 로드하는 데이터 접근 계층(Repository)
/// MVVM에서 데이터 소스 접근은 View가 아닌 Service 계층의 책임이므로
/// Models/가 아닌 Services/에 위치한다.
enum StageLoader {
    /// 특정 챕터와 스테이지 번호의 JSON 파일을 로드하여 Stage 반환
    /// - Parameters:
    ///   - chapter: 챕터 번호
    ///   - stage: 스테이지 번호
    /// - Returns: 파싱 성공 시 Stage, 실패 시 nil
    static func load(chapter: Int, stage: Int) -> Stage? {
        // 파일명 형식: ch1_stage1.json (챕터+스테이지 번호 포함 — 번들 루트에서 유일한 이름)
        // 폴더 구조(Resources/Stages/Chapter1/)는 Xcode Group으로 시각적 정리만 담당
        // 번들에서는 파일명으로만 조회 (Group은 번들 루트에 평탄화되므로 subdirectory 불필요)
        let fileName = "ch\(chapter)_stage\(stage)"

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
            // 파싱 실패 시 콘솔 로그 후 nil 반환
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
