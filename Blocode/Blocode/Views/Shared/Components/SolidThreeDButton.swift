//
//  SolidThreeDButton.swift
//  Blocode
//
//  Created by 조준희 on 10/19/26.
//

import SwiftUI

// MARK: - SolidThreeDButton
/// 단색 면으로 그리는 가로로 긴 3D 버튼 라벨 — 위 뒷면 / 아래 뒷면 / 앞면(+라벨)을 각자 지정한 색으로 칠함
/// 잠금·재도전 확인, 온보딩 "다음", 홈 "이어서 하기·챕터 둘러보기", 챕터 브라우저 "시작하기"가 공용으로 사용
/// (예전엔 같은 3겹 코드가 11곳에 복사돼 있었음 — 값은 호출부가 기존 그대로 넘겨 외형 동일)
///
/// 눌림 표시는 두 방식 중 하나: pressedFace를 주면 앞면 색 자체를 바꾸고(홈 이어서 하기),
/// 없으면 앞면 위에 검정 오버레이(pressedOverlayOpacity, 0이면 표시 없음)를 덮음
struct SolidThreeDButton<Label: View>: View {
    let height: CGFloat                       // 앞면 높이
    let cornerRadius: CGFloat                 // 모서리 반지름
    var topDepth: CGFloat = 0.8               // 위 뒷면 두께
    var bottomDepth: CGFloat = 2.5            // 아래 뒷면 두께 (그림자)
    var face: Color = .slateButtonFace        // 앞면 색 (기본: 슬레이트 — 라이트 다크 잉크 / 다크 슬레이트)
    var topBack: Color = .slateButtonTopBack  // 위 뒷면 색
    var bottomBack: Color = .slateButtonBottomBack  // 아래 뒷면 색
    var pressedFace: Color? = nil             // 눌림 시 앞면 색 (nil이면 오버레이 방식)
    var pressedOverlayOpacity: Double = 0.10  // 눌림 시 앞면에 덮는 검정 강도
    var isPressed: Bool = false               // 눌림 상태
    @ViewBuilder let label: () -> Label       // 앞면 내용

    var body: some View {
        ThreeDSurface(topDepth: topDepth, bottomDepth: bottomDepth, isPressed: isPressed) {
            // ① 위 뒷면
            RoundedRectangle(cornerRadius: cornerRadius).fill(topBack)
                .frame(maxWidth: .infinity).frame(height: height)
        } bottomBack: {
            // ② 아래 뒷면 (그림자)
            RoundedRectangle(cornerRadius: cornerRadius).fill(bottomBack)
                .frame(maxWidth: .infinity).frame(height: height)
        } front: {
            // ③ 앞면 + (눌림 표시) + 라벨
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isPressed ? (pressedFace ?? face) : face)
                if isPressed && pressedFace == nil && pressedOverlayOpacity > 0 {
                    RoundedRectangle(cornerRadius: cornerRadius).fill(Color.black.opacity(pressedOverlayOpacity))
                }
                label()
            }
            .frame(maxWidth: .infinity).frame(height: height)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height + topDepth + bottomDepth)
    }
}
