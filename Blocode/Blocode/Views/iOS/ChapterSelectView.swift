//
//  ChapterSelectView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

// 아이폰 챕터 선택 — iOS 전용 (맥은 SidebarShell과 상단바 컨트롤을 사용하므로 컴파일에서 제외)
#if os(iOS)
import SwiftUI

// MARK: - ChapterSelectView
/// 모든 챕터를 지그재그 맵 형태로 표시하는 화면
struct ChapterSelectView: View {

    @Binding var navPath: NavigationPath  // 뒤로가기 및 다음 화면 이동용

    /// 챕터 선택 화면 상태/로직 — 챕터 목록·잠금·별점 계산은 ViewModel이 담당 (MVVM)
    @StateObject private var vm = ChapterSelectViewModel()

    /// 스크롤 시 헤더 축소 여부
    @State private var isCompact        = false
    @State private var lockInfo: LockInfo? = nil     // 잠금 안내 팝업 (nil이면 숨김)

    var body: some View {
        VStack(spacing: 0) {
            // 고정 헤더 — 스크롤 내려가면 축소
            header

            // 챕터 맵 스크롤 영역
            ScrollView(showsIndicators: false) {
                // 와이드 화면(아이패드·맥)에선 지그재그 맵을 중앙 680pt로 제한 (아이폰에선 영향 없음)
                // 지그재그 챕터 지도 (아이패드·맥 셸과 공용 부품) — 아이폰만 진행 배지 표시
                ChapterMapView(vm: vm,
                               metrics: .init(cardSize: 90, rowSpacing: 158, cornerRadius: 26, numberFontSize: 48, lockFontSize: 28),
                               showsProgressBadge: true,
                               lockInfo: $lockInfo) { navPath.append(AppRoute.chapter($0)) }
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
            }
            // 스크롤 위치에 따라 헤더 축소 상태 갱신
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { _, newY in
                withAnimation(.easeInOut(duration: 0.18)) {
                    isCompact = newY > 30  // 30pt 이상 스크롤 시 축소
                }
            }
        }
        .hideNavigationBar()  // iOS 전용 API 래퍼 (macOS no-op)
        .background(Color.appBackground.ignoresSafeArea())
        // 잠긴 챕터 탭 시 해금 조건 팝업 (표시 패턴은 공용 모디파이어)
        .lockInfoPopup($lockInfo)
    }

    // MARK: - 헤더 (고정 + 스크롤 시 축소)

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                // 스크롤 시 "여정" 레이블 숨김 (애니메이션 포함)
                if !isCompact {
                    Text("여정")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                // 타이틀 — 축소 시 폰트 크기 줄어듦
                Text("chapter map")
                    .font(.system(
                        size: isCompact ? 22 : 34,
                        weight: .bold,
                        design: .serif
                    ))
                    .italic()
                    .foregroundStyle(.primary)
            }
            .animation(.easeInOut(duration: 0.18), value: isCompact)

            Spacer()

            // 홈 버튼 — NavigationStack에서 한 단계 뒤로
            Button {
                SoundService.shared.play(.buttonTap)
                navPath.pop()
            } label: {
                Image(systemName: "house")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.secondary)  // UIColor.secondaryLabel과 동일 톤 (크로스플랫폼)
                    .frame(width: 36, height: 36)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        // 와이드 화면에선 헤더 콘텐츠도 맵과 같은 680pt로 제한해 정렬 유지 (아이폰 영향 없음)
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, isCompact ? 14 : 24)
        .animation(.easeInOut(duration: 0.18), value: isCompact)
        .background(Color.appBackground)
        // 축소 시 구분 그림자 표시
        .shadow(
            color: Color.black.opacity(isCompact ? 0.07 : 0),
            radius: 8, x: 0, y: 4
        )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var path = NavigationPath()
    ChapterSelectView(navPath: $path)
}
#endif
