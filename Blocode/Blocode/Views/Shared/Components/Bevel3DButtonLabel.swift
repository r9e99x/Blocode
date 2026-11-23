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

    // 기본값은 기존 ControlBarView.button3D와 동일 (topDepth 2 / botDepth 2.5 / 오버레이 0.28·0.22)
    // 저장 속성에 기본값을 두면 Swift가 같은 순서의 init을 자동으로 만들어 줌 (예전엔 같은 내용의 init을 직접 20줄 썼음)
    let color: Color                        // 3면 공통 바탕색
    let width: CGFloat                      // 앞면 너비
    let height: CGFloat                     // 앞면 높이
    let cornerRadius: CGFloat               // 모서리 반지름
    var topDepth: CGFloat = 2               // 위 뒷면 두께
    var botDepth: CGFloat = 2.5             // 아래 뒷면 두께
    var topOverlayOpacity: Double = 0.28    // 위 뒷면 흰색 오버레이 강도
    var bottomOverlayOpacity: Double = 0.22 // 아래 뒷면 검정 오버레이 강도
    var isPressed: Bool = false             // 눌림 상태
    @ViewBuilder let label: () -> Label     // 앞면 내용 (아이콘/텍스트)

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
