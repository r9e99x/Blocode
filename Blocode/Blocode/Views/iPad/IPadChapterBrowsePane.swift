//
//  IPadChapterBrowsePane.swift
//  Blocode
//
//  Created by 조준희 on 7/25/26.
//

// 아이패드 전용 — IPadContentShell에서 챕터 브라우징 중 사이드바 자리를 대체하는 3단 컬럼
// 맥의 ChapterBrowsePane과 동일한 구조를 이식(좌: 챕터 목록 / 중: 스테이지 목록 / 우: 미리보기)했고,
// 터치 조작을 고려해 행 높이·아이콘 크기만 살짝 키움 — 색상·컴포넌트는 전부 기존 것 재사용
#if os(iOS)
import SwiftUI

// MARK: - IPadChapterBrowsePane
struct IPadChapterBrowsePane: View {
    let chapterNumber: Int
    let onBackToMap: () -> Void
    let onSelectChapter: (Int) -> Void
    let onStart: (Int, Int) -> Void

    @StateObject private var vm: ChapterViewModel
    @StateObject private var chapterSelectVM = ChapterSelectViewModel()
    @State private var selectedStage: Int?
    @State private var lockInfo: LockInfo? = nil
    @State private var pressedStageNumber: Int? = nil
    /// 다크/라이트 모드 감지 — 잠긴 스테이지 아이콘 베벨 강도를 iOS ChapterView.stageIcon과 맞추는 데 사용
    @Environment(\.colorScheme) private var colorScheme

    init(chapterNumber: Int, onBackToMap: @escaping () -> Void,
         onSelectChapter: @escaping (Int) -> Void, onStart: @escaping (Int, Int) -> Void) {
        self.chapterNumber = chapterNumber
        self.onBackToMap = onBackToMap
        self.onSelectChapter = onSelectChapter
        self.onStart = onStart
        _vm = StateObject(wrappedValue: ChapterViewModel(chapter: chapterNumber))
    }

    private var chapterColor: Color {
        ChapterCatalog.chapter(chapterNumber)?.color ?? .accentColor
    }

    var body: some View {
        HStack(spacing: 0) {
            chapterListColumn
            Divider()
            stageListColumn
                .frame(width: 360)
            Divider()
            stagePreview
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                .font(.system(size: 12, weight: .bold))
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
                            lockInfo = LockInfo(title: "아직 잠겨 있어요",
                                                message: chapterSelectVM.lockMessage(for: chapter),
                                                accentColor: chapter.color)
                        }
                        return
                    }
                    guard chapter.number != chapterNumber else { return }
                    SoundService.shared.play(.buttonTap)
                    onSelectChapter(chapter.number)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9)
                                .fill(unlocked ? chapter.color : Color.lockedBackground)
                                .frame(width: 32, height: 32)
                            if unlocked {
                                Text("\(chapter.number)").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                            } else {
                                Image(systemName: "lock.fill").font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(chapter.title).font(.system(size: 14, weight: .semibold))
                            if unlocked {
                                Text("\(chapterSelectVM.chapterStars(chapter)) / \(chapter.stageCount * 3) stars")
                                    .font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(chapter.number == chapterNumber ? Color.appBackground : Color.clear)
            }
            Spacer()
        }
        .frame(width: 240)
        .background(Color.cardBackground)
    }

    // MARK: 2열 — 스테이지 목록 (챕터색 헤더 포함)

    private var stageListColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 챕터 색 헤더 카드 (iOS 가로 챕터 화면·맥 브라우저와 공용 부품)
                ChapterHeaderCard(chapterNumber: chapterNumber, title: vm.chapterTitle, color: chapterColor,
                                  earned: vm.totalStars(), maxStars: vm.stages.count * 3)
                    .padding(16)

                ForEach(vm.stages) { stage in
                    let locked = vm.isLocked(stage)
                    let cleared = vm.isCleared(stage)
                    Button {
                        if locked {
                            SoundService.shared.play(.lockButton)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                lockInfo = LockInfo(title: "아직 잠겨 있어요",
                                                    message: vm.lockMessage(for: stage),
                                                    accentColor: chapterColor)
                            }
                        } else {
                            SoundService.shared.play(.buttonTap)
                            selectedStage = stage.stageNumber
                        }
                    } label: {
                        HStack(spacing: 14) {
                            stageIcon(stage: stage, locked: locked, cleared: cleared,
                                      isPressed: pressedStageNumber == stage.stageNumber)
                            Text(stage.name).font(.system(size: 15, weight: .medium))
                                .foregroundStyle(locked ? .secondary : .primary)
                            Spacer()
                            if !locked {
                                StarRatingView(earned: vm.stars(stage), size: 12)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
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

    /// 스테이지 아이콘 — iOS ChapterView.stageIcon과 동일한 3D 3레이어 구조 + 눌림 효과
    private func stageIcon(stage: Stage, locked: Bool, cleared: Bool, isPressed: Bool) -> some View {
        let isCurrent = vm.isCurrent(stage)
        let faceColor: Color = locked ? Color.lockedBackground : (isCurrent ? Color.slateButtonFace : chapterColor)
        let iconSize: CGFloat = 40
        let radius: CGFloat = 13
        let topD: CGFloat = 1
        let botD: CGFloat = 2
        // 잠긴 아이콘은 다크모드에서만 베벨을 완화 (iOS ChapterView.stageIcon과 동일 — 라이트는 기존 0.32/0.28 유지)
        let lockedDark = locked && colorScheme == .dark

        return ThreeDSurface(topDepth: topD, bottomDepth: botD, isPressed: isPressed) {
            ZStack {
                RoundedRectangle(cornerRadius: radius).fill(faceColor)
                RoundedRectangle(cornerRadius: radius).fill(Color.white.opacity((isCurrent || lockedDark) ? 0.18 : 0.32))
            }
            .frame(width: iconSize, height: iconSize)
        } bottomBack: {
            ZStack {
                RoundedRectangle(cornerRadius: radius).fill(faceColor)
                RoundedRectangle(cornerRadius: radius).fill(Color.black.opacity(lockedDark ? 0.10 : 0.28))
            }
            .frame(width: iconSize, height: iconSize)
        } front: {
            ZStack {
                RoundedRectangle(cornerRadius: radius).fill(faceColor)
                if locked {
                    Image(systemName: "lock.fill").font(.system(size: 14)).foregroundStyle(Color.primary.opacity(0.55))
                } else if cleared {
                    Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                } else {
                    Text("\(stage.stageNumber)").font(.system(size: 17, weight: .bold, design: .serif)).italic()
                        .foregroundStyle(.white)
                }
            }
            .frame(width: iconSize, height: iconSize)
        }
        .frame(width: iconSize, height: iconSize + topD + botD)
    }

    // MARK: 3열 — 스테이지 미리보기

    @State private var isStartPressed = false

    @ViewBuilder
    private var stagePreview: some View {
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
                StagePreviewMapView(stage: stage)
                    .id(stage.id)
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: 380)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 12) {
                    previewInfoCard(label: "★ 3 = \(stage.starThresholds.threeStar) blocks")
                    previewInfoCard(label: bestRecordLabel(stage: stage))
                }

                Spacer(minLength: 0)

                // 시작하기 버튼 — 공용 SolidThreeDButton + 눌림 효과 (터치용으로 살짝 더 큼)
                Button {
                    SoundService.shared.play(.buttonTap)
                    onStart(chapterNumber, stageNumber)
                } label: {
                    // 슬레이트 3D 버튼 (공용 부품) — 잠긴 스테이지면 회색 앞면, 눌림은 내려앉기만(검정 오버레이 없음 — 기존 그대로)
                    SolidThreeDButton(height: 58, cornerRadius: 18,
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
            .padding(32)
        } else {
            Text("스테이지를 선택하세요")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// 최고 기록 라벨 — 저장된 진행 기록이 있으면 최소 블럭 수, 없으면 "-"
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

#Preview("챕터 2 브라우저", traits: .landscapeLeft) {
    IPadChapterBrowsePane(chapterNumber: 2, onBackToMap: {}, onSelectChapter: { _ in }, onStart: { _, _ in })
}
#endif
