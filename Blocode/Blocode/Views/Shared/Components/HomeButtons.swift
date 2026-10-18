//
//  HomeButtons.swift
//  Blocode
//
//  Created by 조준희 on 10/19/26.
//

import SwiftUI

// MARK: - HomeContinueButton
/// 홈 "시작하기 / 이어서 하기" 3D 버튼 — 아이폰 홈·아이패드 셸·맥 셸 공용
/// (예전엔 세 벌이었고 맥·아이패드엔 눌림 글자색과 "완료 ✓"가 없었음 → 아이폰 버전으로 통일)
struct HomeContinueButton: View {
    let next: (chapter: Int, stage: Int)?  // 이어서 할 스테이지 (nil이면 모두 완료)
    let isFirstTime: Bool                   // 진행 기록이 없으면 "시작하기"
    let action: () -> Void                  // 탭 동작 (화면 이동은 호출부가 결정)

    @State private var isPressed = false

    // 다크 버튼 색상 — 라이트: 기존 값 그대로 / 다크: 슬레이트 톤
    private let face = Color.dynamic(light: (0.165, 0.145, 0.125), dark: (72/255, 78/255, 96/255))
    // 눌림 시 앞면 색 — 라이트: #565048 / 다크: 슬레이트를 살짝 밝게
    private let pressedFace = Color.dynamic(light: (86/255, 80/255, 72/255), dark: (88/255, 95/255, 116/255))
    // 눌림 시 글자색 (라이트/다크 공통)
    private let pressedText = Color(red: 213/255, green: 211/255, blue: 209/255)

    var body: some View {
        Button {
            SoundService.shared.play(.buttonTap)
            action()
        } label: {
            SolidThreeDButton(height: 58, cornerRadius: 18, face: face, pressedFace: pressedFace, isPressed: isPressed) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: isFirstTime ? "sparkles" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(isPressed ? pressedText : .white.opacity(0.9))
                        Text(isFirstTime ? "시작하기" : "이어서 하기")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isPressed ? pressedText : .white)
                    }
                    Spacer()
                    // 오른쪽 보조 텍스트 — 첫 실행이면 숨김, 다음 스테이지가 있으면 "1-3", 모두 완료면 "완료 ✓"
                    if !isFirstTime {
                        if let next {
                            Text("\(next.chapter)-\(next.stage)")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(isPressed ? pressedText.opacity(0.6) : .white.opacity(0.55))
                        } else {
                            Text("완료 ✓")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(isPressed ? pressedText.opacity(0.6) : .white.opacity(0.55))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .buttonStyle(.plain)
        .onPressState(isPressed: $isPressed)
    }
}

// MARK: - HomeBrowseButton
/// 홈 "챕터 둘러보기" 크림색 3D 버튼 — 아이폰 홈·아이패드 셸·맥 셸 공용
struct HomeBrowseButton: View {
    let action: () -> Void  // 탭 동작 (화면 이동은 호출부가 결정)

    @State private var isPressed = false

    var body: some View {
        Button {
            SoundService.shared.play(.buttonTap)
            action()
        } label: {
            // 크림 버튼 색상 — 라이트: #fcf9ee 앞면·위 뒷면 / #c4c0b5 아래 뒷면(그림자), 다크: 슬레이트 톤
            SolidThreeDButton(height: 52, cornerRadius: 18,
                              face: Color.dynamic(light: (252/255, 249/255, 238/255), dark: (0.22, 0.23, 0.27)),
                              topBack: Color.dynamic(light: (252/255, 249/255, 238/255), dark: (0.18, 0.19, 0.22)),
                              bottomBack: Color.dynamic(light: (196/255, 192/255, 181/255), dark: (0.13, 0.14, 0.17)),
                              pressedOverlayOpacity: 0.06, isPressed: isPressed) {
                Text("챕터 둘러보기")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .onPressState(isPressed: $isPressed)
    }
}
