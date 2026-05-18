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
    let chapter: Int                        // 현재 챕터 번호

    private let stages: [Stage]                     // 챕터 내 모든 스테이지 데이터
    @ObservedObject private var progress = ProgressService.shared  // 진행도 감지
    @State private var retryAlertStage:    Stage? = nil  // 재도전 확인 알럿 대상 스테이지
    @State private var pressedStageNumber: Int?   = nil  // 눌린 스테이지 아이콘 번호 추적

    init(navPath: Binding<NavigationPath>, chapter: Int) {
        self._navPath = navPath
        self.chapter  = chapter
        // 챕터 JSON 파일에서 스테이지 목록 로드
        self.stages   = StageLoader.loadChapter(chapter, stageCount: 6)
    }

    // MARK: - 챕터 색상 (챕터 번호 → 색상)
    /// 챕터 번호에 따른 고유 색상 반환 — 헤더 배경과 스테이지 아이콘에 사용
    var chapterColor: Color {
        switch chapter {
        case 1:  return Color(red: 0.576, green: 0.788, blue: 0.671) // #93c9ab — 민트
        case 2:  return Color(red: 0.580, green: 0.760, blue: 0.880)
        case 3:  return Color(red: 0.930, green: 0.620, blue: 0.420)
        case 4:  return Color(red: 0.450, green: 0.780, blue: 0.620)
        case 5:  return Color(red: 0.880, green: 0.500, blue: 0.680)
        default: return Color.accentColor
        }
    }

/// 아직 클리어하지 않은 첫 번째 스테이지 번호 (현재 진행 위치)
    /// — "지금 여기" 레이블을 이 스테이지에 표시
    private var currentStageNumber: Int? {
        stages.first {
            !progress.isLocked(chapter: $0.chapter, stageNumber: $0.stageNumber) &&
            !progress.isCleared($0.id)
        }?.stageNumber
    }

    // status bar 높이 (safe area top) — 헤더 레이아웃 계산에 사용
    private var safeAreaTop: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows.first?.safeAreaInsets.top ?? 47
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
            Button { navPath.removeLast() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                    Text("CHAPTER \(String(format: "%02d", chapter))")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)  // 자간 넓게
                }
                .foregroundStyle(Color.primary.opacity(0.55))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)

            // 챕터 제목 (한국어)
            Text(chapterTitle)
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

    /// 챕터 번호에 따른 한국어 제목 반환
    private var chapterTitle: String {
        switch chapter {
        case 1: return "기본기"
        case 2: return "변수"
        case 3: return "조건문"
        case 4: return "반복문"
        case 5: return "함수"
        default: return "챕터 \(chapter)"
        }
    }

    // MARK: - 별 진행도 바

    /// 챕터 전체 별 획득 현황을 시각화하는 바 (개별 별 아이콘 + 숫자)
    private var starProgressBar: some View {
        let total  = progress.totalStars(chapter: chapter, stageCount: stages.count)  // 현재 획득 별
        let maxStar = stages.count * 3  // 챕터 최대 별 수 (스테이지 수 × 3)

        return HStack(alignment: .center, spacing: 8) {
            // 개별 별 아이콘 나열 — 획득한 만큼 채워짐
            StarRatingView(earned: total, total: maxStar, size: 10, spacing: 2)

            Spacer()

            // 숫자 요약 (X / Y stars)
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(total) / \(maxStar)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("stars")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.primary.opacity(0.55))
            }
        }
    }

    // MARK: - 스테이지 목록

    /// 모든 스테이지를 세로로 나열하는 리스트 (구분선 포함)
    private var stageList: some View {
        VStack(spacing: 0) {
            ForEach(stages) { stage in
                stageRow(stage)

                // 구분선 (마지막 스테이지 제외)
                if stage.stageNumber < stages.count {
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
        let locked    = progress.isLocked(chapter: stage.chapter, stageNumber: stage.stageNumber)
        let cleared   = progress.isCleared(stage.id)
        let earned    = progress.stars(for: stage.id)
        let isCurrent = (stage.stageNumber == currentStageNumber)  // 현재 진행 위치 여부

        return Button {
            guard !locked else { return }  // 잠긴 스테이지는 탭 무효
            if cleared { retryAlertStage = stage }  // 클리어했으면 재도전 확인
            else { navPath.append(AppRoute.stage(chapter: stage.chapter, number: stage.stageNumber)) }
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
        let darkFace = Color(red: 42/255, green: 37/255, blue: 32/255)

        let faceColor: Color = {
            if locked    { return Color.lockedBackground }
            if isCurrent { return darkFace }
            return chapterColor
        }()

        let iconSize: CGFloat = 52
        let radius:   CGFloat = 18
        let topDepth: CGFloat = 1
        let botDepth: CGFloat = 2

        return ZStack(alignment: .top) {

            // ① 위 뒷면 — 눌리면 사라짐
            ZStack {
                RoundedRectangle(cornerRadius: radius).fill(faceColor)
                RoundedRectangle(cornerRadius: radius).fill(Color.white.opacity(isCurrent ? 0.18 : 0.32))
            }
            .frame(width: iconSize, height: iconSize)
            .opacity(isPressed ? 0 : 1)

            // ② 아래 뒷면 — 눌리면 사라짐
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
            .offset(y: topDepth + botDepth)
            .opacity(isPressed ? 0 : 1)

            // ③ 앞면 — 눌리면 아래 뒷면 자리까지 완전히 내려감
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
            .offset(y: isPressed ? topDepth + botDepth : topDepth)
        }
        .frame(width: iconSize, height: iconSize + topDepth + botDepth)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var path = NavigationPath()
    ChapterView(navPath: $path, chapter: 1)
}
