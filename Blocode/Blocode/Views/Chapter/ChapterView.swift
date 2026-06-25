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

    // safe area 조회 실패 시 사용할 폴백 높이 (노치 기기 status bar 기준 기본값)
    private let safeAreaTopFallback: CGFloat = 47

    // status bar 높이 (safe area top) — 헤더 레이아웃 계산에 사용
    private var safeAreaTop: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows.first?.safeAreaInsets.top ?? safeAreaTopFallback
    }

    var body: some View {
        VStack(spacing: 0) {
            chapterHeader   // 고정 헤더 (챕터 색상 배경)

            // 스테이지 목록 스크롤
            ScrollView(showsIndicators: false) {
                stageList
                    .padding(.top, 8)
                    .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(edges: .top)    // 헤더가 status bar 영역까지 확장
        .navigationBarHidden(true)
        .background(Color.appBackground.ignoresSafeArea())
        // 잠긴 스테이지 탭 시 해금 조건 팝업
        .overlay {
            if let lockInfo {
                LockInfoOverlay(info: lockInfo) {
                    withAnimation(.easeInOut(duration: 0.2)) { self.lockInfo = nil }
                }
                .transition(.opacity)
            }
        }
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
    private var chapterHeader: some View {
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
        let darkFace = Color.darkInk

        let faceColor: Color = {
            if locked    { return Color.lockedBackground }
            if isCurrent { return darkFace }
            return chapterColor
        }()

        let iconSize: CGFloat = 52
        let radius:   CGFloat = 18
        let topDepth: CGFloat = 1
        let botDepth: CGFloat = 2

        return ThreeDSurface(topDepth: topDepth, bottomDepth: botDepth, isPressed: isPressed) {
            // ① 위 뒷면
            ZStack {
                RoundedRectangle(cornerRadius: radius).fill(faceColor)
                RoundedRectangle(cornerRadius: radius).fill(Color.white.opacity(isCurrent ? 0.18 : 0.32))
            }
            .frame(width: iconSize, height: iconSize)
        } bottomBack: {
            // ② 아래 뒷면 — 진행 중(isCurrent)이면 단색, 아니면 faceColor + 그림자
            Group {
                if isCurrent {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color(red: 195/255, green: 189/255, blue: 172/255))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: radius).fill(faceColor)
                        RoundedRectangle(cornerRadius: radius).fill(Color.black.opacity(0.28))
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
