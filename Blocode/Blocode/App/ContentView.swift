//
//  ContentView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

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

    /// 진행도 감지 — 별점/챕터/연속 등 실시간 반영
    @ObservedObject private var progress = ProgressService.shared

    /// 홈화면에서 사용할 챕터 목록 (id, stageCount)
    private let chapters: [(id: Int, stageCount: Int)] = [
        (id: 1, stageCount: 6),
        (id: 2, stageCount: 0),
        (id: 3, stageCount: 0),
        (id: 4, stageCount: 0),
        (id: 5, stageCount: 0),
    ]

    /// 전체 획득 가능 별 수 (모든 챕터 합산)
    private var totalPossibleStars: Int {
        chapters.reduce(0) { $0 + $1.stageCount * 3 }
    }

    var body: some View {
        // 루트 NavigationStack — path 바인딩으로 화면 전환 관리
        NavigationStack(path: $navPath) {
            homeContent
                // MARK: 라우트별 목적지 등록
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .chapterSelect:
                        ChapterSelectView(navPath: $navPath)

                    case .chapter(let number):
                        ChapterView(navPath: $navPath, chapter: number)

                    case .stage(let chapter, let number):
                        if let stage = StageLoader.load(chapter: chapter, stage: number) {
                            StageView(stage: stage, navPath: $navPath)
                                .id(stage.id)
                        }
                    }
                }
        }
        // 설정에 따라 라이트/다크/시스템 테마 적용
        .preferredColorScheme(settings.theme.colorScheme)
        // 설정 화면 — fullScreenCover로 모달 표시
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(onResetProgress: {
                // 진행 상황 초기화 후 홈으로 돌아오기 (navPath 초기화)
                navPath = NavigationPath()
            })
        }
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
        .navigationBarHidden(true)
    }

    // MARK: - 헤더 섹션

    private var headerSection: some View {
        HStack(alignment: .center) {

            // 왼쪽: 미니 앱 아이콘 블럭 + "Blocode" 텍스트
            HStack(spacing: 10) {
                // 미니 3D 블럭 아이콘 — 어두운 색상의 작은 3D 사각형
                miniBlockIcon
                // 앱 이름
                Text("Blocode")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Spacer()

            // 오른쪽: 설정 버튼 — 챕터 선택 화면 홈 버튼과 동일한 스타일
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .frame(width: 36, height: 36)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 미니 3D 블럭 아이콘 (헤더 왼쪽)

    private var miniBlockIcon: some View {
        // 3D 효과: 위 뒷면 → 아래 뒷면 → 앞면+내용 (앞면이 마지막 = 최상단)
        let iconSize: CGFloat = 36
        let topD:     CGFloat = 1.0
        let botD:     CGFloat = 2.0
        let cr:       CGFloat = 10

        // 미니 아이콘 색상
        let frontColor   = Color(red: 42/255,  green: 37/255,  blue: 32/255)   // #2a2520 앞면
        let topBackColor = Color(red: 128/255, green: 120/255, blue: 105/255)  // #807869 위 뒷면
        let botBackColor = Color(red: 190/255, green: 181/255, blue: 159/255)  // #beb59f 아래 뒷면
        let arrowColor   = Color(red: 244/255, green: 236/255, blue: 215/255)  // #f4ecd7 화살표

        return ZStack(alignment: .top) {
            // ① 위 뒷면 — #beb59f, y=0
            RoundedRectangle(cornerRadius: cr)
                .fill(topBackColor)
                .frame(width: iconSize, height: iconSize)

            // ② 아래 뒷면 — #807869, y=topD+botD
            RoundedRectangle(cornerRadius: cr)
                .fill(botBackColor)
                .frame(width: iconSize, height: iconSize)
                .offset(y: topD + botD)

            // ③ 앞면 + 화살표 — #2a2520 앞면, #f4ecd7 화살표
            ZStack {
                RoundedRectangle(cornerRadius: cr)
                    .fill(frontColor)
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(arrowColor)
            }
            .frame(width: iconSize, height: iconSize)
            .offset(y: topD)
        }
        .frame(width: iconSize, height: iconSize + topD + botD)
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
                Text("적은 블럭이")
                    .font(.custom("Georgia-Italic", size: 38))
                    .foregroundStyle(.primary)
                    .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.12, d: 1, tx: 0, ty: 0))
                Text("좋은 코드.")
                    .font(.custom("Georgia-Italic", size: 38))
                    .foregroundStyle(.primary)
                    .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.12, d: 1, tx: 0, ty: 0))
            }

            // 진행도에 따른 동적 서브타이틀
            Text(dynamicSubtitle)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    /// 진행 상황에 따라 달라지는 서브타이틀 문구
    private var dynamicSubtitle: String {
        let earned  = progress.totalEarnedStars(chapters: chapters)
        let total   = totalPossibleStars
        let completed = progress.completedChapterCount(chapters: chapters)

        if earned == 0 {
            // 아직 시작 전
            return "첫 번째 블럭을 놓아볼까요?"
        } else if completed == chapters.count {
            // 모든 챕터 완료
            return "모든 챕터를 완료했어요! 대단해요 🎉"
        } else if progress.streak >= 7 {
            // 연속 7일 이상
            return "\(progress.streak)일 연속! 꾸준함이 실력이 돼요."
        } else if earned >= total / 2 {
            // 절반 이상 달성
            return "절반을 넘었어요! 계속 달려봐요."
        } else {
            // 일반 진행 중
            return "오늘도 한 스테이지씩 나아가요."
        }
    }

    // MARK: - 통계 카드 행

    private var statsRow: some View {
        HStack(spacing: 10) {
            // 획득 별 수 카드
            statCard(
                icon: "star.fill",
                iconColor: Color(red: 1.0, green: 0.82, blue: 0.25),
                value: "\(progress.totalEarnedStars(chapters: chapters))/\(totalPossibleStars)",
                label: "획득 별"
            )
            // 완료 챕터 수 카드
            statCard(
                icon: "checkmark.seal.fill",
                iconColor: Color(red: 0.576, green: 0.788, blue: 0.671),
                value: "\(progress.completedChapterCount(chapters: chapters))/\(chapters.count)",
                label: "챕터 완료"
            )
            // 연속 학습 일수 카드
            statCard(
                icon: "flame.fill",
                iconColor: Color(red: 1.0, green: 0.55, blue: 0.30),
                value: "\(progress.streak)일째",
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

            // "이어서 하기" 3D 다크 버튼
            continueButton

            // "챕터 둘러보기" 크림 버튼
            browseButton
        }
    }

    // MARK: - 이어서 하기 버튼 (3D 어두운 스타일)

    @State private var isContinuePressed = false

    private var continueButton: some View {
        let frontH:   CGFloat = 58
        let topD:     CGFloat = 0.8
        let botD:     CGFloat = 2.5
        let cr:       CGFloat = 18
        // 다크 버튼 색상
        let frontColor    = Color(red: 0.165, green: 0.145, blue: 0.125)
        // 위 뒷면 색상 — #807869 (어두운 올리브브라운)
        let topBackColor  = Color(red: 128/255, green: 120/255, blue: 105/255)
        // 아래 뒷면 색상 — #beb59f (연한 탄베이지, 그림자 효과)
        let botBackColor  = Color(red: 190/255, green: 181/255, blue: 159/255)

        // 다음 스테이지 정보 (없으면 모든 완료 상태)
        let next = progress.nextStage(chapters: chapters)
        // 진행 기록이 없으면 "시작하기" 모드
        let isFirstTime = progress.totalEarnedStars(chapters: chapters) == 0

        return Button {
            if let next = next {
                // 다음 스테이지로 바로 이동
                navPath.append(AppRoute.stage(chapter: next.chapter, number: next.stage))
            } else {
                // 모두 완료 → 챕터 목록으로
                navPath.append(AppRoute.chapterSelect)
            }
        } label: {
            ZStack(alignment: .top) {
                // ① 위 뒷면 — 눌리면 사라짐
                RoundedRectangle(cornerRadius: cr)
                    .fill(topBackColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: frontH)
                    .opacity(isContinuePressed ? 0 : 1)

                // ② 아래 뒷면 — 눌리면 사라짐
                RoundedRectangle(cornerRadius: cr)
                    .fill(botBackColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: frontH)
                    .offset(y: topD + botD)
                    .opacity(isContinuePressed ? 0 : 1)

                // ③ 앞면 + 내용 — 눌리면 아래 뒷면 자리까지 완전히 내려감
                ZStack {
                    // 눌리면 앞면 색상 #565048로 변경
                    RoundedRectangle(cornerRadius: cr)
                        .fill(isContinuePressed
                              ? Color(red: 86/255, green: 80/255, blue: 72/255)
                              : frontColor)
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: isFirstTime ? "sparkles" : "play.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(isContinuePressed
                                                 ? Color(red: 213/255, green: 211/255, blue: 209/255)
                                                 : .white.opacity(0.9))
                            // 진행 기록 없으면 "시작하기", 있으면 "이어서 하기"
                            Text(isFirstTime ? "시작하기" : "이어서 하기")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(isContinuePressed
                                                 ? Color(red: 213/255, green: 211/255, blue: 209/255)
                                                 : .white)
                        }
                        Spacer()
                        // 오른쪽 보조 텍스트 — 첫 실행이면 숨김
                        if !isFirstTime {
                            if let next = next {
                                Text("\(next.chapter)-\(next.stage)")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(isContinuePressed
                                                     ? Color(red: 213/255, green: 211/255, blue: 209/255).opacity(0.6)
                                                     : .white.opacity(0.55))
                            } else {
                                Text("완료 ✓")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(isContinuePressed
                                                     ? Color(red: 213/255, green: 211/255, blue: 209/255).opacity(0.6)
                                                     : .white.opacity(0.55))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .frame(height: frontH)
                .offset(y: isContinuePressed ? topD + botD : topD)
            }
            .frame(maxWidth: .infinity)
            .frame(height: frontH + topD + botD)
        }
        // 눌림 애니메이션
        .buttonStyle(HomeThreeDButtonStyle(isPressed: $isContinuePressed))
    }

    // MARK: - 챕터 둘러보기 버튼 (크림 스타일)

    @State private var isBrowsePressed = false

    private var browseButton: some View {
        let frontH:   CGFloat = 52
        let topD:     CGFloat = 0.8
        let botD:     CGFloat = 2.5
        let cr:       CGFloat = 18
        // 크림 버튼 색상
        let frontColor = Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.22, green: 0.23, blue: 0.27, alpha: 1.0)
                : UIColor(red: 252/255, green: 249/255, blue: 238/255, alpha: 1.0) // #fcf9ee (앞면)
        })
        // 위 뒷면 색상 — #fcf9ee (연한 크림, 앞면보다 살짝 밝음)
        let topBackColor = Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.19, blue: 0.22, alpha: 1.0)
                : UIColor(red: 252/255, green: 249/255, blue: 238/255, alpha: 1.0) // #fcf9ee
        })
        // 아래 뒷면 색상 — #c4c0b5 (회베이지, 그림자 효과)
        let botBackColor = Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.13, green: 0.14, blue: 0.17, alpha: 1.0)
                : UIColor(red: 196/255, green: 192/255, blue: 181/255, alpha: 1.0) // #c4c0b5
        })

        return Button {
            navPath.append(AppRoute.chapterSelect)
        } label: {
            ZStack(alignment: .top) {
                // ① 위 뒷면 — 눌리면 사라짐
                RoundedRectangle(cornerRadius: cr)
                    .fill(topBackColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: frontH)
                    .opacity(isBrowsePressed ? 0 : 1)

                // ② 아래 뒷면 — 눌리면 사라짐
                RoundedRectangle(cornerRadius: cr)
                    .fill(botBackColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: frontH)
                    .offset(y: topD + botD)
                    .opacity(isBrowsePressed ? 0 : 1)

                // ③ 앞면 + 텍스트 — 눌리면 아래 뒷면 자리까지 완전히 내려감
                ZStack {
                    RoundedRectangle(cornerRadius: cr)
                        .fill(frontColor)
                    if isBrowsePressed {
                        RoundedRectangle(cornerRadius: cr).fill(Color.black.opacity(0.06))
                    }
                    Text("챕터 둘러보기")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: frontH)
                .offset(y: isBrowsePressed ? topD + botD : topD)
            }
            .frame(maxWidth: .infinity)
            .frame(height: frontH + topD + botD)
        }
        .buttonStyle(HomeThreeDButtonStyle(isPressed: $isBrowsePressed))
    }
}

// MARK: - HomeThreeDButtonStyle
/// 홈 화면 버튼용 3D 눌림 효과 스타일 — 별도의 opacity 변화 없이 위치만 변경
private struct HomeThreeDButtonStyle: ButtonStyle {

    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // isPressed 상태를 바인딩에 동기화 (버튼 눌림 감지)
            .onChange(of: configuration.isPressed) { _, newVal in
                withAnimation(.easeInOut(duration: 0.08)) {
                    isPressed = newVal
                }
            }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(ProgressService.shared)
}
