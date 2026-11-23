//
//  PressableButton.swift
//  Blocode
//
//  Created by 조준희 on 11/23/26.
//

import SwiftUI

// MARK: - PressableButton
/// 누르는 동안 눌림 모양(3D 버튼이 내려앉는 효과 등)을 보여 주는 버튼 — 라벨 클로저가 눌림 여부를 받음
/// SwiftUI 표준 ButtonStyle의 `configuration.isPressed`를 그대로 씀
/// (예전엔 버튼마다 @State를 두고, 손가락이 움직일 때마다 상태를 다시 쓰는 끌기 제스처(onPressState)로 따로 추적했음)
/// 라벨은 그대로 버튼의 라벨이라 VoiceOver·UI 테스트가 글자로 버튼을 찾는 방식도 그대로임
struct PressableButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: (_ isPressed: Bool) -> Label

    var body: some View {
        Button(action: action) {
            PressedLabel(label: label)
        }
        .buttonStyle(PressReportingStyle())
    }
}

// MARK: - 눌림 여부 전달

extension EnvironmentValues {
    /// 감싸고 있는 PressableButton이 눌려 있는지 — PressReportingStyle이 채움 (@Entry: iOS 18+ 환경값 선언)
    @Entry var isButtonPressed = false
}

/// 버튼의 눌림 여부를 환경값으로 라벨에 내려 주는 스타일 — 눌림 변화는 짧게(0.08초) 애니메이션 (예전 onPressState와 같은 값)
private struct PressReportingStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.isButtonPressed, configuration.isPressed)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

/// 환경값으로 받은 눌림 여부로 라벨을 그림
private struct PressedLabel<Label: View>: View {
    @Environment(\.isButtonPressed) private var isPressed
    let label: (Bool) -> Label

    var body: some View {
        label(isPressed)
    }
}
