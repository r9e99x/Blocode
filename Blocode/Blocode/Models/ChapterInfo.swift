//
//  ChapterInfo.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - ChapterInfo
/// 챕터 선택 화면에서 사용하는 챕터 메타데이터
/// ChapterSelectView의 챕터 카드 렌더링 및 잠금 조건 판단에 사용
struct ChapterInfo: Identifiable {
    let id: Int                     // 챕터 번호 (1~5)
    var number: Int { id }          // id의 alias — 가독성을 위한 computed property
    let title: String               // 챕터 이름 (예: "기본기")
    let stageCount: Int             // 챕터 내 스테이지 수
    let color: Color                // 챕터 카드 색상
    let requiredStarsFromPrev: Int  // 이전 챕터에서 필요한 최소 별점 (잠금 해제 조건)
}
