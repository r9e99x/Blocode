//
//  SidebarShell.swift
//  Blocode
//
//  Created by 조준희 on 7/2/26.
//

// 아이패드·맥 공용 최상위 화면 (아이폰은 ContentView의 NavigationStack 화면을 그대로 사용)
// 색상·3D 효과·눌림 효과는 전부 공용 컴포넌트를 재사용 — 맥 전용 부분(윈도우 제목, 툴바 뒤로가기)만 #if로 분기
// 챕터 브라우저(ChapterBrowsePane)와 미리보기 맵(StagePreviewMapView)은 별도 파일
import SwiftUI

// MARK: - SidebarShell
/// 좌측 고정 사이드바(홈/챕터/설정) + 우측 콘텐츠 전환 구조
/// 챕터를 브라우징 중일 때는 사이드바 자리를 챕터 목록이 대신 차지한다(3단 컬럼)
/// 게임 화면(StageView) 진입 시에는 이 셸을 벗어나 전체 화면으로 전환하고,
/// 뒤로가기 시 셸로 복귀한다 (StageView의 onReturnToChapterList로 연결)
struct SidebarShell: View {

    /// 플랫폼별 사이드바 항목 크기 — 아이패드는 터치를 고려해 세로 여백을 넉넉히 줘서 탭 영역을 키움
    private struct ItemMetrics {
        let spacing: CGFloat        // 아이콘-글자 간격
        let iconFontSize: CGFloat   // 아이콘 크기
        let iconWidth: CGFloat      // 아이콘 칸 폭
        let titleFontSize: CGFloat  // 글자 크기
        let verticalPadding: CGFloat
        let cornerRadius: CGFloat

        #if os(macOS)
        static let current = ItemMetrics(spacing: 10, iconFontSize: 14, iconWidth: 18, titleFontSize: 14, verticalPadding: 10, cornerRadius: 10)
        #else
        static let current = ItemMetrics(spacing: 12, iconFontSize: 16, iconWidth: 20, titleFontSize: 15, verticalPadding: 14, cornerRadius: 12)
        #endif
    }

    private let item = ItemMetrics.current

    /// 사이드바 최상위 섹션
    private enum Section: Hashable {
        case home, chapters, myMaps, library, settings
    }

    @State private var section: Section = .home
    /// 챕터 섹션 내부 상태 — nil이면 지그재그 지도, 값이 있으면 해당 챕터의 3단 브라우저
    /// (값이 있을 때는 메인 사이드바 대신 챕터 목록이 그 자리를 대체함)
    @State private var browsingChapter: Int? = nil
    /// 게임 화면(StageView) 진입/복귀 전용 스택 — 사이드바 셸과는 별개의 스택
    @State private var navPath = NavigationPath()

    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var chapterSelectVM = ChapterSelectViewModel()
    @ObservedObject private var settings = SettingsService.shared

    var body: some View {
        NavigationStack(path: $navPath) {
            Group {
                if section == .chapters, let chapter = browsingChapter {
                    // 챕터 브라우징 중 — 메인 사이드바 대신 3단 컬럼(챕터목록|스테이지목록|미리보기)
                    ChapterBrowsePane(
                        chapterNumber: chapter,
                        // 지도↔브라우저 이동과 챕터끼리 전환 모두 전환 효과 없이 즉시 교체 (사용자 요청)
                        onBackToMap: { browsingChapter = nil },
                        onSelectChapter: { newChapter in browsingChapter = newChapter },
                        onStart: { ch, num in navPath.append(AppRoute.stage(chapter: ch, number: num)) }
                    )
                    .id(chapter)  // 챕터 전환 시 뷰 정체성 갱신 → ViewModel/선택 스테이지 초기화
                } else {
                    HStack(spacing: 0) {
                        sidebar
                        Divider()
                        contentPane
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            #if os(macOS)
            .navigationTitle(windowTitle)
            #endif
            // 게임·에디터 화면 — 아이폰 홈과 같은 연결 코드를 함께 씀 (맥 툴바 뒤로가기도 그 안에서 처리)
            .navigationDestination(for: AppRoute.self) { route in
                GameRouteDestination(route: route, navPath: $navPath) {
                    // "챕터 목록으로" 복귀 — 사이드바 셸의 챕터 브라우저로 이동
                    navPath.pop()
                    section = .chapters
                }
            }
        }
        // 복습 알림을 눌렀으면 오늘의 퍼즐로 (앱이 꺼진 채 눌렀을 때는 화면이 준비된 뒤 onAppear에서 처리)
        .onAppear { openPendingDailyPuzzle() }
        .onChange(of: homeVM.hasPendingDailyPuzzle) { _, _ in openPendingDailyPuzzle() }
        .lockInfoPopup($lockInfo)
        .preferredColorScheme(settings.theme.colorScheme)
    }

    /// 열려 있으면 해당 화면으로 이동, 잠겨 있으면 해금 조건 팝업 (잠금 사운드 포함)
    private func openIfUnlocked(_ feature: UnlockableFeature, _ route: AppRoute) {
        if homeVM.isUnlocked(feature) {
            navPath.append(route)
        } else {
            $lockInfo.present(homeVM.lockHint(for: feature))
        }
    }

    /// 대기 중인 알림 이동 요청이 있으면 홈에서 오늘의 퍼즐만 열린 상태로 이동 — 뒤로가면 홈
    private func openPendingDailyPuzzle() {
        guard let route = homeVM.takePendingDailyPuzzleRoute() else { return }
        section = .home
        browsingChapter = nil
        navPath = NavigationPath([route])
    }

    #if os(macOS)
    /// 윈도우 타이틀 바 텍스트 — 현재 섹션/챕터 반영 (맥 전용)
    private var windowTitle: String {
        switch section {
        case .home: return "Blocode"
        case .chapters:
            if let ch = browsingChapter, let info = ChapterCatalog.chapter(ch) {
                return "Blocode — \(info.title)"
            }
            return "Blocode — 챕터"
        case .myMaps: return "Blocode — 내 맵"
        case .library: return "Blocode — 개념 카드"
        case .settings: return "Blocode — 설정"
        }
    }
    #endif

    // MARK: - 사이드바

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 로고
            HStack(spacing: 10) {
                miniLogoIcon
                Text("Blocode")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)

            sidebarItem(icon: "house", title: "홈", isSelected: section == .home) {
                withAnimation(.easeInOut(duration: 0.2)) { section = .home }
            }
            sidebarItem(icon: "square.grid.2x2", title: "챕터", isSelected: section == .chapters) {
                withAnimation(.easeInOut(duration: 0.2)) { section = .chapters }
            }
            sidebarItem(icon: homeVM.isUnlocked(.customMaps) ? "pencil.and.ruler" : "lock.fill",
                        title: "내 맵", isSelected: section == .myMaps) {
                if homeVM.isUnlocked(.customMaps) {
                    withAnimation(.easeInOut(duration: 0.2)) { section = .myMaps }
                } else {
                    $lockInfo.present(homeVM.lockHint(for: .customMaps))
                }
            }
            sidebarItem(icon: "books.vertical", title: "개념 카드", isSelected: section == .library) {
                withAnimation(.easeInOut(duration: 0.2)) { section = .library }
            }
            sidebarItem(icon: "gearshape", title: "설정", isSelected: section == .settings) {
                withAnimation(.easeInOut(duration: 0.2)) { section = .settings }
            }

            Spacer()

            // 하단 통계 요약 (홈 통계와 동일한 데이터 소스)
            statsFooter
                .padding(16)
        }
        .frame(width: 240)
        .background(Color.cardBackground)
    }

    private func sidebarItem(icon: String, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            SoundService.shared.play(.buttonTap)  // iOS 버튼들과 동일하게 탭 효과음
            action()
        } label: {
            HStack(spacing: item.spacing) {
                Image(systemName: icon)
                    .font(.system(size: item.iconFontSize, weight: .semibold))
                    .frame(width: item.iconWidth)
                Text(title)
                    .font(.system(size: item.titleFontSize, weight: .semibold))
                Spacer()
            }
            // 행 전체 폭을 채워야 Spacer가 여백을 차지하고, 그 여백도 탭 가능해짐
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .foregroundStyle(isSelected ? .white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, item.verticalPadding)
            // 선택 항목 — 라이트: 다크 잉크 / 다크: 슬레이트 (고정 darkInk는 다크 배경에 묻혔음)
            .background(isSelected ? Color.slateButtonFace : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: item.cornerRadius))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
    }

    /// 사이드바 로고 아이콘 — 홈 화면 미니 아이콘과 동일한 다이나믹 컬러 사용
    private var miniLogoIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color.characterBody)
            Image(systemName: "arrow.up")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.characterArrow)
        }
        .frame(width: 28, height: 28)
    }

    /// 하단 통계 카드 — 별/연속을 각각 아이콘+굵은값+레이블 한 줄로 표시
    private var statsFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            statsFooterRow(icon: "star.fill", iconColor: Color.starGold,
                           value: "\(homeVM.earnedStars)/\(homeVM.totalPossibleStars)", label: "획득 별")
            statsFooterRow(icon: "flame.fill", iconColor: Color(red: 1.0, green: 0.55, blue: 0.30),
                           value: "\(homeVM.streak)일째", label: "연속")
        }
        .padding(12)
        .background(Color.statCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func statsFooterRow(icon: String, iconColor: Color, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(iconColor)
            Text(value).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    // MARK: - 콘텐츠 패널 (섹션에 따라 전환)

    @ViewBuilder
    private var contentPane: some View {
        Group {
            switch section {
            case .home:
                homeContent
            case .chapters:
                // browsingChapter가 nil일 때만 이 분기로 오므로 항상 지도
                chapterMapContent
            case .myMaps:
                CustomMapListView(
                    onNew: { navPath.append(AppRoute.mapEditor(nil)) },
                    onPlay: { navPath.append(AppRoute.customMapPlay($0)) },
                    onEdit: { navPath.append(AppRoute.mapEditor($0)) }
                )
            case .library:
                LearningLibraryView()
            case .settings:
                SettingsView(isEmbedded: true)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.18), value: section)
    }

    // MARK: - 홈 콘텐츠

    /// 상단(인용구+통계)은 창 크기에 맞춰 유연하게 리플로우되고,
    /// 버튼은 항상 화면 맨 아래 중앙에 고정
    private var homeContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("오늘의 한 줄").font(.system(size: 13)).foregroundStyle(.secondary)
                    Text(homeVM.dailyQuote.joined)  // 매일 바뀌는 문구
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .italic()
                    Text(homeVM.dynamicSubtitle)
                        .font(.system(size: 14)).foregroundStyle(.secondary)
                        .padding(.top, 6)

                    HStack(spacing: 12) {
                        statCard(icon: "star.fill", color: Color.starGold,
                                 value: "\(homeVM.earnedStars)/\(homeVM.totalPossibleStars)", label: "획득 별")
                        statCard(icon: "checkmark.seal.fill", color: Color(red: 0.576, green: 0.788, blue: 0.671),
                                 value: "\(homeVM.completedChapters)/\(homeVM.chapterCount)", label: "챕터 완료")
                        statCard(icon: "flame.fill", color: Color(red: 1.0, green: 0.55, blue: 0.30),
                                 value: "\(homeVM.streak)일째", label: "연속")
                    }
                    .padding(.top, 32)

                    // 오늘의 퍼즐 카드 — 누르면 일일 퍼즐, 주사위는 랜덤 퍼즐
                    DailyPuzzleCard(info: homeVM.dailyPuzzle,
                                    isLocked: !homeVM.isUnlocked(.dailyPuzzle),
                                    onDaily: { openIfUnlocked(.dailyPuzzle, AppRoute.dailyPuzzle(homeVM.dailyPuzzle.key)) },
                                    onRandom: { openIfUnlocked(.dailyPuzzle, AppRoute.newRandomPuzzle()) })
                        .padding(.top, 14)
                }
                .padding(48)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 버튼 영역 — 스크롤 밖, 화면 맨 아래 중앙에 고정
            VStack(spacing: 12) {
                // 홈 버튼 2개 — 아이폰 홈과 공용 부품 (모두 완료면 챕터 지도로)
                HomeContinueButton(next: homeVM.nextStage, isFirstTime: homeVM.isFirstTime) {
                    if let next = homeVM.nextStage {
                        navPath.append(AppRoute.stage(chapter: next.chapter, number: next.stage))
                    } else {
                        section = .chapters
                    }
                }
                HomeBrowseButton { section = .chapters }
            }
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 48)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    private func statCard(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded))
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.statCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        // iOS statCard와 동일한 그림자
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - 챕터 지도 (지그재그 + 3D + 눌림 + 잠금 팝업)

    /// 잠긴 챕터·잠긴 기능(내 맵, 일일 퍼즐)을 눌렀을 때의 해금 조건 팝업 — 셸 전체에서 하나를 공유
    @State private var lockInfo: LockInfo? = nil

    private var chapterMapContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 제목 — 스크롤 밖에 고정해 항상 좌상단에 위치 (스크롤해도 안 움직임)
            VStack(alignment: .leading, spacing: 4) {
                Text("여정").font(.system(size: 13)).foregroundStyle(.secondary)
                Text("chapter map")
                    .font(.system(size: 30, weight: .bold, design: .serif)).italic()
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)
            .padding(.bottom, 20)

            // 지도는 세로 스크롤 (iOS 챕터 지도와 동일한 방향 — 예전엔 가로 스크롤이었으나
            // 챕터가 10개로 늘면서 카드가 옆으로 계속 넓어지는 게 부자연스러워 세로 지그재그로 변경)
            ScrollView(.vertical, showsIndicators: false) {
                // 지그재그 챕터 지도 (아이폰 챕터 선택과 공용 부품)
                ChapterMapView(vm: chapterSelectVM,
                               metrics: .init(cardSize: 100, rowSpacing: 172, cornerRadius: 24, numberFontSize: 40, lockFontSize: 24),
                               lockInfo: $lockInfo) { browsingChapter = $0 }
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Preview

#if os(macOS)
#Preview("셸 홈") {
    SidebarShell()
        .frame(width: 1280, height: 860)
}
#else
#Preview("셸 홈", traits: .landscapeLeft) {
    SidebarShell()
}
#endif
