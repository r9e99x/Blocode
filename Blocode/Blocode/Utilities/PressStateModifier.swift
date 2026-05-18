//
//  PressStateModifier.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - PressStateModifier
/// 버튼 눌림 상태를 Binding<Bool>로 추적하는 ViewModifier
/// DragGesture(minimumDistance: 0)를 사용해 손가락이 닿는 순간 isPressed = true,
/// 떼는 순간 isPressed = false가 됨
///
/// 사용 예:
/// ```swift
/// Button { ... } label: { ... }
///     .onPressState(isPressed: $isMyButtonPressed)
/// ```
private struct PressStateModifier: ViewModifier {

    @Binding var isPressed: Bool

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.easeInOut(duration: 0.08)) { isPressed = true }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.08)) { isPressed = false }
                    }
            )
    }
}

// MARK: - View Extension

extension View {
    /// 버튼 눌림 상태를 Binding<Bool>로 전달하는 modifier
    /// - Parameter isPressed: 눌림 여부를 추적할 바인딩
    func onPressState(isPressed: Binding<Bool>) -> some View {
        modifier(PressStateModifier(isPressed: isPressed))
    }
}
