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

    // 각 버튼의 눌림 상태 (3D 효과용)
    @State private var isResetPressed    = false
    @State private var isRunPressed      = false
    @State private var isSettingsPressed = false

    /// 설정 시트 표시 여부
    @State private var showSettings = false

    // MARK: - 실행 버튼 색상

    /// 실행 버튼 색상 — 비활성/실행 중: 따뜻한 회색 / 활성: 민트 그린
    private var runButtonColor: Color {
        viewModel.codeBlocks.isEmpty || viewModel.gameState == .running
            ? Color(red: 0.72, green: 0.70, blue: 0.67) // 솔리드 따뜻한 회색
            : Color(red: 0.27, green: 0.72, blue: 0.58)  // 민트 그린 (활성)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {

            // 왼쪽: 리셋 / 전체 초기화 버튼
            Button {
                if viewModel.characterMoved { viewModel.reset() }
                else { viewModel.fullReset() }
            } label: {
                button3D(color: Color.panelBackground, width: 54, height: 54, cornerRadius: 17,
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
            Button { showSettings = true } label: {
                button3D(color: Color.panelBackground, width: 54, height: 54, cornerRadius: 17,
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
    @ViewBuilder
    private func button3D<Content: View>(
        color: Color,
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat,
        topDepth: CGFloat = 2,
        botDepth: CGFloat = 2.5,
        isPressed: Bool = false,
        @ViewBuilder label: () -> Content
    ) -> some View {
        ZStack(alignment: .top) {
            // ① 위 뒷면 — 눌리면 사라짐
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius).fill(color)
                RoundedRectangle(cornerRadius: cornerRadius).fill(Color.white.opacity(0.28))
            }
            .frame(width: width, height: height)
            .opacity(isPressed ? 0 : 1)

            // ② 아래 뒷면 — 눌리면 사라짐
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius).fill(color)
                RoundedRectangle(cornerRadius: cornerRadius).fill(Color.black.opacity(0.22))
            }
            .frame(width: width, height: height)
            .offset(y: topDepth + botDepth)
            .opacity(isPressed ? 0 : 1)

            // ③ 앞면 — 눌리면 아래 뒷면 자리까지 완전히 내려감
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius).fill(color)
                if isPressed {
                    RoundedRectangle(cornerRadius: cornerRadius).fill(Color.black.opacity(0.10))
                }
                label()
            }
            .frame(width: width, height: height)
            .offset(y: isPressed ? topDepth + botDepth : topDepth)
        }
        .frame(width: width, height: height + topDepth + botDepth)
    }
}
