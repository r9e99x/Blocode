//
//  ChapterView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

// 아이폰 스테이지 목록 — iOS 전용 (맥은 SidebarShell과 상단바 컨트롤을 사용하므로 컴파일에서 제외)
#if os(iOS)
import SwiftUI

// MARK: - ChapterView
/// 특정 챕터의 스테이지 목록을 표시하는 화면
struct ChapterView: View {

    @Binding var navPath: NavigationPath    // 화면 이동 제어

    /// 챕터 화면 상태/로직 — 스테이지 로딩·진행 계산은 ViewModel이 담당 (MVVM)
    @State private var vm: ChapterViewModel

    @State private var retryConfirmInfo: RetryConfirmInfo? = nil  // 재도전 확인 팝업 (nil이면 숨김)
    @State private var lockInfo: LockInfo?         = nil  // 잠금 안내 팝업 (nil이면 숨김)
    /// 가로 모드에서 고른 스테이지 번호 — 왼쪽 헤더 아래 미리보기에 표시 (nil이면 지금 진행 위치, 없으면 1번)
    @State private var selectedStage: Int? = nil

    /// 가로 모드 미리보기에 보여 줄 스테이지
    private var previewStage: Stage? {
        let number = selectedStage ?? vm.currentStageNumber ?? 1
        return vm.stages.first { $0.stageNumber == number }
    }

    init(navPath: Binding<NavigationPath>, chapter: Int) {
        self._navPath = navPath
        // ViewModel 초기화 (스테이지 로딩은 VM 생성 시 수행)
        self._vm = State(initialValue: ChapterViewModel(chapter: chapter))
    }

    // MARK: - 챕터 색상 (챕터 번호 → 색상)
    /// 챕터 색상 — 헤더 배경과 스테이지 아이콘에 사용
    /// (색상 값 자체는 카탈로그가 보유 — 화면별 색상 이중 정의 제거)
    /// "지금 여기" 아이콘 아래 뒷면 색 — 행마다 새로 만들지 않도록 한 번만 만들어 둠 (값은 그대로)
    private static let currentBottomBack = Color.dynamic(light: (195/255, 189/255, 172/255),
                                                         dark: (56/255, 61/255, 76/255))

    var chapterColor: Color {
        vm.chapterInfo?.color ?? Color.accentColor
    }

    var body: some View {
        // GeometryReader는 safe area를 소비하지 않으므로 여기서 실제 상단 인셋을 읽고,
        // 내부 VStack만 상단 safe area를 무시해 헤더가 status bar 영역까지 확장되게 한다
        // (기존 UIApplication 기반 조회는 macOS에서 컴파일 불가 + 폴백 상수 의존이라 교체)
        GeometryReader { geo in
            if geo.size.width >= LayoutBreakpoint.wide {
                // ── 와이드(아이폰 가로모드): 좌측 챕터 헤더 패널 + 우측 스테이지 목록 분할 ──
                // 헤더는 세로모드의 풀블리드 배너 대신, 맥/아이패드의 챕터 브라우저와 동일한
                // "작은 둥근 카드" 스타일(ChapterHeaderCard)을 사용 — 세로모드 chapterHeader는 무변경
                HStack(alignment: .top, spacing: 0) {
                    // 왼쪽 — 뒤로가기 + 챕터 카드 (맥/아이패드는 별도 챕터목록 컬럼에 뒤로가기가 있지만
                    // 아이폰엔 그 컬럼이 없어서 카드 위에 별도로 배치)
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: geo.safeAreaInsets.top + 16)

                        Button {
                            SoundService.shared.play(.buttonTap)
                            navPath.pop()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 12, weight: .bold))
                                Text("CHAPTERS").tracking(1)
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                        // 챕터 색 헤더 카드 (맥/아이패드 챕터 브라우저와 공용 부품)
                        ChapterHeaderCard(chapterNumber: vm.chapter, title: vm.chapterTitle, color: chapterColor,
                                          earned: vm.totalStars(), maxStars: vm.maxStars)
                            .padding(.horizontal, 16)

                        // 카드 아래 — 오른쪽 목록에서 고른 스테이지의 맵 미리보기 + 이름·별 기준 + 시작 버튼
                        // (예전엔 여기 챕터 한 줄 설명이 가운데에 있었고, 스테이지를 누르면 바로 게임으로 들어갔음)
                        if let stage = previewStage {
                            landscapePreview(stage, mapSide: min(200, max(132, geo.size.height - 190)))
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(width: 380)
                    .frame(maxHeight: .infinity, alignment: .top)

                    // 오른쪽 — 스테이지 목록 (중앙 640pt 제한)
                    ScrollView(showsIndicators: false) {
                        stageList(isWide: true)
                            .frame(maxWidth: 640)
                            .frame(maxWidth: .infinity)
                            .padding(.top, geo.safeAreaInsets.top + 16)
                            .padding(.bottom, 48)
                    }
                }
                .ignoresSafeArea(edges: .top)
            } else {
                // ── 컴팩트(아이폰): 기존 세로 스택 ──
                VStack(spacing: 0) {
                    chapterHeader(safeAreaTop: geo.safeAreaInsets.top)   // 고정 헤더 (챕터 색상 배경)

                    // 스테이지 목록 스크롤
                    ScrollView(showsIndicators: false) {
                        stageList(isWide: false)
                            .padding(.top, 8)
                            .padding(.bottom, 48)
                    }
                }
                .ignoresSafeArea(edges: .top)    // 헤더가 status bar 영역까지 확장
            }
        }
        .hideNavigationBar()  // iOS 전용 API 래퍼 (macOS no-op)
        .background(Color.appBackground.ignoresSafeArea())
        // 잠긴 스테이지 탭 시 해금 조건 팝업 (표시 패턴은 공용 모디파이어)
        .lockInfoPopup($lockInfo)
        // 이미 클리어한 스테이지 탭 시 재도전 확인 팝업 (잠금 안내와 동일한 커스텀 카드 스타일 — 시스템 기본 Alert 미사용)
        .retryConfirmPopup($retryConfirmInfo)
    }

    // MARK: - 챕터 헤더 (컬러 배경)

    /// 챕터 색상 배경과 제목, 별 진행도를 표시하는 헤더
    /// - Parameter safeAreaTop: 상단 safe area 높이 (body의 GeometryReader에서 전달 — macOS에선 0)
    private func chapterHeader(safeAreaTop: CGFloat) -> some View {
        let depth: CGFloat = 5  // 3D 효과 깊이
        // 하단 모서리만 둥근 모양
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 0, bottomLeadingRadius: 28,
            bottomTrailingRadius: 28, topTrailingRadius: 0
        )

        return VStack(alignment: .leading, spacing: 0) {

            // status bar 공간 확보 (ignoresSafeArea로 인해 수동 처리)
            Spacer().frame(height: safeAreaTop)

            // 뒤로가기 버튼
            Button {
                            SoundService.shared.play(.buttonTap)
                            navPath.pop()
                        } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                    Text("CHAPTER \(vm.chapter, format: .number.precision(.integerLength(2)))")  // 두 자리(01)로
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)  // 자간 넓게
                }
                .foregroundStyle(Color.primary.opacity(0.55))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)

            // 챕터 제목 (한국어)
            Text(vm.chapterTitle)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.top, 6)

            // 별 진행도 바 (개별 별 + 총계)
            starProgressBar
                .padding(.top, 14)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32 + depth)   // depth만큼 여유 확보
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ChapterBevelBackground(shape: shape, color: chapterColor, depth: depth)
        }
    }

    // MARK: - 별 진행도 바

    /// 챕터 전체 별 획득 현황을 시각화하는 바 (개별 별 아이콘 + 숫자)
    private var starProgressBar: some View {
        let total  = vm.totalStars()       // 현재 획득 별
        let maxStar = vm.maxStars          // 챕터 최대 별 수

        return HStack(alignment: .top, spacing: 8) {
            // 별 아이콘 — 한 줄에 다 안 들어가면 다음 줄로 자동 감싸기
            // (예전엔 .clipped()로 넘치는 별을 그냥 잘라서 보여줬는데, 스테이지 수 많은 챕터에서
            // 오른쪽 별 몇 개가 통째로 안 보이는 문제가 있었음 — 와이드 카드 헤더와 동일한 방식으로 통일)
            WrappingStarRow(earned: total, total: maxStar, size: 10, spacing: 2, lineSpacing: 4)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 숫자 요약 (X / Y stars) — .fixedSize()로 텍스트가 절대 압축되지 않음
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(total) / \(maxStar)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("stars")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.primary.opacity(0.55))
            }
            .fixedSize()
        }
    }

    // MARK: - 스테이지 목록

    /// 모든 스테이지를 세로로 나열하는 리스트 (구분선 포함)
    /// - Parameter isWide: 가로 모드면 행을 누를 때 게임으로 가지 않고 미리보기만 바꿈
    private func stageList(isWide: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(vm.stages) { stage in
                stageRow(stage, isWide: isWide)

                // 구분선 (마지막 스테이지 제외)
                if stage.stageNumber < vm.stages.count {
                    Divider()
                        .padding(.leading, 76)   // 아이콘 너비 맞춤 들여쓰기
                        .padding(.trailing, 20)
                }
            }
        }
    }

    // MARK: - 스테이지 행

    /// 스테이지 하나를 표시하는 행 (아이콘 + 텍스트 + 별점 or "지금 여기")
    private func stageRow(_ stage: Stage, isWide: Bool) -> some View {
        let locked    = vm.isLocked(stage)
        let cleared   = vm.isCleared(stage)
        let earned    = vm.stars(stage)
        let isCurrent = vm.isCurrent(stage)  // 현재 진행 위치 여부

        return PressableButton {
            if locked {
                // 잠긴 스테이지: 전용 잠금 사운드 + 해금 조건 팝업 표시
                SoundService.shared.play(.lockButton)
                withAnimation(.easeInOut(duration: 0.2)) {
                    lockInfo = LockInfo(
                        message: vm.lockMessage(for: stage),
                        accentColor: chapterColor
                    )
                }
            } else if isWide {
                // 가로: 미리보기에 고른 스테이지를 보여 줌 — 시작은 미리보기의 버튼으로 (클리어한 스테이지의 재도전 확인도 거기서 "다시 도전")
                SoundService.shared.play(.buttonTap)
                selectedStage = stage.stageNumber
            } else if cleared {
                // 클리어했으면 재도전 확인 팝업 표시 — "다시 하기" 선택 시 스테이지로 이동 후 팝업 닫기
                SoundService.shared.play(.buttonTap)
                withAnimation(.easeInOut(duration: 0.2)) {
                    retryConfirmInfo = RetryConfirmInfo(
                        title: "이미 클리어한 스테이지예요",
                        message: "\(stage.name) — 다시 도전하겠습니까?",
                        accentColor: chapterColor,
                        onRetry: {
                            navPath.append(AppRoute.stage(chapter: stage.chapter, number: stage.stageNumber))
                            withAnimation(.easeInOut(duration: 0.2)) { retryConfirmInfo = nil }
                        }
                    )
                }
            } else {
                SoundService.shared.play(.buttonTap)
                navPath.append(AppRoute.stage(chapter: stage.chapter, number: stage.stageNumber))
            }
        } label: { isPressed in
            HStack(spacing: 16) {

                // 3D 스테이지 아이콘 (숫자 / 체크 / 자물쇠) — 맥·아이패드 브라우저와 공용 부품
                // 눌림 시 검정 오버레이, "지금 여기" 아래 뒷면은 연한 탄색 단색(라이트) / 슬레이트 그림자(다크)
                StageIcon3D(number: stage.stageNumber, locked: locked, cleared: cleared, isCurrent: isCurrent,
                            chapterColor: chapterColor,
                            metrics: .init(size: 52, cornerRadius: 18, lockFontSize: 18, checkFontSize: 20, numberFontSize: 26),
                            isPressed: isPressed,
                            showsPressedOverlay: true,
                            currentBottomBack: Self.currentBottomBack)

                // 스테이지 텍스트 정보
                VStack(alignment: .leading, spacing: 3) {
                    // "STAGE 01" 형식 서브타이틀
                    Text("STAGE \(stage.stageNumber, format: .number.precision(.integerLength(2)))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .tracking(1.2)
                    // 스테이지 이름
                    Text(stage.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(locked ? .secondary : .primary)
                }

                Spacer()

                // 오른쪽 콘텐츠 — 현재 위치이면 "지금 여기", 아니면 별점
                if isCurrent {
                    Text("지금 여기")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                } else if !locked {
                    // 획득한 별 수에 따라 채워진 별 / 빈 별 표시
                    StarRatingView(earned: earned)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            // 가로에서 미리보기로 고른 행은 챕터 색 옅은 바탕으로 표시
            .background(isWide && stage.stageNumber == previewStage?.stageNumber ? chapterColor.opacity(0.14) : Color.clear)
        }
        .opacity(locked ? 0.72 : 1.0)
    }

    // MARK: - 가로 미리보기

    /// 가로 모드 왼쪽 헤더 아래 — 맵 미리보기(왼쪽) + 스테이지 이름·별 기준·시작 버튼(오른쪽)
    /// - Parameter mapSide: 미리보기 맵 한 변 — 화면 높이에 맞춰 최대 200pt (큰 맵도 칸이 보이게)
    private func landscapePreview(_ stage: Stage, mapSide: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 실제 게임과 같은 SpriteKit 맵 — 스테이지가 바뀌면 새로 그림
            StagePreviewMapView(stage: stage)
                .id(stage.id)
                .frame(width: mapSide, height: mapSide)

            VStack(alignment: .leading, spacing: 4) {
                Text("STAGE \(stage.chapter)-\(stage.stageNumber)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Text(stage.name)
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(1)
                Text("★ 3 = \(stage.starThresholds.threeStar) blocks")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)

                PressableButton {
                    SoundService.shared.play(.buttonTap)
                    navPath.append(AppRoute.stage(chapter: stage.chapter, number: stage.stageNumber))
                } label: { isPressed in
                    SolidThreeDButton(height: 40, cornerRadius: 14, pressedOverlayOpacity: 0, isPressed: isPressed) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill").font(.system(size: 12))
                            Text(vm.isCleared(stage) ? "다시 도전" : "시작하기")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: mapSide)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var path = NavigationPath()
    ChapterView(navPath: $path, chapter: 1)
}

#Preview("가로 (와이드 헤더 카드)", traits: .landscapeLeft) {
    @Previewable @State var path = NavigationPath()
    ChapterView(navPath: $path, chapter: 2)
}
#endif
