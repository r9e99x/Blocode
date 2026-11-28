//
//  ChapterBrowsePane.swift
//  Blocode
//
//  Created by 조준희 on 7/16/26.
//

// 맥 전용 챕터 화면 (아이폰은 ChapterView, 아이패드는 PadChapterView 사용)
#if os(macOS)
import SwiftUI

// MARK: - ChapterBrowsePane
/// 사이드바에서 챕터를 골랐을 때 오른쪽 화면
/// 가운데: 챕터 색 헤더(진행 막대) + 맵 썸네일이 들어간 스테이지 카드 격자
/// 오른쪽 인스펙터: 고른 스테이지의 큰 맵·기준·최고 기록·시작 버튼 (툴바 버튼으로 접기/펼치기)
/// 툴바 ‹ › 로 이전·다음 장 이동 (예전엔 스테이지 줄 목록 + 미리보기 2칸이었음)
struct ChapterBrowsePane: View {

    let chapterNumber: Int
    /// 스테이지 시작 — 셸이 게임 화면을 올림
    let onStart: (Int, Int) -> Void
    /// 이전·다음 장으로 — 잠금 확인은 셸의 사이드바 선택과 같은 길로 처리
    let onSelectChapter: (Int) -> Void

    @State private var vm: ChapterViewModel
    @State private var selectedStage: Int?
    @State private var lockInfo: LockInfo? = nil
    @State private var showsInspector = true

    init(chapterNumber: Int, onStart: @escaping (Int, Int) -> Void, onSelectChapter: @escaping (Int) -> Void) {
        self.chapterNumber = chapterNumber
        self.onStart = onStart
        self.onSelectChapter = onSelectChapter
        _vm = State(initialValue: ChapterViewModel(chapter: chapterNumber))
    }

    private var chapterColor: Color {
        vm.chapterInfo?.color ?? .accentColor
    }

    /// 지금 고른 스테이지 — 없으면 이어서 할 스테이지, 그것도 없으면 1번
    private var selected: Stage? {
        let number = selectedStage ?? vm.currentStageNumber ?? 1
        return vm.stages.first { $0.stageNumber == number }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                chapterHeader
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 14)], spacing: 14) {
                    ForEach(vm.stages) { stage in
                        stageCard(stage)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 1000, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .inspector(isPresented: $showsInspector) {
            inspectorContent
                .inspectorColumnWidth(min: 280, ideal: 320, max: 400)
                .background(Color.appBackground)
        }
        .toolbar {
            // 이전·다음 장 — 첫 장·마지막 장에선 꺼짐
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    onSelectChapter(chapterNumber - 1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(chapterNumber <= 1)
                .help("이전 챕터")

                Button {
                    onSelectChapter(chapterNumber + 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(chapterNumber >= ChapterCatalog.all.count)
                .help("다음 챕터")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showsInspector.toggle()
                } label: {
                    Image(systemName: "sidebar.right")
                }
                .help(showsInspector ? "스테이지 정보 숨기기" : "스테이지 정보 보기")
            }
        }
        // 잠긴 스테이지 탭 시 해금 조건 팝업 (표시 패턴은 공용 모디파이어)
        .lockInfoPopup($lockInfo)
    }

    // MARK: - 챕터 헤더

    /// 챕터 색 카드 — 번호·이름·소개 + 오른쪽에 별 수와 진행 막대
    /// (예전 헤더는 별을 최대 24개까지 줄줄이 그려 두 줄로 넘쳤음)
    private var chapterHeader: some View {
        let earned = vm.totalStars()
        let maxStars = max(vm.maxStars, 1)
        return HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "CHAPTER %02d", chapterNumber))
                    .font(.system(size: 11, weight: .bold)).tracking(1.5)
                    .opacity(0.8)
                Text(vm.chapterTitle)
                    .font(.system(size: 28, weight: .bold))
                if let description = vm.chapterInfo?.description {
                    Text(description)
                        .font(.system(size: 13))
                        .opacity(0.85)
                }
            }
            Spacer(minLength: 16)
            VStack(alignment: .trailing, spacing: 8) {
                Label("\(earned) / \(vm.maxStars)", systemImage: "star.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                // 별 획득 비율 막대 — 흰색 (챕터 색 위)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.3))
                        Capsule().fill(.white)
                            .frame(width: geo.size.width * CGFloat(earned) / CGFloat(maxStars))
                    }
                }
                .frame(width: 200, height: 6)
            }
        }
        .foregroundStyle(.white)
        .padding(22)
        .background(chapterColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 스테이지 카드

    /// 맵 썸네일(잠기면 자물쇠) + 번호·이름 + 별 — 고른 카드는 챕터 색 테두리
    private func stageCard(_ stage: Stage) -> some View {
        let locked = vm.isLocked(stage)
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
                showsInspector = true  // 접어 둔 상태에서 골라도 정보가 보이게
            }
        } label: { isPressed in
            VStack(alignment: .leading, spacing: 10) {
                thumbnail(stage, locked: locked)
                HStack(spacing: 10) {
                    // 3D 스테이지 아이콘 — 아이폰 챕터 시트와 공용 부품
                    StageIcon3D(number: stage.stageNumber, locked: locked, cleared: vm.isCleared(stage),
                                isCurrent: vm.isCurrent(stage), chapterColor: chapterColor,
                                metrics: .init(size: 28, cornerRadius: 9, lockFontSize: 11, checkFontSize: 12, numberFontSize: 13),
                                isPressed: isPressed)
                    Text(stage.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(locked ? .secondary : .primary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if !locked {
                        StarRatingView(earned: vm.stars(stage), size: 10)
                    }
                }
            }
            .padding(12)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? chapterColor : Color.clear, lineWidth: 2.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .opacity(locked ? 0.72 : 1.0)
    }

    /// 카드 위쪽 맵 — 실제 게임과 같은 SpriteKit 렌더링, 잠긴 스테이지는 맵을 감추고 자물쇠만
    @ViewBuilder
    private func thumbnail(_ stage: Stage, locked: Bool) -> some View {
        if locked {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.mapBackground)
                .aspectRatio(1.0, contentMode: .fit)
                .overlay(
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                )
        } else {
            StagePreviewMapView(stage: stage)
                .id(stage.id)
                .aspectRatio(1.0, contentMode: .fit)
        }
    }

    // MARK: - 인스펙터

    @ViewBuilder
    private var inspectorContent: some View {
        if let stage = selected {
            let locked = vm.isLocked(stage)
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("STAGE \(chapterNumber)-\(stage.stageNumber)")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).tracking(1)
                        Text(stage.name).font(.system(size: 22, weight: .bold))
                    }
                    Spacer()
                    StarRatingView(earned: vm.stars(stage), size: 13)
                }

                // .id(stage.id)로 스테이지 전환 시 뷰를 새로 만들어 이전 맵이 남지 않게
                StagePreviewMapView(stage: stage)
                    .id(stage.id)
                    .aspectRatio(1.0, contentMode: .fit)

                VStack(spacing: 8) {
                    infoRow(icon: "star.fill", label: "별 3개", value: "\(stage.starThresholds.threeStar)블럭 이하")
                    infoRow(icon: "trophy.fill", label: "최고 기록", value: bestRecordLabel(stage: stage))
                }

                Spacer(minLength: 0)

                // 시작하기 버튼 — 공용 SolidThreeDButton + 눌림 효과
                PressableButton {
                    SoundService.shared.play(.buttonTap)
                    onStart(chapterNumber, stage.stageNumber)
                } label: { isPressed in
                    // 슬레이트 3D 버튼 (공용 부품) — 잠긴 스테이지면 회색 앞면, 눌림은 내려앉기만(검정 오버레이 없음 — 기존 그대로)
                    SolidThreeDButton(height: 50, cornerRadius: 16,
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
                .keyboardShortcut(.defaultAction)  // Return으로 바로 시작
            }
            .padding(20)
        } else {
            Text("스테이지를 선택하세요")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// 인스펙터 정보 한 줄 — 아이콘 + 이름 ……… 값
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(Color.starGold)
            Text(label).font(.system(size: 12)).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.statCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// 최고 기록 — 저장된 진행 기록이 있으면 최소 블럭 수, 없으면 "-"
    /// (데이터 조회는 ChapterViewModel에 위임 — 뷰가 ProgressService에 직접 접근하지 않음)
    private func bestRecordLabel(stage: Stage) -> String {
        let best = vm.bestBlockCount(stage)
        return best > 0 ? "\(best)블럭" : "-"
    }
}

// MARK: - Preview

#Preview("챕터 2") {
    ChapterBrowsePane(chapterNumber: 2, onStart: { _, _ in }, onSelectChapter: { _ in })
        .frame(width: 1040, height: 860)
}
#endif
