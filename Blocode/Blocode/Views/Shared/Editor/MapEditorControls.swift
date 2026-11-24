//
//  MapEditorControls.swift
//  Blocode
//
//  Created by 조준희 on 11/11/26.
//

import SwiftUI

// MARK: - 도구 표시 정보

extension MapEditorTool {

    /// 도구 버튼 이름
    var title: String {
        switch self {
        case .floor: "바닥"
        case .wall: "벽"
        case .start: "시작"
        case .goal: "목표"
        case .item: "보석"
        case .switchGate: "스위치"
        case .portal: "포탈"
        case .eraser: "지우개"
        }
    }

    /// 도구 버튼 아이콘 (SF Symbol)
    var icon: String {
        switch self {
        case .floor: "square"
        case .wall: "square.fill"
        case .start: "arrowtriangle.right.fill"
        case .goal: "circle.fill"
        case .item: "diamond.fill"
        case .switchGate: "hand.tap.fill"
        case .portal: "circle.circle"
        case .eraser: "eraser.fill"
        }
    }

    /// 맵 위 요소와 같은 색 — nil이면 기본 글자색
    var tint: Color? {
        switch self {
        case .goal: .mapGoal
        case .item: .gemMint
        case .switchGate: .switchOrange
        case .portal: .portalPurple
        default: nil
        }
    }

    /// 도구를 고르면 안내 줄에 보여 줄 사용법
    var hint: String {
        switch self {
        case .floor: "끌어서 바닥을 칠해요."
        case .wall: "끌어서 벽을 칠해요."
        case .start: "누른 칸으로 시작을 옮겨요. 시작 칸을 다시 누르면 방향이 돌아가요."
        case .goal: "누른 칸으로 목표를 옮겨요."
        case .item: "보석을 놓아요. 놓은 보석을 다시 누르면 지워져요."
        case .switchGate: "스위치를 먼저 놓고, 이어서 그 스위치로 열 문을 놓아요."
        case .portal: "두 칸을 차례로 눌러 포탈 짝을 만들어요."
        case .eraser: "끌어서 보석·스위치·문·포탈을 지워요."
        }
    }
}

// MARK: - MapEditorToolPicker
/// 도구 선택 — 아이폰 세로는 한 줄, 넓은 화면은 4열 격자, 맥은 왼쪽 세로 줄
struct MapEditorToolPicker: View {

    var editor: MapEditorViewModel
    var isGrid = false
    var isVertical = false  // 맥 에디터 왼쪽 세로 도구 줄

    var body: some View {
        if isVertical {
            VStack(spacing: 6) { buttons }
        } else if isGrid {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                buttons
            }
        } else {
            HStack(spacing: 4) { buttons }
        }
    }

    private var buttons: some View {
        ForEach(MapEditorTool.allCases, id: \.self) { tool in
            let isSelected = editor.tool == tool
            Button {
                SoundService.shared.play(.buttonTap)
                editor.selectTool(tool)
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: tool.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : (tool.tint ?? Color.secondary))
                    Text(tool.title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(isSelected ? Color.slateButtonFace : Color.statCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(tool.title)
        }
    }
}

// MARK: - MapEditorSettingsView
/// 맵 설정 — 크기, 시작 방향, 팔레트 (아이폰은 시트, 넓은 화면은 왼쪽 패널에 넣음)
struct MapEditorSettingsView: View {

    var editor: MapEditorViewModel
    /// 시작 방향을 이 안에 그릴지 — 아이패드 세로 에디터는 도구 아래(왼쪽 칸)에 따로 두므로 false
    var includesStartDirection = true

    private let range = MapValidator.minSize...MapValidator.maxSize

    /// 맵 요소에 따라 자동으로 들어가는 블럭
    private var autoBlocks: [BlockType] {
        editor.palette.filter { !MapEditorViewModel.optionalBlocks.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            section("크기") {
                VStack(spacing: 8) {
                    Stepper("가로 \(editor.width)칸",
                            value: Binding(get: { editor.width },
                                           set: { editor.resize(width: $0, height: editor.height) }),
                            in: range)
                    Stepper("세로 \(editor.height)칸",
                            value: Binding(get: { editor.height },
                                           set: { editor.resize(width: editor.width, height: $0) }),
                            in: range)
                }
                .font(.system(size: 15, weight: .medium))
            }

            if includesStartDirection {
                MapEditorStartDirectionSection(editor: editor)
            }

            section("사용할 블럭") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 6)], spacing: 6) {
                    ForEach(MapEditorViewModel.optionalBlocks, id: \.self) { type in
                        let isOn = editor.enabledBlocks.contains(type)
                        Button {
                            editor.toggleBlock(type)
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: type.iconName).font(.system(size: 12, weight: .semibold))
                                Text(type.shortName).font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(isOn ? .white : Color.secondary)
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background(isOn ? type.blockColor : Color.statCardBackground)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(type.displayName) 블럭 \(isOn ? "끄기" : "켜기")")
                    }
                }
                if !autoBlocks.isEmpty {
                    Text("맵에 있는 요소 때문에 \(autoBlocks.map(\.displayName).joined(separator: ", ")) 블럭이 자동으로 들어가요.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        editorSection(title, content: content)
    }
}

// MARK: - 시작 방향

/// 시작 방향 고르기 (위·오른쪽·아래·왼쪽) — 맵 설정 안에 들어가거나, 아이패드 세로에선 도구 아래에 따로 놓임
struct MapEditorStartDirectionSection: View {

    var editor: MapEditorViewModel

    var body: some View {
        editorSection("시작 방향") {
            HStack(spacing: 8) {
                ForEach([(Direction.up, "arrow.up", "위"), (.right, "arrow.right", "오른쪽"),
                         (.down, "arrow.down", "아래"), (.left, "arrow.left", "왼쪽")], id: \.0) { direction, icon, label in
                    let isSelected = editor.map.startDirection == direction
                    Button {
                        editor.setStartDirection(direction)
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : Color.secondary)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(isSelected ? Color.slateButtonFace : Color.statCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("시작 방향 \(label)")
                }
            }
        }
    }
}

/// 맵 설정의 한 묶음 — 작은 회색 제목 + 내용 (맵 설정·시작 방향 공용)
private func editorSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(0.5)
        content()
    }
}

// MARK: - 버튼

/// 아이콘만 있는 작은 버튼 — 되돌리기·다시 하기·설정
struct EditorIconButton: View {

    let icon: String
    let label: String
    var isEnabled = true
    var side: CGFloat = 44  // 맥 툴바에선 작게
    let action: () -> Void

    var body: some View {
        Button {
            SoundService.shared.play(.buttonTap)
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(isEnabled ? 0.8 : 0.3))
                .frame(width: side, height: side)
                .background(Color.statCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

/// 3D 글자 버튼 — 확인·테스트 플레이
struct EditorTextButton: View {

    let title: String
    var icon: String?
    var face: Color = .slateButtonFace
    var height: CGFloat = 44  // 맥 툴바에선 작게
    let action: () -> Void

    var body: some View {
        PressableButton {
            SoundService.shared.play(.buttonTap)
            action()
        } label: { isPressed in
            SolidThreeDButton(height: height, cornerRadius: height * 14 / 44, face: face, isPressed: isPressed) {
                HStack(spacing: 6) {
                    if let icon { Image(systemName: icon).font(.system(size: 12, weight: .bold)) }
                    Text(title).font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, height < 44 ? 12 : 0)  // 작은 버튼(맥 툴바)은 글자 폭 + 좌우 여백
            }
        }
    }
}
