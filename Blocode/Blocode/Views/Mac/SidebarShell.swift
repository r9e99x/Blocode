//
//  SidebarShell.swift
//  Blocode
//
//  Created by 조준희 on 7/2/26.
//

// 맥 전용 최상위 화면 (아이폰은 ContentView, 아이패드는 PadShell을 사용)
// 색상·3D 효과·눌림 효과는 전부 공용 컴포넌트를 재사용
// 챕터 브라우저(ChapterBrowsePane)와 미리보기 맵(StagePreviewMapView)은 별도 파일
#if os(macOS)
import SwiftUI

// MARK: - SidebarShell
/// 맥 기본 사이드바(NavigationSplitView) + 우측 콘텐츠 구조
/// 사이드바: 홈·챕터·나만의 맵·개념 카드 — 챕터를 보는 동안 "챕터" 아래에 1~15장이 펼쳐짐 (설정은 ⌘, 설정 창)
/// 챕터를 고르면 사이드바는 그대로 두고 오른쪽에 스테이지 목록|미리보기 2칸 (예전엔 챕터 목록이 사이드바를 통째로 대체했음)
/// 게임·에디터 화면은 오른쪽 스택에 올리고, 그동안 사이드바를 접어 창 전체를 씀 (뒤로 오면 다시 펼침)
struct SidebarShell: View {

    /// 사이드바에서 고를 수 있는 항목
    private enum SidebarItem: Hashable {
        case home, chapterMap, myMaps, library
        case chapter(Int)
    }

    @State private var selection: SidebarItem = .home
    /// 사이드바 펼침 상태 — 게임 화면에선 접어서 창 전체를 씀
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    /// 게임·에디터 화면 진입/복귀 스택 — 오른쪽 칸 안에서만 쌓임
    @State private var navPath = NavigationPath()

    @State private var homeVM = HomeViewModel()
    @State private var chapterSelectVM = ChapterSelectViewModel()
    /// 잠긴 챕터·잠긴 기능(나만의 맵, 일일 퍼즐)을 눌렀을 때의 해금 조건 팝업 — 셸 전체에서 하나를 공유
    @State private var lockInfo: LockInfo? = nil
    private let settings = SettingsService.shared  // @Observable — 테마를 읽기만 해도 바뀔 때 다시 그려짐

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
        } detail: {
            NavigationStack(path: $navPath) {
                contentPane
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.appBackground.ignoresSafeArea())
                    .navigationTitle(windowTitle)
                    .appWindowToolbarBackground()
                    // 게임·에디터 화면 — 아이폰 홈과 같은 연결 코드를 함께 씀 (맥 툴바 뒤로가기도 그 안에서 처리)
                    .navigationDestination(for: AppRoute.self) { route in
                        GameRouteDestination(route: route, navPath: $navPath) {
                            // "챕터 목록으로" 복귀 — 그 스테이지의 챕터를 사이드바에서 고른 상태로
                            navPath.pop()
                            if case .stage(let chapter, _) = route {
                                selection = .chapter(chapter)
                            } else {
                                selection = .chapterMap
                            }
                        }
                        .appWindowToolbarBackground()
                    }
            }
        }
        // 게임 화면에선 사이드바를 접고 접기 버튼도 숨겨 창 전체를 씀 (예전 전체 화면 전환과 같은 느낌)
        .toolbar(removing: navPath.isEmpty ? nil : .sidebarToggle)
        .onChange(of: navPath.isEmpty) { _, isEmpty in
            columnVisibility = isEmpty ? .all : .detailOnly
        }
        // 복습 알림을 눌렀으면 오늘의 퍼즐로 (앱이 꺼진 채 눌렀을 때는 화면이 준비된 뒤 onAppear에서 처리)
        .onAppear { openPendingDailyPuzzle() }
        .onChange(of: homeVM.hasPendingDailyPuzzle) { _, _ in openPendingDailyPuzzle() }
        .lockInfoPopup($lockInfo)
        .preferredColorScheme(settings.theme.colorScheme)
        // 메뉴 막대 "이동"(⌘1~4) — 게임·에디터 화면 중엔 넘기지 않아 메뉴가 꺼짐 (저장 안 한 에디터를 단축키로 떠나지 않게)
        .focusedSceneValue(\.macShowSection, navPath.isEmpty ? { showSection($0) } : nil)
    }

    /// 메뉴 막대에서 고른 화면으로 — 사이드바를 누른 것과 같은 길(잠금 확인 포함)
    private func showSection(_ section: MacSection) {
        switch section {
        case .home: select(.home)
        case .chapters: select(.chapterMap)
        case .myMaps: select(.myMaps)
        case .library: select(.library)
        }
    }

    /// 대기 중인 알림 이동 요청이 있으면 홈에서 오늘의 퍼즐만 열린 상태로 이동 — 뒤로가면 홈
    private func openPendingDailyPuzzle() {
        guard let route = homeVM.takePendingDailyPuzzleRoute() else { return }
        selection = .home
        navPath = NavigationPath([route])
    }

    /// 윈도우 타이틀 바 텍스트 — 현재 항목/챕터 반영 (맥 전용)
    private var windowTitle: String {
        switch selection {
        case .home: return "Blocode"
        case .chapterMap: return "Blocode — 챕터"
        case .chapter(let ch): return "Blocode — \(ChapterCatalog.chapter(ch)?.title ?? "챕터")"
        case .myMaps: return "Blocode — 나만의 맵"
        case .library: return "Blocode — 개념 카드"
        }
    }

    // MARK: - 사이드바

    /// 사이드바 항목을 눌렀을 때 — 잠긴 항목은 고르지 않고 해금 조건 팝업만 띄움
    private func select(_ item: SidebarItem) {
        guard item != selection else { return }
        switch item {
        case .myMaps where !homeVM.isUnlocked(.customMaps):
            $lockInfo.present(homeVM.lockHint(for: .customMaps))
        case .chapter(let number):
            guard let chapter = ChapterCatalog.chapter(number) else { return }
            if chapterSelectVM.isUnlocked(chapter) {
                SoundService.shared.play(.buttonTap)
                selection = item
            } else {
                SoundService.shared.play(.lockButton)
                withAnimation(.easeInOut(duration: 0.2)) {
                    lockInfo = LockInfo(message: chapterSelectVM.lockMessage(for: chapter), accentColor: chapter.color)
                }
            }
        default:
            SoundService.shared.play(.buttonTap)  // iOS 버튼들과 동일하게 탭 효과음
            selection = item
        }
    }

    /// 챕터 지도나 챕터 하나를 보고 있는지 — 이때만 "챕터" 아래에 1~15장을 펼침
    private var isInChapters: Bool {
        switch selection {
        case .chapterMap, .chapter: return true
        default: return false
        }
    }

    /// 사이드바 — 줄을 직접 그려서 선택 색을 앱 색(라이트: 진한 잉크 / 다크: 슬레이트)으로 유지
    /// (List 기본 선택은 .tint가 먹지 않아 시스템 파랑으로 나왔음)
    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                SidebarRow(isSelected: selection == .home, action: { select(.home) }) {
                    Label("홈", systemImage: "house")
                }
                // 챕터 지도 — 챕터 하나를 고르면 강조는 그 챕터 줄로 옮겨 감 (진한 줄이 두 개 겹치지 않게)
                SidebarRow(isSelected: selection == .chapterMap, action: { select(.chapterMap) }) {
                    Label("챕터", systemImage: "map")
                }
                if isInChapters {
                    ForEach(chapterSelectVM.chapters) { chapter in
                        SidebarRow(isSelected: selection == .chapter(chapter.number), isNested: true,
                                   action: { select(.chapter(chapter.number)) }) {
                            chapterRow(chapter)
                        }
                    }
                }
                SidebarRow(isSelected: selection == .myMaps, action: { select(.myMaps) }) {
                    Label("나만의 맵", systemImage: homeVM.isUnlocked(.customMaps) ? "pencil.and.ruler" : "lock.fill")
                }
                SidebarRow(isSelected: selection == .library, action: { select(.library) }) {
                    Label("개념 카드", systemImage: "books.vertical")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .animation(.easeInOut(duration: 0.2), value: isInChapters)
        }
        // 사이드바 배경은 예전 색 그대로 (시스템 반투명 재질 대신)
        .background(Color.cardBackground)
        // 하단 통계 요약 — 목록이 길어도 항상 아래에 고정
        .safeAreaInset(edge: .bottom, spacing: 0) {
            statsFooter
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
    }

    /// 사이드바 챕터 한 줄 — 챕터 색 번호 배지(잠기면 자물쇠) + 이름 + 별 수
    private func chapterRow(_ chapter: ChapterInfo) -> some View {
        let unlocked = chapterSelectVM.isUnlocked(chapter)
        return HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(unlocked ? chapter.color : Color.lockedBackground)
                if unlocked {
                    Text("\(chapter.number)").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                } else {
                    Image(systemName: "lock.fill").font(.system(size: 8)).foregroundStyle(.secondary)
                }
            }
            .frame(width: 20, height: 20)
            Text(chapter.title)
                .opacity(unlocked ? 1 : 0.6)
            Spacer(minLength: 4)
            if unlocked {
                Text("\(chapterSelectVM.chapterStars(chapter))/\(chapter.maxStars)")
                    .font(.system(size: 11).monospacedDigit())
                    .opacity(0.6)
            }
        }
        .accessibilityIdentifier("sidebarChapter-\(chapter.number)")
    }

    /// 하단 통계 카드 — 별/연속을 각각 아이콘+굵은값+레이블 한 줄로 표시
    private var statsFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            statsFooterRow(icon: "star.fill", iconColor: Color.starGold,
                           value: "\(homeVM.earnedStars)/\(homeVM.totalPossibleStars)", label: "획득 별")
            statsFooterRow(icon: "flame.fill", iconColor: Color.statFlameOrange,
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

    private var contentPane: some View {
        Group {
            switch selection {
            case .home:
                // 대시보드 홈 — 버튼·카드는 아이폰·아이패드와 같은 공용 부품
                MacHomeView(vm: homeVM, chapterSelectVM: chapterSelectVM, lockInfo: $lockInfo,
                            onOpen: { navPath.append($0) },
                            onShowChapter: { selection = $0.map { .chapter($0) } ?? .chapterMap })
            case .chapterMap:
                chapterMapContent
            case .chapter(let number):
                // 스테이지 목록|미리보기 — 챕터가 바뀌면 뷰를 새로 만들어 ViewModel·선택 스테이지 초기화
                ChapterBrowsePane(chapterNumber: number,
                                  onStart: { ch, num in navPath.append(AppRoute.stage(chapter: ch, number: num)) },
                                  onSelectChapter: { select(.chapter($0)) })
                .id(number)
            case .myMaps:
                CustomMapListView(
                    onNew: { navPath.append(AppRoute.mapEditor(nil)) },
                    onPlay: { navPath.append(AppRoute.customMapPlay($0)) },
                    onEdit: { navPath.append(AppRoute.mapEditor($0)) }
                )
            case .library:
                LearningLibraryView()
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.18), value: selection)
    }

    // MARK: - 챕터 지도 (지그재그 + 3D + 눌림 + 잠금 팝업)

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
                               lockInfo: $lockInfo) { selection = .chapter($0) }
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - 창 툴바 배경

private extension View {
    /// 창 위쪽 툴바 띠를 앱 배경색으로 고정 — 게임 화면에 들어가면 시스템 흰 배경이 나타나고,
    /// 돌아와도 흰색으로 남던 문제 (화면마다 붙여야 스택의 어느 화면에서도 같은 색)
    func appWindowToolbarBackground() -> some View {
        self
            .toolbarBackground(Color.appBackground, for: .windowToolbar)
            .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
    }
}

// MARK: - 메뉴 막대 "이동"

/// 메뉴 막대에서 고를 수 있는 화면 (사이드바 위쪽 4개 항목)
enum MacSection {
    case home, chapters, myMaps, library
}

extension FocusedValues {
    /// 지금 앞에 있는 창의 셸이 화면을 바꾸는 함수 — 게임·에디터 화면 중엔 nil
    @Entry var macShowSection: ((MacSection) -> Void)? = nil
}

/// "이동" 메뉴 — ⌘1 홈 / ⌘2 챕터 / ⌘3 나만의 맵 / ⌘4 개념 카드
struct MacNavigationCommands: Commands {
    @FocusedValue(\.macShowSection) private var showSection

    var body: some Commands {
        CommandMenu("이동") {
            item("홈", .home, key: "1")
            item("챕터", .chapters, key: "2")
            item("나만의 맵", .myMaps, key: "3")
            item("개념 카드", .library, key: "4")
        }
    }

    private func item(_ title: String, _ section: MacSection, key: KeyEquivalent) -> some View {
        Button(title) { showSection?(section) }
            .keyboardShortcut(key, modifiers: .command)
            .disabled(showSection == nil)
    }
}

// MARK: - SidebarRow
/// 사이드바 한 줄 — 선택: 앱의 진한 버튼 색 + 흰 글자 / 마우스를 올리면 옅은 배경 (맥 사이드바처럼)
private struct SidebarRow<Content: View>: View {
    let isSelected: Bool
    var isNested = false  // 챕터 1~15장처럼 한 단계 들여 쓴 줄
    let action: () -> Void
    @ViewBuilder let content: Content

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            content
                .font(.system(size: isNested ? 13 : 14, weight: isNested ? .medium : .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, isNested ? 26 : 10)
                .padding(.trailing, 10)
                .padding(.vertical, isNested ? 6 : 8)
                // 행 전체 폭을 채워야 여백까지 눌림
                .contentShape(Rectangle())
                .foregroundStyle(isSelected ? .white : Color.primary)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.slateButtonFace
                              : isHovering ? Color.statCardBackground : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Preview

#Preview("셸 홈") {
    SidebarShell()
        .frame(width: 1280, height: 860)
}
#endif
