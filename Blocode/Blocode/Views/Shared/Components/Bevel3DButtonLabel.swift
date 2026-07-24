//
//  Bevel3DButtonLabel.swift
//  Blocode
//
//  Created by 조준희 on 7/8/26.
//

import SwiftUI

// MARK: - Bevel3DButtonLabel
/// "단색 면 + 반투명 오버레이 베벨" 방식 3D 버튼의 공용 라벨 뷰
/// (기존 ControlBarView.button3D를 컴포넌트로 승격 — 파라미터·렌더링 완전 동일)
///
/// 3D 뼈대(쌓기 + 눌림 효과)는 ThreeDSurface가 담당하고,
/// 이 뷰는 위 뒷면(color+white 오버레이) / 아래 뒷면(color+black 오버레이) /
/// 앞면(color + 눌림 시 black 0.10 + 라벨) 3면의 채우기 규칙을 제공한다.
/// iOS 컨트롤 바와 맥 상단바 컨트롤이 공용으로 사용한다.
struct Bevel3DButtonLabel<Label: View>: View {

    let color: Color               // 3면 공통 바탕색
    let width: CGFloat             // 앞면 너비
    let height: CGFloat            // 앞면 높이
    let cornerRadius: CGFloat      // 모서리 반지름
    var topDepth: CGFloat          // 위 뒷면 두께
    var botDepth: CGFloat          // 아래 뒷면 두께
    var topOverlayOpacity: Double     // 위 뒷면 흰색 오버레이 강도
    var bottomOverlayOpacity: Double  // 아래 뒷면 검정 오버레이 강도
    var isPressed: Bool            // 눌림 상태
    @ViewBuilder let label: () -> Label  // 앞면 내용 (아이콘/텍스트)

    /// 기본값은 기존 ControlBarView.button3D와 동일 (topDepth 2 / botDepth 2.5 / 오버레이 0.28·0.22)
    init(color: Color,
         width: CGFloat,
         height: CGFloat,
         cornerRadius: CGFloat,
         topDepth: CGFloat = 2,
         botDepth: CGFloat = 2.5,
         topOverlayOpacity: Double = 0.28,
         bottomOverlayOpacity: Double = 0.22,
         isPressed: Bool = false,
         @ViewBuilder label: @escaping () -> Label) {
        self.color = color
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.topDepth = topDepth
        self.botDepth = botDepth
        self.topOverlayOpacity = topOverlayOpacity
        self.bottomOverlayOpacity = bottomOverlayOpacity
        self.isPressed = isPressed
        self.label = label
    }

    var body: some View {
        ThreeDSurface(topDepth: topDepth, bottomDepth: botDepth, isPressed: isPressed) {
            // ① 위 뒷면 — color + white 오버레이 (강도는 호출부가 결정)
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius).fill(color)
                RoundedRectangle(cornerRadius: cornerRadius).fill(Color.white.opacity(topOverlayOpacity))
            }
            .frame(width: width, height: height)
        } bottomBack: {
            // ② 아래 뒷면 — color + black 오버레이 (강도는 호출부가 결정)
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius).fill(color)
                RoundedRectangle(cornerRadius: cornerRadius).fill(Color.black.opacity(bottomOverlayOpacity))
            }
            .frame(width: width, height: height)
        } front: {
            // ③ 앞면 — color + (눌림 시 black 0.10) + label
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius).fill(color)
                if isPressed {
                    RoundedRectangle(cornerRadius: cornerRadius).fill(Color.black.opacity(0.10))
                }
                label()
            }
            .frame(width: width, height: height)
        }
        .frame(width: width, height: height + topDepth + botDepth)
    }
}
