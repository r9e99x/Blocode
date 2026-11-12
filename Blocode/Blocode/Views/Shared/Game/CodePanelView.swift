//
//  CodePanelView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - BlockDragState
/// 팔레트 삽입 드래그와 코드 리스트 순서 변경 드래그의 상태 — StageView(고스트)와 CodePanelView(삽입선)가 공유
struct BlockDragState {
    var paletteType: BlockType? = nil      // 팔레트에서 드래그 중인 블럭 타입 (nil이면 비활성)
    var palettePosition: CGPoint = .zero   // 팔레트 드래그 현재 글로벌 좌표
    var paletteInsertIndex: Int = 0        // 삽입될 예상 인덱스

    var reorderIndex: Int? = nil           // 순서 변경 중인 블럭의 원래 인덱스 (nil이면 비활성)
    var reorderPosition: CGPoint = .zero   // 순서 변경 드래그 현재 글로벌 좌표
    var reorderTargetIndex: Int = 0        // 놓일 예상 인덱스

    var codeListFrame: CGRect = .zero      // 코드 리스트 영역의 글로벌 프레임 (놓으면 취소되는 영역 판단용)
}

// MARK: - CodePanelView
/// 게임 화면 하단 코드 편집 패널
/// 코드 블럭 리스트 + 팔레트 + 컨트롤 바로 구성
///
/// 드래그 상태(BlockDragState)는 StageView에서 Binding으로 받아 고스트 블럭 오버레이와 공유
struct CodePanelView: View {

    @ObservedObject var viewModel: GameViewModel  // 게임 상태 / 블럭 관리

    @Binding var drag: BlockDragState  // 드래그 상태 — StageView의 고스트 오버레이와 공유

    /// 각 행의 글로벌 중간 Y 좌표 (드래그 삽입 인덱스 계산용)
    /// 스크롤할 때마다 바뀌므로 BlockDragState에 넣지 않음 — 넣으면 스크롤 중 StageView 전체가 다시 그려짐
    @State private var rowMidYs: [Int: CGFloat] = [:]

    /// "코드로 보기" 시트 표시 여부
    @State private var showCodeView = false

    @Binding var isPanelExpanded: Bool        // 패널 확장/최소화 — StageView와 공유 (stageInfoBar·맵 크기와 연동)

    /// true면 확장/축소 토글 자체를 없애고 코드 리스트를 항상 펼친 상태로 고정
    /// (아이폰 가로모드·아이패드 — 이미 좌우 분할로 공간이 넉넉해 축소 기능이 필요 없음. 맥 배치는 원래 토글이 없어 영향 없음)
    var alwaysExpanded: Bool = false

    // MARK: - Body

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    #if os(iOS)
    /// iOS/iPadOS 배치 — 코드 카드(핸들+확장·축소) → 팔레트 → 컨트롤 바 (기존 그대로)
    private var iOSBody: some View {
        VStack(spacing: 0) {

            // ── 패널 카드 (핸들 + 코드 리스트) ──
            VStack(spacing: 0) {

                // 드래그 핸들 — 탭으로 패널 확장/최소화 토글 (항상 펼침 모드에선 토글 자체가 없으니 숨김)
                if !alwaysExpanded {
                    dragHandle
                }

                // 확장/축소 상태 모두 동일한 코드 리스트를 그대로 표시(드래그 삽입·순서 변경·삭제·스크롤 전부 유지) —
                // 두 상태의 차이는 StageView 쪽에서 맵 크기를 늘렸다 줄였다 해서 이 카드에 남는 세로 공간이
                // 달라지는 것뿐, CodePanelView 내부에서 다른 뷰로 바꿔치기하지 않음
                codeListHeader
                codeBlockList
                Spacer(minLength: 8)
            }
            .background(Color.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 16)
            .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 2)
            .animation(.spring(duration: 0.3), value: isPanelExpanded)

            // ── 팔레트 (카드 밖, 앱 배경에 직접) ──
            paletteView
                // 실행 중에는 팔레트 비활성화 + 흐리게
                .allowsHitTesting(viewModel.gameState != .running)
                .opacity(viewModel.gameState == .running ? 0.4 : 1.0)
                .padding(.top, 8)

            // 컨트롤 바
            ControlBarView(viewModel: viewModel)
                .padding(.top, 6)
                .padding(.bottom, 24)
        }
    }
    #endif

    #if os(macOS)
    /// 맥 전용 배치 — 팔레트를 코드 영역 위에 배치하고, 확장/축소 토글 없이 코드 리스트가 남은 세로 공간을 전부 사용
    private var macOSBody: some View {
        VStack(spacing: 10) {

            // ── 팔레트 (코드 영역 위) ──
            paletteView
                .allowsHitTesting(viewModel.gameState != .running)
                .opacity(viewModel.gameState == .running ? 0.4 : 1.0)

            // ── 코드 리스트 (확장/축소 토글 없이 항상 펼침, 남은 세로 공간 전부 사용) ──
            // 되돌리기/실행/설정은 StageView 상단바(별점 옆)로 이동했으므로 여기선 ControlBarView 미사용
            VStack(spacing: 0) {
                codeListHeader
                codeBlockList
            }
            .background(Color.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }
    #endif

    /// 블럭 팔레트 — 스테이지별 허용 블럭만 표시 / 탭 추가 / 드래그 삽입 지원 (플랫폼 공용)
    private var paletteView: some View {
        PaletteView(
            availableBlocks: viewModel.availableBlocks,
            onSelect: { type in
                // 탭: 코드 리스트 맨 뒤에 추가
                viewModel.addBlock(type)
            },
            onDragStart: { type, pt in
                // 드래그 시작: 편집 가능할 때만 허용
                guard viewModel.canEdit else { return }
                withAnimation(.spring(duration: 0.2)) {
                    drag.paletteType = type
                    drag.palettePosition = pt
                    drag.paletteInsertIndex = calculateInsertIndex(for: pt.y)
                }
            },
            onDragChange: { _, pt in
                // 드래그 중: 위치와 삽입 인덱스 갱신
                drag.palettePosition = pt
                drag.paletteInsertIndex = calculateInsertIndex(for: pt.y)
            },
            onDragEnd: { type, location in
                // 코드 리스트 영역 안에서 손을 뗐을 때만 삽입 (영역 밖이면 취소)
                if drag.codeListFrame.contains(location) {
                    withAnimation(.spring(duration: 0.2)) {
                        viewModel.insertBlock(type, at: drag.paletteInsertIndex)
                    }
                }
                withAnimation(.spring(duration: 0.2)) {
                    drag.paletteType = nil  // 고스트 블럭 제거 (삽입했든 취소했든)
                }
            }
        )
    }

    #if os(iOS)
    // MARK: - 드래그 핸들 (확장/최소화 토글)

    private var dragHandle: some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                isPanelExpanded.toggle()
            }
        } label: {
            // 확장 상태: 아래 화살표 / 최소화 상태: 위 화살표
            Image(systemName: isPanelExpanded ? "chevron.down" : "chevron.up")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.28))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
    }
    #endif

    // MARK: - 코드 리스트 헤더

    /// "CODE" 레이블 + 현재 블럭 수 뱃지 + 별 3개 기준
    private var codeListHeader: some View {
        HStack {
            // "CODE" 레이블
            Text("CODE")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1.2)

            // 현재 총 블럭 수 캡슐 뱃지
            Text("\(viewModel.totalBlockCount)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.tertiaryBackground)
                .clipShape(Capsule())

            // 코드로 보기 — 블럭이 하나라도 있을 때만 (텍스트 코드로 바꿔 보여 주는 시트)
            if viewModel.totalBlockCount > 0 {
                Button {
                    SoundService.shared.play(.buttonTap)
                    showCodeView = true
                } label: {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.tertiaryBackground)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("코드로 보기")
            }

            Spacer()

            // 별 3개 기준 블럭 수 표시
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.starGold)
                Text("3 = \(viewModel.stage.starThresholds.threeStar) blocks")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 6)
        .sheet(isPresented: $showCodeView) { CodeViewSheet(blocks: viewModel.codeBlocks) }
    }

    // MARK: - 코드 블럭 리스트

    /// 사용자가 추가한 코드 블럭을 세로 리스트로 표시
    private var codeBlockList: some View {
        Group {
            if viewModel.codeBlocks.isEmpty {
                Group {
                    // 드래그 중 코드 영역 안이면 "여기에 놓기" 드롭존, 평소엔 안내 메시지
                    if let dragType = drag.paletteType, drag.codeListFrame.contains(drag.palettePosition) {
                        // 드롭존 — 점선 박스 + 블럭 색 (블럭이 없으니 삽입선 대신 영역 강조)
                        RoundedRectangle(cornerRadius: 14)
                            .fill(dragType.blockColor.opacity(0.10))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(dragType.blockColor,
                                                  style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                            }
                            .overlay {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                    Text("여기에 놓기")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundStyle(dragType.blockColor)
                            }
                            .padding(.horizontal, 16)
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "plus.square.dashed")
                                .font(.system(size: 26))
                                .foregroundStyle(Color.tertiaryLabelColor)
                            Text("아래 팔레트에서 블럭을 추가하세요")
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            } else {
                // 순서 변경 중인 블럭의 색상 — 재정렬 삽입 인디케이터 표시용
                let reorderColor = drag.reorderIndex.flatMap { viewModel.codeBlocks.indices.contains($0) ? viewModel.codeBlocks[$0].type.blockColor : nil }

                // List의 onMove 기본 재정렬은 시스템 흰 카드 고스트가 앱의 3D 블럭 스타일과 안 맞아서
                // ScrollView+LazyVStack과 커스텀 드래그(BlockRowView.onReorderDrag*)로 교체 —
                // 팔레트 삽입 드래그와 동일한 ghost 오버레이 방식(StageView.reorderGhost)을 그대로 재사용
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(viewModel.codeBlocks.enumerated()), id: \.element.id) { offset, block in
                            // 삽입 인디케이터 — 첫 번째 위치 (팔레트 삽입 / 순서 변경 공용)
                            if let dragType = drag.paletteType, drag.codeListFrame.contains(drag.palettePosition), drag.paletteInsertIndex == 0 && offset == 0 {
                                insertionIndicator(color: dragType.blockColor)
                            }
                            if let reorderColor, drag.codeListFrame.contains(drag.reorderPosition), drag.reorderTargetIndex == 0 && offset == 0 {
                                insertionIndicator(color: reorderColor)
                            }

                            // 블럭 행 뷰
                            BlockRowView(
                                block: block,
                                index: offset,
                                isActive: viewModel.isRowActive(offset),
                                isFailed: viewModel.isRowFailed(offset),
                                activeChildPath: viewModel.activeChildPath(inRow: offset),
                                failedChildPath: viewModel.failedChildPath(inRow: offset),
                                actions: BlockEditActions(viewModel: viewModel),
                                onReorderDragStart: { pt in
                                    guard viewModel.canEdit else { return }
                                    withAnimation(.spring(duration: 0.2)) {
                                        drag.reorderIndex = offset
                                        drag.reorderPosition = pt
                                        drag.reorderTargetIndex = calculateInsertIndex(for: pt.y)
                                    }
                                },
                                onReorderDragChange: { pt in
                                    drag.reorderPosition = pt
                                    drag.reorderTargetIndex = calculateInsertIndex(for: pt.y)
                                },
                                onReorderDragEnd: { location in
                                    // 코드 리스트 영역 안에서 손을 뗐을 때만 순서 변경 (영역 밖이면 취소)
                                    if let source = drag.reorderIndex, drag.codeListFrame.contains(location) {
                                        withAnimation(.spring(duration: 0.2)) {
                                            viewModel.moveBlock(from: source, to: drag.reorderTargetIndex)
                                        }
                                    }
                                    withAnimation(.spring(duration: 0.2)) {
                                        drag.reorderIndex = nil  // 고스트 제거 (이동했든 취소했든)
                                    }
                                }
                            )
                            .padding(.horizontal, 12)
                            // 각 행의 중간 Y 좌표를 preference로 보고 (드래그 인덱스 계산용)
                            .background(GeometryReader { geo in
                                Color.clear.preference(
                                    key: RowMidYKey.self,
                                    value: [offset: geo.frame(in: .global).midY]
                                )
                            })

                            // 삽입 인디케이터 — 현재 블럭 다음 위치 (팔레트 삽입 / 순서 변경 공용)
                            if let dragType = drag.paletteType, drag.codeListFrame.contains(drag.palettePosition), drag.paletteInsertIndex == offset + 1 {
                                insertionIndicator(color: dragType.blockColor)
                            }
                            if let reorderColor, drag.codeListFrame.contains(drag.reorderPosition), drag.reorderTargetIndex == offset + 1 {
                                insertionIndicator(color: reorderColor)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        // 확장/축소 상태와 무관하게 항상 남은 세로 공간을 전부 사용 — 아이폰은 StageView가 확장 시 맵을 줄여서
        // 이 공간을 만들어줌(예전엔 고정 160pt라 블럭이 많아지면 좁은 창 안에서만 스크롤됐음)
        .frame(maxHeight: .infinity)
        // 각 행의 중간 Y 좌표를 preference로 수집 (드래그 삽입 인덱스 계산용)
        .onPreferenceChange(RowMidYKey.self) { midYs in
            rowMidYs = midYs
        }
        // 코드 리스트 글로벌 프레임 추적 (드래그 감지용)
        // size가 아닌 frame(위치+크기) 변화를 추적 — 빈 상태에선 size가 안 바뀌어
        // 좌표 갱신이 누락돼 영역 판정이 어긋났음(빈 영역 드래그 추가 불가)
        .background(GeometryReader { geo in
            Color.clear
                .onAppear { drag.codeListFrame = geo.frame(in: .global) }
                .onChange(of: geo.frame(in: .global)) { drag.codeListFrame = geo.frame(in: .global) }
        })
    }

    // MARK: - 삽입 인디케이터

    /// 드래그 중 삽입 위치를 표시하는 가로 선 + 도트
    private func insertionIndicator(color: Color) -> some View {
        HStack(spacing: 0) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Rectangle()
                .fill(color)
                .frame(height: 2)
        }
        .padding(.horizontal, 12)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.15), value: drag.paletteInsertIndex)
    }

    // MARK: - 드래그 삽입 인덱스 계산

    /// 드래그 Y 좌표를 기반으로 삽입될 인덱스 계산
    private func calculateInsertIndex(for globalY: CGFloat) -> Int {
        if rowMidYs.isEmpty { return 0 }
        // 인덱스 오름차순으로 정렬
        let sorted = rowMidYs.sorted { $0.key < $1.key }
        // 드래그 위치가 행 중간 Y보다 위면 해당 행 앞에 삽입
        for (i, entry) in sorted.enumerated() {
            if globalY < entry.value { return i }
        }
        // 모든 행보다 아래면 맨 뒤에 삽입
        return sorted.count
    }
}

// MARK: - RowMidY PreferenceKey
/// 각 블럭 행의 글로벌 중간 Y 좌표를 상위 뷰로 전달하기 위한 PreferenceKey
struct RowMidYKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    /// 여러 행의 값을 병합 — 나중에 온 값이 우선 (같은 키면 새 값으로 덮어씀)
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}
