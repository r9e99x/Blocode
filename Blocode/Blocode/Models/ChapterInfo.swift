//
//  ChapterInfo.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - ChapterInfo
/// 챕터 한 개의 메타데이터 — ChapterCatalog가 보유하는 단일 원본 데이터 모델
/// 챕터 카드 렌더링, 챕터 해금, 종합 스테이지 잠금 판단 등에 두루 사용
struct ChapterInfo: Identifiable {
    let id: Int                     // 챕터 번호 (1~5)
    var number: Int { id }          // id의 alias — 가독성을 위한 computed property
    let title: String               // 챕터 이름 (예: "기본기")
    let stageCount: Int             // 챕터 내 스테이지 수
    let color: Color                // 챕터 카드 색상
    let requiredStarsFromPrev: Int  // 이전 챕터에서 필요한 최소 별점 (챕터 잠금 해제 조건)
    let finalStageRequiredStars: Int // 종합(마지막) 스테이지 잠금 해제에 필요한 이전 스테이지 별점 합
}
