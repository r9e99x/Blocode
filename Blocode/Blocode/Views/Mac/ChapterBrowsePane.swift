//
//  ChapterBrowsePane.swift
//  Blocode
//
//  Created by 조준희 on 7/16/26.
//

// 맥 전용 챕터 브라우저 (아이폰은 ChapterView, 아이패드는 PadChapterView 사용)
#if os(macOS)
import SwiftUI

// MARK: - ChapterBrowsePane
/// 사이드바에서 챕터를 골랐을 때 오른쪽에 뜨는 2칸
/// 좌: 스테이지 목록(챕터색 헤더 포함) / 우: 스테이지 미리보기 (챕터 목록은 셸의 사이드바가 맡음)
/// 크기 숫자는 전부 Metrics에 모음
struct ChapterBrowsePane: View {

    /// 크기 수치
    private struct Metrics {
        let stageColumnWidth: CGFloat      // 2열(스테이지 목록) 폭
        let rowVerticalPadding: CGFloat    // 스테이지 행 세로 여백
        let stageIcon: StageIcon3D.Metrics // 스테이지 아이콘
        let stageNameFontSize: CGFloat     // 스테이지 이름
        let stageStarSize: CGFloat         // 스테이지 행 별
        let previewMapMaxWidth: CGFloat    // 미리보기 맵 최대 폭
        let startButtonHeight: CGFloat     // 시작 버튼 높이
        let startButtonRadius: CGFloat     // 시작 버튼 모서리

        static let current = Metrics(
            stageColumnWidth: 340, rowVerticalPadding: 8,
            stageIcon: .init(size: 36, cornerRadius: 12, lockFontSize: 13, checkFontSize: 14, numberFontSize: 16),
            stageNameFontSize: 14, stageStarSize: 11, previewMapMaxWidth: 360,
            startButtonHeight: 54, startButtonRadius: 16)
    }

    private let m = Metrics.current

    let chapterNumber: Int
    let onStart: (Int, Int) -> Void

    @State private var vm: ChapterViewModel
    @State private var selectedStage: Int?
    @State private var lockInfo: LockInfo? = nil

    init(chapterNumber: Int, onStart: @escaping (Int, Int) -> Void) {
        self.chapterNumber = chapterNumber
        self.onStart = onStart
        _vm = State(initialValue: ChapterViewModel(chapter: chapterNumber))
    }

    private var chapterColor: Color {
        vm.chapterInfo?.color ?? .accentColor
    }

    var body: some View {
        // 맥 창은 최소 폭이 1080이라 사이드바 옆에 두 칸이 늘 들어감
        HStack(spacing: 0) {
            stageListColumn
                .frame(width: m.stageColumnWidth)
            Divider()
            stagePreview(padding: 32)
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

    // MARK: 1열 — 스테이지 목록 (챕터색 헤더 포함)

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
                    PressableButton {
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
                    } label: { isPressed in
                        HStack(spacing: 14) {
                            // 3D 스테이지 아이콘 — 아이폰 챕터 화면과 공용 부품 (눌림은 내려앉기만)
                            StageIcon3D(number: stage.stageNumber, locked: locked, cleared: cleared,
                                        isCurrent: vm.isCurrent(stage), chapterColor: chapterColor,
                                        metrics: m.stageIcon,
                                        isPressed: isPressed)
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
                    .opacity(locked ? 0.72 : 1.0)
                }
            }
        }
    }

    // MARK: 2열 — 스테이지 미리보기

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
                PressableButton {
                    SoundService.shared.play(.buttonTap)
                    onStart(chapterNumber, stageNumber)
                } label: { isPressed in
                    // 슬레이트 3D 버튼 (공용 부품) — 잠긴 스테이지면 회색 앞면, 눌림은 내려앉기만(검정 오버레이 없음 — 기존 그대로)
                    SolidThreeDButton(height: m.startButtonHeight, cornerRadius: m.startButtonRadius,
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

#Preview("챕터 2 브라우저") {
    ChapterBrowsePane(chapterNumber: 2) { _, _ in }
        .frame(width: 1280, height: 860)
}
#endif
