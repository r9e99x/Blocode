//
//  ChapterSelectView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

// 아이폰 전용 챕터 선택 (아이패드는 PadShell의 챕터 탭, 맥은 SidebarShell의 챕터 지도를 사용)
#if os(iOS)
import SwiftUI

// MARK: - ChapterSelectView
/// 모든 챕터를 지그재그 맵 형태로 표시하는 화면
struct ChapterSelectView: View {

    @Binding var navPath: NavigationPath  // 뒤로가기 및 다음 화면 이동용
    /// 아래 시트로 열린 챕터 — 지도에서 장을 누르거나, 클리어 뒤 "챕터 목록으로"로 셸이 채움 (nil이면 시트 닫힘)
    @Binding var presentedChapter: Int?
    /// 오른쪽 위 홈 버튼 — 탭 막대 셸(챕터 탭 첫 화면)에선 탭으로 이동하므로 숨김
    var showsHomeButton = true

    /// 챕터 선택 화면 상태/로직 — 챕터 목록·잠금·별점 계산은 ViewModel이 담당 (MVVM)
    @State private var vm = ChapterSelectViewModel()

    /// 스크롤 시 헤더 축소 여부
    @State private var isCompact        = false
    @State private var lockInfo: LockInfo? = nil     // 잠금 안내 팝업 (nil이면 숨김)
    /// 시트에서 고른 스테이지 — 시트가 다 닫힌 뒤에 게임 화면을 올림 (시트가 떠 있는 채로 화면을 올리면 전환이 꼬임)
    @State private var pendingStage: (chapter: Int, stage: Int)?
    /// 게임을 시작한 챕터 — 게임에서 돌아오면 그 챕터 시트를 다시 열어 줌
    @State private var lastChapter: Int?

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
                               lockInfo: $lockInfo) { presentedChapter = $0 }
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
            }
            // 스크롤 위치에 따라 헤더 축소 상태 갱신
            // 스크롤 위치를 "30pt 넘었는지"로 바꿔 받아서, 넘을 때와 돌아올 때만 알림이 옴 (예전엔 스크롤 매 프레임 알림)
            .onScrollGeometryChange(for: Bool.self) { geo in
                geo.contentOffset.y > 30
            } action: { _, scrolled in
                withAnimation(.easeInOut(duration: 0.18)) {
                    isCompact = scrolled  // 30pt 이상 스크롤 시 축소
                }
            }
        }
        .hideNavigationBar()  // iOS 전용 API 래퍼 (macOS no-op)
        .background(Color.appBackground.ignoresSafeArea())
        // 잠긴 챕터 탭 시 해금 조건 팝업 (표시 패턴은 공용 모디파이어)
        .lockInfoPopup($lockInfo)
        // 챕터 시트 — 장을 누르면 아래에서 올라옴 (예전엔 챕터 화면으로 넘어갔음)
        .sheet(isPresented: Binding(get: { presentedChapter != nil },
                                    set: { if !$0 { presentedChapter = nil } }),
               onDismiss: startPendingStage) {
            if let chapter = presentedChapter {
                PhoneChapterSheet(chapterNumber: chapter) { stage in
                    pendingStage = (chapter, stage)
                    presentedChapter = nil  // 시트를 닫고, 다 닫히면 onDismiss에서 게임을 올림
                }
            }
        }
        // 게임에서 지도로 돌아오면 방금 하던 챕터 시트를 다시 열어 줌
        .onChange(of: navPath.isEmpty) { _, isEmpty in
            if isEmpty, let chapter = lastChapter {
                presentedChapter = chapter
                lastChapter = nil
            }
        }
    }

    /// 시트가 다 닫힌 뒤 — 고른 스테이지가 있으면 게임 화면을 올림
    private func startPendingStage() {
        guard let pending = pendingStage else { return }
        pendingStage = nil
        lastChapter = pending.chapter
        navPath.append(AppRoute.stage(chapter: pending.chapter, number: pending.stage))
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
            if showsHomeButton {
                Button {
                    SoundService.shared.play(.buttonTap)
                    navPath.pop()
                } label: {
                    CardIconLabel(icon: "house", fontSize: 14, background: .cardBackground, shadowOpacity: 0.08, shadowY: 2)
                }
                .buttonStyle(.plain)
            }
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
    @Previewable @State var chapter: Int? = nil
    ChapterSelectView(navPath: $path, presentedChapter: $chapter)
}
#endif
