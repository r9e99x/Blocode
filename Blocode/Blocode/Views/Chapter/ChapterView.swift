//
//  ChapterView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - ChapterView
/// 특정 챕터의 스테이지 목록을 표시하는 화면
struct ChapterView: View {

    @Binding var navPath: NavigationPath    // 화면 이동 제어

    /// 챕터 화면 상태/로직 — 스테이지 로딩·진행 계산은 ViewModel이 담당 (MVVM)
    @StateObject private var vm: ChapterViewModel

    /// 다크/라이트 모드 감지 — 잠긴 스테이지 아이콘의 베벨 강도를 다크에서만 조정하는 데 사용
    @Environment(\.colorScheme) private var colorScheme
    @State private var retryAlertStage:    Stage? = nil  // 재도전 확인 알럿 대상 스테이지
    @State private var pressedStageNumber: Int?   = nil  // 눌린 스테이지 아이콘 번호 추적
    @State private var lockInfo: LockInfo?         = nil  // 잠금 안내 팝업 (nil이면 숨김)

    init(navPath: Binding<NavigationPath>, chapter: Int) {
        self._navPath = navPath
        // ViewModel 초기화 (스테이지 로딩은 VM 생성 시 수행)
        self._vm = StateObject(wrappedValue: ChapterViewModel(chapter: chapter))
    }

    // MARK: - 챕터 색상 (챕터 번호 → 색상)
    /// 챕터 색상 — ChapterCatalog(단일 원본)에서 조회, 헤더 배경과 스테이지 아이콘에 사용
    /// (색상 값 자체는 카탈로그가 보유 — 화면별 색상 이중 정의 제거)
    var chapterColor: Color {
        ChapterCatalog.chapter(vm.chapter)?.color ?? Color.accentColor
    }

    var body: some View {
        // GeometryReader는 safe area를 소비하지 않으므로 여기서 실제 상단 인셋을 읽고,
        // 내부 VStack만 상단 safe area를 무시해 헤더가 status bar 영역까지 확장되게 한다
        // (기존 UIApplication 기반 조회는 macOS에서 컴파일 불가 + 폴백 상수 의존이라 교체)
        GeometryReader { geo in
            if geo.size.width >= LayoutBreakpoint.wide {
                // ── 와이드(아이패드·맥): 좌측 챕터 헤더 패널 + 우측 스테이지 목록 분할 ──
                HStack(alignment: .top, spacing: 0) {
                    // 왼쪽 — 챕터 정보 패널 (색상 헤더를 고정 폭 카드로 사용)
                    chapterHeader(safeAreaTop: geo.safeAreaInsets.top)
                        .frame(width: 380)
                        .frame(maxHeight: .infinity, alignment: .top)

                    // 오른쪽 — 스테이지 목록 (중앙 640pt 제한)
                    ScrollView(showsIndicators: false) {
                        stageList
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
                        stageList
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
        // 이미 클리어한 스테이지 탭 시 재도전 확인 알럿
        .alert("이미 클리어한 스테이지예요", isPresented: Binding(
            get: { retryAlertStage != nil },
            set: { if !$0 { retryAlertStage = nil } }
        )) {
            Button("다시 하기") {
                if let s = retryAlertStage {
                    navPath.append(AppRoute.stage(chapter: s.chapter, number: s.stageNumber))
                }
                retryAlertStage = nil
            }
            Button("취소", role: .cancel) { retryAlertStage = nil }
        } message: {
            if let s = retryAlertStage { Text("\(s.name) — 다시 도전하겠습니까?") }
        }
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
            Button { if !navPath.isEmpty { navPath.removeLast() } } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                    Text("CHAPTER \(String(format: "%02d", vm.chapter))")
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
            ZStack(alignment: .top) {
                // 뒷면 — 어둡게, depth만큼 아래로 (3D 효과)
                shape.fill(chapterColor)
                    .overlay(shape.fill(Color.black.opacity(0.28)))
                    .padding(.top, depth)

                // 앞면 — depth만큼 짧게 (뒷면이 아래로 보이게)
                shape.fill(chapterColor)
                    .padding(.bottom, depth)
            }
        }
    }

    // MARK: - 별 진행도 바

    /// 챕터 전체 별 획득 현황을 시각화하는 바 (개별 별 아이콘 + 숫자)
    private var starProgressBar: some View {
        let total  = vm.totalStars()       // 현재 획득 별
        let maxStar = vm.stages.count * 3  // 챕터 최대 별 수 (스테이지 수 × 3)

        return HStack(alignment: .center, spacing: 8) {
            // 별 아이콘 — 남은 공간을 채우고, 넘치면 잘림 (스테이지 수 많을수록 별도 많아짐)
            StarRatingView(earned: total, total: maxStar, size: 10, spacing: 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()

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
    private var stageList: some View {
        VStack(spacing: 0) {
            ForEach(vm.stages) { stage in
                stageRow(stage)

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
    private func stageRow(_ stage: Stage) -> some View {
        let locked    = vm.isLocked(stage)
        let cleared   = vm.isCleared(stage)
        let earned    = vm.stars(stage)
        let isCurrent = vm.isCurrent(stage)  // 현재 진행 위치 여부

        return Button {
            if locked {
                // 잠긴 스테이지: 해금 조건 팝업 표시
                withAnimation(.easeInOut(duration: 0.2)) {
                    lockInfo = LockInfo(
                        title: "아직 잠겨 있어요",
                        message: vm.lockMessage(for: stage),
                        accentColor: chapterColor
                    )
                }
            } else if cleared {
                retryAlertStage = stage  // 클리어했으면 재도전 확인
            } else {
                navPath.append(AppRoute.stage(chapter: stage.chapter, number: stage.stageNumber))
            }
        } label: {
            HStack(spacing: 16) {

                // 3D 스테이지 아이콘 (숫자 / 체크 / 자물쇠)
                stageIcon(number: stage.stageNumber,
                          locked: locked, cleared: cleared, isCurrent: isCurrent,
                          isPressed: pressedStageNumber == stage.stageNumber)

                // 스테이지 텍스트 정보
                VStack(alignment: .leading, spacing: 3) {
                    // "STAGE 01" 형식 서브타이틀
                    Text("STAGE \(String(format: "%02d", stage.stageNumber))")
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
        }
        .buttonStyle(.plain)
        .opacity(locked ? 0.72 : 1.0)
        // 눌림 상태 추적
        .onPressState(isPressed: Binding(
            get: { pressedStageNumber == stage.stageNumber },
            set: { pressed in pressedStageNumber = pressed ? stage.stageNumber : nil }
        ))
    }

    // MARK: - 스테이지 아이콘 (챕터 버튼과 동일한 3D 구조)

    /// 스테이지 번호/상태를 표시하는 3D 아이콘
    private func stageIcon(number: Int, locked: Bool, cleared: Bool, isCurrent: Bool, isPressed: Bool = false) -> some View {
        // "지금 여기" 아이콘 앞면 — 라이트: darkInk와 동일 / 다크: 슬레이트 (다크 배경에 묻히지 않도록)
        let darkFace = Color.slateButtonFace

        let faceColor: Color = {
            if locked    { return Color.lockedBackground }
            if isCurrent { return darkFace }
            return chapterColor
        }()

        // 다크모드 여부 — 잠긴 아이콘 베벨 강도를 챕터 선택 화면의 잠긴 챕터 카드와 맞추는 데 사용
        let isDark = colorScheme == .dark

        let iconSize: CGFloat = 52
        let radius:   CGFloat = 18
        let topDepth: CGFloat = 1
        let botDepth: CGFloat = 2

        return ThreeDSurface(topDepth: topDepth, bottomDepth: botDepth, isPressed: isPressed) {
            // ① 위 뒷면
            // 잠긴 아이콘은 다크모드에서만 챕터 선택 화면 잠긴 카드와 동일한 0.18로 낮춤 (라이트는 기존 0.32 유지)
            ZStack {
                RoundedRectangle(cornerRadius: radius).fill(faceColor)
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color.white.opacity((isCurrent || (locked && isDark)) ? 0.18 : 0.32))
            }
            .frame(width: iconSize, height: iconSize)
        } bottomBack: {
            // ② 아래 뒷면 — 진행 중(isCurrent)이면 단색, 아니면 faceColor + 그림자
            Group {
                if isCurrent {
                    // 라이트: 기존 탄색 유지 / 다크: 앞면(슬레이트)보다 약간 어두운 그림자 톤
                    // (slateButtonBottomBack 다크 값과 동일, Color.dynamic 크로스플랫폼 헬퍼 사용)
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color.dynamic(light: (195/255, 189/255, 172/255),
                                            dark: (56/255, 61/255, 76/255)))
                } else {
                    // 잠긴 아이콘은 다크모드에서만 챕터 선택 화면 잠긴 카드와 동일한 0.10으로 낮춤 (라이트는 기존 0.28 유지)
                    ZStack {
                        RoundedRectangle(cornerRadius: radius).fill(faceColor)
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color.black.opacity((locked && isDark) ? 0.10 : 0.28))
                    }
                }
            }
            .frame(width: iconSize, height: iconSize)
        } front: {
            // ③ 앞면 — faceColor + (눌림 시 그림자) + 상태 아이콘
            ZStack {
                RoundedRectangle(cornerRadius: radius).fill(faceColor)
                if isPressed {
                    RoundedRectangle(cornerRadius: radius).fill(Color.black.opacity(0.10))
                }
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.primary.opacity(0.55))
                } else if cleared {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .italic()
                        .foregroundStyle(.white)
                }
            }
            .frame(width: iconSize, height: iconSize)
        }
        .frame(width: iconSize, height: iconSize + topDepth + botDepth)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var path = NavigationPath()
    ChapterView(navPath: $path, chapter: 1)
}
