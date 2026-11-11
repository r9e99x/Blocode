//
//  ControlBarView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

// 아이폰·아이패드 하단 컨트롤 바 — iOS 전용 (맥은 SidebarShell과 상단바 컨트롤을 사용하므로 컴파일에서 제외)
#if os(iOS)
import SwiftUI

// MARK: - ControlBarView
/// 게임 화면 하단 컨트롤 바 — 리셋 / 실행 / 설정 버튼 3개
/// GameViewModel을 통해 게임 상태를 제어
struct ControlBarView: View {

    @ObservedObject var viewModel: GameViewModel  // 게임 상태/액션 제어

    /// 다크/라이트 모드 감지 — 되돌리기/설정 버튼의 베벨 강도를 다크에서만 낮추는 데 사용
    @Environment(\.colorScheme) private var colorScheme

    // 각 버튼의 눌림 상태 (3D 효과용)
    @State private var isResetPressed    = false
    @State private var isRunPressed      = false
    @State private var isStepPressed     = false
    @State private var isSettingsPressed = false

    /// 설정 시트 표시 여부
    @State private var showSettings = false

    // MARK: - 실행 버튼 색상

    /// 실행 버튼 색상 — 비활성/실행 중: 따뜻한 회색(모드 무관 기존 값 유지) / 활성: 민트 그린(다크에서만 톤 다운)
    private var runButtonColor: Color {
        (viewModel.canPressRun || viewModel.isStepping)
            ? Color.runButtonActiveMint  // 활성 민트 (라이트: 기존 accentMint / 다크: 딥 민트)
            : Color.runButtonInactiveGray  // 솔리드 따뜻한 회색 — 값은 기존과 동일 (AppColors로 단일화)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {

            // 왼쪽: 리셋 / 전체 초기화 버튼
            // 앞면: 다크에서 배경에 묻히지 않는 슬레이트 / 베벨: 다크에서만 강도 완화 (라이트는 기존 그대로)
            Button {
                SoundService.shared.play(.buttonTap)
                viewModel.resetOrClear()
            } label: {
                Bevel3DButtonLabel(color: Color.controlIconButtonFace, width: 54, height: 54, cornerRadius: 17,
                                   topOverlayOpacity: colorScheme == .dark ? 0.12 : 0.28,
                                   bottomOverlayOpacity: colorScheme == .dark ? 0.30 : 0.22,
                                   isPressed: isResetPressed) {
                    Image(systemName: viewModel.characterMoved ? "arrow.uturn.backward" : "arrow.counterclockwise")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.secondary)  // UIColor.secondaryLabel과 동일 톤 (크로스플랫폼)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.gameState == .running && !viewModel.isStepping)  // 단계별 실행 중에는 리셋으로 멈출 수 있음
            .onPressState(isPressed: $isResetPressed)
            .frame(maxWidth: .infinity)

            // 가운데: 실행 버튼
            Button {
                SoundService.shared.play(.buttonTap)
                if viewModel.isStepping { viewModel.continueRun() } else { viewModel.run() }  // 단계별 중에는 남은 블럭을 이어서 실행
            } label: {
                Bevel3DButtonLabel(color: runButtonColor, width: 152, height: 54, cornerRadius: 27,
                                   isPressed: isRunPressed) {
                    HStack(spacing: 8) {
                        if viewModel.gameState == .running && !viewModel.isStepping {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .bold))
                        }
                        Text(viewModel.isStepping ? "계속" : (viewModel.gameState == .running ? "실행 중" : "실행"))
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .allowsHitTesting(viewModel.canPressRun || viewModel.isStepping)
            .onPressState(isPressed: $isRunPressed)
            .animation(.easeInOut(duration: 0.15), value: viewModel.gameState)

            // 한 칸씩 실행 — 누를 때마다 강조된 블럭 하나만 실행
            Button {
                SoundService.shared.play(.buttonTap)
                viewModel.step()
            } label: {
                Bevel3DButtonLabel(color: Color.controlIconButtonFace, width: 54, height: 54, cornerRadius: 17,
                                   topOverlayOpacity: colorScheme == .dark ? 0.12 : 0.28,
                                   bottomOverlayOpacity: colorScheme == .dark ? 0.30 : 0.22,
                                   isPressed: isStepPressed) {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(viewModel.isStepping ? Color.runButtonActiveMint : Color.secondary)
                }
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canStep)
            .opacity(viewModel.canStep ? 1 : 0.45)
            .onPressState(isPressed: $isStepPressed)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(viewModel.isStepping ? "다음 블럭 실행" : "한 칸씩 실행")

            // 오른쪽: 설정 버튼
            // 앞면/베벨 색상 규칙은 리셋 버튼과 동일 (다크에서만 조정, 라이트는 기존 그대로)
            Button {
                SoundService.shared.play(.buttonTap)
                showSettings = true
            } label: {
                Bevel3DButtonLabel(color: Color.controlIconButtonFace, width: 54, height: 54, cornerRadius: 17,
                                   topOverlayOpacity: colorScheme == .dark ? 0.12 : 0.28,
                                   bottomOverlayOpacity: colorScheme == .dark ? 0.30 : 0.22,
                                   isPressed: isSettingsPressed) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.secondary)  // UIColor.secondaryLabel과 동일 톤 (크로스플랫폼)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.gameState == .running)
            .onPressState(isPressed: $isSettingsPressed)
            .frame(maxWidth: .infinity)
            // 설정 화면 (iOS: fullScreenCover / macOS: sheet)
            .fullScreenCoverCompat(isPresented: $showSettings) {
                SettingsView()
                .preferredColorScheme(SettingsService.shared.theme.colorScheme)
            }
        }
        .padding(.horizontal, 20)
    }

    // 참고: 3D 버튼 렌더링은 공용 컴포넌트 Bevel3DButtonLabel(Views/Components)이 담당
    // (기존 이 파일의 button3D를 컴포넌트로 승격 — 맥 상단바 컨트롤과 공용)
}
#endif
