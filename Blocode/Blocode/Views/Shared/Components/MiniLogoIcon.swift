//
//  MiniLogoIcon.swift
//  Blocode
//
//  Created by 조준희 on 10/19/26.
//

import SwiftUI

// MARK: - MiniLogoIcon
/// 앱 로고와 같은 3D 미니 블럭 아이콘 (위쪽 화살표) — 홈 헤더·온보딩 환영 슬라이드 공용
/// 색은 게임 캐릭터와 같은 다이나믹 컬러 세트 (라이트: 다크 잉크 몸체+탄색 베벨+크림 화살표 / 다크: 밝은 몸체+쿨 그레이 베벨+다크 화살표)
struct MiniLogoIcon: View {
    let size: CGFloat         // 아이콘 한 변 크기
    let topDepth: CGFloat     // 위 뒷면 두께
    let bottomDepth: CGFloat  // 아래 뒷면 두께 (그림자)
    let cornerRadius: CGFloat // 모서리 반지름
    let arrowSize: CGFloat    // 화살표 글자 크기

    var body: some View {
        ThreeDSurface(topDepth: topDepth, bottomDepth: bottomDepth) {
            // ① 위 뒷면
            RoundedRectangle(cornerRadius: cornerRadius).fill(Color.characterTopBack)
                .frame(width: size, height: size)
        } bottomBack: {
            // ② 아래 뒷면
            RoundedRectangle(cornerRadius: cornerRadius).fill(Color.characterBottomBack)
                .frame(width: size, height: size)
        } front: {
            // ③ 앞면 + 화살표
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius).fill(Color.characterBody)
                Image(systemName: "arrow.up")
                    .font(.system(size: arrowSize, weight: .bold))
                    .foregroundStyle(Color.characterArrow)
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size + topDepth + bottomDepth)
    }
}
