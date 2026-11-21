//
//  LongPressDragModifier.swift
//  Blocode
//
//  Created by 조준희 on 11/21/26.
//

import SwiftUI

// MARK: - LongPressDragModifier
/// 0.38초 길게 누른 뒤 끌기 시작하는 제스처 — 코드 리스트의 블럭 순서 변경과 맥 팔레트 카드가 함께 씀
/// (예전엔 두 화면에 같은 타이머·상태 코드가 따로 있었음, 동작은 그대로)
/// 눌림·끌기 상태는 화면이 모양(축소·흐림)에 쓰므로 바인딩으로 받음
private struct LongPressDragModifier: ViewModifier {

    @Binding var isPressed: Bool     // 누르고 있는 동안 true (끌기가 시작되면 false)
    @Binding var isDragging: Bool    // 끌기 중
    let isEnabled: Bool              // false면 누름·끌기를 시작하지 않음 (탭은 그대로 전달)
    let onTap: (() -> Void)?         // 끌기 없이 손을 뗐을 때 — nil이면 아무 일도 없음
    let onStart: (CGPoint) -> Void   // 끌기 시작 (글로벌 좌표)
    let onChange: (CGPoint) -> Void  // 끌기 중 위치
    let onEnd: (CGPoint) -> Void     // 끌기 끝

    @State private var timer: Timer?  // 길게 누르기 감지 타이머

    func body(content: Content) -> some View {
        content.gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if isDragging {
                        onChange(value.location)
                    } else if timer == nil && isEnabled {
                        // 처음 누름 — 눌린 모양을 보여 주고 0.38초 뒤 끌기 모드로
                        withAnimation { isPressed = true }
                        let newTimer = Timer(timeInterval: 0.38, repeats: false) { _ in
                            DispatchQueue.main.async {
                                withAnimation { isDragging = true; isPressed = false }
                                onStart(value.location)
                            }
                        }
                        #if os(macOS)
                        // 맥은 마우스를 누르는 동안 .eventTracking 런루프라 .default 타이머가 멈춤 → .common으로 등록
                        RunLoop.current.add(newTimer, forMode: .common)
                        #else
                        RunLoop.current.add(newTimer, forMode: .default)
                        #endif
                        timer = newTimer
                    }
                }
                .onEnded { value in
                    timer?.invalidate()
                    timer = nil
                    if isDragging {
                        onEnd(value.location)
                    } else {
                        onTap?()
                    }
                    withAnimation { isDragging = false; isPressed = false }
                }
        )
    }
}

extension View {
    /// 길게 누른 뒤 끌기 — 사용법은 LongPressDragModifier 설명 참고
    func longPressDrag(isPressed: Binding<Bool>, isDragging: Binding<Bool>, isEnabled: Bool,
                       onTap: (() -> Void)? = nil,
                       onStart: @escaping (CGPoint) -> Void,
                       onChange: @escaping (CGPoint) -> Void,
                       onEnd: @escaping (CGPoint) -> Void) -> some View {
        modifier(LongPressDragModifier(isPressed: isPressed, isDragging: isDragging, isEnabled: isEnabled,
                                       onTap: onTap, onStart: onStart, onChange: onChange, onEnd: onEnd))
    }
}
