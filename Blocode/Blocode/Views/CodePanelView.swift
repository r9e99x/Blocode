//
//  CodePanelView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - CodePanelView
/// 게임 화면 하단 코드 편집 패널
/// 코드 블럭 리스트 + 팔레트 + 컨트롤 바로 구성
///
/// 드래그 관련 상태(dragType, dragPosition, dragInsertIndex)는
/// StageView에서 Binding으로 받아 고스트 블럭 오버레이와 공유
struct CodePanelView: View {

    @ObservedObject var viewModel: GameViewModel  // 게임 상태 / 블럭 관리
    let stage: Stage                              // 별 기준 표시용

    // 드래그 상태 — StageView의 ghost block과 공유
    @Binding var dragType: BlockType?
    @Binding var dragPosition: CGPoint
    @Binding var dragInsertIndex: Int
    @Binding var codeListFrame: CGRect
    @Binding var rowMidYs: [Int: CGFloat]

    @Binding var navPath: NavigationPath      // 컨트롤 바 설정 초기화 시 홈 복귀용
    @Binding var isPanelExpanded: Bool        // 패널 확장/최소화 — StageView와 공유 (stageInfoBar 연동)

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // ── 패널 카드 (핸들 + 코드 리스트) ──
            VStack(spacing: 0) {

                // 드래그 핸들 — 탭으로 패널 확장/최소화 토글
                dragHandle

                if isPanelExpanded {
                    // ─── 확장 상태: 코드 리스트 헤더 + 리스트 ───
                    codeListHeader
                    codeBlockList
                    Spacer(minLength: 8)
                } else {
                    // ─── 최소화 상태: 가로 칩 요약 ───
                    collapsedChipRow
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .padding(.bottom, 6)
                }
            }
            .background(Color.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 16)
            .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 2)
            .animation(.spring(duration: 0.3), value: isPanelExpanded)

            // ── 팔레트 (카드 밖, 앱 배경에 직접) ──
            VStack(spacing: 4) {
                // "PALETTE" 레이블
                HStack {
                    Text("PALETTE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.2)
                    Spacer()
                }
                .padding(.horizontal, 20)

                // 블럭 팔레트 — 탭 추가 / 드래그 삽입 지원
                PaletteView(
                    onSelect: { type in
                        // 탭: 코드 리스트 맨 뒤에 추가
                        viewModel.addBlock(type)
                    },
                    onDragStart: { type, pt in
                        // 드래그 시작: idle 상태일 때만 허용
                        guard viewModel.gameState == .idle else { return }
                        withAnimation(.spring(duration: 0.2)) {
                            dragType = type
                            dragPosition = pt
                            dragInsertIndex = calculateInsertIndex(for: pt.y)
                        }
                    },
                    onDragChange: { _, pt in
                        // 드래그 중: 위치와 삽입 인덱스 갱신
                        dragPosition = pt
                        dragInsertIndex = calculateInsertIndex(for: pt.y)
                    },
                    onDragEnd: { type, _ in
                        // 드래그 종료: 계산된 인덱스에 블럭 삽입
                        if dragType != nil {
                            withAnimation(.spring(duration: 0.2)) {
                                viewModel.insertBlock(type, at: dragInsertIndex)
                            }
                        }
                        withAnimation(.spring(duration: 0.2)) {
                            dragType = nil  // 고스트 블럭 제거
                        }
                    }
                )
                // 실행 중에는 팔레트 비활성화 + 흐리게
                .allowsHitTesting(viewModel.gameState != .running)
                .opacity(viewModel.gameState == .running ? 0.4 : 1.0)
            }
            .padding(.top, 8)

            // 컨트롤 바
            ControlBarView(viewModel: viewModel, navPath: $navPath)
                .padding(.top, 6)
                .padding(.bottom, 24)
        }
    }

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

            Spacer()

            // 별 3개 기준 블럭 수 표시
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.starGold)
                Text("3 = \(stage.starThresholds.threeStar) blocks")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    // MARK: - 코드 블럭 리스트

    /// 사용자가 추가한 코드 블럭을 세로 리스트로 표시
    private var codeBlockList: some View {
        Group {
            if viewModel.codeBlocks.isEmpty {
                // 블럭이 없을 때 안내 메시지
                VStack(spacing: 6) {
                    Image(systemName: "plus.square.dashed")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.tertiaryLabelColor)
                    Text("아래 팔레트에서 블럭을 추가하세요")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            } else {
                List {
                    ForEach(Array(viewModel.codeBlocks.enumerated()), id: \.element.id) { offset, block in
                        // 드래그 삽입 인디케이터 — 첫 번째 위치
                        if dragType != nil && dragInsertIndex == 0 && offset == 0 {
                            insertionIndicator(color: dragType!.blockColor)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                        }

                        // 블럭 행 뷰
                        BlockRowView(
                            block: block,
                            index: offset,
                            // 실행 중이고 현재 인덱스와 일치하면 활성 표시
                            isActive: viewModel.currentBlockIndex == offset && viewModel.gameState == .running,
                            isFailed: viewModel.failedBlockIndex == offset,
                            onDelete: { viewModel.removeBlock(at: offset) },
                            onAddChild: { childType in
                                viewModel.addChildBlock(childType, to: offset)
                            },
                            onRemoveChild: { childIndex in
                                viewModel.removeChildBlock(at: childIndex, from: offset)
                            },
                            onRepeatCountChange: { count in
                                viewModel.setRepeatCount(count, at: offset)
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        // 각 행의 중간 Y 좌표를 preference로 보고 (드래그 인덱스 계산용)
                        .background(GeometryReader { geo in
                            Color.clear.preference(
                                key: RowMidYKey.self,
                                value: [offset: geo.frame(in: .global).midY]
                            )
                        })

                        // 드래그 삽입 인디케이터 — 현재 블럭 다음 위치
                        if dragType != nil && dragInsertIndex == offset + 1 {
                            insertionIndicator(color: dragType!.blockColor)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(height: 160)  // 패널 확장 시 고정 높이
        // 코드 리스트 글로벌 프레임 추적 (드래그 감지용)
        .background(GeometryReader { geo in
            Color.clear
                .onAppear { codeListFrame = geo.frame(in: .global) }
                .onChange(of: geo.size) { codeListFrame = geo.frame(in: .global) }
        })
    }

    // MARK: - 최소화 상태 칩 요약 뷰

    /// 패널 최소화 시 블럭들을 작은 칩 형태로 가로 스크롤로 표시
    private var collapsedChipRow: some View {
        HStack(spacing: 0) {
            // 가로 스크롤 칩 행
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if viewModel.codeBlocks.isEmpty {
                        // 블럭 없음 안내
                        Text("블럭 없음")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    } else {
                        // 각 블럭을 작은 칩으로 표시
                        ForEach(Array(viewModel.codeBlocks.enumerated()), id: \.element.id) { _, block in
                            blockChip(block)
                        }
                    }
                }
                .padding(.vertical, 6)
                .padding(.leading, 16)
            }

            // 블럭 수 뱃지 — 스크롤 영역 오른쪽에 고정
            HStack(spacing: 4) {
                Text("\(viewModel.totalBlockCount)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.tertiaryBackground)
                    .clipShape(Capsule())
                Text("blocks")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.leading, 8)
            .padding(.trailing, 16)
        }
        .frame(height: 36)
    }

    /// 블럭 하나를 작은 캡슐 칩으로 표시 — 아이콘 (+ repeat 횟수)
    private func blockChip(_ block: Block) -> some View {
        HStack(spacing: 3) {
            Image(systemName: block.type.shortIconName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
            // repeat 블럭은 반복 횟수도 표시
            if block.type == .repeatBlock {
                Text("×\(block.repeatCount ?? 2)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(block.type.blockColor)
        .clipShape(Capsule())
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
        .animation(.easeInOut(duration: 0.15), value: dragInsertIndex)
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
