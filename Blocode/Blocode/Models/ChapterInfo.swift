//
//  ChapterInfo.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation

// MARK: - ChapterInfo
/// 챕터 한 개의 메타데이터 — ChapterCatalog가 보유하는 단일 원본 데이터 모델
/// 챕터 카드 렌더링, 챕터 해금, 종합 스테이지 잠금 판단 등에 두루 사용
struct ChapterInfo: Identifiable {
    let id: Int                     // 챕터 번호 (1부터)
    var number: Int { id }          // id의 alias — 가독성을 위한 computed property
    let title: String               // 챕터 이름 (예: "기본기")
    let description: String         // 챕터를 한 줄로 소개하는 짧은 설명
    let stageCount: Int             // 챕터 내 스테이지 수
    let rgb: (red: Double, green: Double, blue: Double)  // 챕터 카드 색상 값 — Color 변환은 View 계층(AppColors.swift)
    let requiredStarsFromPrev: Int  // 다음 챕터 해금에 필요한 이전 챕터 총 별점 (종합 클리어와 함께 AND 조건)

    /// 이 챕터에서 얻을 수 있는 최대 별 수 (스테이지당 3개)
    var maxStars: Int { stageCount * 3 }
}
