//
//  PhoneChapterSheet.swift
//  Blocode
//
//  Created by 조준희 on 11/24/26.
//

// 아이폰 전용 챕터 시트 — 챕터 지도에서 장을 누르면 아래에서 올라옴 (아이패드는 PadChapterView, 맥은 ChapterBrowsePane)
#if os(iOS)
import SwiftUI

// MARK: - PhoneChapterSheet
/// 위: 챕터 색 배지·이름·별 진행 막대 / 가운데: 스테이지 줄 목록 / 아래 고정: 고른 스테이지 미리보기 + 시작 3D 버튼
/// 처음엔 화면 60%쯤 높이로 열리고, 끌어 올리면 전체 목록 (예전엔 장을 누르면 새 화면으로 넘어갔음)
struct PhoneChapterSheet: View {

    let chapterNumber: Int
    /// 스테이지 시작 — 지도가 시트를 닫은 뒤 게임 화면을 올림
    let onStart: (Int) -> Void

    @State private var vm: ChapterViewModel
    @State private var selectedStage: Int?
    @State private var lockInfo: LockInfo?

    /// "지금 여기" 아이콘 아래 뒷면 색 — 예전 아이폰 챕터 화면과 같은 값
    private static let currentBottomBack = Color.dynamic(light: (195/255, 189/255, 172/255),
                                                         dark: (56/255, 61/255, 76/255))

    init(chapterNumber: Int, onStart: @escaping (Int) -> Void) {
        self.chapterNumber = chapterNumber
        self.onStart = onStart
        _vm = State(initialValue: ChapterViewModel(chapter: chapterNumber))
    }

    private var chapterColor: Color {
        vm.chapterInfo?.color ?? .accentColor
    }

    /// 고른 스테이지 — 안 골랐으면 이어서 할 스테이지, 그것도 없으면 1번
    private var selected: Stage? {
        let number = selectedStage ?? vm.currentStageNumber ?? 1
        return vm.stages.first { $0.stageNumber == number }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(vm.stages) { stage in
                        stageRow(stage)
                    }
                }
            }

            if let stage = selected {
                startBar(stage)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .lockInfoPopup($lockInfo)
        .presentationDetents([.fraction(0.62), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appBackground)
        .presentationCornerRadius(28)
    }

    // MARK: - 머리글

    /// 챕터 색 번호 배지 + "CHAPTER 03" + 이름 / 오른쪽 별 수 + 아래 진행 막대
    private var header: some View {
        let earned = vm.totalStars()
        let maxStars = max(vm.maxStars, 1)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(chapterColor)
                    Text("\(chapterNumber)")
                        .font(.system(size: 20, weight: .bold, design: .serif)).italic()
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 1) {
                    Text(String(format: "CHAPTER %02d", chapterNumber))
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).tracking(1.2)
                    Text(vm.chapterTitle)
                        .font(.system(size: 22, weight: .bold))
                }
                Spacer()
                Label("\(earned) / \(vm.maxStars)", systemImage: "star.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            // 별 획득 비율 — 챕터 색
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.statCardBackground)
                    Capsule().fill(chapterColor)
                        .frame(width: geo.size.width * CGFloat(earned) / CGFloat(maxStars))
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - 스테이지 줄

    /// 3D 스테이지 아이콘 + 번호·이름 + 별(또는 "지금 여기") — 누르면 고르기, 잠겼으면 해금 조건
    private func stageRow(_ stage: Stage) -> some View {
        let locked = vm.isLocked(stage)
        let cleared = vm.isCleared(stage)
        let isCurrent = vm.isCurrent(stage)
        let isSelected = stage.stageNumber == selected?.stageNumber
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
                // 3D 스테이지 아이콘 — 예전 아이폰 챕터 화면과 같은 부품·모양
                StageIcon3D(number: stage.stageNumber, locked: locked, cleared: cleared, isCurrent: isCurrent,
                            chapterColor: chapterColor,
                            metrics: .init(size: 44, cornerRadius: 15, lockFontSize: 16, checkFontSize: 18, numberFontSize: 22),
                            isPressed: isPressed,
                            showsPressedOverlay: true,
                            currentBottomBack: Self.currentBottomBack)
                VStack(alignment: .leading, spacing: 2) {
                    Text("STAGE \(stage.stageNumber, format: .number.precision(.integerLength(2)))")
                        .font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary).tracking(1.2)
                    Text(stage.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(locked ? .secondary : .primary)
                }
                Spacer()
                if isCurrent {
                    Text("지금 여기")
                        .font(.system(size: 12, weight: .medium))
                } else if !locked {
                    StarRatingView(earned: vm.stars(stage))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
            // 고른 줄은 챕터 색 옅은 바탕
            .background(isSelected ? chapterColor.opacity(0.14) : Color.clear)
            .contentShape(Rectangle())
        }
        .opacity(locked ? 0.72 : 1.0)
    }

    // MARK: - 아래 시작 막대

    /// 고른 스테이지의 작은 미리보기 맵 + 이름·기준 + 시작 3D 버튼 — 목록을 스크롤해도 아래에 고정
    private func startBar(_ stage: Stage) -> some View {
        let locked = vm.isLocked(stage)
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                // 실제 게임과 같은 SpriteKit 미리보기 — 고른 스테이지가 바뀌면 새로 그림
                StagePreviewMapView(stage: stage)
                    .id(stage.id)
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 3) {
                    Text("STAGE \(chapterNumber)-\(stage.stageNumber)")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).tracking(1)
                    Text(stage.name)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)
                    Label("\(stage.starThresholds.threeStar)블럭 이하면 별 3개", systemImage: "star.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            // 시작 버튼 — 공용 SolidThreeDButton + 눌림 효과 (잠긴 스테이지면 회색)
            PressableButton {
                guard !locked else { return }
                SoundService.shared.play(.buttonTap)
                onStart(stage.stageNumber)
            } label: { isPressed in
                SolidThreeDButton(height: 52, cornerRadius: 16,
                                  face: locked ? Color.systemGray3Color : Color.slateButtonFace,
                                  pressedOverlayOpacity: 0, isPressed: isPressed) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(vm.isCleared(stage) ? "다시 도전" : "시작하기").fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.cardBackground)
    }
}
#endif
