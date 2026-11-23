//
//  PadChapterView.swift
//  Blocode
//
//  Created by 조준희 on 11/24/26.
//

// 아이패드 전용 챕터 화면 — 맥은 ChapterBrowsePane(3칸), 아이폰은 ChapterView를 그대로 씀
#if os(iOS)
import SwiftUI

// MARK: - PadChapterView
/// 위: 지도로 돌아가기 + 챕터 칩(가로로 넘겨 다른 챕터로 바로 이동)
/// 가로: 왼쪽(챕터 헤더 + 스테이지 목록) / 오른쪽(큰 미리보기 맵 + 기준 + 시작 버튼)
/// 세로: 챕터 헤더 → 스테이지 2열 격자 → 미리보기(맵 왼쪽, 설명·시작 버튼 오른쪽)
/// 예전엔 맥과 같은 3칸이라 세로에서 칸이 다 좁고, 작은 미리보기 맵 아래부터 시작 버튼까지 크게 비었음
struct PadChapterView: View {

    let chapterNumber: Int
    let chapterSelectVM: ChapterSelectViewModel
    /// 잠긴 챕터·스테이지를 눌렀을 때의 해금 조건 팝업 — 셸이 띄움
    @Binding var lockInfo: LockInfo?
    let onBackToMap: () -> Void
    let onSelectChapter: (Int) -> Void
    /// 시작 — (챕터, 스테이지)
    let onStart: (Int, Int) -> Void

    @State private var vm: ChapterViewModel
    @State private var selectedStage: Int?

    init(chapterNumber: Int, chapterSelectVM: ChapterSelectViewModel, lockInfo: Binding<LockInfo?>,
         onBackToMap: @escaping () -> Void, onSelectChapter: @escaping (Int) -> Void,
         onStart: @escaping (Int, Int) -> Void) {
        self.chapterNumber = chapterNumber
        self.chapterSelectVM = chapterSelectVM
        _lockInfo = lockInfo
        self.onBackToMap = onBackToMap
        self.onSelectChapter = onSelectChapter
        self.onStart = onStart
        _vm = State(initialValue: ChapterViewModel(chapter: chapterNumber))
    }

    private var chapterColor: Color {
        vm.chapterInfo?.color ?? .accentColor
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            VStack(spacing: 0) {
                topBar
                Group {
                    if isLandscape {
                        HStack(alignment: .top, spacing: 24) {
                            stageColumn
                                .frame(width: 400)
                            previewPanel(isWide: false)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        // 스테이지는 최대 8개라 2열이면 4줄 — 스크롤 없이 다 보이고 남는 높이는 미리보기가 가짐
                        VStack(spacing: 16) {
                            chapterHeader
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                                      spacing: 10) {
                                ForEach(vm.stages) { stage in
                                    stageRow(stage)
                                }
                            }
                            previewPanel(isWide: true)
                                .frame(maxHeight: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            if selectedStage == nil {
                selectedStage = vm.currentStageNumber ?? 1
            }
        }
    }

    // MARK: - 위: 지도로 + 챕터 칩

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                SoundService.shared.play(.buttonTap)
                onBackToMap()
            } label: {
                CardIconLabel(icon: "chevron.left", fontSize: 15, background: .cardBackground, shadowOpacity: 0.08, shadowY: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("챕터 지도로")

            // 지금 보는 챕터가 보이도록 가운데로 옮긴 채 시작
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(chapterSelectVM.chapters) { chapter in
                            chapterChip(chapter)
                                .id(chapter.number)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onAppear { proxy.scrollTo(chapterNumber, anchor: .center) }
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    /// 챕터 칩 — 지금 챕터는 챕터 색으로 채움, 잠긴 챕터는 자물쇠
    private func chapterChip(_ chapter: ChapterInfo) -> some View {
        let unlocked = chapterSelectVM.isUnlocked(chapter)
        let isCurrent = chapter.number == chapterNumber
        return Button {
            guard unlocked else {
                SoundService.shared.play(.lockButton)
                withAnimation(.easeInOut(duration: 0.2)) {
                    lockInfo = LockInfo(message: chapterSelectVM.lockMessage(for: chapter), accentColor: chapter.color)
                }
                return
            }
            guard !isCurrent else { return }
            SoundService.shared.play(.buttonTap)
            onSelectChapter(chapter.number)
        } label: {
            HStack(spacing: 6) {
                if unlocked {
                    Text("\(chapter.number)")
                        .font(.system(size: 13, weight: .bold, design: .serif)).italic()
                } else {
                    Image(systemName: "lock.fill").font(.system(size: 11))
                }
                Text(chapter.title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(isCurrent ? Color.white : (unlocked ? Color.primary : Color.secondary))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isCurrent ? chapter.color : Color.cardBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 왼쪽: 챕터 헤더 + 스테이지 목록

    private var stageColumn: some View {
        VStack(spacing: 14) {
            chapterHeader
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(vm.stages) { stage in
                        stageRow(stage)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    /// 챕터 색 3D 헤더 — 별은 줄바꿈되는 별 줄 대신 진행 막대 + 숫자 (별이 많은 챕터에서 둘째 줄에 몇 개만 남던 어색함 해결)
    private var chapterHeader: some View {
        let earned = vm.totalStars()
        let maxStars = max(vm.maxStars, 1)
        return VStack(alignment: .leading, spacing: 6) {
            Text("CHAPTER \(chapterNumber, format: .number.precision(.integerLength(2)))")
                .font(.system(size: 11, weight: .bold)).foregroundStyle(.white.opacity(0.7)).tracking(1)
            Text(vm.chapterTitle)
                .font(.system(size: 26, weight: .bold)).foregroundStyle(.white)
            HStack(spacing: 10) {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 6)
                    .overlay(alignment: .leading) {
                        GeometryReader { bar in
                            Capsule()
                                .fill(Color.white)
                                .frame(width: bar.size.width * CGFloat(earned) / CGFloat(maxStars))
                        }
                    }
                HStack(spacing: 3) {
                    Image(systemName: "star.fill").font(.system(size: 10))
                    Text("\(earned) / \(vm.maxStars)").font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .fixedSize()
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 18 + 5)  // 3D 뒷면 두께(5)만큼 더
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ChapterBevelBackground(shape: RoundedRectangle(cornerRadius: 18), color: chapterColor, depth: 5)
        }
    }

    /// 스테이지 한 줄 — 3D 아이콘 + 이름 + 별, 고른 스테이지는 챕터 색 테두리
    private func stageRow(_ stage: Stage) -> some View {
        let locked = vm.isLocked(stage)
        let isSelected = stage.stageNumber == selectedStage
        return PressableButton {
            if locked {
                SoundService.shared.play(.lockButton)
                withAnimation(.easeInOut(duration: 0.2)) {
                    lockInfo = LockInfo(message: vm.lockMessage(for: stage), accentColor: chapterColor)
                }
            } else {
                SoundService.shared.play(.buttonTap)
                selectedStage = stage.stageNumber
            }
        } label: { isPressed in
            HStack(spacing: 14) {
                // 3D 스테이지 아이콘 — 아이폰 챕터 화면·맥 브라우저와 공용 부품
                StageIcon3D(number: stage.stageNumber, locked: locked, cleared: vm.isCleared(stage),
                            isCurrent: vm.isCurrent(stage), chapterColor: chapterColor,
                            metrics: .init(size: 44, cornerRadius: 14, lockFontSize: 15, checkFontSize: 16, numberFontSize: 18),
                            isPressed: isPressed)
                Text(stage.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(locked ? .secondary : .primary)
                Spacer()
                if !locked {
                    StarRatingView(earned: vm.stars(stage), size: 13)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(isSelected ? chapterColor : Color.clear, lineWidth: 2)
            }
            .contentShape(Rectangle())  // 글자·아이콘뿐 아니라 줄 전체가 눌리도록
        }
        .opacity(locked ? 0.72 : 1.0)
    }

    // MARK: - 미리보기

    /// 고른 스테이지의 큰 미리보기 — 맵이 남는 공간을 최대한 차지하는 정사각형
    /// - Parameter isWide: true(세로 화면)면 맵 왼쪽·설명 오른쪽, false(가로 화면)면 위아래
    @ViewBuilder
    private func previewPanel(isWide: Bool) -> some View {
        if let stageNumber = selectedStage,
           let stage = vm.stages.first(where: { $0.stageNumber == stageNumber }) {
            Group {
                if isWide {
                    HStack(alignment: .center, spacing: 24) {
                        previewMap(stage)
                        VStack(alignment: .leading, spacing: 14) {
                            previewTitle(stage)
                            Spacer(minLength: 0)
                            infoCard(icon: "star.fill", text: "\(stage.starThresholds.threeStar)블럭 이하면 별 3개")
                            infoCard(icon: "trophy.fill", text: bestRecordText(stage))
                            startButton(stage)
                        }
                        .frame(width: 280)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 18) {
                        previewTitle(stage)
                        previewMap(stage)
                        HStack(spacing: 12) {
                            infoCard(icon: "star.fill", text: "\(stage.starThresholds.threeStar)블럭 이하면 별 3개")
                            infoCard(icon: "trophy.fill", text: bestRecordText(stage))
                        }
                        startButton(stage)
                    }
                }
            }
            .padding(24)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 28))
        } else {
            Text("스테이지를 선택하세요")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// "STAGE 5-1" + 이름 + 별
    private func previewTitle(_ stage: Stage) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("STAGE \(stage.chapter)-\(stage.stageNumber)")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary).tracking(1)
                Text(stage.name).font(.system(size: 28, weight: .bold))
            }
            Spacer()
            StarRatingView(earned: vm.stars(stage), size: 16)
        }
    }

    /// 실제 게임과 같은 SpriteKit 맵 — 남는 공간 안에서 가장 큰 정사각형 (스테이지가 바뀌면 새로 그림)
    private func previewMap(_ stage: Stage) -> some View {
        StagePreviewMapView(stage: stage)
            .id(stage.id)
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 시작하기 — 맥 브라우저와 같은 슬레이트 3D 버튼 (잠긴 스테이지면 회색)
    private func startButton(_ stage: Stage) -> some View {
        let locked = vm.isLocked(stage)
        return PressableButton {
            SoundService.shared.play(.buttonTap)
            onStart(stage.chapter, stage.stageNumber)
        } label: { isPressed in
            SolidThreeDButton(height: 60, cornerRadius: 18,
                              face: locked ? Color.systemGray3Color : Color.slateButtonFace,
                              pressedOverlayOpacity: 0, isPressed: isPressed) {
                HStack {
                    Image(systemName: "play.fill")
                    Text(vm.isCleared(stage) ? "다시 도전" : "시작하기").fontWeight(.semibold)
                }
                .foregroundStyle(.white)
            }
        }
        .disabled(locked)
    }

    /// 최고 기록 글자 — 기록이 없으면 "-" (조회는 ChapterViewModel 담당)
    private func bestRecordText(_ stage: Stage) -> String {
        let best = vm.bestBlockCount(stage)
        return "최고 기록 \(best > 0 ? "\(best)" : "-")블럭"
    }

    private func infoCard(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appBackground)  // 카드 패널 위라 패널과 다른 바탕색으로 구분
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Preview
#Preview("아이패드 챕터 2", traits: .landscapeLeft) {
    PadChapterView(chapterNumber: 2, chapterSelectVM: ChapterSelectViewModel(), lockInfo: .constant(nil),
                   onBackToMap: {}, onSelectChapter: { _ in }, onStart: { _, _ in })
}
#endif
