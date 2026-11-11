//
//  ContentView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

// 아이폰 홈 + 아이패드 진입점 — iOS 전용 (맥은 SidebarShell과 상단바 컨트롤을 사용하므로 컴파일에서 제외)
#if os(iOS)
import SwiftUI

// MARK: - ContentView (홈 화면)
/// 앱 실행 시 가장 먼저 보이는 홈 화면
/// NavigationStack의 루트 — 모든 화면 전환은 navPath로 제어
struct ContentView: View {

    /// 앱 전역 내비게이션 경로 — append로 이동, removeLast로 뒤로가기
    @State private var navPath = NavigationPath()

    /// 설정 시트 표시 여부 — true이면 SettingsView를 fullScreenCover로 표시
    @State private var showSettings = false

    /// 테마 변경 감지 — SettingsService 변경 시 뷰 자동 갱신
    @ObservedObject private var settings = SettingsService.shared

    /// 홈 화면 상태/로직 — 진행도 가공은 ViewModel이 담당 (MVVM)
    @StateObject private var vm = HomeViewModel()

    /// 잠긴 기능을 눌렀을 때 띄우는 해금 조건 팝업
    @State private var lockInfo: LockInfo?

    /// 알림을 눌러 앱이 열렸을 때의 이동 요청 — 오늘의 퍼즐 열기
    @ObservedObject private var router = NotificationRouter.shared

    var body: some View {
        // 아이패드는 맥과 같은 사이드바 셸로 분기 (아이폰은 기존 NavigationStack 경로 그대로)
        if isPadIdiom {
            SidebarShell()
        } else {
            defaultBody
        }
    }

    /// 아이폰(기존 그대로) · 맥이 함께 쓰는 기본 홈 화면 — NavigationStack 기반
    private var defaultBody: some View {
        // 루트 NavigationStack — path 바인딩으로 화면 전환 관리
        NavigationStack(path: $navPath) {
            // 화면 폭에 따라 홈 레이아웃 분기 (아이폰 세로: 세로 스택 / 아이폰 가로·맥: 좌우 분할)
            GeometryReader { geo in
                if geo.size.width >= LayoutBreakpoint.wide {
                    wideHomeContent
                } else {
                    homeContent
                }
            }
            // MARK: 라우트별 목적지 등록
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .chapterSelect:
                    ChapterSelectView(navPath: $navPath)

                case .chapter(let number):
                    ChapterView(navPath: $navPath, chapter: number)

                case .stage(let chapter, let number):
                    // 로딩은 StageView의 ViewModel이 담당 (View 계층 데이터 호출 제거)
                    StageView(chapter: chapter, number: number, navPath: $navPath)
                        .id("stage-\(chapter)-\(number)")

                case .library:
                    LearningLibraryView(onBack: { if !navPath.isEmpty { navPath.removeLast() } })

                case .customMaps:
                    CustomMapListView(
                        onBack: { if !navPath.isEmpty { navPath.removeLast() } },
                        onNew: { navPath.append(AppRoute.mapEditor(nil)) },
                        onPlay: { navPath.append(AppRoute.customMapPlay($0)) },
                        onEdit: { navPath.append(AppRoute.mapEditor($0)) }
                    )

                case .customMapPlay(let id):
                    CustomMapPlayView(id: id) { if !navPath.isEmpty { navPath.removeLast() } }

                case .mapEditor(let id):
                    MapEditorView(editing: id.flatMap { CustomMapService.shared.map(withID: $0) }) {
                        if !navPath.isEmpty { navPath.removeLast() }
                    }

                case .dailyPuzzle(let key):
                    PuzzlePlayView(kind: .daily(key)) { if !navPath.isEmpty { navPath.removeLast() } }

                case .randomPuzzle(let seed):
                    PuzzlePlayView(kind: .random(seed), onNewPuzzle: {
                        // 한 판 더 — 지금 퍼즐을 빼고 새 씨앗의 퍼즐로 교체
                        if !navPath.isEmpty { navPath.removeLast() }
                        navPath.append(AppRoute.randomPuzzle(.random(in: 1...UInt64.max)))
                    }) { if !navPath.isEmpty { navPath.removeLast() } }
                }
            }
        }
        // 복습 알림을 눌렀으면 오늘의 퍼즐로 (앱이 꺼진 채 눌렀을 때는 화면이 준비된 뒤 onAppear에서 처리)
        .onAppear { openPendingDailyPuzzle() }
        .onChange(of: router.pendingDailyPuzzle) { _, _ in openPendingDailyPuzzle() }
        .lockInfoPopup($lockInfo)
        // 설정에 따라 라이트/다크/시스템 테마 적용
        .preferredColorScheme(settings.theme.colorScheme)
        // 설정 화면 — 모달 표시 (iOS: fullScreenCover / macOS: sheet)
        .fullScreenCoverCompat(isPresented: $showSettings) {
            SettingsView()
        }
    }

    /// 대기 중인 알림 이동 요청이 있으면 오늘의 퍼즐만 남기고 이동 — 뒤로가면 홈
    private func openPendingDailyPuzzle() {
        guard router.consumeDailyPuzzle(), vm.isUnlocked(.dailyPuzzle) else { return }
        navPath = NavigationPath([AppRoute.dailyPuzzle(vm.dailyPuzzle.key)])
    }

    // MARK: - 홈 화면 전체 레이아웃

    private var homeContent: some View {
        VStack(spacing: 0) {

            // MARK: 스크롤 콘텐츠 (헤더 / 인용구 / 통계)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // 헤더 (앱 아이콘 + 타이틀 / 설정 버튼)
                    headerSection

                    // 오늘의 한 줄 인용구 섹션
                    quoteSection
                        .padding(.top, 32)

                    // 통계 카드 3종 (별 / 챕터 / 연속)
                    statsRow
                        .padding(.top, 28)

                    // 오늘의 퍼즐 카드
                    dailyCard(compact: false)
                        .padding(.top, 14)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }

            // MARK: 버튼 영역 — 화면 하단 고정
            buttonSection
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 36)
                .background(Color.appBackground)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .hideNavigationBar()  // iOS 전용 API 래퍼 (macOS no-op)
    }

    // MARK: - 헤더 섹션

    private var headerSection: some View {
        HStack(alignment: .center) {
            // 왼쪽: 미니 앱 아이콘 블럭 + "Blocode" 텍스트
            brandRow

            Spacer()

            // 오른쪽: 학습 보관함 + 설정 버튼
            HStack(spacing: 10) {
                libraryButton
                settingsButton
            }
        }
    }

    /// 로고 + 앱 이름 행 — 컴팩트 헤더와 와이드 레이아웃 왼쪽 열에서 공용 사용
    private var brandRow: some View {
        HStack(spacing: 10) {
            // 앱 로고와 같은 3D 미니 아이콘 (온보딩과 공용 부품)
            MiniLogoIcon(size: 36, topDepth: 1.0, bottomDepth: 2.0, cornerRadius: 10, arrowSize: 14)
            // 앱 이름
            Text("Blocode")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }

    /// 학습 보관함 버튼 — 설정 버튼과 같은 모양 (개념 카드 모음으로 이동)
    private var libraryButton: some View {
        Button {
            SoundService.shared.play(.buttonTap)
            navPath.append(AppRoute.library)
        } label: {
            Image(systemName: "books.vertical")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .frame(width: 36, height: 36)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("개념 카드 모음")
    }

    /// 설정 버튼 — 챕터 선택 화면 홈 버튼과 동일한 스타일
    /// (컴팩트: 헤더 오른쪽 / 와이드: 화면 우상단 오버레이로 공용 사용)
    private var settingsButton: some View {
        Button {
            SoundService.shared.play(.buttonTap)
            showSettings = true
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.secondary)  // UIColor.secondaryLabel과 동일 톤 (크로스플랫폼)
                .frame(width: 36, height: 36)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 와이드 레이아웃 홈 (아이패드·맥)

    /// 좌: 브랜딩+인용구 / 우: 통계 카드+시작 버튼 — 큰 화면에서 좌우 분할 배치
    private var wideHomeContent: some View {
        ZStack(alignment: .topTrailing) {

            // 중앙 분할 콘텐츠 (최대 1120pt로 제한해 초대형 화면에서도 밀도 유지)
            HStack(alignment: .center, spacing: 56) {

                // ── 왼쪽 열: 로고 + 인용구 ──
                VStack(alignment: .leading, spacing: 0) {
                    brandRow
                    quoteSection
                        .padding(.top, 40)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // ── 오른쪽 열: 통계 카드 + 시작/둘러보기 버튼 ──
                VStack(spacing: 14) {
                    statsRow
                    dailyCard(compact: true)  // 가로 화면은 세로가 모자라 두 카드를 반 크기로 한 줄에
                    buttonSection
                        .padding(.top, 8)
                }
                .frame(width: 400)
            }
            .padding(.horizontal, 64)
            .padding(.top, 48)  // 오른쪽 위에 겹쳐 놓인 학습 보관함·설정 버튼 아래로 내용을 내림
            .frame(maxWidth: 1120)
            .frame(maxWidth: .infinity, maxHeight: .infinity)  // 화면 중앙 정렬

            // 우상단 설정 버튼 (컴팩트 헤더의 버튼과 동일)
            HStack(spacing: 10) {
                libraryButton
                settingsButton
            }
            .padding(.trailing, 24)
            .padding(.top, 20)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .hideNavigationBar()  // iOS 전용 API 래퍼 (macOS no-op)
    }

    /// 오늘의 퍼즐 카드 — 누르면 일일 퍼즐, 주사위는 랜덤 퍼즐
    private func dailyCard(compact: Bool) -> some View {
        DailyPuzzleCard(info: vm.dailyPuzzle,
                        isLocked: !vm.isUnlocked(.dailyPuzzle),
                        isCompact: compact,
                        onDaily: { openIfUnlocked(.dailyPuzzle, AppRoute.dailyPuzzle(vm.dailyPuzzle.key)) },
                        onRandom: { openIfUnlocked(.dailyPuzzle, AppRoute.randomPuzzle(.random(in: 1...UInt64.max))) })
    }

    /// 열려 있으면 해당 화면으로 이동, 잠겨 있으면 해금 조건 팝업 (잠금 사운드 포함)
    private func openIfUnlocked(_ feature: UnlockableFeature, _ route: AppRoute) {
        if vm.isUnlocked(feature) {
            navPath.append(route)
        } else {
            let hint = vm.lockHint(for: feature)
            SoundService.shared.play(.lockButton)
            withAnimation(.easeInOut(duration: 0.2)) {
                lockInfo = LockInfo(message: hint.message, accentColor: hint.chapter?.color ?? .gray)
            }
        }
    }

    // MARK: - 인용구 섹션

    private var quoteSection: some View {
        VStack(alignment: .leading, spacing: 6) {

            // 소제목 레이블
            Text("오늘의 한 줄")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .tracking(1.2)

            // 메인 인용구 — Georgia Italic 폰트로 감성적 표현
            // (한국어는 시스템 폰트 폴백 + 기울임 변환으로 이탤릭 효과 구현)
            VStack(alignment: .leading, spacing: 0) {
                // 매일 바뀌는 문구 — 길면 한 줄 안에서 글자를 줄여 줄바꿈을 막음
                Text(vm.dailyQuote.first)
                    .font(.custom("Georgia-Italic", size: 38))
                    .foregroundStyle(.primary)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.12, d: 1, tx: 0, ty: 0))
                Text(vm.dailyQuote.second)
                    .font(.custom("Georgia-Italic", size: 38))
                    .foregroundStyle(.primary)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.12, d: 1, tx: 0, ty: 0))
            }

            // 진행도에 따른 동적 서브타이틀
            Text(vm.dynamicSubtitle)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    // MARK: - 통계 카드 행

    private var statsRow: some View {
        HStack(spacing: 10) {
            // 획득 별 수 카드
            statCard(
                icon: "star.fill",
                iconColor: Color(red: 1.0, green: 0.82, blue: 0.25),
                value: "\(vm.earnedStars)/\(vm.totalPossibleStars)",
                label: "획득 별"
            )
            // 완료 챕터 수 카드
            statCard(
                icon: "checkmark.seal.fill",
                iconColor: Color(red: 0.576, green: 0.788, blue: 0.671),
                value: "\(vm.completedChapters)/\(vm.chapterCount)",
                label: "챕터 완료"
            )
            // 연속 학습 일수 카드
            statCard(
                icon: "flame.fill",
                iconColor: Color(red: 1.0, green: 0.55, blue: 0.30),
                value: "\(vm.streak)일째",
                label: "연속"
            )
        }
    }

    /// 개별 통계 카드 뷰 — 아이콘 + 값 + 레이블
    private func statCard(
        icon: String,
        iconColor: Color,
        value: String,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 아이콘
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)

            // 숫자 값
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // 레이블
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        // 카드 배경 — 팔레트와 동일한 크림색
        .background(Color.statCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - 버튼 섹션

    private var buttonSection: some View {
        VStack(spacing: 12) {

            // "시작하기 / 이어서 하기" 3D 다크 버튼 (아이패드·맥 셸과 공용 부품)
            HomeContinueButton(next: vm.nextStage, isFirstTime: vm.isFirstTime) {
                if let next = vm.nextStage {
                    navPath.append(AppRoute.stage(chapter: next.chapter, number: next.stage))  // 다음 스테이지로 바로 이동
                } else {
                    navPath.append(AppRoute.chapterSelect)  // 모두 완료 → 챕터 목록으로
                }
            }

            // 크림 버튼 두 개를 반 폭씩 한 줄에 — "챕터 둘러보기"(아이패드·맥 셸과 공용 부품)와 "내 맵"(직접 만든 퍼즐 목록)
            HStack(spacing: 12) {
                HomeBrowseButton { navPath.append(AppRoute.chapterSelect) }
                HomeBrowseButton(title: "나만의 맵", isLocked: !vm.isUnlocked(.customMaps)) { openIfUnlocked(.customMaps, AppRoute.customMaps) }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
#endif
