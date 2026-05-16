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
    let onDelete: (() -> Void)?               // 블럭 삭제 콜백
    let onAddChild: ((BlockType) -> Void)?    // repeat 자식 블럭 추가 콜백
    let onRemoveChild: ((Int) -> Void)?       // repeat 자식 블럭 삭제 콜백 (자식 인덱스 전달)
    let onRepeatCountChange: ((Int) -> Void)? // repeat 횟수 변경 콜백

    // repeat 내부 블럭 추가용 미니 팔레트 펼침 여부
    @State private var showChildPalette = false

    // 3D 카드 파라미터
    private let frontH:  CGFloat = 48  // 앞면 높이
    private let topD:    CGFloat = 2   // 위 뒷면 두께
    private let botD:    CGFloat = 3   // 아래 뒷면 두께
    private let cr:      CGFloat = 14  // 모서리 반지름

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 메인 블럭 행 항상 표시
            blockRow
            // repeat 블럭이면 자식 블럭 영역 추가 표시
            if block.isRepeatBlock {
                repeatChildArea
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
                        // 블럭 종류 아이콘
                        Image(systemName: block.type.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 22)

                        // 블럭 이름
                        Text(block.type.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        Spacer()

                        // repeat 블럭 전용 — 반복 횟수 스테퍼
                        if block.isRepeatBlock, let count = block.repeatCount {
                            repeatCountStepper(count: count)
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

    // MARK: - repeat 블럭 자식 영역

    /// repeat 블럭 아래에 표시되는 자식 블럭 목록 및 추가 UI
    private var repeatChildArea: some View {
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

            // repeat 블럭 끝 레이블
            Text("end repeat")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(block.type.blockColor.opacity(0.5))
                .padding(.top, 2)
        }
        .padding(.leading, 18)
        .padding(.bottom, 8)
    }

    /// 자식 블럭 하나를 표시하는 미니 행 뷰
    private func childBlockMiniRow(_ child: Block, index: Int) -> some View {
        HStack(spacing: 8) {
            // 자식 블럭 아이콘
            Image(systemName: child.type.iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(child.type.blockColor)
            // 자식 블럭 이름
            Text(child.type.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
            Spacer()
            // 자식 블럭 삭제 버튼
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onRemoveChild?(index)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(child.type.lightColor)  // 연한 배경으로 자식 블럭 구분
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// 자식 블럭 선택용 미니 팔레트 — repeat 블럭 제외한 타입만 표시
    private var childMiniPalette: some View {
        let childTypes = BlockType.allCases.filter { $0 != .repeatBlock }  // repeat 중첩 불허
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(childTypes, id: \.self) { type in
                    Button {
                        onAddChild?(type)               // 자식 블럭 추가
                        withAnimation { showChildPalette = false }  // 팔레트 닫기
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: type.iconName)
                                .font(.system(size: 12, weight: .semibold))
                            Text(type.shortName)
                                .font(.system(size: 12, weight: .semibold))
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
            onDelete: nil, onAddChild: nil, onRemoveChild: nil, onRepeatCountChange: nil
        )
        // 일반 상태 블럭
        BlockRowView(
            block: Block(type: .turnLeft),
            index: 1, isActive: false, isFailed: false,
            onDelete: nil, onAddChild: nil, onRemoveChild: nil, onRepeatCountChange: nil
        )
        // 실패 상태 블럭
        BlockRowView(
            block: Block(type: .moveForward),
            index: 2, isActive: false, isFailed: true,
            onDelete: nil, onAddChild: nil, onRemoveChild: nil, onRepeatCountChange: nil
        )
        // repeat 블럭 (자식 포함)
        BlockRowView(
            block: Block(type: .repeatBlock, repeatCount: 3, children: [Block(type: .moveForward)]),
            index: 3, isActive: false, isFailed: false,
            onDelete: { }, onAddChild: { _ in }, onRemoveChild: { _ in }, onRepeatCountChange: { _ in }
        )
    }
    .padding()
    .background(Color(red: 0.957, green: 0.925, blue: 0.843))
}
