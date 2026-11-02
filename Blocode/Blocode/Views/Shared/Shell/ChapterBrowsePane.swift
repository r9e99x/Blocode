//
//  ChapterBrowsePane.swift
//  Blocode
//
//  Created by 조준희 on 7/16/26.
//

// 아이패드·맥 공용 챕터 브라우저 (아이폰은 이 타입을 호출하지 않음 — ChapterView 사용)
import SwiftUI

// MARK: - ChapterBrowsePane
/// 챕터 브라우징 중 메인 사이드바 자리를 대체하는 3단 컬럼
/// 좌: 챕터 목록(메인 사이드바 폭·배경과 동일) / 중: 스테이지 목록(챕터색 헤더 포함) / 우: 스테이지 미리보기
/// 두 플랫폼은 크기 숫자만 다름 (터치용인 아이패드가 살짝 더 큼) — 전부 Metrics에 모음
struct ChapterBrowsePane: View {

    /// 플랫폼별 크기 수치
    private struct Metrics {
        let stageColumnWidth: CGFloat      // 2열(스테이지 목록) 폭
        let backFontSize: CGFloat          // "‹ CHAPTERS" 글자
        let chapterRowSpacing: CGFloat     // 챕터 행 아이콘-글자 간격
        let chapterBadgeSize: CGFloat      // 챕터 번호 배지 한 변
        let chapterBadgeRadius: CGFloat    // 챕터 번호 배지 모서리
        let chapterNumberFontSize: CGFloat // 배지 안 번호
        let chapterLockFontSize: CGFloat   // 배지 안 자물쇠
        let chapterTitleFontSize: CGFloat  // 챕터 이름
        let chapterStarsFontSize: CGFloat  // "N / M stars"
        let rowVerticalPadding: CGFloat    // 챕터·스테이지 행 세로 여백
        let stageIcon: StageIcon3D.Metrics // 스테이지 아이콘
        let stageNameFontSize: CGFloat     // 스테이지 이름
        let stageStarSize: CGFloat         // 스테이지 행 별
        let previewMapMaxWidth: CGFloat    // 미리보기 맵 최대 폭
        let startButtonHeight: CGFloat     // 시작 버튼 높이
        let startButtonRadius: CGFloat     // 시작 버튼 모서리

        #if os(macOS)
        static let current = Metrics(
            stageColumnWidth: 340, backFontSize: 11, chapterRowSpacing: 10,
            chapterBadgeSize: 28, chapterBadgeRadius: 8, chapterNumberFontSize: 13, chapterLockFontSize: 10,
            chapterTitleFontSize: 13, chapterStarsFontSize: 10, rowVerticalPadding: 8,
            stageIcon: .init(size: 36, cornerRadius: 12, lockFontSize: 13, checkFontSize: 14, numberFontSize: 16),
            stageNameFontSize: 14, stageStarSize: 11, previewMapMaxWidth: 360,
            startButtonHeight: 54, startButtonRadius: 16)
        #else
        static let current = Metrics(
            stageColumnWidth: 360, backFontSize: 12, chapterRowSpacing: 12,
            chapterBadgeSize: 32, chapterBadgeRadius: 9, chapterNumberFontSize: 14, chapterLockFontSize: 11,
            chapterTitleFontSize: 14, chapterStarsFontSize: 11, rowVerticalPadding: 12,
            stageIcon: .init(size: 40, cornerRadius: 13, lockFontSize: 14, checkFontSize: 15, numberFontSize: 17),
            stageNameFontSize: 15, stageStarSize: 12, previewMapMaxWidth: 380,
            startButtonHeight: 58, startButtonRadius: 18)
        #endif
    }

    private let m = Metrics.current

    let chapterNumber: Int
    let onBackToMap: () -> Void
    let onSelectChapter: (Int) -> Void
    let onStart: (Int, Int) -> Void

    @StateObject private var vm: ChapterViewModel
    @StateObject private var chapterSelectVM = ChapterSelectViewModel()
    @State private var selectedStage: Int?
    @State private var lockInfo: LockInfo? = nil
    @State private var pressedStageNumber: Int? = nil

    init(chapterNumber: Int, onBackToMap: @escaping () -> Void,
         onSelectChapter: @escaping (Int) -> Void, onStart: @escaping (Int, Int) -> Void) {
        self.chapterNumber = chapterNumber
        self.onBackToMap = onBackToMap
        self.onSelectChapter = onSelectChapter
        self.onStart = onStart
        _vm = StateObject(wrappedValue: ChapterViewModel(chapter: chapterNumber))
    }

    private var chapterColor: Color {
        vm.chapterInfo?.color ?? .accentColor
    }

    /// 이 폭보다 좁으면 왼쪽 두 칸을 줄여 미리보기 칸을 확보 — 작은 아이패드 세로에서만 걸림 (맥 창은 최소 폭이 1080이라 해당 없음)
    private let narrowLayoutWidth: CGFloat = 900

    var body: some View {
        GeometryReader { geo in
            let isNarrow = geo.size.width < narrowLayoutWidth
            HStack(spacing: 0) {
                chapterListColumn
                    .frame(width: isNarrow ? 180 : 240)
                    .background(Color.cardBackground)
                Divider()
                stageListColumn
                    .frame(width: isNarrow ? 260 : m.stageColumnWidth)
                Divider()
                stagePreview(padding: isNarrow ? 20 : 32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        // 잠긴 챕터/스테이지 탭 시 해금 조건 팝업 (표시 패턴은 공용 모디파이어)
        .lockInfoPopup($lockInfo)
        .onAppear {
            if selectedStage == nil {
                selectedStage = vm.currentStageNumber ?? 1
            }
        }
    }

    // MARK: 1열 — 챕터 목록 (메인 사이드바 자리를 대체 → 폭·배경을 사이드바와 통일)

    private var chapterListColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                SoundService.shared.play(.buttonTap)  // iOS ChapterView 뒤로가기와 동일하게 탭 효과음
                onBackToMap()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("CHAPTERS").tracking(1)
                }
                .font(.system(size: m.backFontSize, weight: .bold))
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(16)

            ForEach(chapterSelectVM.chapters) { chapter in
                let unlocked = chapterSelectVM.isUnlocked(chapter)
                Button {
                    guard unlocked else {
                        SoundService.shared.play(.lockButton)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            lockInfo = LockInfo(message: chapterSelectVM.lockMessage(for: chapter),
                                                accentColor: chapter.color)
                        }
                        return
                    }
                    guard chapter.number != chapterNumber else { return }
                    SoundService.shared.play(.buttonTap)
                    onSelectChapter(chapter.number)
                } label: {
                    HStack(spacing: m.chapterRowSpacing) {
                        ZStack {
                            RoundedRectangle(cornerRadius: m.chapterBadgeRadius)
                                .fill(unlocked ? chapter.color : Color.lockedBackground)
                                .frame(width: m.chapterBadgeSize, height: m.chapterBadgeSize)
                            if unlocked {
                                Text("\(chapter.number)").font(.system(size: m.chapterNumberFontSize, weight: .bold)).foregroundStyle(.white)
                            } else {
                                Image(systemName: "lock.fill").font(.system(size: m.chapterLockFontSize)).foregroundStyle(.secondary)
                            }
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(chapter.title).font(.system(size: m.chapterTitleFontSize, weight: .semibold))
                            if unlocked {
                                Text("\(chapterSelectVM.chapterStars(chapter)) / \(chapter.maxStars) stars")
                                    .font(.system(size: m.chapterStarsFontSize)).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, m.rowVerticalPadding)
                    .contentShape(Rectangle())  // 글자·아이콘뿐 아니라 행 전체가 눌리도록
                }
                .buttonStyle(.plain)
                .background(chapter.number == chapterNumber ? Color.appBackground : Color.clear)
            }
            Spacer()
        }
    }

    // MARK: 2열 — 스테이지 목록 (챕터색 헤더 포함)

    private var stageListColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 챕터 색 헤더 카드 (iOS 가로 챕터 화면·아이패드 브라우저와 공용 부품)
                ChapterHeaderCard(chapterNumber: chapterNumber, title: vm.chapterTitle, color: chapterColor,
                                  earned: vm.totalStars(), maxStars: vm.maxStars)
                    .padding(16)

                ForEach(vm.stages) { stage in
                    let locked = vm.isLocked(stage)
                    let cleared = vm.isCleared(stage)
                    Button {
                        if locked {
                            SoundService.shared.play(.lockButton)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                lockInfo = LockInfo(message: vm.lockMessage(for: stage),
                                                    accentColor: chapterColor)
                            }
                        } else {
                            SoundService.shared.play(.buttonTap)
                            selectedStage = stage.stageNumber
                        }
                    } label: {
                        HStack(spacing: 14) {
                            // 3D 스테이지 아이콘 — 아이폰 챕터 화면과 공용 부품 (눌림은 내려앉기만)
                            StageIcon3D(number: stage.stageNumber, locked: locked, cleared: cleared,
                                        isCurrent: vm.isCurrent(stage), chapterColor: chapterColor,
                                        metrics: m.stageIcon,
                                        isPressed: pressedStageNumber == stage.stageNumber)
                            Text(stage.name).font(.system(size: m.stageNameFontSize, weight: .medium))
                                .foregroundStyle(locked ? .secondary : .primary)
                            Spacer()
                            if !locked {
                                StarRatingView(earned: vm.stars(stage), size: m.stageStarSize)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, m.rowVerticalPadding)
                        .contentShape(Rectangle())  // 글자·아이콘뿐 아니라 행 전체가 눌리도록
                    }
                    .buttonStyle(.plain)
                    .opacity(locked ? 0.72 : 1.0)
                    .onPressState(isPressed: Binding(
                        get: { pressedStageNumber == stage.stageNumber },
                        set: { pressed in pressedStageNumber = pressed ? stage.stageNumber : nil }
                    ))
                }
            }
        }
    }

    // MARK: 3열 — 스테이지 미리보기

    @State private var isStartPressed = false

    @ViewBuilder
    private func stagePreview(padding: CGFloat) -> some View {
        if let stageNumber = selectedStage,
           let stage = vm.stages.first(where: { $0.stageNumber == stageNumber }) {
            let locked = vm.isLocked(stage)
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("STAGE \(chapterNumber)-\(stageNumber)")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).tracking(1)
                        Text(stage.name).font(.system(size: 22, weight: .bold))
                    }
                    Spacer()
                    StarRatingView(earned: vm.stars(stage), size: 13)
                }

                // 실제 게임 화면과 동일한 SpriteKit 맵 렌더링 재사용 (타일·캐릭터 완전히 동일하게 표시)
                // .id(stage.id)로 스테이지 전환 시 뷰를 확실히 새로 만들어 이전 맵이 남는 문제 방지
                // 바깥 VStack이 .leading 정렬이라 최대 폭으로 제한된 맵이 왼쪽에 붙으므로, 남은 폭 안에서 가운데 정렬
                StagePreviewMapView(stage: stage)
                    .id(stage.id)
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: m.previewMapMaxWidth)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 12) {
                    previewInfoCard(label: "★ 3 = \(stage.starThresholds.threeStar) blocks")
                    previewInfoCard(label: bestRecordLabel(stage: stage))
                }

                Spacer(minLength: 0)

                // 시작하기 버튼 — 공용 SolidThreeDButton + 눌림 효과
                Button {
                    SoundService.shared.play(.buttonTap)
                    onStart(chapterNumber, stageNumber)
                } label: {
                    // 슬레이트 3D 버튼 (공용 부품) — 잠긴 스테이지면 회색 앞면, 눌림은 내려앉기만(검정 오버레이 없음 — 기존 그대로)
                    SolidThreeDButton(height: m.startButtonHeight, cornerRadius: m.startButtonRadius,
                                      face: locked ? Color.systemGray3Color : Color.slateButtonFace,
                                      pressedOverlayOpacity: 0, isPressed: isStartPressed) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text(vm.isCleared(stage) ? "다시 도전" : "시작하기").fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .onPressState(isPressed: $isStartPressed)
                .disabled(locked)
            }
            .padding(padding)
        } else {
            Text("스테이지를 선택하세요")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// 최고 기록 라벨 — 저장된 진행 기록이 있으면 최소 블럭 수, 없으면 "-"
    /// (데이터 조회는 ChapterViewModel에 위임 — 뷰가 ProgressService에 직접 접근하지 않음)
    private func bestRecordLabel(stage: Stage) -> String {
        let best = vm.bestBlockCount(stage)
        return "최고 기록: \(best > 0 ? "\(best)" : "-") blocks"
    }

    private func previewInfoCard(label: String) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.statCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#if os(macOS)
#Preview("챕터 2 브라우저") {
    ChapterBrowsePane(chapterNumber: 2, onBackToMap: {}, onSelectChapter: { _ in }, onStart: { _, _ in })
        .frame(width: 1280, height: 860)
}
#else
#Preview("챕터 2 브라우저", traits: .landscapeLeft) {
    ChapterBrowsePane(chapterNumber: 2, onBackToMap: {}, onSelectChapter: { _ in }, onStart: { _, _ in })
}
#endif
