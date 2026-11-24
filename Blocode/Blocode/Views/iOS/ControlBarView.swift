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

    var viewModel: GameViewModel  // 게임 상태/액션 제어

    /// 다크/라이트 모드 감지 — 되돌리기/설정 버튼의 베벨 강도를 다크에서만 낮추는 데 사용
    @Environment(\.colorScheme) private var colorScheme

    /// 설정 시트 표시 여부
    @State private var showSettings = false

    // MARK: - 실행 버튼 색상

    /// 실행 버튼 색상 — 비활성/실행 중: 따뜻한 회색(모드 무관 기존 값 유지) / 활성: 민트 그린(다크에서만 톤 다운)
    private var runButtonColor: Color {
        viewModel.isRunButtonActive
            ? Color.runButtonActiveMint  // 활성 민트 (라이트: 기존 accentMint / 다크: 딥 민트)
            : Color.runButtonInactiveGray  // 솔리드 따뜻한 회색 — 값은 기존과 동일 (AppColors로 단일화)
    }

    // MARK: - 아이콘 버튼

    /// 버튼 한 변(실행 버튼의 높이도 같음) — 아이패드는 손가락·화면에 맞춰 키움
    private var iconSide: CGFloat { isPadIdiom ? 62 : 54 }

    /// 되돌리기·한 칸씩·설정에 쓰는 정사각 3D 아이콘 버튼 (예전엔 같은 설정을 세 번 복사해 썼음)
    /// 앞면: 다크에서 배경에 묻히지 않는 슬레이트 / 베벨: 다크에서만 강도 완화 (라이트는 기존 그대로)
    private func iconButton(icon: String, size: CGFloat, tint: Color = .secondary,
                            action: @escaping () -> Void) -> some View {
        PressableButton {
            SoundService.shared.play(.buttonTap)
            action()
        } label: { isPressed in
            Bevel3DButtonLabel(color: Color.controlIconButtonFace, width: iconSide, height: iconSide, cornerRadius: isPadIdiom ? 19 : 17,
                               topOverlayOpacity: colorScheme == .dark ? 0.12 : 0.28,
                               bottomOverlayOpacity: colorScheme == .dark ? 0.30 : 0.22,
                               isPressed: isPressed) {
                Image(systemName: icon)
                    .font(.system(size: size, weight: .medium))
                    .foregroundStyle(tint)  // 기본 secondary — UIColor.secondaryLabel과 동일 톤
            }
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {

            // 왼쪽: 리셋 / 전체 초기화 버튼
            iconButton(icon: viewModel.characterMoved ? "arrow.uturn.backward" : "arrow.counterclockwise", size: 20) {
                viewModel.resetOrClear()
            }
            .disabled(viewModel.isRunningContinuously)  // 단계별 실행 중에는 리셋으로 멈출 수 있음
            .frame(maxWidth: .infinity)

            // 가운데: 실행 버튼
            PressableButton {
                SoundService.shared.play(.buttonTap)
                viewModel.runOrContinue()  // 단계별 중에는 남은 블럭을 이어서 실행
            } label: { isPressed in
                Bevel3DButtonLabel(color: runButtonColor, width: isPadIdiom ? 200 : 152, height: iconSide, cornerRadius: iconSide / 2,
                                   isPressed: isPressed) {
                    HStack(spacing: 8) {
                        if viewModel.isRunningContinuously {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .bold))
                        }
                        Text(viewModel.runButtonTitle)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                }
            }
            .allowsHitTesting(viewModel.isRunButtonActive)
            .animation(.easeInOut(duration: 0.15), value: viewModel.gameState)

            // 한 칸씩 실행 — 누를 때마다 강조된 블럭 하나만 실행
            iconButton(icon: "forward.end.fill", size: 18,
                       tint: viewModel.isStepping ? Color.runButtonActiveMint : Color.secondary) {
                viewModel.step()
            }
            .disabled(!viewModel.canStep)
            .opacity(viewModel.canStep ? 1 : 0.45)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(viewModel.isStepping ? "다음 블럭 실행" : "한 칸씩 실행")

            // 오른쪽: 설정 버튼
            iconButton(icon: "gearshape", size: 20) {
                showSettings = true
            }
            .disabled(viewModel.gameState == .running)
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
