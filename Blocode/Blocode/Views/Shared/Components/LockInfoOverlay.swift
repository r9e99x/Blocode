//
//  LockInfoOverlay.swift
//  Blocode
//
//  Created by 조준희 on 6/26/26.
//

import SwiftUI

// MARK: - LockInfo
/// 잠금 안내 팝업에 표시할 내용 (제목 / 조건 문구 / 강조 색)
struct LockInfo: Identifiable {
    let id = UUID()
    var title = "아직 잠겨 있어요"  // 팝업 제목
    let message: String      // 해금 조건 안내 문구
    let accentColor: Color   // 강조 색 (챕터 색)
}

extension Binding where Value == LockInfo? {
    /// 잠금 안내 팝업 띄우기 — 잠금 사운드와 나타나는 효과까지 한 번에
    /// 강조 색은 해금 조건이 되는 챕터의 색 (챕터가 없으면 회색)
    func present(_ hint: (message: String, chapter: ChapterInfo?)) {
        SoundService.shared.play(.lockButton)
        withAnimation(.easeInOut(duration: 0.2)) {
            wrappedValue = LockInfo(message: hint.message, accentColor: hint.chapter?.color ?? .gray)
        }
    }
}

// MARK: - LockInfoOverlay
/// 잠긴 챕터/스테이지를 탭했을 때 해금 조건을 안내하는 커스텀 팝업
/// 배경을 어둡게 덮고 가운데 카드로 조건을 보여줌 (배경 탭 또는 확인 버튼으로 닫음)
struct LockInfoOverlay: View {

    let info: LockInfo       // 표시할 잠금 안내 내용
    let onClose: () -> Void  // 닫기 콜백

    var body: some View {
        ConfirmCardOverlay(icon: "lock.fill", title: info.title, message: info.message,
                           accentColor: info.accentColor, primaryTitle: "확인",
                           onPrimary: onClose, onDismiss: onClose)
    }
}

// MARK: - ConfirmCardOverlay
/// 잠금 안내·확인 팝업이 함께 쓰는 카드 — 딤 배경 + 아이콘 원 + 제목 + 안내 문구 + 3D 주 버튼 (+ 선택적 "취소")
/// (예전엔 두 팝업에 같은 카드 코드가 따로 있었고, 재도전 "다시 하기"에만 탭 효과음이 빠져 있었음)
struct ConfirmCardOverlay: View {
    let icon: String               // 원 안 아이콘 (SF Symbol)
    let title: String              // 제목
    let message: String            // 안내 문구
    let accentColor: Color         // 강조 색 (챕터 색)
    let primaryTitle: String       // 주 버튼 글자
    let onPrimary: () -> Void      // 주 버튼 동작
    let onDismiss: () -> Void      // 배경 탭(과 "취소") 동작
    var showsCancel: Bool = false  // 주 버튼 아래 "취소" 텍스트 버튼 표시 여부


    var body: some View {
        ZStack {
            // 배경 딤 — 탭하면 닫힘
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // 안내 카드
            VStack(spacing: 18) {
                // 아이콘 (원형 배경 + 강조 색)
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.18))
                        .frame(width: 64, height: 64)
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                .padding(.top, 4)

                // 제목
                Text(title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.primary)

                // 안내 문구
                Text(message)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                // 주 버튼 (슬레이트 3D + 눌림 효과) — 라이트: darkInk+탄색 베벨 / 다크: 슬레이트 톤
                PressableButton {
                    SoundService.shared.play(.buttonTap)
                    onPrimary()
                } label: { isPressed in
                    SolidThreeDButton(height: 50, cornerRadius: 25, isPressed: isPressed) {
                        Text(primaryTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 2)

                // "취소" — 보조 액션이라 3D 없이 텍스트로만 (주 버튼과 위계 구분)
                if showsCancel {
                    Button(action: onDismiss) {
                        Text("취소")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .frame(maxWidth: 300)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - 팝업 표시 공용 수정자
/// 값이 있으면 화면 위에 팝업을 띄우고, 닫으면 애니메이션과 함께 값을 nil로 되돌림
private struct ItemPopupModifier<Item, Popup: View>: ViewModifier {
    @Binding var item: Item?
    let popup: (_ item: Item, _ close: @escaping () -> Void) -> Popup

    func body(content: Content) -> some View {
        content.overlay {
            if let item {
                popup(item) {
                    withAnimation(.easeInOut(duration: 0.2)) { self.item = nil }
                }
                .transition(.opacity)
            }
        }
    }
}

extension View {
    /// 잠금 안내 팝업 오버레이 — 값이 있으면 표시, 확인/배경 탭 시 nil로 닫힘
    func lockInfoPopup(_ lockInfo: Binding<LockInfo?>) -> some View {
        modifier(ItemPopupModifier(item: lockInfo) { info, close in
            LockInfoOverlay(info: info, onClose: close)
        })
    }
}

// MARK: - Preview
#Preview {
    LockInfoOverlay(
        info: LockInfo(
            message: "이전 챕터에서 별 12개를 모으고\n종합 스테이지를 클리어하면 열려요",
            accentColor: Color(red: 0.58, green: 0.76, blue: 0.88)
        ),
        onClose: {}
    )
}
