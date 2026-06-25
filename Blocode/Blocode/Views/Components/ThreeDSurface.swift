//
//  ThreeDSurface.swift
//  Blocode
//
//  Created by 조준희 on 6/24/26.
//

import SwiftUI

// MARK: - ThreeDSurface
/// 3D 버튼/아이콘의 공통 뼈대 — "위 뒷면 / 아래 뒷면 / 앞면" 3겹을 쌓고
/// 눌림 시 두 뒷면이 사라지며 앞면이 아래로 내려가는 효과를 담당한다.
///
/// 각 면의 색·내용·크기는 호출부가 @ViewBuilder로 직접 넘기므로,
/// 색칠 방식(단색+반투명 오버레이 / 위·앞·아래 직접 색 지정)에 상관없이
/// 기존 외형을 픽셀 단위로 그대로 유지한다.
/// (깊이 topDepth/bottomDepth는 호출부가 기존 값을 그대로 전달 — 기본값 없음)
struct ThreeDSurface<TopBack: View, BottomBack: View, Front: View>: View {

    let topDepth: CGFloat        // 위 뒷면이 앞면 위로 보이는 두께
    let bottomDepth: CGFloat     // 아래 뒷면이 앞면 아래로 보이는 두께 (그림자)
    var isPressed: Bool = false  // 눌림 상태 (true면 두 뒷면 숨기고 앞면을 아래로)

    @ViewBuilder let topBack: () -> TopBack        // 위 뒷면 내용
    @ViewBuilder let bottomBack: () -> BottomBack  // 아래 뒷면 내용
    @ViewBuilder let front: () -> Front            // 앞면 내용

    var body: some View {
        ZStack(alignment: .top) {
            // ① 위 뒷면 — 눌리면 사라짐
            topBack()
                .opacity(isPressed ? 0 : 1)

            // ② 아래 뒷면 — 눌리면 사라짐
            bottomBack()
                .offset(y: topDepth + bottomDepth)
                .opacity(isPressed ? 0 : 1)

            // ③ 앞면 — 눌리면 아래 뒷면 자리까지 완전히 내려감
            front()
                .offset(y: isPressed ? topDepth + bottomDepth : topDepth)
        }
    }
}
