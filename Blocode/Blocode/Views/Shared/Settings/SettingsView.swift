//
//  SettingsView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - SettingsView
/// 앱 설정 화면 — 테마, 피드백, 게임, 데이터 섹션으로 구성
struct SettingsView: View {

    /// 임베드 모드 — true면 커스텀 헤더(제목+닫기 버튼)를 숨김
    /// 기본값 false로 기존 iOS 호출부는 전부 동작 변화 없음. 맥 사이드바 셸에 내용만 삽입할 때만 true로 사용
    var isEmbedded: Bool = false

    @State private var vm = SettingsViewModel()              // 설정 상태/로직
    @Environment(\.dismiss) private var dismiss                    // fullScreenCover 닫기
    @Environment(\.colorScheme) private var colorScheme            // 현재 색상 모드
    @Environment(\.openURL) private var openURL                    // 기기 알림 설정 열기

    @State private var showResetAlert   = false  // 진행도 초기화 확인 알럿 표시 여부
    @State private var isScrolled       = false  // 스크롤 여부 (헤더 그림자 표시용)
    @State private var usesTwoColumns   = false  // 아이패드에서 폭이 넉넉하면 섹션을 2칸으로 (아이폰·맥은 항상 한 줄)
    @State private var devUnlockedLabel: String? = nil  // 개발자 해금 완료 알럿에 표시할 챕터 설명 (nil이면 알럿 숨김)

    // 팔레트 블럭 색상 프리뷰 (테마 카드 상단 색상 도트)
    private static let paletteColors: [Color] = [
        Color.decorMint,                            // 민트
        Color(red: 0.45, green: 0.62, blue: 0.95),  // 블루
        Color(red: 0.95, green: 0.55, blue: 0.52)   // 레드
    ]

    // 토글 및 슬라이더 강조 색상 — 민트 그린
    private let toggleTint = Color.accentMint

    // 설정 화면 전용 색 — 그릴 때마다 새로 만들지 않도록 한 번만 만들어 둠 (값은 그대로)
    private static let darkThemeCardBackground = Color(red: 0.10, green: 0.12, blue: 0.20)  // 다크 테마 미리보기 카드
    private static let soundIconColor = Color(red: 0.98, green: 0.72, blue: 0.28)
    private static let reminderIconColor = Color(red: 0.93, green: 0.50, blue: 0.40)
    private static let clockIconColor = Color(red: 0.45, green: 0.62, blue: 0.85)
    private static let resetIconColor = Color(red: 0.95, green: 0.45, blue: 0.22)
    private static let resetTextColor = Color(red: 0.93, green: 0.28, blue: 0.18)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: 커스텀 헤더 (툴바 완전 제거 → 이중 원 없음)
                // 임베드 모드(맥 사이드바 셸)에서는 숨김 — 사이드바가 이미 내비게이션을 제공하므로 불필요
                if !isEmbedded {
                    ZStack {
                        // 가운데 타이틀
                        Text("설정")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)

                        HStack {
                            // x 버튼으로 화면 닫기
                            Button { dismiss() } label: {
                                // 다른 화면의 카드형 아이콘 버튼과 같은 모양 (사용자 결정으로 34pt → 36pt 통일)
                                CardIconLabel(icon: "xmark", fontSize: 14, background: .cardBackground,
                                              shadowOpacity: 0.08, shadowY: 2)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(height: 44)
                    .padding(.top, 4)
                    .background(Color.appBackground)
                    // 스크롤 내려가면 헤더 하단 그림자 표시
                    .shadow(
                        color: Color.black.opacity(isScrolled ? 0.07 : 0),
                        radius: 8, x: 0, y: 4
                    )
                }

                // 설정 섹션 스크롤 영역
                ScrollView {
                    VStack(spacing: 28) {
                        // 아이패드 탭 안에서는 다른 탭(나만의 맵·개념 카드)과 같은 머리글
                        if isEmbedded && isPadIdiom { padHeader }

                        if usesTwoColumns {
                            // 아이패드 넓은 화면 — 왼쪽(화면·소리·알림) / 오른쪽(게임·데이터·개발자)
                            // (예전엔 가운데 560pt 한 줄만 써서 양옆이 넓게 비었음)
                            HStack(alignment: .top, spacing: 28) {
                                VStack(spacing: 28) {
                                    themeSection
                                    feedbackSection
                                    if vm.dailyPuzzleUnlocked { reminderSection }
                                }
                                VStack(spacing: 28) {
                                    gameSection
                                    dataSection
                                    developerSection
                                }
                            }
                        } else {
                            themeSection      // 테마 선택 섹션
                            feedbackSection   // 효과음/배경음악 섹션
                            if vm.dailyPuzzleUnlocked { reminderSection }   // 복습 알림 섹션 (일일 퍼즐이 열린 뒤에만)
                            gameSection       // 실행 속도 섹션
                            dataSection       // 진행도 초기화 섹션
                            developerSection  // 챕터 강제 해금(테스트 편의) — 임시, 정식 배포 전 제거 예정
                        }
                        footerView        // 버전 정보
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                    // 와이드 화면(아이패드·맥)에선 설정 목록을 중앙 560pt로 제한 (아이폰 영향 없음), 아이패드 2칸은 1000pt
                    .frame(maxWidth: usesTwoColumns ? 1000 : 560)
                    .frame(maxWidth: .infinity)
                }
                // 아이패드에서 폭이 900pt 이상이면 2칸 — 넘을 때와 돌아올 때만 알림이 옴
                // (폭 계산은 메인 스레드 밖에서 돌 수 있어서, 아이패드 판별은 결과를 받는 쪽에서 함)
                .onGeometryChange(for: Bool.self) { $0.size.width >= 900 } action: { usesTwoColumns = isPadIdiom && $0 }
                // 스크롤 위치에 따라 헤더 그림자 토글
                // 스크롤 위치를 "4pt 넘었는지"로 바꿔 받아서, 넘을 때와 돌아올 때만 알림이 옴 (예전엔 스크롤 매 프레임 알림)
                .onScrollGeometryChange(for: Bool.self) { geo in
                    geo.contentOffset.y > 4
                } action: { _, scrolled in
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isScrolled = scrolled  // 4pt 이상 스크롤 시 그림자 표시
                    }
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .hideNavigationBar()  // 기본 툴바 숨김 (iOS 전용 API 래퍼 — macOS no-op)
        }
        // 테마 설정에 따라 색상 모드 적용
        .preferredColorScheme(vm.theme.colorScheme)
        // 진행도 초기화 확인 알럿
        .alert("진행도 초기화", isPresented: $showResetAlert) {
            // 초기화하면 앱 진입점이 바로 온보딩으로 바뀌며 이 화면도 사라짐
            Button("초기화", role: .destructive) { vm.resetProgress() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("모든 별과 클리어 기록이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.")
        }
        // 개발자 해금 완료 알럿
        .alert("해금 완료", isPresented: Binding(
            get: { devUnlockedLabel != nil },
            set: { if !$0 { devUnlockedLabel = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("\(devUnlockedLabel ?? "")까지 전부 3별로 처리됐어요.")
        }
    }

    // MARK: - 아이패드 머리글

    /// 아이패드 탭 안 머리글 — 나만의 맵("my maps")·개념 카드("library")와 같은 모양
    private var padHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("앱 설정")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("settings")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }

    // MARK: - 테마 섹션

    /// 라이트/다크 테마 카드 + 시스템 따르기 토글
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("테마")

            // 라이트 / 다크 프리뷰 카드 (가로 2개)
            HStack(spacing: 12) {
                themeCard(.light)
                themeCard(.dark)
            }

            // 시스템 따르기 — 별도 카드로 토글 표시
            settingsCard {
                settingsRow(title: "시스템 따르기") {
                    Toggle("", isOn: $vm.followsSystemTheme)
                    .labelsHidden()
                    .tint(toggleTint)
                }
            }
        }
    }

    /// 테마 프리뷰 카드 — 선택 시 해당 테마로 즉시 변경
    private func themeCard(_ theme: SettingsService.ThemePreference) -> some View {
        let isDark = (theme == .dark)
        // 현재 선택된 테마인지 판단 (시스템 모드 고려)
        let isSelected: Bool = {
            if vm.theme == .system {
                // 시스템 모드에서는 현재 색상 모드와 일치하는 카드가 선택됨
                return (theme == .light && colorScheme == .light) ||
                       (theme == .dark  && colorScheme == .dark)
            }
            return vm.theme == theme
        }()

        // 카드 배경색 — 테마 프리뷰를 직접 반영
        let cardBg: Color = isDark
            ? Self.darkThemeCardBackground
            : Color.white

        return Button { vm.theme = theme } label: {
            VStack(alignment: .leading, spacing: 0) {

                // 상단 — 블럭 색상 점 + 코드 라인 프리뷰
                VStack(alignment: .leading, spacing: 8) {
                    // 블럭 색상 도트 3개 (팔레트 색상 미리보기)
                    HStack(spacing: 5) {
                        ForEach(Self.paletteColors.indices, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Self.paletteColors[i])
                                .frame(width: 20, height: 20)
                        }
                    }
                    // 코드 라인 모양 줄 (진짜 코드처럼 보이는 더미 바)
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isDark ? Color.white.opacity(0.22) : Color.black.opacity(0.13))
                            .frame(maxWidth: .infinity)
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.07))
                            .frame(maxWidth: .infinity)
                            .frame(height: 5)
                            .padding(.trailing, 28)  // 두 번째 줄은 짧게
                    }
                }
                .padding(12)

                // 하단 — 테마 레이블 + 선택 체크마크
                HStack {
                    Text(theme.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isDark ? .white : .primary)
                    Spacer()
                    // 선택된 테마에만 체크마크 표시
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(
                                isDark ? Color.white : toggleTint
                            )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
            // 선택된 테마 카드에 테두리 표시
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color.primary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: vm.theme)
    }

    // MARK: - 피드백 섹션

    /// 효과음 토글 설정 (햅틱 기능은 제거됨)
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("피드백")
            settingsCard {
                VStack(spacing: 0) {
                    // 효과음 토글
                    settingsRow(
                        icon: "speaker.wave.2.fill",
                        iconColor: Self.soundIconColor,  // 노란 계열
                        title: "효과음"
                    ) {
                        Toggle("", isOn: $vm.soundEnabled)
                            .labelsHidden()
                            .tint(toggleTint)
                    }

                    rowDivider

                    // 배경음악 토글
                    settingsRow(
                        icon: "music.note",
                        iconColor: Color.decorLavender,  // 보라 계열
                        title: "배경음악"
                    ) {
                        Toggle("", isOn: $vm.musicEnabled)
                            .labelsHidden()
                            .tint(toggleTint)
                    }
                }
            }
        }
    }

    // MARK: - 복습 알림 섹션

    /// 정해 둔 시각에 한 판 풀도록 알려 주는 알림 — 켤 때 권한을 묻고, 거부되면 기기 설정 안내를 보여 줌
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("알림")
            settingsCard {
                VStack(spacing: 0) {
                    settingsRow(
                        icon: "bell.fill",
                        iconColor: Self.reminderIconColor,  // 코랄 계열
                        title: "복습 알림"
                    ) {
                        Toggle("", isOn: Binding(get: { vm.reminderEnabled },
                                                 set: { vm.setReminderEnabled($0) }))
                            .labelsHidden()
                            .tint(toggleTint)
                    }

                    if vm.reminderEnabled {
                        rowDivider
                        settingsRow(
                            icon: "clock.fill",
                            iconColor: Self.clockIconColor,  // 파랑 계열
                            title: "알림 시간"
                        ) {
                            DatePicker("", selection: $vm.reminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                    }
                }
            }
            if vm.reminderDenied {
                HStack(spacing: 8) {
                    Text("알림이 꺼져 있어요. 기기 설정에서 Blocode 알림을 허용해 주세요.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.failureRed)
                    if let url = notificationSettingsURL {
                        Button("설정 열기") { openURL(url) }
                            .font(.system(size: 12, weight: .semibold))
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    /// 기기의 알림 설정 화면 주소
    private var notificationSettingsURL: URL? {
        #if os(iOS)
        URL(string: UIApplication.openNotificationSettingsURLString)
        #else
        URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")
        #endif
    }

    // MARK: - 게임 섹션

    /// 실행 속도 슬라이더
    private var gameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("게임")
            settingsCard {
                VStack(spacing: 0) {

                    // 실행 속도 — 슬라이더 (3단계: 0.5× / 1× / 2×)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            iconBadge("play.fill", color: Color.accentMint)
                            Text("실행 속도")
                                .font(.system(size: 16))
                            Spacer()
                        }

                        VStack(spacing: 4) {
                            // 0~2 범위의 정수 슬라이더 — 배율 변환과 저장은 ViewModel 담당
                            Slider(value: $vm.speedIndex, in: 0...2, step: 1)
                                .tint(Color.primary)

                            // 눈금 레이블 (0.5× / 1× / 2×)
                            HStack {
                                Text("0.5×")
                                Spacer()
                                Text("1×")
                                Spacer()
                                Text("2×")
                            }
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 44)  // 아이콘 너비 맞춤 들여쓰기
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                }
            }
        }
    }

    // MARK: - 데이터 섹션

    /// 진행도 초기화
    /// (iCloud 동기화 자리표시자 행은 동작하지 않는 기능이라 심사 지적 위험 때문에 제거 — 실제 구현 시 다시 추가)
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("데이터")
            settingsCard {
                VStack(spacing: 0) {

                    // 진행도 초기화 — 탭 시 확인 알럿 표시
                    settingsRow(
                        icon: "arrow.counterclockwise",
                        iconColor: Self.resetIconColor,  // 주황 계열
                        title: "진행도 초기화",
                        subtitle: "모든 별과 기록 삭제"
                    ) {
                        Button("초기화") { showResetAlert = true }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Self.resetTextColor)  // 빨간 텍스트
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - 개발자 섹션 (챕터 강제 해금 — 테스트 편의용 임시 기능, 정식 배포 전 제거 예정)

    /// 챕터별 "해금" 버튼 — 정식 플레이(스테이지 클리어) 없이 1번 챕터부터 눌린 챕터까지
    /// 모든 스테이지를 3별 클리어 기록으로 채워 바로 플레이 가능하게 만듦
    /// (매번 진행도 초기화 후 마지막 챕터까지 직접 깨면서 테스트하는 시간을 줄이기 위한 용도)
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("개발자")
            settingsCard {
                VStack(spacing: 0) {
                    ForEach(vm.chapters.enumerated(), id: \.element.id) { index, chapter in
                        settingsRow(
                            title: "챕터 \(chapter.number) · \(chapter.title)",
                            subtitle: "1~\(chapter.number)챕터 전체 스테이지 3별 처리"
                        ) {
                            Button("해금") {
                                vm.devUnlock(throughChapter: chapter.number)
                                devUnlockedLabel = "챕터 \(chapter.number) · \(chapter.title)"
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(toggleTint)
                            .buttonStyle(.plain)
                        }
                        if index < vm.chapters.count - 1 {
                            rowDivider
                        }
                    }
                }
            }
        }
    }

    // MARK: - 푸터

    /// 앱 버전 + 개발자 이름 표시
    private var footerView: some View {
        // 번들에서 앱 버전 문자열 읽기 (없으면 "0.1")
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
        return Text("Blocode v\(version) · r9e99x")
            .font(.system(size: 12))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
    }

    // MARK: - 공통 컴포넌트

    /// 섹션 레이블 — 섹션 위에 표시되는 작은 보조 텍스트
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    /// 카드 컨테이너 — 배경색 + 모서리 + 그림자로 카드 형태 구성
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 3)
    }

    /// 설정 행 — 아이콘(선택) + 제목 + 부제목(선택) + 오른쪽 트레일링 뷰
    private func settingsRow<Trailing: View>(
        icon: String? = nil,
        iconColor: Color? = nil,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            // 아이콘 배지 (icon과 iconColor가 모두 있을 때만 표시)
            if let icon, let iconColor {
                iconBadge(icon, color: iconColor)
            }
            // 텍스트 그룹
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            // 오른쪽 컨트롤 (토글, 버튼, 아이콘 등)
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    /// 행 구분선 — 아이콘 너비 맞춤 들여쓰기 적용
    private var rowDivider: some View {
        Divider()
            .padding(.leading, 56)  // 아이콘 배지(32) + 간격(12) + 여유(12)
    }

    /// 아이콘 배지 — 둥근 사각형 색상 배경 + 흰 아이콘
    private func iconBadge(_ icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 32, height: 32)
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}

// 전체 섹션 비교용 — 맥 기본 프리뷰 창은 낮아 위쪽만 보이므로 창 높이를 키움
#if os(macOS)
#Preview("전체 섹션") {
    SettingsView()
        .frame(width: 700, height: 1500)
}
#endif
