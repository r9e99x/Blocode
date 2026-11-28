//
//  ChapterBevelBackground.swift
//  Blocode
//
//  Created by 조준희 on 10/19/26.
//

import SwiftUI

// MARK: - ChapterBevelBackground
/// 챕터 색 3D 배경 — 앞면 아래로 depth만큼 어두운 면이 비쳐 입체로 보임
/// (아이패드 챕터 화면 헤더가 씀)
struct ChapterBevelBackground<S: Shape>: View {
    let shape: S
    let color: Color
    let depth: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            // 뒷면 — 어둡게, depth만큼 아래로 (3D 효과)
            shape.fill(color)
                .overlay(shape.fill(Color.black.opacity(0.28)))
                .padding(.top, depth)
            // 앞면 — depth만큼 짧게 (뒷면이 아래로 보이게)
            shape.fill(color)
                .padding(.bottom, depth)
        }
    }
}
