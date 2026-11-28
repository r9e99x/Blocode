//
//  ContentView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

// 아이폰 전용 최상위 화면 (아이패드는 PadShell, 맥은 SidebarShell을 사용)
#if os(iOS)
import SwiftUI

// MARK: - ContentView (아이폰 탭 셸)
/// 아래 탭 막대(홈·챕터·내 맵·개념)로 화면을 나눔 — 어디서든 한 번에 이동
/// (예전엔 홈 하나에서 챕터·내 맵·개념 카드로 들어갔다 뒤로 나오는 구조였음)
/// 탭마다 자기 내비게이션 스택을 가지며, 게임·에디터 화면에 들어가면 탭 막대를 숨김
struct ContentView: View {

    /// 탭 종류 (SwiftUI의 Tab 타입과 이름이 겹치지 않게 PhoneTab)
    enum PhoneTab: Hashable {
        case home, chapters, myMaps, library
    }

    @State private var tab: PhoneTab = .home
    /// 탭별 내비게이션 스택 — 챕터 화면·게임·에디터를 올림
    @State private var homePath = NavigationPath()
    @State private var chaptersPath = NavigationPath()
    @State private var myMapsPath = NavigationPath()
    /// 챕터 탭 지도 위에 시트로 열린 챕터 (nil이면 지도만)
    @State private var chapterSheet: Int?

    /// 홈 화면 상태/로직 — 진행도 가공은 ViewModel이 담당 (MVVM)
    @State private var homeVM = HomeViewModel()
    /// 잠긴 기능을 눌렀을 때 띄우는 해금 조건 팝업 — 셸 전체에서 하나를 공유
    @State private var lockInfo: LockInfo?
    /// 테마 변경 감지 — SettingsService 변경 시 뷰 자동 갱신
    private let settings = SettingsService.shared  // @Observable — 테마를 읽기만 해도 바뀔 때 다시 그려짐

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("홈", systemImage: "house", value: PhoneTab.home) {
                NavigationStack(path: $homePath) {
                    PhoneHomeView(vm: homeVM, lockInfo: $lockInfo,
                                  open: { homePath.append($0) },
                                  showChapters: { showChapters(nil) })
                        .phoneDestinations(path: $homePath, onReturnToChapterList: returnToChapters)
                }
            }

            Tab("챕터", systemImage: "map", value: PhoneTab.chapters) {
                NavigationStack(path: $chaptersPath) {
                    // 탭 막대가 있으니 지도 오른쪽 위 홈 버튼은 숨김
                    ChapterSelectView(navPath: $chaptersPath, presentedChapter: $chapterSheet, showsHomeButton: false)
                        .phoneDestinations(path: $chaptersPath, onReturnToChapterList: returnToChapters)
                }
            }

            Tab("내 맵", systemImage: homeVM.isUnlocked(.customMaps) ? "pencil.and.ruler" : "lock.fill",
                value: PhoneTab.myMaps) {
                NavigationStack(path: $myMapsPath) {
                    CustomMapListView(
                        onNew: { myMapsPath.append(AppRoute.mapEditor(nil)) },
                        onPlay: { myMapsPath.append(AppRoute.customMapPlay($0)) },
                        onEdit: { myMapsPath.append(AppRoute.mapEditor($0)) }
                    )
                    .phoneDestinations(path: $myMapsPath, onReturnToChapterList: returnToChapters)
                }
            }

            Tab("개념", systemImage: "books.vertical", value: PhoneTab.library) {
                LearningLibraryView()
            }
        }
        // 복습 알림을 눌렀으면 오늘의 퍼즐로 (앱이 꺼진 채 눌렀을 때는 화면이 준비된 뒤 onAppear에서 처리)
        .onAppear { openPendingDailyPuzzle() }
        .onChange(of: homeVM.hasPendingDailyPuzzle) { _, _ in openPendingDailyPuzzle() }
        .lockInfoPopup($lockInfo)
        // 설정에 따라 라이트/다크/시스템 테마 적용
        .preferredColorScheme(settings.theme.colorScheme)
    }

    // MARK: - 탭 선택

    /// 탭 선택 — 잠긴 "내 맵"은 탭을 바꾸지 않고 해금 조건 팝업만 띄움 (잠금 사운드 포함)
    private var tabSelection: Binding<PhoneTab> {
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

    /// 챕터 탭으로 — 챕터 번호가 있으면 지도 위에 그 챕터 시트를 열고, 없으면 지도만
    private func showChapters(_ chapter: Int?) {
        chaptersPath = NavigationPath()
        tab = .chapters
        chapterSheet = chapter
    }

    /// 클리어 뒤 "챕터 목록으로" — 게임을 띄운 탭의 스택을 비우고 그 스테이지의 챕터 화면으로
    private func returnToChapters(_ chapter: Int?) {
        switch tab {
        case .home: homePath = NavigationPath()
        case .myMaps: myMapsPath = NavigationPath()
        case .chapters, .library: break  // 챕터 탭은 showChapters가 스택을 비움
        }
        showChapters(chapter)
    }

    /// 대기 중인 알림 이동 요청이 있으면 홈 탭에서 오늘의 퍼즐만 열린 상태로 — 뒤로가면 홈
    private func openPendingDailyPuzzle() {
        guard let route = homeVM.takePendingDailyPuzzleRoute() else { return }
        tab = .home
        homePath = NavigationPath([route])
    }
}

// MARK: - 탭 안 화면 연결

private extension View {
    /// 탭 스택에 올라오는 화면 — 챕터 화면은 탭 막대를 그대로 두고, 게임·에디터는 숨겨 화면을 다 씀
    func phoneDestinations(path: Binding<NavigationPath>,
                           onReturnToChapterList: @escaping (Int?) -> Void) -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .chapter(let number):
                ChapterView(navPath: path, chapter: number)
            default:
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
}

// MARK: - Preview
#Preview {
    ContentView()
}
#endif
