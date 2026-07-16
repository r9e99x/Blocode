//
//  BlockRowView.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - BlockRowView
/// 코드 순서 리스트에서 하나의 블럭을 표시하는 행 뷰
/// 실행 중 활성/실패 하이라이트, repeat 블럭의 자식 인라인 표시 지원
struct BlockRowView: View {

    let block: Block            // 표시할 블럭 데이터
    let index: Int              // 코드 순서에서의 인덱스 (1부터 표시)
    let isActive: Bool          // 현재 실행 중인 블럭 여부 (흰 테두리 하이라이트)
    let isFailed: Bool          // 실패한 블럭 여부 (빨간 막대 표시)
    // 실행 중인 자식의 상대 경로 — [자식 인덱스] 또는 [자식, 손자], 이 행 내부가 아니면 빈 배열
    // (기본값 빈 배열 → 하이라이트가 필요 없는 호출부/프리뷰는 생략 가능)
    var activeChildPath: [Int] = []
    // 실패한 자식의 상대 경로 — 형식은 activeChildPath와 동일
    var failedChildPath: [Int] = []
    let onDelete: (() -> Void)?                                      // 블럭 삭제 콜백
    let onAddChild: ((BlockType) -> Void)?                           // 자식 블럭 추가 콜백
    let onRemoveChild: ((Int) -> Void)?                              // 자식 블럭 삭제 콜백
    let onRepeatCountChange: ((Int) -> Void)?                        // repeat 횟수 변경 콜백
    let onIfConditionChange: ((IfCondition) -> Void)?                // if 조건 변경 콜백
    // 중첩 블럭 (자식 컨테이너의 손자 블럭) 관리 콜백
    let onAddGrandchild: ((BlockType, Int) -> Void)?                 // (type, childIndex)
    let onRemoveGrandchild: ((Int, Int) -> Void)?                    // (grandchildIndex, childIndex)
    let onSetChildIfCondition: ((IfCondition, Int) -> Void)?         // (condition, childIndex)
    let onSetChildRepeatCount: ((Int, Int) -> Void)?                 // (count, childIndex)
    // 증손자 블럭(손자 컨테이너의 자식) 관리 콜백 — 손자가 repeat/if일 때만 사용, 3단 중첩 지원
    var onAddGreatGrandchild: ((BlockType, Int, Int) -> Void)? = nil       // (type, childIndex, grandchildIndex)
    var onRemoveGreatGrandchild: ((Int, Int, Int) -> Void)? = nil          // (greatGrandchildIndex, childIndex, grandchildIndex)
    var onSetGrandchildIfCondition: ((IfCondition, Int, Int) -> Void)? = nil   // (condition, childIndex, grandchildIndex)
    var onSetGrandchildRepeatCount: ((Int, Int, Int) -> Void)? = nil           // (count, childIndex, grandchildIndex)
    // 코드 리스트 내 순서 변경(재정렬) 드래그 콜백 — 팔레트의 삽입 드래그와 동일한 구조(글로벌 좌표 전달)
    var onReorderDragStart:  ((CGPoint) -> Void)? = nil
    var onReorderDragChange: ((CGPoint) -> Void)? = nil
    var onReorderDragEnd:    ((CGPoint) -> Void)? = nil

    // 자식 블럭 추가 팔레트 펼침 여부
    @State private var showChildPalette = false
    // 손자 블럭 추가 팔레트 펼침 여부 (자식 인덱스별 관리)
    @State private var showGrandchildPalette: [UUID: Bool] = [:]
    // 증손자 블럭 추가 팔레트 펼침 여부 (손자 인덱스별 관리)
    @State private var showGreatGrandchildPalette: [UUID: Bool] = [:]

    // 순서 변경 드래그 상태 (PaletteCardView의 드래그 감지 로직과 동일한 구조)
    @State private var isReorderPressed = false
    @State private var isReorderDragging = false
    @State private var reorderLongPressTimer: Timer? = nil

    // 3D 카드 파라미터 — 맥은 코드 패널 폭이 좁아 블럭도 축소, iOS/아이패드는 기존 크기 유지
    #if os(macOS)
    private let frontH:  CGFloat = 34
    private let topD:    CGFloat = 1.3
    private let botD:    CGFloat = 2.2
    private let cr:      CGFloat = 10
    #else
    private let frontH:  CGFloat = 48  // 앞면 높이
    private let topD:    CGFloat = 2   // 위 뒷면 두께
    private let botD:    CGFloat = 3   // 아래 뒷면 두께
    private let cr:      CGFloat = 14  // 모서리 반지름
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 메인 블럭 행 항상 표시
            blockRow
            // 컨테이너 블럭(repeat/if/function)이면 자식 블럭 영역 추가 표시
            if block.hasChildren {
                containerChildArea
            }
        }
    }

    // MARK: - 메인 블럭 행 (3D 버튼)

    private var blockRow: some View {
        HStack(spacing: 10) {

            // 순서 번호 — 블럭 밖 왼쪽에 표시 (1-based index)
            Text("\(index + 1)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.tertiaryLabelColor)
                .frame(width: 18, alignment: .center)

            // 3D 블럭 본체 — ZStack으로 세 레이어 적층
            ZStack(alignment: .top) {

                // ① 뒷면 위 (blockColor + white 0.30) — 앞면보다 위에 보임
                ZStack {
                    RoundedRectangle(cornerRadius: cr).fill(blockFaceColor)
                    RoundedRectangle(cornerRadius: cr).fill(Color.white.opacity(0.30))
                }
                .frame(maxWidth: .infinity)
                .frame(height: frontH)

                // ② 뒷면 아래 (blockColor + black 0.22) — 그림자 효과
                ZStack {
                    RoundedRectangle(cornerRadius: cr).fill(blockFaceColor)
                    RoundedRectangle(cornerRadius: cr).fill(Color.black.opacity(0.22))
                }
                .frame(maxWidth: .infinity)
                .frame(height: frontH)
                .offset(y: topD + botD)  // 앞면 아래로 오프셋

                // ③ 앞면 (blockColor + 내용) — topDepth만큼 아래로
                ZStack {
                    RoundedRectangle(cornerRadius: cr).fill(blockFaceColor)

                    // 실행 중 — 흰 테두리 오버레이로 하이라이트
                    if isActive {
                        RoundedRectangle(cornerRadius: cr)
                            .strokeBorder(Color.white.opacity(0.7), lineWidth: 2)
                    }

                    HStack(spacing: 10) {
                        // 아이콘+이름+빈 공간 전체가 드래그 영역 — 실제 컨트롤(스테퍼·토글·삭제 버튼)만 제외
                        // (그 컨트롤들과 겹치면 탭이 막히므로, 블럭에서 컨트롤을 뺀 나머지 전부를 여기 포함)
                        HStack(spacing: 10) {
                            // 블럭 종류 아이콘
                            Image(systemName: block.type.iconName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 22)

                            // 블럭 이름
                            Text(block.type.displayName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)

                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                        #if os(macOS)
                        .highPriorityGesture(reorderDragGesture)
                        #else
                        .gesture(reorderDragGesture)
                        #endif

                        // repeat 블럭 전용 — 반복 횟수 스테퍼
                        if block.isRepeatBlock, let count = block.repeatCount {
                            repeatCountStepper(count: count)
                        }

                        // if 블럭 전용 — 조건 선택 토글 버튼
                        if block.type == .ifBlock, let condition = block.ifCondition {
                            Button {
                                // 탭할 때마다 pathClear ↔ pathBlocked 전환
                                let next: IfCondition = condition == .pathClear ? .pathBlocked : .pathClear
                                onIfConditionChange?(next)
                            } label: {
                                HStack(spacing: 4) {
                                    Text(condition.displayName)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    // 전환 가능함을 나타내는 화살표 아이콘
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.20))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.borderless)
                            .disabled(isActive)  // 실행 중에는 변경 불가
                        }

                        // 삭제 버튼 — 실행 중에는 숨김
                        if let onDelete, !isActive {
                            Button {
                                withAnimation(.spring(duration: 0.2)) { onDelete() }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.white.opacity(0.6))
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.horizontal, 14)

                }
                .frame(maxWidth: .infinity)
                .frame(height: frontH)
                .offset(y: topD)  // 위 뒷면이 살짝 보이도록 아래로 오프셋
            }
            .frame(maxWidth: .infinity)
            .frame(height: frontH + topD + botD)  // 전체 3D 높이 확보
            .animation(.easeInOut(duration: 0.15), value: isActive)
            .animation(.easeInOut(duration: 0.15), value: isFailed)

            // 실패 — 3D 블럭 오른쪽 바깥에 세로 빨간 막대 표시
            if isFailed {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.95, green: 0.25, blue: 0.20))
                    .frame(width: 4, height: frontH * 0.6)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isFailed)
        // 순서 변경 드래그 중: 원래 자리는 흐리게(고스트가 손가락을 따라감) / 누른 상태: 살짝 축소
        .opacity(isReorderDragging ? 0.35 : 1.0)
        .scaleEffect(isReorderPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isReorderDragging)
        .animation(.spring(response: 0.2,  dampingFraction: 0.8), value: isReorderPressed)
    }

    /// 순서 변경 활성화 여부 — onReorderDragStart 콜백이 있을 때만 활성화 (PaletteCardView.dragEnabled와 동일 패턴)
    private var reorderDragEnabled: Bool { onReorderDragStart != nil }

    /// 코드 리스트 내 순서 변경 드래그 제스처 — 0.38초 롱프레스 후 드래그 시작 (PaletteCardView.dragGesture와 동일 구조)
    private var reorderDragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if isReorderDragging {
                    onReorderDragChange?(value.location)
                } else if reorderLongPressTimer == nil && reorderDragEnabled {
                    withAnimation { isReorderPressed = true }
                    let timer = Timer(timeInterval: 0.38, repeats: false) { _ in
                        DispatchQueue.main.async {
                            withAnimation { isReorderDragging = true; isReorderPressed = false }
                            onReorderDragStart?(value.location)
                        }
                    }
                    #if os(macOS)
                    // 마우스를 누르고 있는 동안(.eventTracking 런루프)에도 타이머가 돌도록 .common 모드로 등록
                    RunLoop.current.add(timer, forMode: .common)
                    #else
                    RunLoop.current.add(timer, forMode: .default)  // 기존 Timer.scheduledTimer와 동일 (동작 변화 없음)
                    #endif
                    reorderLongPressTimer = timer
                }
            }
            .onEnded { value in
                reorderLongPressTimer?.invalidate()
                reorderLongPressTimer = nil
                if isReorderDragging {
                    onReorderDragEnd?(value.location)
                }
                withAnimation { isReorderDragging = false; isReorderPressed = false }
            }
    }

    /// 블럭 앞면 색상 — 블럭 타입에 따라 결정
    private var blockFaceColor: Color {
        block.type.blockColor
    }

    // MARK: - Repeat 횟수 스테퍼

    /// repeat 블럭의 반복 횟수를 조절하는 스테퍼 컴포넌트
    private func repeatCountStepper(count: Int) -> some View {
        HStack(spacing: 0) {
            // 횟수 감소 버튼 (최소 1회)
            Button {
                onRepeatCountChange?(max(1, count - 1))
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.borderless)

            // 현재 횟수 표시 ("2×" 형식)
            Text("\(count)×")
                .font(.system(size: 13, weight: .bold))
                .monospacedDigit()
                .frame(minWidth: 24)

            // 횟수 증가 버튼 (최대 10회)
            Button {
                onRepeatCountChange?(min(10, count + 1))
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.borderless)
        }
        .foregroundStyle(.white)
        .background(Color.white.opacity(0.18))  // 반투명 흰 배경
        .clipShape(Capsule())
    }

    // MARK: - 컨테이너 블럭 공통 헬퍼

    /// 컨테이너 블럭 종류에 따른 끝 레이블 텍스트
    private var containerEndLabel: String {
        switch block.type {
        case .repeatBlock:   return "end repeat"
        case .ifBlock:       return "end if"
        case .functionBlock: return "end function"
        default:             return "end"
        }
    }

    // MARK: - 컨테이너 블럭 자식 영역

    /// 컨테이너 블럭(repeat/if/function) 아래에 표시되는 자식 블럭 목록 및 추가 UI
    private var containerChildArea: some View {
        VStack(alignment: .leading, spacing: 4) {

            if let children = block.children, !children.isEmpty {
                // 자식 블럭 목록 표시
                ForEach(Array(children.enumerated()), id: \.element.id) { childIndex, child in
                    HStack(spacing: 10) {
                        Color.clear.frame(width: 28) // 번호 열 맞춤 (부모 인덱스 번호 너비)
                        // 세로 연결선 — 자식 블럭들의 들여쓰기 표시
                        Rectangle()
                            .fill(block.type.blockColor.opacity(0.35))
                            .frame(width: 2)
                        // 자식 블럭 미니 행
                        childBlockMiniRow(child, index: childIndex)
                    }
                }
            } else {
                // 자식 블럭이 없을 때 안내 텍스트
                HStack(spacing: 10) {
                    Color.clear.frame(width: 28)
                    Rectangle()
                        .fill(block.type.blockColor.opacity(0.35))
                        .frame(width: 2)
                    Text("블럭을 추가하세요")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 8)
                }
            }

            // 자식 블럭 추가 버튼 — 탭 시 미니 팔레트 토글
            HStack(spacing: 10) {
                Color.clear.frame(width: 28)
                Rectangle()
                    .fill(block.type.blockColor.opacity(0.35))
                    .frame(width: 2)
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        showChildPalette.toggle()
                    }
                } label: {
                    Label("추가", systemImage: "plus.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(block.type.blockColor)
                }
                .buttonStyle(.borderless)
                .padding(.vertical, 4)
            }

            // 미니 팔레트 — 자식 블럭 타입 선택
            if showChildPalette {
                childMiniPalette
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
            }

            // 컨테이너 블럭 끝 레이블 — 블럭 타입별로 다른 텍스트 표시
            Text(containerEndLabel)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(block.type.blockColor.opacity(0.5))
                .padding(.top, 2)
        }
        .padding(.leading, 18)
        .padding(.bottom, 8)
    }

    /// 자식 블럭 하나를 표시하는 미니 행 뷰
    /// 자식이 컨테이너(repeat/if)이면 손자 블럭 영역과 조건/횟수 컨트롤도 함께 표시
    private func childBlockMiniRow(_ child: Block, index childIndex: Int) -> some View {
        // 이 자식(또는 그 손자)이 현재 실행/실패 중인지 — 경로 첫 요소로 판별
        let isChildActive = activeChildPath.first == childIndex
        let isChildFailed = failedChildPath.first == childIndex

        return VStack(alignment: .leading, spacing: 4) {

            // ── 자식 블럭 헤더 행 ──
            HStack(spacing: 8) {
                Image(systemName: child.type.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(child.type.blockColor)
                Text(child.type.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                // 중첩 repeat 전용: 횟수 스테퍼
                if child.type == .repeatBlock, let count = child.repeatCount {
                    nestedRepeatStepper(count: count, childIndex: childIndex)
                }

                // 중첩 if 전용: 조건 토글 버튼
                if child.type == .ifBlock, let condition = child.ifCondition {
                    Button {
                        let next: IfCondition = condition == .pathClear ? .pathBlocked : .pathClear
                        onSetChildIfCondition?(next, childIndex)
                    } label: {
                        HStack(spacing: 3) {
                            Text(condition.displayName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(child.type.blockColor)
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(child.type.blockColor.opacity(0.7))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(child.type.lightColor)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.borderless)
                }

                // 자식 삭제 버튼
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { onRemoveChild?(childIndex) }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(child.type.lightColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            // 실행/실패 중 테두리 하이라이트 — 밝은 lightColor 배경 위라
            // (최상위 행의 흰 테두리 대신) 블럭 색/실패 색 테두리로 표시
            .overlay {
                if isChildActive {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(child.type.blockColor.opacity(0.9), lineWidth: 2)
                } else if isChildFailed {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color(red: 0.95, green: 0.25, blue: 0.20), lineWidth: 2)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isChildActive)
            .animation(.easeInOut(duration: 0.15), value: isChildFailed)

            // 자식이 컨테이너이면 손자 블럭 영역 표시
            if child.hasChildren {
                grandchildArea(child: child, childIndex: childIndex)
            }
        }
    }

    /// 중첩 repeat 블럭의 횟수 스테퍼 (소형)
    private func nestedRepeatStepper(count: Int, childIndex: Int) -> some View {
        HStack(spacing: 0) {
            Button { onSetChildRepeatCount?(max(1, count - 1), childIndex) } label: {
                Image(systemName: "minus").font(.system(size: 10, weight: .bold)).frame(width: 22, height: 22)
            }
            Text("\(count)×").font(.system(size: 12, weight: .bold)).monospacedDigit().frame(minWidth: 18)
            Button { onSetChildRepeatCount?(min(10, count + 1), childIndex) } label: {
                Image(systemName: "plus").font(.system(size: 10, weight: .bold)).frame(width: 22, height: 22)
            }
        }
        .foregroundStyle(BlockType.repeatBlock.blockColor)
        .background(BlockType.repeatBlock.lightColor)
        .clipShape(Capsule())
        .buttonStyle(.borderless)
    }

    /// 손자 블럭 영역 — 자식 컨테이너(repeat/if)의 내부 블럭 목록 + 추가 버튼
    /// 손자 자신이 컨테이너(repeat/if)이면 조건/횟수 컨트롤 + 증손자 영역까지 표시 (3단 중첩 지원)
    private func grandchildArea(child: Block, childIndex: Int) -> some View {
        let lineColor = child.type.blockColor.opacity(0.30)

        return VStack(alignment: .leading, spacing: 3) {

            // 손자 블럭 목록
            if let grandchildren = child.children, !grandchildren.isEmpty {
                ForEach(Array(grandchildren.enumerated()), id: \.element.id) { gcIdx, gc in
                    grandchildRow(gc, childIndex: childIndex, grandchildIndex: gcIdx, lineColor: lineColor)
                }
            } else {
                HStack(spacing: 6) {
                    Rectangle().fill(lineColor).frame(width: 2)
                    Text("블럭을 추가하세요").font(.caption).foregroundStyle(.tertiary).padding(.vertical, 4)
                }
            }

            // 손자 블럭 추가 버튼
            HStack(spacing: 6) {
                Rectangle().fill(lineColor).frame(width: 2)
                Button {
                    withAnimation(.spring(duration: 0.2)) {
                        showGrandchildPalette[child.id, default: false].toggle()
                    }
                } label: {
                    Label("추가", systemImage: "plus.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(child.type.blockColor)
                }
                .buttonStyle(.borderless)
                .padding(.vertical, 2)
            }

            // 손자 팔레트
            if showGrandchildPalette[child.id, default: false] {
                grandchildMiniPalette(child: child, childIndex: childIndex)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
            }

            // end 레이블
            Text(child.type == .repeatBlock ? "end repeat" : "end if")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(child.type.blockColor.opacity(0.45))
                .padding(.top, 1)
        }
        .padding(.leading, 14)
    }

    /// 손자 블럭 하나를 표시하는 행 — 손자가 컨테이너(repeat/if)면 조건/횟수 컨트롤과 증손자 영역도 함께 표시
    private func grandchildRow(_ gc: Block, childIndex: Int, grandchildIndex gcIdx: Int, lineColor: Color) -> some View {
        // 이 손자(또는 그 증손자)가 현재 실행/실패 중인지 — 경로가 [자식, 손자]로 시작하면 조상 하이라이트
        // (증손자가 실행 중이어도 손자 행 테두리가 함께 강조되도록 자식 행과 동일한 prefix 방식 사용)
        let isGcActive = activeChildPath.starts(with: [childIndex, gcIdx])
        let isGcFailed = failedChildPath.starts(with: [childIndex, gcIdx])

        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Rectangle().fill(lineColor).frame(width: 2)
                HStack(spacing: 6) {
                    Image(systemName: gc.type.iconName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(gc.type.blockColor)
                    Text(gc.type.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)

                    Spacer()

                    // 중첩 repeat 전용: 횟수 스테퍼 (손자가 repeat일 때)
                    if gc.type == .repeatBlock, let count = gc.repeatCount {
                        HStack(spacing: 0) {
                            Button { onSetGrandchildRepeatCount?(max(1, count - 1), childIndex, gcIdx) } label: {
                                Image(systemName: "minus").font(.system(size: 9, weight: .bold)).frame(width: 20, height: 20)
                            }
                            Text("\(count)×").font(.system(size: 11, weight: .bold)).monospacedDigit().frame(minWidth: 16)
                            Button { onSetGrandchildRepeatCount?(min(10, count + 1), childIndex, gcIdx) } label: {
                                Image(systemName: "plus").font(.system(size: 9, weight: .bold)).frame(width: 20, height: 20)
                            }
                        }
                        .foregroundStyle(BlockType.repeatBlock.blockColor)
                        .background(BlockType.repeatBlock.lightColor)
                        .clipShape(Capsule())
                        .buttonStyle(.borderless)
                    }

                    // 중첩 if 전용: 조건 토글 버튼 (손자가 if일 때)
                    if gc.type == .ifBlock, let condition = gc.ifCondition {
                        Button {
                            let next: IfCondition = condition == .pathClear ? .pathBlocked : .pathClear
                            onSetGrandchildIfCondition?(next, childIndex, gcIdx)
                        } label: {
                            HStack(spacing: 3) {
                                Text(condition.displayName)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(gc.type.blockColor)
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(gc.type.blockColor.opacity(0.7))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(gc.type.lightColor)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.borderless)
                    }

                    Button {
                        withAnimation { onRemoveGrandchild?(gcIdx, childIndex) }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary.opacity(0.45))
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(gc.type.lightColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                // 실행/실패 중 테두리 하이라이트 — 자식 미니 행과 동일한 방식
                .overlay {
                    if isGcActive {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(gc.type.blockColor.opacity(0.9), lineWidth: 2)
                    } else if isGcFailed {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color(red: 0.95, green: 0.25, blue: 0.20), lineWidth: 2)
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: isGcActive)
                .animation(.easeInOut(duration: 0.15), value: isGcFailed)
            }

            // 손자가 컨테이너(repeat/if)이면 증손자 영역 표시
            if gc.hasChildren {
                greatGrandchildArea(grandchild: gc, childIndex: childIndex, grandchildIndex: gcIdx)
            }
        }
    }

    /// 증손자 블럭 영역 — 손자 컨테이너(repeat/if)의 내부 블럭 목록 + 추가 버튼
    /// 여기서는 기본 동작 블럭만 허용해 더 깊은 중첩(4단 이상)은 만들지 않음
    private func greatGrandchildArea(grandchild: Block, childIndex: Int, grandchildIndex gcIdx: Int) -> some View {
        let lineColor = grandchild.type.blockColor.opacity(0.30)

        return VStack(alignment: .leading, spacing: 2) {
            if let greatGrandchildren = grandchild.children, !greatGrandchildren.isEmpty {
                ForEach(Array(greatGrandchildren.enumerated()), id: \.element.id) { ggcIdx, ggc in
                    // 증손자는 항상 기본 동작 블럭(leaf)이므로 경로 완전 일치로 판별
                    let isActive = activeChildPath == [childIndex, gcIdx, ggcIdx]
                    let isFailed = failedChildPath == [childIndex, gcIdx, ggcIdx]

                    HStack(spacing: 5) {
                        Rectangle().fill(lineColor).frame(width: 2)
                        HStack(spacing: 5) {
                            Image(systemName: ggc.type.iconName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(ggc.type.blockColor)
                            Text(ggc.type.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            Button {
                                withAnimation { onRemoveGreatGrandchild?(ggcIdx, childIndex, gcIdx) }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.secondary.opacity(0.45))
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(ggc.type.lightColor)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay {
                            if isActive {
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(ggc.type.blockColor.opacity(0.9), lineWidth: 2)
                            } else if isFailed {
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(Color(red: 0.95, green: 0.25, blue: 0.20), lineWidth: 2)
                            }
                        }
                        .animation(.easeInOut(duration: 0.15), value: isActive)
                        .animation(.easeInOut(duration: 0.15), value: isFailed)
                    }
                }
            } else {
                HStack(spacing: 5) {
                    Rectangle().fill(lineColor).frame(width: 2)
                    Text("블럭을 추가하세요").font(.system(size: 10)).foregroundStyle(.tertiary).padding(.vertical, 3)
                }
            }

            // 증손자 블럭 추가 버튼
            HStack(spacing: 5) {
                Rectangle().fill(lineColor).frame(width: 2)
                Button {
                    withAnimation(.spring(duration: 0.2)) {
                        showGreatGrandchildPalette[grandchild.id, default: false].toggle()
                    }
                } label: {
                    Label("추가", systemImage: "plus.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(grandchild.type.blockColor)
                }
                .buttonStyle(.borderless)
                .padding(.vertical, 1)
            }

            // 증손자 팔레트
            if showGreatGrandchildPalette[grandchild.id, default: false] {
                greatGrandchildMiniPalette(grandchildId: grandchild.id, childIndex: childIndex, grandchildIndex: gcIdx)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
            }

            Text(grandchild.type == .repeatBlock ? "end repeat" : "end if")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(grandchild.type.blockColor.opacity(0.45))
        }
        .padding(.leading, 12)
    }

    /// 손자 블럭 선택 미니 팔레트 — repeat/if 상호 허용, 동일 타입·function 중첩 불허 (자식 팔레트와 동일 규칙)
    /// (기존엔 컨테이너를 전부 막았지만, 손자도 컨테이너가 될 수 있도록 자식 팔레트와 같은 규칙으로 완화)
    private func grandchildMiniPalette(child: Block, childIndex: Int) -> some View {
        let types = BlockType.allCases.filter { type in
            if type == .functionBlock { return false }  // function 중첩 불허
            if type == child.type    { return false }  // 동일 타입 중첩 불허
            return true
        }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(types, id: \.self) { type in
                    Button {
                        onAddGrandchild?(type, childIndex)
                        withAnimation { showGrandchildPalette[child.id] = false }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: type.iconName).font(.system(size: 11, weight: .semibold))
                            Text(type.shortName).font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(type.blockColor)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.leading, 20)
    }

    /// 증손자 블럭 선택 미니 팔레트 — 기본 동작 블럭만 허용 (여기서 중첩을 끊어 4단 이상은 만들지 않음)
    private func greatGrandchildMiniPalette(grandchildId: UUID, childIndex: Int, grandchildIndex: Int) -> some View {
        let types = BlockType.allCases.filter {
            $0 != .repeatBlock && $0 != .ifBlock && $0 != .functionBlock
        }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(types, id: \.self) { type in
                    Button {
                        onAddGreatGrandchild?(type, childIndex, grandchildIndex)
                        withAnimation { showGreatGrandchildPalette[grandchildId] = false }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: type.iconName).font(.system(size: 10, weight: .semibold))
                            Text(type.shortName).font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(type.blockColor)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.leading, 18)
    }

    /// 자식 블럭 선택용 미니 팔레트
    /// 허용 규칙: 동일 타입 중첩 불허, functionBlock 중첩 불허
    /// → repeat 안에 if 가능, if 안에 repeat 가능
    private var childMiniPalette: some View {
        let childTypes = BlockType.allCases.filter { type in
            if type == .functionBlock { return false }  // function 중첩 불허
            if type == block.type    { return false }  // 동일 타입 중첩 불허
            return true
        }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(childTypes, id: \.self) { type in
                    Button {
                        onAddChild?(type)
                        withAnimation { showChildPalette = false }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: type.iconName).font(.system(size: 12, weight: .semibold))
                            Text(type.shortName).font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(type.blockColor)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.leading, 32)
        .padding(.bottom, 4)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        // 실행 중 활성 상태 블럭
        BlockRowView(
            block: Block(type: .moveForward),
            index: 0, isActive: true, isFailed: false,
            onDelete: nil, onAddChild: nil, onRemoveChild: nil,
            onRepeatCountChange: nil, onIfConditionChange: nil,
            onAddGrandchild: nil, onRemoveGrandchild: nil,
            onSetChildIfCondition: nil, onSetChildRepeatCount: nil
        )
        // 일반 상태 블럭
        BlockRowView(
            block: Block(type: .turnLeft),
            index: 1, isActive: false, isFailed: false,
            onDelete: nil, onAddChild: nil, onRemoveChild: nil,
            onRepeatCountChange: nil, onIfConditionChange: nil,
            onAddGrandchild: nil, onRemoveGrandchild: nil,
            onSetChildIfCondition: nil, onSetChildRepeatCount: nil
        )
        // 실패 상태 블럭
        BlockRowView(
            block: Block(type: .moveForward),
            index: 2, isActive: false, isFailed: true,
            onDelete: nil, onAddChild: nil, onRemoveChild: nil,
            onRepeatCountChange: nil, onIfConditionChange: nil,
            onAddGrandchild: nil, onRemoveGrandchild: nil,
            onSetChildIfCondition: nil, onSetChildRepeatCount: nil
        )
        // repeat 블럭 (if 자식 포함)
        BlockRowView(
            block: Block(type: .repeatBlock, repeatCount: 3,
                         children: [Block(type: .moveForward),
                                    Block(type: .ifBlock, children: [Block(type: .turnRight)])]),
            index: 3, isActive: false, isFailed: false,
            onDelete: { }, onAddChild: { _ in }, onRemoveChild: { _ in },
            onRepeatCountChange: { _ in }, onIfConditionChange: nil,
            onAddGrandchild: nil, onRemoveGrandchild: nil,
            onSetChildIfCondition: nil, onSetChildRepeatCount: nil
        )
        // if 블럭 (repeat 자식 포함)
        BlockRowView(
            block: Block(type: .ifBlock,
                         children: [Block(type: .repeatBlock, repeatCount: 2,
                                          children: [Block(type: .moveForward)])]),
            index: 4, isActive: false, isFailed: false,
            onDelete: { }, onAddChild: { _ in }, onRemoveChild: { _ in },
            onRepeatCountChange: nil, onIfConditionChange: { _ in },
            onAddGrandchild: nil, onRemoveGrandchild: nil,
            onSetChildIfCondition: nil, onSetChildRepeatCount: nil
        )
    }
    .padding()
    .background(Color(red: 0.957, green: 0.925, blue: 0.843))
}
