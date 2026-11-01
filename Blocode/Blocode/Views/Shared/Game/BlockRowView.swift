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
    let actions: BlockEditActions  // 블럭 편집 동작 — 깊이와 무관하게 경로로 호출
    // 코드 리스트 내 순서 변경(재정렬) 드래그 콜백 — 팔레트의 삽입 드래그와 동일한 구조(글로벌 좌표 전달)
    var onReorderDragStart:  ((CGPoint) -> Void)? = nil
    var onReorderDragChange: ((CGPoint) -> Void)? = nil
    var onReorderDragEnd:    ((CGPoint) -> Void)? = nil

    // 순서 변경 드래그 상태 (PaletteCardView의 드래그 감지 로직과 동일한 구조)
    @State private var isReorderPressed = false
    @State private var isReorderDragging = false
    @State private var reorderLongPressTimer: Timer? = nil

    // 3D 카드 파라미터 — 맥은 코드 패널 폭이 좁아 블럭도 축소, iOS/아이패드는 기존 크기 유지
    #if os(macOS)
    private let frontH:  CGFloat = 29
    private let topD:    CGFloat = 1.1
    private let botD:    CGFloat = 1.9
    private let cr:      CGFloat = 9
    #else
    private let frontH:  CGFloat = 40  // 앞면 높이 (코드 영역 블럭 세로 크기 축소 — 기존 48)
    private let topD:    CGFloat = 1.6 // 위 뒷면 두께
    private let botD:    CGFloat = 2.4 // 아래 뒷면 두께
    private let cr:      CGFloat = 12  // 모서리 반지름
    #endif

    // 아이콘/텍스트/스테퍼 크기 — iOS는 블럭 축소에 맞춰 함께 축소, 맥은 기존 값 그대로 유지
    #if os(macOS)
    private let rowIconSize:    CGFloat = 16
    private let rowTextSize:    CGFloat = 15
    private let stepperBtnSize: CGFloat = 30
    private let stepperFontSize: CGFloat = 13
    #else
    private let rowIconSize:    CGFloat = 14
    private let rowTextSize:    CGFloat = 13
    private let stepperBtnSize: CGFloat = 26
    private let stepperFontSize: CGFloat = 12
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 메인 블럭 행 항상 표시
            blockRow
            // 컨테이너 블럭(repeat/if/function)이면 자식 블럭 영역 추가 표시
            if block.hasChildren {
                NestedBlockArea(
                    parent: block, parentPath: [index], depth: 1,
                    activePath: activeChildPath, failedPath: failedChildPath, actions: actions
                )
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
                                .font(.system(size: rowIconSize, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 22)

                            // 블럭 이름
                            Text(block.type.displayName)
                                .font(.system(size: rowTextSize, weight: .semibold))
                                .foregroundStyle(.white)

                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                        .gesture(reorderDragGesture)

                        // repeat 블럭 전용 — 반복 횟수 스테퍼
                        if block.isRepeatBlock, let count = block.repeatCount {
                            repeatCountStepper(count: count)
                        }

                        // if 블럭 전용 — 조건 선택 토글 버튼
                        if block.type == .ifBlock, let condition = block.ifCondition {
                            Button {
                                // 탭할 때마다 pathClear ↔ pathBlocked 전환
                                let next: IfCondition = condition == .pathClear ? .pathBlocked : .pathClear
                                actions.setIfCondition(next, [index])
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
                        if !isActive {
                            Button {
                                withAnimation(.spring(duration: 0.2)) { actions.remove([index]) }
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
                    .fill(Color.failureRed)
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
                actions.setRepeatCount(max(1, count - 1), [index])
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: stepperBtnSize, height: stepperBtnSize)
            }
            .buttonStyle(.borderless)

            // 현재 횟수 표시 ("2×" 형식)
            Text("\(count)×")
                .font(.system(size: stepperFontSize, weight: .bold))
                .monospacedDigit()
                .frame(minWidth: 24)

            // 횟수 증가 버튼 (최대 10회)
            Button {
                actions.setRepeatCount(min(10, count + 1), [index])
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: stepperBtnSize, height: stepperBtnSize)
            }
            .buttonStyle(.borderless)
        }
        .foregroundStyle(.white)
        .background(Color.white.opacity(0.18))  // 반투명 흰 배경
        .clipShape(Capsule())
    }
}

// MARK: - BlockEditActions
/// 블럭 편집 동작 묶음 — 경로는 GameViewModel과 같은 형식([최상위, 자식, 손자, ...])
struct BlockEditActions {
    let addChild: (BlockType, [Int]) -> Void
    let remove: ([Int]) -> Void
    let setRepeatCount: (Int, [Int]) -> Void
    let setIfCondition: (IfCondition, [Int]) -> Void
    let allowedChildTypes: ([Int]) -> [BlockType]

    init(viewModel: GameViewModel) {
        addChild = { viewModel.addChildBlock($0, at: $1) }
        remove = { viewModel.removeBlock(at: $0) }
        setRepeatCount = { viewModel.setRepeatCount($0, at: $1) }
        setIfCondition = { viewModel.setIfCondition($0, at: $1) }
        allowedChildTypes = { viewModel.allowedChildTypes(at: $0) }
    }
}

// MARK: - NestedBlockArea
/// 컨테이너 블럭의 내부 영역 — 자식 행 목록 + 추가 버튼 + 미니 팔레트 + end 레이블
/// 자식이 컨테이너이면 한 단계 깊은 NestedBlockArea를 다시 표시 (깊이 1=자식, 2=손자, 3=증손자)
private struct NestedBlockArea: View {

    let parent: Block            // 이 영역을 가진 컨테이너 블럭
    let parentPath: [Int]        // 컨테이너의 전체 경로
    let depth: Int               // 자식 행의 깊이 — 글자·여백 크기를 결정
    let activePath: [Int]        // 실행 중인 블럭의 이 영역 기준 상대 경로 (없으면 빈 배열)
    let failedPath: [Int]        // 실패한 블럭의 이 영역 기준 상대 경로 (없으면 빈 배열)
    let actions: BlockEditActions

    @State private var showPalette = false  // 미니 팔레트 펼침 여부

    private var metrics: Metrics { Metrics.forDepth(depth) }

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.areaSpacing) {

            if let children = parent.children, !children.isEmpty {
                ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                    childItem(child, index: index)
                }
            } else {
                // 자식 블럭이 없을 때 안내 텍스트
                linedRow {
                    Text("블럭을 추가하세요")
                        .font(metrics.emptyFont)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, metrics.emptyPadding)
                }
            }

            // 추가 버튼 — 탭 시 미니 팔레트 토글
            linedRow {
                Button {
                    withAnimation(.spring(duration: metrics.paletteToggleDuration)) {
                        showPalette.toggle()
                    }
                } label: {
                    Label("추가", systemImage: "plus.circle.fill")
                        .font(metrics.addFont)
                        .foregroundStyle(parent.type.blockColor)
                }
                .buttonStyle(.borderless)
                .padding(.vertical, metrics.addPadding)
            }

            if showPalette {
                miniPalette
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
            }

            Text(endLabel)
                .font(.system(size: metrics.endSize, weight: .medium, design: .monospaced))
                .foregroundStyle(parent.type.blockColor.opacity(metrics.endOpacity))
                .padding(.top, metrics.endTop)
        }
        .padding(.leading, metrics.areaLeading)
        .padding(.bottom, metrics.areaBottom)
    }

    // MARK: - 연결선

    /// 왼쪽 세로 연결선이 붙은 행 — 들여쓰기 깊이를 표시
    private func linedRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: metrics.lineSpacing) {
            if let column = metrics.numberColumnWidth {
                Color.clear.frame(width: column)  // 번호 열 맞춤 (부모 인덱스 번호 너비)
            }
            Rectangle()
                .fill(parent.type.blockColor.opacity(metrics.lineOpacity))
                .frame(width: 2)
            content()
        }
    }

    // MARK: - 자식 행

    /// 자식 한 줄 — 깊이 1은 연결선이 손자 영역까지 이어지고, 그 아래 깊이는 자기 행 옆에만 표시
    @ViewBuilder
    private func childItem(_ child: Block, index: Int) -> some View {
        if metrics.lineSpansNestedArea {
            linedRow {
                VStack(alignment: .leading, spacing: metrics.rowSpacing) {
                    childCard(child, index: index)
                    nestedArea(of: child, index: index)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: metrics.rowSpacing) {
                linedRow { childCard(child, index: index) }
                nestedArea(of: child, index: index)
            }
        }
    }

    /// 자식이 컨테이너이면 한 단계 깊은 영역 표시 — 하이라이트 경로에서 자기 인덱스를 떼어 전달
    @ViewBuilder
    private func nestedArea(of child: Block, index: Int) -> some View {
        if child.hasChildren {
            NestedBlockArea(
                parent: child,
                parentPath: parentPath + [index],
                depth: depth + 1,
                activePath: activePath.first == index ? Array(activePath.dropFirst()) : [],
                failedPath: failedPath.first == index ? Array(failedPath.dropFirst()) : [],
                actions: actions
            )
        }
    }

    /// 자식 카드 — 아이콘·이름·(repeat 횟수 / if 조건)·삭제 버튼
    private func childCard(_ child: Block, index: Int) -> some View {
        // 경로 첫 요소로 판별 — 더 깊은 블럭이 실행/실패 중이어도 조상 행이 함께 강조됨
        let isActive = activePath.first == index
        let isFailed = failedPath.first == index
        let path = parentPath + [index]

        return HStack(spacing: metrics.cardSpacing) {
            Image(systemName: child.type.iconName)
                .font(.system(size: metrics.iconSize, weight: .semibold))
                .foregroundStyle(child.type.blockColor)
            Text(child.type.displayName)
                .font(.system(size: metrics.textSize, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()

            if child.type == .repeatBlock, let count = child.repeatCount {
                repeatStepper(count: count, path: path)
            }

            if child.type == .ifBlock, let condition = child.ifCondition {
                conditionToggle(child, condition: condition, path: path)
            }

            Button {
                withAnimation(metrics.removeAnimation) { actions.remove(path) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: metrics.deleteSize))
                    .foregroundStyle(Color.secondary.opacity(metrics.deleteOpacity))
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, metrics.cardHorizontal)
        .padding(.vertical, metrics.cardVertical)
        .background(child.type.lightColor)
        .clipShape(RoundedRectangle(cornerRadius: metrics.cardRadius))
        // 실행/실패 중 테두리 — 밝은 배경 위라 최상위 행의 흰 테두리 대신 블럭 색/실패 색 사용
        .overlay {
            if isActive {
                RoundedRectangle(cornerRadius: metrics.cardRadius)
                    .strokeBorder(child.type.blockColor.opacity(0.9), lineWidth: 2)
            } else if isFailed {
                RoundedRectangle(cornerRadius: metrics.cardRadius)
                    .strokeBorder(Color.failureRed, lineWidth: 2)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isActive)
        .animation(.easeInOut(duration: 0.15), value: isFailed)
    }

    /// 중첩 repeat 블럭의 횟수 스테퍼 (소형)
    private func repeatStepper(count: Int, path: [Int]) -> some View {
        HStack(spacing: 0) {
            Button { actions.setRepeatCount(max(1, count - 1), path) } label: {
                Image(systemName: "minus")
                    .font(.system(size: metrics.stepperIconSize, weight: .bold))
                    .frame(width: metrics.stepperButtonSize, height: metrics.stepperButtonSize)
            }
            Text("\(count)×")
                .font(.system(size: metrics.stepperTextSize, weight: .bold))
                .monospacedDigit()
                .frame(minWidth: metrics.stepperTextMinWidth)
            Button { actions.setRepeatCount(min(10, count + 1), path) } label: {
                Image(systemName: "plus")
                    .font(.system(size: metrics.stepperIconSize, weight: .bold))
                    .frame(width: metrics.stepperButtonSize, height: metrics.stepperButtonSize)
            }
        }
        .foregroundStyle(BlockType.repeatBlock.blockColor)
        .background(BlockType.repeatBlock.lightColor)
        .clipShape(Capsule())
        .buttonStyle(.borderless)
    }

    /// 중첩 if 블럭의 조건 토글 버튼
    private func conditionToggle(_ child: Block, condition: IfCondition, path: [Int]) -> some View {
        Button {
            let next: IfCondition = condition == .pathClear ? .pathBlocked : .pathClear
            actions.setIfCondition(next, path)
        } label: {
            HStack(spacing: 3) {
                Text(condition.displayName)
                    .font(.system(size: metrics.toggleTextSize, weight: .semibold))
                    .foregroundStyle(child.type.blockColor)
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: metrics.toggleArrowSize, weight: .bold))
                    .foregroundStyle(child.type.blockColor.opacity(0.7))
            }
            .padding(.horizontal, metrics.toggleHorizontal)
            .padding(.vertical, metrics.toggleVertical)
            .background(child.type.lightColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.borderless)
    }

    // MARK: - 미니 팔레트

    /// 추가할 블럭 선택 — 허용 규칙은 GameViewModel.allowedChildTypes 한 곳에서 결정
    private var miniPalette: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: metrics.paletteSpacing) {
                ForEach(actions.allowedChildTypes(parentPath), id: \.self) { type in
                    Button {
                        actions.addChild(type, parentPath)
                        withAnimation { showPalette = false }
                    } label: {
                        HStack(spacing: metrics.paletteIconSpacing) {
                            Image(systemName: type.iconName)
                                .font(.system(size: metrics.paletteFontSize, weight: .semibold))
                            Text(type.shortName)
                                .font(.system(size: metrics.paletteFontSize, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, metrics.paletteHorizontal)
                        .padding(.vertical, metrics.paletteVertical)
                        .background(type.blockColor)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.leading, metrics.paletteLeading)
        .padding(.bottom, metrics.paletteBottom)
    }

    /// 컨테이너 블럭 종류에 따른 끝 레이블
    private var endLabel: String {
        switch parent.type {
        case .repeatBlock:   return "end repeat"
        case .ifBlock:       return "end if"
        case .functionBlock: return "end function"
        default:             return "end"
        }
    }

    // MARK: - 깊이별 크기

    /// 깊어질수록 작아지는 글자·여백 값 — 깊이 3의 스테퍼·토글 값은 안 쓰이지만(증손자는 기본 동작 블럭만) 깊이 2와 맞춤
    private struct Metrics {
        var areaSpacing: CGFloat, areaLeading: CGFloat, areaBottom: CGFloat
        var numberColumnWidth: CGFloat?, lineSpacing: CGFloat, lineOpacity: Double, lineSpansNestedArea: Bool
        var emptyFont: Font, emptyPadding: CGFloat
        var addFont: Font, addPadding: CGFloat, paletteToggleDuration: Double
        var endSize: CGFloat, endOpacity: Double, endTop: CGFloat
        var rowSpacing: CGFloat, cardSpacing: CGFloat, iconSize: CGFloat, textSize: CGFloat
        var cardHorizontal: CGFloat, cardVertical: CGFloat, cardRadius: CGFloat
        var deleteSize: CGFloat, deleteOpacity: Double, removeAnimation: Animation
        var stepperIconSize: CGFloat, stepperButtonSize: CGFloat, stepperTextSize: CGFloat, stepperTextMinWidth: CGFloat
        var toggleTextSize: CGFloat, toggleArrowSize: CGFloat, toggleHorizontal: CGFloat, toggleVertical: CGFloat
        var paletteSpacing: CGFloat, paletteIconSpacing: CGFloat, paletteFontSize: CGFloat
        var paletteHorizontal: CGFloat, paletteVertical: CGFloat, paletteLeading: CGFloat, paletteBottom: CGFloat

        static func forDepth(_ depth: Int) -> Metrics {
            switch depth {
            case 1: return child
            case 2: return grandchild
            default: return greatGrandchild
            }
        }

        static let child = Metrics(
            areaSpacing: 4, areaLeading: 18, areaBottom: 8,
            numberColumnWidth: 28, lineSpacing: 10, lineOpacity: 0.35, lineSpansNestedArea: true,
            emptyFont: .caption, emptyPadding: 8,
            addFont: .caption.bold(), addPadding: 4, paletteToggleDuration: 0.25,
            endSize: 11, endOpacity: 0.5, endTop: 2,
            rowSpacing: 4, cardSpacing: 8, iconSize: 13, textSize: 13,
            cardHorizontal: 10, cardVertical: 7, cardRadius: 8,
            deleteSize: 16, deleteOpacity: 0.5, removeAnimation: .easeInOut(duration: 0.2),
            stepperIconSize: 10, stepperButtonSize: 22, stepperTextSize: 12, stepperTextMinWidth: 18,
            toggleTextSize: 10, toggleArrowSize: 8, toggleHorizontal: 6, toggleVertical: 3,
            paletteSpacing: 8, paletteIconSpacing: 5, paletteFontSize: 12,
            paletteHorizontal: 10, paletteVertical: 6, paletteLeading: 32, paletteBottom: 4
        )

        static let grandchild = Metrics(
            areaSpacing: 3, areaLeading: 14, areaBottom: 0,
            numberColumnWidth: nil, lineSpacing: 6, lineOpacity: 0.30, lineSpansNestedArea: false,
            emptyFont: .caption, emptyPadding: 4,
            addFont: .caption.bold(), addPadding: 2, paletteToggleDuration: 0.2,
            endSize: 10, endOpacity: 0.45, endTop: 1,
            rowSpacing: 3, cardSpacing: 6, iconSize: 11, textSize: 12,
            cardHorizontal: 8, cardVertical: 5, cardRadius: 6,
            deleteSize: 13, deleteOpacity: 0.45, removeAnimation: .default,
            stepperIconSize: 9, stepperButtonSize: 20, stepperTextSize: 11, stepperTextMinWidth: 16,
            toggleTextSize: 9, toggleArrowSize: 7, toggleHorizontal: 5, toggleVertical: 2,
            paletteSpacing: 6, paletteIconSpacing: 4, paletteFontSize: 11,
            paletteHorizontal: 8, paletteVertical: 5, paletteLeading: 20, paletteBottom: 0
        )

        static let greatGrandchild = Metrics(
            areaSpacing: 2, areaLeading: 12, areaBottom: 0,
            numberColumnWidth: nil, lineSpacing: 5, lineOpacity: 0.30, lineSpansNestedArea: false,
            emptyFont: .system(size: 10), emptyPadding: 3,
            addFont: .system(size: 10, weight: .bold), addPadding: 1, paletteToggleDuration: 0.2,
            endSize: 9, endOpacity: 0.45, endTop: 0,
            rowSpacing: 3, cardSpacing: 5, iconSize: 10, textSize: 11,
            cardHorizontal: 7, cardVertical: 4, cardRadius: 5,
            deleteSize: 12, deleteOpacity: 0.45, removeAnimation: .default,
            stepperIconSize: 9, stepperButtonSize: 20, stepperTextSize: 11, stepperTextMinWidth: 16,
            toggleTextSize: 9, toggleArrowSize: 7, toggleHorizontal: 5, toggleVertical: 2,
            paletteSpacing: 5, paletteIconSpacing: 3, paletteFontSize: 10,
            paletteHorizontal: 7, paletteVertical: 4, paletteLeading: 18, paletteBottom: 0
        )
    }
}

// MARK: - Preview

/// 프리뷰용 편집 동작 — 실제 편집 규칙(미니 팔레트 목록)이 적용되도록 VM을 사용
private func previewActions(blocks: [Block]) -> BlockEditActions {
    let viewModel = GameViewModel(stage: .preview)
    viewModel.codeBlocks = blocks
    return BlockEditActions(viewModel: viewModel)
}

#Preview {
    let actions = previewActions(blocks: [])
    VStack(spacing: 12) {
        // 실행 중 활성 상태 블럭
        BlockRowView(
            block: Block(type: .moveForward),
            index: 0, isActive: true, isFailed: false,
            actions: actions
        )
        // 일반 상태 블럭
        BlockRowView(
            block: Block(type: .turnLeft),
            index: 1, isActive: false, isFailed: false,
            actions: actions
        )
        // 실패 상태 블럭
        BlockRowView(
            block: Block(type: .moveForward),
            index: 2, isActive: false, isFailed: true,
            actions: actions
        )
        // repeat 블럭 (if 자식 포함)
        BlockRowView(
            block: Block(type: .repeatBlock, repeatCount: 3,
                         children: [Block(type: .moveForward),
                                    Block(type: .ifBlock, children: [Block(type: .turnRight)])]),
            index: 3, isActive: false, isFailed: false,
            actions: actions
        )
        // if 블럭 (repeat 자식 포함)
        BlockRowView(
            block: Block(type: .ifBlock,
                         children: [Block(type: .repeatBlock, repeatCount: 2,
                                          children: [Block(type: .moveForward)])]),
            index: 4, isActive: false, isFailed: false,
            actions: actions
        )
    }
    .padding()
    .background(Color(red: 0.957, green: 0.925, blue: 0.843))
}

// 중첩 영역 전후 비교용 — 자식·손자·증손자 모든 깊이의 스테퍼·토글·빈 안내를 한 화면에 표시
private let previewNestedTree = Block(type: .functionBlock, children: [
    Block(type: .moveForward),
    Block(type: .repeatBlock, repeatCount: 3, children: [
        Block(type: .turnLeft),
        Block(type: .ifBlock, children: [Block(type: .moveForward), Block(type: .turnRight)]),
        Block(type: .ifBlock, children: [])
    ]),
    Block(type: .ifBlock, children: [
        Block(type: .repeatBlock, repeatCount: 2, children: [Block(type: .collectItem)])
    ]),
    Block(type: .repeatBlock, repeatCount: 4, children: [])
])

private let previewHighlightTree = Block(type: .repeatBlock, repeatCount: 2, children: [
    Block(type: .ifBlock, children: [
        Block(type: .repeatBlock, repeatCount: 3, children: [Block(type: .moveForward), Block(type: .turnLeft)]),
        Block(type: .turnRight)
    ]),
    Block(type: .moveForward)
])

#Preview("중첩") {
    let actions = previewActions(blocks: [previewNestedTree])
    BlockRowView(
        block: previewNestedTree,
        index: 0, isActive: false, isFailed: false,
        actions: actions
    )
    .padding()
    .frame(width: 400)
    .background(Color.appBackground)
}

#Preview("중첩 강조") {
    let actions = previewActions(blocks: [previewHighlightTree, previewHighlightTree])
    VStack(spacing: 8) {
        // 증손자 실행 중 — 자식·손자 테두리까지 함께 강조
        BlockRowView(
            block: previewHighlightTree,
            index: 0, isActive: true, isFailed: false,
            activeChildPath: [0, 0, 1],
            actions: actions
        )
        // 손자 실패
        BlockRowView(
            block: previewHighlightTree,
            index: 1, isActive: false, isFailed: true,
            failedChildPath: [0, 1],
            actions: actions
        )
    }
    .padding()
    .frame(width: 400)
    .background(Color.appBackground)
}
