//
//  MapEditorGridView.swift
//  Blocode
//
//  Created by 조준희 on 11/11/26.
//

import SwiftUI

// MARK: - EditorGridLayout
/// 격자를 화면 크기에 맞춰 가운데에 배치하는 계산 — 칸 크기, 칸 위치, 터치 좌표 → 칸 변환
struct EditorGridLayout {
    let cell: CGFloat      // 칸 한 변 (정사각)
    let origin: CGPoint    // 격자 왼쪽 위
    let cols: Int
    let rows: Int

    init(size: CGSize, cols: Int, rows: Int, inset: CGFloat = 12) {
        let availableWidth = max(size.width - inset * 2, 1)
        let availableHeight = max(size.height - inset * 2, 1)
        cell = min(availableWidth / CGFloat(max(cols, 1)), availableHeight / CGFloat(max(rows, 1)))
        origin = CGPoint(x: (size.width - cell * CGFloat(cols)) / 2,
                         y: (size.height - cell * CGFloat(rows)) / 2)
        self.cols = cols
        self.rows = rows
    }

    /// 칸의 화면 영역
    func rect(of position: Position) -> CGRect {
        CGRect(x: origin.x + CGFloat(position.x) * cell, y: origin.y + CGFloat(position.y) * cell,
               width: cell, height: cell)
    }

    /// 터치 좌표가 가리키는 칸 — 격자 밖이면 nil
    func position(at point: CGPoint) -> Position? {
        let x = Int(((point.x - origin.x) / cell).rounded(.down))
        let y = Int(((point.y - origin.y) / cell).rounded(.down))
        guard (0..<cols).contains(x), (0..<rows).contains(y), point.x >= origin.x, point.y >= origin.y else { return nil }
        return Position(x: x, y: y)
    }

    /// 두 칸 사이를 잇는 칸들 (시작 칸 제외, 끝 칸 포함) — 손가락이 빠르게 움직여도 칸을 건너뛰지 않게 함
    static func cells(from start: Position, to end: Position) -> [Position] {
        let steps = max(abs(end.x - start.x), abs(end.y - start.y))
        guard steps > 0 else { return [end] }
        return (1...steps).map { step in
            let t = Double(step) / Double(steps)
            return Position(x: start.x + Int((Double(end.x - start.x) * t).rounded()),
                            y: start.y + Int((Double(end.y - start.y) * t).rounded()))
        }
    }
}

// MARK: - MapEditorGridView
/// 맵 편집 격자 — Canvas로 그리고, 끌기·누르기를 ViewModel에 전달
/// 바닥·벽·지우개는 끄는 동안 칠하고, 나머지 도구는 손을 뗀 칸에 한 번 적용함
struct MapEditorGridView: View {

    @ObservedObject var editor: MapEditorViewModel

    @State private var isStroking = false
    @State private var lastPaintedCell: Position?

    /// 끌어서 칠하는 도구
    private var isBrush: Bool {
        editor.tool == .floor || editor.tool == .wall || editor.tool == .eraser
    }

    var body: some View {
        GeometryReader { geo in
            let layout = EditorGridLayout(size: geo.size, cols: editor.width, rows: editor.height)
            Canvas { context, _ in
                draw(context, layout: layout)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in handleChange(value.location, layout: layout) }
                    .onEnded { value in handleEnd(value.location, layout: layout) }
            )
        }
        .background(Color.mapBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.separatorColor, lineWidth: 1))
        .accessibilityLabel("맵 편집 격자")
    }

    // MARK: - 입력

    private func handleChange(_ point: CGPoint, layout: EditorGridLayout) {
        guard let position = layout.position(at: point) else { return }
        if !isStroking {
            isStroking = true
            lastPaintedCell = nil
            editor.beginStroke()
        }
        guard isBrush, position != lastPaintedCell else { return }
        // 이전 칸에서 이어서 칠해 빠른 움직임에도 빈 칸이 없게 함
        let cells = lastPaintedCell.map { EditorGridLayout.cells(from: $0, to: position) } ?? [position]
        for cell in cells { editor.paint(at: cell) }
        lastPaintedCell = position
    }

    private func handleEnd(_ point: CGPoint, layout: EditorGridLayout) {
        guard isStroking else { return }
        if !isBrush, let position = layout.position(at: point) {
            editor.paint(at: position)
        }
        editor.endStroke()
        isStroking = false
        lastPaintedCell = nil
    }

    // MARK: - 그리기

    private func draw(_ context: GraphicsContext, layout: EditorGridLayout) {
        for y in 0..<editor.height {
            for x in 0..<editor.width {
                drawCell(context, layout: layout, position: Position(x: x, y: y))
            }
        }
    }

    private func drawCell(_ context: GraphicsContext, layout: EditorGridLayout, position: Position) {
        let info = editor.cell(at: position)
        let full = layout.rect(of: position)
        let rect = full.insetBy(dx: layout.cell * 0.04, dy: layout.cell * 0.04)
        let tile = Path(roundedRect: rect, cornerRadius: layout.cell * 0.22)
        let center = CGPoint(x: full.midX, y: full.midY)
        let size = layout.cell

        context.fill(tile, with: .color(info.isFloor ? .mapTileFloor : .mapTileWall))
        if info.isFloor {
            context.stroke(tile, with: .color(.mapTileFloorStroke), lineWidth: 1)
        } else {
            // 편집 중에는 어두운 벽도 칸 경계가 보여야 함
            context.stroke(tile, with: .color(.mapTileFloorStroke.opacity(0.3)), lineWidth: 1)
        }

        if info.hasItem { drawGem(context, center: center, size: size) }
        if let pair = info.gatePair {
            context.stroke(Path(ellipseIn: circleRect(center, size * 0.22)),
                           with: .color(.switchOrange.opacity(0.9)), lineWidth: 3)
            drawBadge(context, number: pair + 1, in: full)
        }
        if let pair = info.switchPair {
            context.fill(Path(ellipseIn: circleRect(center, size * 0.24)), with: .color(.switchOrange))
            drawBadge(context, number: pair + 1, in: full)
        }
        if let pair = info.portalPair {
            context.stroke(Path(ellipseIn: circleRect(center, size * 0.32)), with: .color(.portalPurple), lineWidth: 3)
            context.fill(Path(ellipseIn: circleRect(center, size * 0.16)), with: .color(.portalPurple.opacity(0.5)))
            drawBadge(context, number: pair + 1, in: full)
        }
        if info.isGoal { drawGoal(context, center: center, size: size) }
        if info.isStart { drawStart(context, center: center, size: size) }

        if info.isPending {
            context.stroke(tile, with: .color(.accentColor), lineWidth: max(2, size * 0.07))
        }
    }

    private func circleRect(_ center: CGPoint, _ radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }

    private func drawGem(_ context: GraphicsContext, center: CGPoint, size: CGFloat) {
        let s = size * 0.28
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - s))
        path.addLine(to: CGPoint(x: center.x + s, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + s))
        path.addLine(to: CGPoint(x: center.x - s, y: center.y))
        path.closeSubpath()
        context.fill(path, with: .color(.gemMint))
    }

    private func drawGoal(_ context: GraphicsContext, center: CGPoint, size: CGFloat) {
        let radius = size * 0.34
        context.fill(Path(ellipseIn: circleRect(center, radius)), with: .color(.mapGoal))
        let highlight = CGPoint(x: center.x - radius * 0.2, y: center.y - radius * 0.25)
        context.fill(Path(ellipseIn: circleRect(highlight, radius * 0.45)), with: .color(.white.opacity(0.35)))
    }

    /// 시작 — 캐릭터와 같은 둥근 사각형에 바라보는 방향 화살표
    private func drawStart(_ context: GraphicsContext, center: CGPoint, size: CGFloat) {
        let body = CGRect(x: center.x - size * 0.4, y: center.y - size * 0.4, width: size * 0.8, height: size * 0.8)
        context.fill(Path(roundedRect: body, cornerRadius: size * 0.18), with: .color(.characterBody))

        let a = size * 0.2
        var arrow = Path()
        arrow.move(to: CGPoint(x: 0, y: -a))
        arrow.addLine(to: CGPoint(x: a, y: a * 0.8))
        arrow.addLine(to: CGPoint(x: -a, y: a * 0.8))
        arrow.closeSubpath()
        let angle: Double
        switch editor.map.startDirection {
        case .up: angle = 0
        case .right: angle = .pi / 2
        case .down: angle = .pi
        case .left: angle = .pi * 1.5
        }
        let transform = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: angle)
        context.fill(arrow.applying(transform), with: .color(.characterArrow))
    }

    /// 짝 번호 배지 — 칸 오른쪽 위
    private func drawBadge(_ context: GraphicsContext, number: Int, in rect: CGRect) {
        let radius = rect.width * 0.17
        let center = CGPoint(x: rect.maxX - radius * 1.2, y: rect.minY + radius * 1.2)
        context.fill(Path(ellipseIn: circleRect(center, radius)), with: .color(.black.opacity(0.55)))
        context.draw(Text("\(number)").font(.system(size: radius * 1.3, weight: .bold)).foregroundStyle(.white),
                     at: center)
    }
}
