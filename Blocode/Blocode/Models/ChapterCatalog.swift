//
//  ChapterCatalog.swift
//  Blocode
//
//  Created by 조준희 on 6/24/26.
//

import SwiftUI

// MARK: - ChapterCatalog
/// 모든 챕터 메타데이터의 단일 원본(Source of Truth)
/// 챕터 번호·제목·스테이지 수·색상·해금 기준·종합 스테이지 잠금 기준을
/// 이 한 곳에서만 정의하고, 화면/뷰모델/서비스가 모두 여기서 읽는다.
/// (예전에는 같은 값이 4~5곳에 흩어져 있어 한 곳만 고치면 어긋나는 문제가 있었음)
///
/// 챕터/스테이지를 추가·변경할 때는 아래 `all` 배열만 수정하면 된다.
enum ChapterCatalog {

    /// 전체 챕터 메타데이터 (챕터 번호 오름차순)
    static let all: [ChapterInfo] = [
        ChapterInfo(id: 1, title: "기본기",  stageCount: 6,
                    color: Color(red: 0.576, green: 0.788, blue: 0.671), // #93c9ab
                    requiredStarsFromPrev: 0,        // 챕터 1은 항상 개방
                    finalStageRequiredStars: 9),     // 1~5 최대 15개 중 9개 (60%)
        ChapterInfo(id: 2, title: "반복",   stageCount: 8,
                    color: Color(red: 0.58, green: 0.76, blue: 0.88),
                    requiredStarsFromPrev: 12,       // 챕터 1 최대 18개 중 12개 (67%)
                    finalStageRequiredStars: 13),    // 1~7 최대 21개 중 13개 (62%)
        ChapterInfo(id: 3, title: "조건문", stageCount: 8,
                    color: Color(red: 0.93, green: 0.62, blue: 0.42),
                    requiredStarsFromPrev: 16,       // 챕터 2 최대 24개 중 16개 (67%)
                    finalStageRequiredStars: 13),    // 1~7 최대 21개 중 13개 (62%)
        ChapterInfo(id: 4, title: "함수",   stageCount: 7,
                    color: Color(red: 0.45, green: 0.78, blue: 0.62),
                    requiredStarsFromPrev: 16,       // 챕터 3 최대 24개 중 16개 (67%)
                    finalStageRequiredStars: 11),    // 1~6 최대 18개 중 11개 (61%)
        ChapterInfo(id: 5, title: "심화",   stageCount: 6,
                    color: Color(red: 0.88, green: 0.50, blue: 0.68),
                    requiredStarsFromPrev: 14,       // 챕터 4 최대 21개 중 14개 (67%)
                    finalStageRequiredStars: 9),     // 1~5 최대 15개 중 9개 (60%)
    ]

    /// 챕터 번호로 메타데이터 조회 (없으면 nil)
    static func chapter(_ number: Int) -> ChapterInfo? {
        all.first { $0.number == number }
    }
}
