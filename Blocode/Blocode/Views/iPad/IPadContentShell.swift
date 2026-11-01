//
//  IPadContentShell.swift
//  Blocode
//
//  Created by 조준희 on 7/25/26.
//

// 아이패드 전용 최상위 화면 — 아이폰은 이 화면에 절대 진입하지 않음
// (ContentView가 isPadIdiom일 때만 이 뷰로 분기하고, 그 외엔 기존 iOS 홈 화면을 그대로 사용)
// 배치(좌측 고정 사이드바 + 우측 콘텐츠 전환, 챕터 브라우징 시 3단 컬럼)는 맥의 MacContentShell을
// 그대로 참고해서 이식했고, 색상·3D 효과·컴포넌트는 전부 기존 공용 컴포넌트를 그대로 재사용한다
// (ThreeDSurface/AppColors/onPressState/LockInfoOverlay/StarRatingView — 새 색·모양은 만들지 않음)
#if os(iOS)
import SwiftUI

// MARK: - IPadContentShell
/// 좌측 고정 사이드바(홈/챕터/설정) + 우측 콘텐츠 전환 구조
/// 챕터를 브라우징 중일 때는 사이드바 자리를 챕터 목록이 대신 차지한다(3단 컬럼)
/// 게임 화면(StageView) 진입 시에는 이 셸 내부의 전용 NavigationStack으로 푸시한다
struct IPadContentShell: View {

    /// 사이드바 최상위 섹션
    private enum Section: Hashable {
        case home, chapters, settings
    }

    @State private var section: Section = .home
    /// 챕터 섹션 내부 상태 — nil이면 지그재그 지도, 값이 있으면 해당 챕터의 3단 브라우저
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
                    IPadChapterBrowsePane(
                        chapterNumber: chapter,
                        // 지도↔브라우저 이동과 챕터끼리 전환 모두 전환 효과 없이 즉시 교체 (맥과 동일, 사용자 요청)
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
            .navigationDestination(for: AppRoute.self) { route in
                if case .stage(let chapter, let number) = route {
                    // StageView가 내부적으로 시스템 네비게이션 바 자체를 숨기므로(.hideNavigationBar()),
                    // 맥처럼 별도 toolbar 백버튼을 달아도 표시되지 않음 — 아이폰과 동일하게
                    // showsOwnBackButton 기본값(true)을 그대로 써서 StageView 자체 내장 백버튼을 사용
                    StageView(chapter: chapter, number: number, navPath: $navPath) {
                        // "챕터 목록으로" 복귀 — 사이드바 셸의 챕터 브라우저로 이동
                        if !navPath.isEmpty { navPath.removeLast() }
                        section = .chapters
                    }
                    // 스테이지 번호별로 뷰 정체성을 강제 구분 (iOS ContentView와 동일한 처리)
                    .id("stage-\(chapter)-\(number)")
                }
            }
        }
        .preferredColorScheme(settings.theme.colorScheme)
    }

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

    /// 사이드바 항목 — 터치 조작을 고려해 맥보다 세로 여백을 넉넉히 줘서 탭 영역을 키움
    private func sidebarItem(icon: String, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            SoundService.shared.play(.buttonTap)  // iOS 버튼들과 동일하게 탭 효과음
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            // 행 전체 폭을 채워야 Spacer가 여백을 차지하고, 그 여백도 탭 가능해짐
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .foregroundStyle(isSelected ? .white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(isSelected ? Color.darkInk : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
            case .settings:
                SettingsView(onResetProgress: {
                    navPath = NavigationPath()
                    withAnimation(.easeInOut(duration: 0.2)) { section = .home }
                }, isEmbedded: true)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.18), value: section)
    }

    // MARK: - 홈 콘텐츠

    /// 상단(인용구+통계)은 창 크기에 맞춰 유연하게 리플로우되고, 버튼은 항상 화면 맨 아래 중앙에 고정
    private var homeContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("오늘의 한 줄").font(.system(size: 13)).foregroundStyle(.secondary)
                    Text("적은 블럭이 좋은 코드.")
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
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - 챕터 지도 (지그재그 + 3D + 눌림 + 잠금 팝업)

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

            // 지도는 세로 스크롤 (iOS/맥 챕터 지도와 동일한 방향)
            ScrollView(.vertical, showsIndicators: false) {
                // 지그재그 챕터 지도 (아이폰 챕터 선택과 공용 부품)
                ChapterMapView(vm: chapterSelectVM,
                               metrics: .init(cardSize: 100, rowSpacing: 172, cornerRadius: 24, numberFontSize: 40, lockFontSize: 24),
                               lockInfo: $lockInfo) { browsingChapter = $0 }
                    .padding(.horizontal, 40)
            }
        }
        // 잠긴 챕터 탭 시 해금 조건 팝업 (표시 패턴은 공용 모디파이어)
        .lockInfoPopup($lockInfo)
    }
}

// MARK: - Preview

#Preview("아이패드 셸 홈", traits: .landscapeLeft) {
    IPadContentShell()
}
#endif
