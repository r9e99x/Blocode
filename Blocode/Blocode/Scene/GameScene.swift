//
//  GameScene.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SpriteKit
import SwiftUI

// MARK: - GameScene
/// SpriteKit 기반 2D 탑뷰 맵 렌더링 씬
/// 타일, 캐릭터, 목표 지점을 그리고 캐릭터 이동 애니메이션을 담당
class GameScene: SKScene {

    // MARK: - 색상 (다크모드 대응 — updateColorScheme으로 갱신)
    // 길(경로): 연한 색 / 벽: 짙은 색
    private var floorColor  = SKColor(red: 232/255, green: 221/255, blue: 194/255, alpha: 1.0) // 라이트: #e8ddc2 — 걸을 수 있는 길
    private var wallColor   = SKColor(red: 187/255, green: 167/255, blue: 126/255, alpha: 1.0) // 라이트: #bba77e — 벽
    private var characterColor = SKColor(red: 42/255, green: 37/255, blue: 32/255, alpha: 1.0) // #2a2520
    private let goalColor   = SKColor(red: 0.93, green: 0.67, blue: 0.24, alpha: 1.0) // 골드 (공통)

    // MARK: - 맵 데이터
    // 외부 읽기 가능, 내부에서만 쓰기 가능
    private(set) var mapData: MapData

    // MARK: - 캐릭터 현재 상태
    // GameViewModel에서 직접 수정 가능 (external write 허용)
    var characterPosition: Position   // 현재 캐릭터가 있는 타일 좌표
    var characterDirection: Direction // 현재 캐릭터가 바라보는 방향

    // MARK: - 노드 참조
    private var characterNode: SKNode?  // 캐릭터 SKNode — 이동/회전 애니메이션 적용 대상

    // MARK: - 초기화
    init(mapData: MapData) {
        self.mapData = mapData
        // 시작 위치와 방향으로 초기화
        self.characterPosition = mapData.start
        self.characterDirection = mapData.startDirection
        super.init(size: .zero)
        // 뷰 크기에 맞게 씬이 리사이즈되도록 설정
        self.scaleMode = .resizeFill
        // 배경을 투명으로 설정 (SwiftUI 배경 색상이 보이도록)
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 색상 업데이트

    /// 다크/라이트 모드에 따라 타일 색상을 변경하고 맵을 다시 그림
    func updateColorScheme(isDark: Bool) {
        floorColor = isDark
            ? SKColor(red: 0.24, green: 0.27, blue: 0.36, alpha: 1.0) // 다크: 밝은 블루그레이 — 길
            : SKColor(red: 232/255, green: 221/255, blue: 194/255, alpha: 1.0) // 라이트: #e8ddc2 — 길
        wallColor = isDark
            ? SKColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1.0) // 다크: 매우 어두운 네이비 — 벽
            : SKColor(red: 187/255, green: 167/255, blue: 126/255, alpha: 1.0) // 라이트: #bba77e — 벽
        characterColor = isDark
            ? SKColor(red: 0.88, green: 0.88, blue: 0.90, alpha: 1.0)
            : SKColor(red: 42/255, green: 37/255, blue: 32/255, alpha: 1.0) // #2a2520
        // 색상 변경 후 맵 전체 다시 그리기
        setupMap()
    }

    // MARK: - 라이프사이클

    /// 씬이 뷰에 표시될 때 호출 — 초기 맵 설정
    override func didMove(to view: SKView) {
        setupMap()
    }

    /// 씬 크기가 변경될 때 호출 — 유효한 크기일 때만 맵 재설정
    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        setupMap()
    }

    // MARK: - 맵 설정

    /// 모든 자식 노드를 제거하고 맵, 목표 지점, 캐릭터를 새로 렌더링
    func setupMap() {
        // 기존 노드 전체 제거
        removeAllChildren()
        guard size.width > 0, size.height > 0 else { return }

        let cols = mapData.width
        let rows = mapData.height

        // 타일 간격과 패딩 설정
        let gap: CGFloat = 8
        let padding: CGFloat = 20
        let availableWidth  = size.width  - padding * 2
        let availableHeight = size.height - padding * 2
        // 타일 크기는 항상 5×5 기준으로 계산 — 작은 맵도 타일이 너무 커지지 않음
        let refCols = max(cols, 5)
        let refRows = max(rows, 5)
        let maxByWidth  = (availableWidth  + gap) / CGFloat(refCols) - gap
        let maxByHeight = (availableHeight + gap) / CGFloat(refRows) - gap
        let tileSize    = min(maxByWidth, maxByHeight, 76)  // 최대 76pt 제한
        let cornerRadius = tileSize * 0.22  // 타일 모서리 반지름 (타일 크기의 22%)

        let cellSize  = tileSize + gap  // 하나의 셀 크기 (타일 + 간격)
        let mapWidth  = CGFloat(cols) * cellSize - gap
        let mapHeight = CGFloat(rows) * cellSize - gap

        // 맵을 씬 중앙에 배치하기 위한 오프셋 계산
        let originX = (size.width  - mapWidth)  / 2
        let originY = (size.height - mapHeight) / 2

        // MARK: 타일 렌더링 — 경로 + 빈 칸 모두 그리기
        for row in 0..<rows {
            for col in 0..<cols {
                // 바닥 타일인지 벽 타일인지 확인
                let isFloor = mapData.grid[row][col] == TileType.floor.rawValue

                // SpriteKit은 y가 아래에서 위 방향이므로 행을 반전하여 계산
                let x = originX + CGFloat(col) * cellSize + tileSize / 2
                let y = originY + CGFloat(rows - 1 - row) * cellSize + tileSize / 2

                let tile = makeTileNode(
                    at: CGPoint(x: x, y: y),
                    size: tileSize,
                    radius: cornerRadius,
                    isFloor: isFloor
                )
                addChild(tile)
            }
        }

        // MARK: 목표 지점 렌더링
        let goalX = originX + CGFloat(mapData.goal.x) * cellSize + tileSize / 2
        let goalY = originY + CGFloat(rows - 1 - mapData.goal.y) * cellSize + tileSize / 2
        let goal  = makeGoalNode(at: CGPoint(x: goalX, y: goalY), tileSize: tileSize)
        addChild(goal)

        // MARK: 캐릭터 렌더링
        let character = makeCharacterNode(tileSize: tileSize, cornerRadius: cornerRadius)
        characterNode = character  // 이동/회전 애니메이션을 위한 참조 저장
        addChild(character)

        // 캐릭터를 현재 위치에 배치 (애니메이션 없음)
        placeCharacter(originX: originX, originY: originY,
                       rows: rows, cellSize: cellSize,
                       tileSize: tileSize, animated: false)
    }

    // MARK: - 노드 생성

    /// 타일 노드 — isFloor: 연한 길(평면) / !isFloor: 짙은 벽(3D)
    private func makeTileNode(at position: CGPoint, size: CGFloat,
                               radius: CGFloat, isFloor: Bool) -> SKNode {
        if isFloor {
            // 바닥 타일 — 평면 + 테두리로 표현
            let node = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: radius)
            node.position    = position
            node.fillColor   = floorColor
            // 연한 테두리로 바닥 타일 구분
            node.strokeColor = SKColor(red: 210/255, green: 198/255, blue: 172/255, alpha: 1.0)
            node.lineWidth   = 1.5
            node.zPosition   = 0  // 맨 아래 레이어
            return node
        } else {
            // 벽 타일 — 3D 레이어 구조로 입체감 표현
            let node = make3DBlockNode(
                at: position,
                size: size,
                radius: radius,
                color: wallColor,
                topDepth: 0.8,  // 위 뒷면 두께
                botDepth: 3.0,  // 아래 뒷면 두께 (그림자 효과)
                baseZ: 0,
                topColor: SKColor(red: 199/255, green: 182/255, blue: 148/255, alpha: 1.0), // #c7b694
                botColor: SKColor(red: 159/255, green: 139/255, blue: 101/255, alpha: 1.0)  // #9f8b65
            )
            return node
        }
    }

    /// 3D 블럭 노드 생성 — 위 뒷면(밝게) + 앞면 + 아래 뒷면(어둡게)
    /// topColor: 위 뒷면 직접 지정 (nil이면 color + white 오버레이로 자동 계산)
    /// botColor: 아래 뒷면 직접 지정 (nil이면 color + black 오버레이로 자동 계산)
    private func make3DBlockNode(at position: CGPoint, size: CGFloat, radius: CGFloat,
                                  color: SKColor, topDepth: CGFloat, botDepth: CGFloat,
                                  baseZ: CGFloat, topColor: SKColor? = nil, botColor: SKColor? = nil) -> SKNode {
        // 컨테이너 노드로 묶어서 한 번에 이동/회전 가능하게 설정
        let container = SKNode()
        container.position = position
        container.zPosition = baseZ

        // ① 위 뒷면 — topColor 직접 지정 or color + white 0.28 오버레이
        let topBack = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: radius)
        topBack.strokeColor = .clear
        topBack.position    = CGPoint(x: 0, y: topDepth)  // 앞면보다 위에 위치
        topBack.zPosition   = 0
        if let topColor = topColor {
            topBack.fillColor = topColor
        } else {
            topBack.fillColor = color
            // 흰색 오버레이로 밝게 표현
            let topOverlay = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: radius)
            topOverlay.fillColor   = SKColor(white: 1.0, alpha: 0.28)
            topOverlay.strokeColor = .clear
            topBack.addChild(topOverlay)
        }
        container.addChild(topBack)

        // ② 아래 뒷면 — botColor 직접 지정 or color + black 0.28 오버레이
        let botBack = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: radius)
        botBack.strokeColor = .clear
        botBack.position    = CGPoint(x: 0, y: -(topDepth + botDepth))  // 앞면보다 아래에 위치
        botBack.zPosition   = 0
        if let botColor = botColor {
            botBack.fillColor = botColor
        } else {
            botBack.fillColor = color
            // 검정 오버레이로 어둡게 표현 (그림자 효과)
            let botOverlay = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: radius)
            botOverlay.fillColor   = SKColor(white: 0.0, alpha: 0.28)
            botOverlay.strokeColor = .clear
            botBack.addChild(botOverlay)
        }
        container.addChild(botBack)

        // ③ 앞면 — color, y: -topDepth (위 뒷면이 앞면 위로 살짝 보이도록)
        let front = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: radius)
        front.fillColor   = color
        front.strokeColor = .clear
        front.position    = CGPoint(x: 0, y: -topDepth)
        front.zPosition   = 1  // 뒷면보다 앞에 표시
        container.addChild(front)

        return container
    }

    /// 목표 지점 노드 — 골드 원형 + 하이라이트로 입체감 표현
    private func makeGoalNode(at position: CGPoint, tileSize: CGFloat) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 1  // 바닥 타일보다 위에 표시

        // 골드 원형 본체
        let radius = tileSize * 0.34
        let circle = SKShapeNode(circleOfRadius: radius)
        circle.fillColor  = goalColor
        circle.strokeColor = .clear
        container.addChild(circle)

        // 하이라이트 (입체감) — 왼쪽 상단에 작은 흰 원으로 광택 표현
        let highlightRadius = radius * 0.45
        let highlight = SKShapeNode(circleOfRadius: highlightRadius)
        highlight.fillColor  = SKColor(white: 1.0, alpha: 0.35)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -radius * 0.20, y: radius * 0.25)
        container.addChild(highlight)

        return container
    }

    /// 캐릭터 노드 — 3D 다크 정사각형 + 흰 삼각형 화살표로 방향 표시
    private func makeCharacterNode(tileSize: CGFloat, cornerRadius: CGFloat) -> SKNode {
        let container = SKNode()
        container.zPosition = 2  // 타일/목표 지점보다 위에 표시

        // 캐릭터 몸체 크기 (타일의 80%)
        let bodySize   = tileSize * 0.80
        let bodyRadius = cornerRadius * 0.85

        // 3D 블럭 본체 (topDepth=1, botDepth=2 — 스테이지 아이콘과 동일)
        let body3D = make3DBlockNode(
            at: .zero,
            size: bodySize,
            radius: bodyRadius,
            color: characterColor,
            topDepth: 0.5,
            botDepth: 2.0,
            baseZ: 0,
            topColor: SKColor(red: 128/255, green: 120/255, blue: 105/255, alpha: 1.0), // #807869
            botColor: SKColor(red: 190/255, green: 181/255, blue: 159/255, alpha: 1.0)  // #beb59f
        )
        container.addChild(body3D)

        // 방향 화살표 — body3D 앞면보다 높은 zPosition에 배치
        let arrowSize = tileSize * 0.22
        let arrow = makeArrowNode(size: arrowSize)
        arrow.zPosition = 3  // 캐릭터 본체 앞에 표시
        container.addChild(arrow)

        return container
    }

    /// 위쪽을 향하는 화살표 (머리 + 줄기) — CGMutablePath로 직접 그리기
    private func makeArrowNode(size: CGFloat) -> SKShapeNode {
        // SpriteKit: y 위가 양수
        let hw  = size * 0.65  // 화살 머리 반폭
        let sw  = size * 0.22  // 줄기 반폭
        let hy  = size * 0.10  // 머리·줄기 경계 y
        let top = size * 1.0   // 꼭짓점
        let bot = -size * 0.75 // 줄기 아래

        // 화살표 모양의 경로 생성
        let path = CGMutablePath()
        path.move(to:    CGPoint(x:  0,   y:  top))   // 꼭짓점
        path.addLine(to: CGPoint(x: -hw,  y:  hy))    // 머리 왼쪽
        path.addLine(to: CGPoint(x: -sw,  y:  hy))    // 줄기 왼쪽 위
        path.addLine(to: CGPoint(x: -sw,  y:  bot))   // 줄기 왼쪽 아래
        path.addLine(to: CGPoint(x:  sw,  y:  bot))   // 줄기 오른쪽 아래
        path.addLine(to: CGPoint(x:  sw,  y:  hy))    // 줄기 오른쪽 위
        path.addLine(to: CGPoint(x:  hw,  y:  hy))    // 머리 오른쪽
        path.closeSubpath()

        let node = SKShapeNode(path: path)
        node.fillColor   = SKColor(red: 244/255, green: 236/255, blue: 215/255, alpha: 1.0) // #f4ecd7
        node.strokeColor = .clear
        return node
    }

    // MARK: - 캐릭터 이동

    /// 현재 characterPosition과 characterDirection에 맞게 캐릭터 노드 위치/각도 업데이트
    /// - Parameter animated: true이면 부드러운 이동 애니메이션 적용
    func updateCharacterTransform(animated: Bool) {
        guard size.width > 0, size.height > 0 else { return }

        // setupMap과 동일한 타일 크기 계산
        let cols = mapData.width
        let rows = mapData.height
        let gap: CGFloat = 8
        let padding: CGFloat = 20
        let availableWidth  = size.width  - padding * 2
        let availableHeight = size.height - padding * 2
        let refCols = max(cols, 5)
        let refRows = max(rows, 5)
        let maxByWidth  = (availableWidth  + gap) / CGFloat(refCols) - gap
        let maxByHeight = (availableHeight + gap) / CGFloat(refRows) - gap
        let tileSize = min(maxByWidth, maxByHeight, 76)
        let cellSize = tileSize + gap
        let mapWidth  = CGFloat(cols) * cellSize - gap
        let mapHeight = CGFloat(rows) * cellSize - gap
        let originX = (size.width  - mapWidth)  / 2
        let originY = (size.height - mapHeight) / 2

        placeCharacter(originX: originX, originY: originY,
                       rows: rows, cellSize: cellSize,
                       tileSize: tileSize, animated: animated)
    }

    /// 캐릭터 노드를 현재 position과 direction에 맞게 배치
    private func placeCharacter(originX: CGFloat, originY: CGFloat,
                                 rows: Int, cellSize: CGFloat,
                                 tileSize: CGFloat, animated: Bool) {
        guard let character = characterNode else { return }

        // 타일 좌표를 씬 좌표로 변환
        let x = originX + CGFloat(characterPosition.x) * cellSize + tileSize / 2
        let y = originY + CGFloat(rows - 1 - characterPosition.y) * cellSize + tileSize / 2
        let targetPos   = CGPoint(x: x, y: y)
        let targetAngle = rotationAngle(for: characterDirection)

        if animated {
            // 설정된 실행 속도에 맞춰 애니메이션 시간 조절
            let speed  = SettingsService.shared.executionSpeed
            let move   = SKAction.move(to: targetPos, duration: 0.25 / speed)
            let rotate = SKAction.rotate(toAngle: targetAngle, duration: 0.15 / speed, shortestUnitArc: true)
            move.timingMode = .easeInEaseOut  // 부드러운 시작과 끝
            // 이동과 회전을 동시에 실행
            character.run(SKAction.group([move, rotate]))
        } else {
            // 즉시 배치 (초기화 시 사용)
            character.position = targetPos
            character.zRotation = targetAngle
        }
    }

    /// Direction을 SpriteKit 회전 각도(라디안)로 변환
    private func rotationAngle(for direction: Direction) -> CGFloat {
        switch direction {
        case .up:    return 0           // 위: 회전 없음 (기본 방향)
        case .left:  return .pi / 2     // 왼쪽: 90도 반시계
        case .down:  return .pi         // 아래: 180도
        case .right: return -.pi / 2    // 오른쪽: 90도 시계
        }
    }

    // MARK: - 리셋

    /// 캐릭터를 시작 위치와 방향으로 되돌림 (애니메이션 포함)
    func resetCharacter() {
        characterPosition = mapData.start
        characterDirection = mapData.startDirection
        updateCharacterTransform(animated: true)
    }
}
