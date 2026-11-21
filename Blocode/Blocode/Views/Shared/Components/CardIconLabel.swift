//
//  CardIconLabel.swift
//  Blocode
//
//  Created by 조준희 on 11/17/26.
//

import SwiftUI

// MARK: - CardIconLabel
/// 36×36 카드형 아이콘 버튼의 모양 — 뒤로가기·설정·보관함·홈 버튼이 함께 씀
/// (예전엔 같은 모양 코드가 화면마다 따로 있었음 — 값은 화면별 기존 값을 그대로 넘겨받아 모양은 변함없음)
struct CardIconLabel: View {

    let icon: String              // SF Symbol 이름
    let fontSize: CGFloat         // 아이콘 크기
    let background: Color         // 카드 배경
    let shadowOpacity: Double     // 그림자 진하기
    let shadowY: CGFloat          // 그림자 아래 방향 거리

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(Color.secondary)
            .frame(width: 36, height: 36)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: Color.black.opacity(shadowOpacity), radius: 8, x: 0, y: shadowY)
    }
}
