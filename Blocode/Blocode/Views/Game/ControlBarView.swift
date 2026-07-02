//
//  ControlBarView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - ControlBarView
/// 게임 화면 하단 컨트롤 바 — 리셋 / 실행 / 설정 버튼 3개
/// GameViewModel을 통해 게임 상태를 제어하고,
/// 설정 초기화 시 navPath를 통해 홈으로 이동
struct ControlBarView: View {

    @ObservedObject var viewModel: GameViewModel  // 게임 상태/액션 제어
    @Binding var navPath: NavigationPath          // 설정 초기화 시 홈 복귀용

    /// 다크/라이트 모드 감지 — 되돌리기/설정 버튼의 베벨 강도를 다크에서만 낮추는 데 사용
    @Environment(\.colorScheme) private var colorScheme

    // 각 버튼의 눌림 상태 (3D 효과용)
    @State private var isResetPressed    = false
    @State private var isRunPressed      = false
    @State private var isSettingsPressed = false

    /// 설정 시트 표시 여부
    @State private var showSettings = false

    // MARK: - 실행 버튼 색상

    /// 실행 버튼 색상 — 비활성/실행 중: 따뜻한 회색(모드 무관 기존 값 유지) / 활성: 민트 그린(다크에서만 톤 다운)
    private var runButtonColor: Color {
        viewModel.codeBlocks.isEmpty || viewModel.gameState == .running
            ? Color(red: 0.72, green: 0.70, blue: 0.67) // 솔리드 따뜻한 회색 — 그대로 유지
            : Color.runButtonActiveMint  // 활성 민트 (라이트: 기존 accentMint / 다크: 딥 민트)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {

            // 왼쪽: 리셋 / 전체 초기화 버튼
            // 앞면: 다크에서 배경에 묻히지 않는 슬레이트 / 베벨: 다크에서만 강도 완화 (라이트는 기존 그대로)
            Button {
                if viewModel.characterMoved { viewModel.reset() }
                else { viewModel.fullReset() }
            } label: {
                button3D(color: Color.controlIconButtonFace, width: 54, height: 54, cornerRadius: 17,
                         topOverlayOpacity: colorScheme == .dark ? 0.12 : 0.28,
                         bottomOverlayOpacity: colorScheme == .dark ? 0.30 : 0.22,
                         isPressed: isResetPressed) {
                    Image(systemName: viewModel.characterMoved ? "arrow.uturn.backward" : "arrow.counterclockwise")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.gameState == .running)
            .onPressState(isPressed: $isResetPressed)
            .frame(maxWidth: .infinity)

            // 가운데: 실행 버튼
            Button { viewModel.run() } label: {
                button3D(color: runButtonColor, width: 152, height: 54, cornerRadius: 27,
                         isPressed: isRunPressed) {
                    HStack(spacing: 8) {
                        if viewModel.gameState == .running {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .bold))
                        }
                        Text(viewModel.gameState == .running ? "실행 중" : "실행")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .allowsHitTesting(!(viewModel.codeBlocks.isEmpty || viewModel.gameState == .running))
            .onPressState(isPressed: $isRunPressed)
            .animation(.easeInOut(duration: 0.15), value: viewModel.gameState)

            // 오른쪽: 설정 버튼
            // 앞면/베벨 색상 규칙은 리셋 버튼과 동일 (다크에서만 조정, 라이트는 기존 그대로)
            Button { showSettings = true } label: {
                button3D(color: Color.controlIconButtonFace, width: 54, height: 54, cornerRadius: 17,
                         topOverlayOpacity: colorScheme == .dark ? 0.12 : 0.28,
                         bottomOverlayOpacity: colorScheme == .dark ? 0.30 : 0.22,
                         isPressed: isSettingsPressed) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.gameState == .running)
            .onPressState(isPressed: $isSettingsPressed)
            .frame(maxWidth: .infinity)
            // 설정 화면 — 진행도 초기화 시 홈으로 이동
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView(onResetProgress: {
                    navPath = NavigationPath()  // 스택 초기화로 홈 복귀
                })
                .preferredColorScheme(SettingsService.shared.theme.colorScheme)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 3D 버튼 헬퍼

    /// 3D 레이어 버튼 — 뒷면 2개 + 앞면 1개 구조
    /// isPressed 시 뒷면이 사라지고 앞면이 아래 뒷면 위치까지 내려감
    /// topOverlayOpacity/bottomOverlayOpacity: 베벨 강도 (기본값 = 기존 고정값 0.28/0.22 —
    /// 실행 버튼은 기본값 그대로 사용, 되돌리기/설정 버튼만 다크에서 조정된 값을 전달)
    @ViewBuilder
    private func button3D<Content: View>(
        color: Color,
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat,
        topDepth: CGFloat = 2,
        botDepth: CGFloat = 2.5,
        topOverlayOpacity: Double = 0.28,
        bottomOverlayOpacity: Double = 0.22,
        isPressed: Bool = false,
        @ViewBuilder label: @escaping () -> Content
    ) -> some View {
        // 3D 뼈대(쌓기 + 눌림 효과)는 ThreeDSurface가 담당, 각 면 내용만 전달
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
