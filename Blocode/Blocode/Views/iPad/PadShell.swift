//
//  PadShell.swift
//  Blocode
//
//  Created by 조준희 on 11/24/26.
//

// 아이패드 전용 최상위 화면 — 맥은 SidebarShell, 아이폰은 ContentView를 그대로 씀
#if os(iOS)
import SwiftUI

// MARK: - PadShell
/// 아이패드OS 기본 탭 막대(위에 떠 있는 막대, 필요하면 사이드바로 펼침)로 화면을 나눔
/// 예전엔 맥과 같은 고정 사이드바(240pt)를 써서 세로 화면에서도 내용이 좁고 빈 공간이 많았음
/// 탭마다 자기 내비게이션 스택을 가지며, 게임·에디터 화면에 들어가면 탭 막대를 숨김
struct PadShell: View {

    /// 탭 종류 (SwiftUI의 Tab 타입과 이름이 겹치지 않게 PadTab)
    enum PadTab: Hashable {
        case home, chapters, myMaps, library, settings
    }

    @State private var tab: PadTab = .home
    /// 탭별 내비게이션 스택 — 게임·에디터 화면을 올림
    @State private var homePath = NavigationPath()
    @State private var chaptersPath = NavigationPath()
    @State private var myMapsPath = NavigationPath()
    /// 챕터 탭에서 보고 있는 챕터 — nil이면 챕터 지도
    @State private var browsingChapter: Int? = nil

    @State private var homeVM = HomeViewModel()
    @State private var chapterSelectVM = ChapterSelectViewModel()
    /// 잠긴 챕터·기능을 눌렀을 때의 해금 조건 팝업 — 셸 전체에서 하나를 공유
    @State private var lockInfo: LockInfo? = nil
    private let settings = SettingsService.shared  // @Observable — 테마를 읽기만 해도 바뀔 때 다시 그려짐

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("홈", systemImage: "house", value: PadTab.home) {
                NavigationStack(path: $homePath) {
                    PadHomeView(vm: homeVM, chapterSelectVM: chapterSelectVM, lockInfo: $lockInfo,
                                open: { homePath.append($0) },
                                showChapters: showChapters)
                        .padGameDestinations(path: $homePath, onReturnToChapterList: returnToChapters)
                }
            }

            Tab("챕터", systemImage: "square.grid.2x2", value: PadTab.chapters) {
                NavigationStack(path: $chaptersPath) {
                    chaptersContent
                        .padGameDestinations(path: $chaptersPath, onReturnToChapterList: returnToChapters)
                }
            }

            Tab("나만의 맵", systemImage: homeVM.isUnlocked(.customMaps) ? "pencil.and.ruler" : "lock.fill",
                value: PadTab.myMaps) {
                NavigationStack(path: $myMapsPath) {
                    CustomMapListView(
                        onNew: { myMapsPath.append(AppRoute.mapEditor(nil)) },
                        onPlay: { myMapsPath.append(AppRoute.customMapPlay($0)) },
                        onEdit: { myMapsPath.append(AppRoute.mapEditor($0)) }
                    )
                    .background(Color.appBackground.ignoresSafeArea())
                    .padGameDestinations(path: $myMapsPath, onReturnToChapterList: returnToChapters)
                }
            }

            Tab("개념 카드", systemImage: "books.vertical", value: PadTab.library) {
                LearningLibraryView()
                    .background(Color.appBackground.ignoresSafeArea())
            }

            Tab("설정", systemImage: "gearshape", value: PadTab.settings) {
                SettingsView(isEmbedded: true)
                    .background(Color.appBackground.ignoresSafeArea())
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        // 사이드바로 펼쳤을 때 위에는 로고, 아래에는 별·연속 요약 (맥 사이드바와 같은 내용)
        .tabViewSidebarHeader { sidebarLogo }
        .tabViewSidebarBottomBar { sidebarStats }
        // 복습 알림을 눌렀으면 오늘의 퍼즐로 (앱이 꺼진 채 눌렀을 때는 화면이 준비된 뒤 onAppear에서 처리)
        .onAppear { openPendingDailyPuzzle() }
        .onChange(of: homeVM.hasPendingDailyPuzzle) { _, _ in openPendingDailyPuzzle() }
        .lockInfoPopup($lockInfo)
        .preferredColorScheme(settings.theme.colorScheme)
    }

    // MARK: - 탭 선택

    /// 탭 선택 — 잠긴 "나만의 맵"은 탭을 바꾸지 않고 해금 조건 팝업만 띄움 (잠금 사운드 포함)
    private var tabSelection: Binding<PadTab> {
        Binding(
            get: { tab },
            set: { newTab in
                if newTab == .myMaps && !homeVM.isUnlocked(.customMaps) {
                    $lockInfo.present(homeVM.lockHint(for: .customMaps))
                } else {
                    if newTab != tab { SoundService.shared.play(.buttonTap) }  // 다른 버튼들과 같은 탭 효과음
                    tab = newTab
                }
            }
        )
    }

    /// 챕터 탭으로 이동 — 챕터 번호가 있으면 그 챕터 화면, 없으면 챕터 지도
    private func showChapters(_ chapter: Int?) {
        browsingChapter = chapter
        tab = .chapters
    }

    /// 클리어 뒤 "챕터 목록으로" — 게임을 띄운 탭의 스택을 비우고 그 스테이지의 챕터 화면으로
    private func returnToChapters(_ chapter: Int?) {
        switch tab {
        case .home: homePath = NavigationPath()
        case .chapters: chaptersPath = NavigationPath()
        case .myMaps: myMapsPath = NavigationPath()
        case .library, .settings: break
        }
        showChapters(chapter ?? browsingChapter)
    }

    /// 대기 중인 알림 이동 요청이 있으면 홈 탭에서 오늘의 퍼즐만 열린 상태로 이동 — 뒤로가면 홈
    private func openPendingDailyPuzzle() {
        guard let route = homeVM.takePendingDailyPuzzleRoute() else { return }
        tab = .home
        homePath = NavigationPath([route])
    }

    // MARK: - 챕터 탭

    /// 챕터 지도 ↔ 챕터 화면 (전환 효과 없이 즉시 교체 — 맥 셸과 같은 동작)
    @ViewBuilder
    private var chaptersContent: some View {
        if let chapter = browsingChapter {
            ChapterBrowsePane(
                chapterNumber: chapter,
                onBackToMap: { browsingChapter = nil },
                onSelectChapter: { browsingChapter = $0 },
                onStart: { ch, num in chaptersPath.append(AppRoute.stage(chapter: ch, number: num)) }
            )
            .id(chapter)  // 챕터 전환 시 뷰 정체성 갱신 → ViewModel/선택 스테이지 초기화
            .background(Color.appBackground.ignoresSafeArea())
        } else {
            chapterMap
        }
    }

    /// 지그재그 챕터 지도 (아이폰·맥과 같은 공용 부품)
    private var chapterMap: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 4) {
                Text("여정").font(.system(size: 13)).foregroundStyle(.secondary)
                Text("chapter map")
                    .font(.system(size: 30, weight: .bold, design: .serif)).italic()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
            .padding(.top, 24)
            .padding(.bottom, 20)

            ChapterMapView(vm: chapterSelectVM,
                           metrics: .init(cardSize: 100, rowSpacing: 172, cornerRadius: 24, numberFontSize: 40, lockFontSize: 24),
                           lockInfo: $lockInfo) { browsingChapter = $0 }
                .padding(.horizontal, 40)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - 사이드바 머리·바닥

    /// 사이드바 맨 위 로고 (홈 화면 미니 아이콘과 같은 부품)
    private var sidebarLogo: some View {
        HStack(spacing: 10) {
            MiniLogoIcon(size: 28, topDepth: 1.0, bottomDepth: 2.0, cornerRadius: 8, arrowSize: 12)
            Text("Blocode")
                .font(.system(size: 18, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 사이드바 맨 아래 별·연속 요약
    private var sidebarStats: some View {
        HStack(spacing: 14) {
            sidebarStat(icon: "star.fill", color: Color.starGold,
                        value: "\(homeVM.earnedStars)/\(homeVM.totalPossibleStars)")
            sidebarStat(icon: "flame.fill", color: Color.statFlameOrange, value: "\(homeVM.streak)일째")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sidebarStat(icon: String, color: Color, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(color)
            Text(value).font(.system(size: 13, weight: .bold, design: .rounded))
        }
    }
}

// MARK: - 게임·에디터 목적지
private extension View {
    /// 탭 스택에 게임·에디터 화면 연결 — 아이폰·맥과 같은 연결 코드를 쓰고, 그 화면에서는 탭 막대를 숨김
    /// - Parameter onReturnToChapterList: 클리어 뒤 "챕터 목록으로" — 스테이지의 챕터 번호를 넘김
    func padGameDestinations(path: Binding<NavigationPath>,
                             onReturnToChapterList: @escaping (Int?) -> Void) -> some View {
        navigationDestination(for: AppRoute.self) { route in
            GameRouteDestination(route: route, navPath: path) {
                if case .stage(let chapter, _) = route {
                    onReturnToChapterList(chapter)
                } else {
                    onReturnToChapterList(nil)
                }
            }
            .toolbar(.hidden, for: .tabBar)
        }
    }
}

// MARK: - Preview
#Preview("아이패드 셸", traits: .landscapeLeft) {
    PadShell()
}
#endif
