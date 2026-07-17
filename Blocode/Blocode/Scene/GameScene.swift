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
    private var characterColor = SKColor.darkInk // #2a2520
    private let goalColor   = SKColor(red: 0.93, green: 0.67, blue: 0.24, alpha: 1.0) // 골드 (공통)

    // 기믹 색상 (챕터 6+ 전용 — goalColor와 동일하게 라이트/다크 구분 없는 고정값)
    private let itemColor       = SKColor(red: 0.42, green: 0.82, blue: 0.68, alpha: 1.0) // 민트 보석
    private let switchColor     = SKColor(red: 0.93, green: 0.62, blue: 0.28, alpha: 1.0) // 주황 스위치
    private let gateMarkerColor = SKColor(red: 0.93, green: 0.62, blue: 0.28, alpha: 1.0) // 문 표시(스위치와 동일 톤)
    private let portalColor     = SKColor(red: 0.62, green: 0.45, blue: 0.85, alpha: 1.0) // 보라 포탈

    // 바닥 타일 테두리 — 라이트: #d2c6ac (기존 고정값) / 다크: 바닥 채우기보다 살짝 밝은 쿨톤
    private var floorStrokeColor = SKColor(red: 210/255, green: 198/255, blue: 172/255, alpha: 1.0)
    // 벽 3D 베벨 — 라이트: #c7b694 / #9f8b65 (기존 고정값) / 다크: 벽 채우기와 어울리는 쿨톤
    private var wallTopColor = SKColor(red: 199/255, green: 182/255, blue: 148/255, alpha: 1.0)
    private var wallBotColor = SKColor(red: 159/255, green: 139/255, blue: 101/255, alpha: 1.0)
    // 캐릭터 3D 베벨/화살표 — 라이트: 기존 탄색 베벨 + 크림 화살표 / 다크: 쿨 그레이 베벨 + 다크 화살표
    // (다크에선 캐릭터 몸체가 밝은 회백색이라 탄색 베벨·크림 화살표가 뭉개지는 문제 수정)
    private var charTopBackColor    = SKColor.bevelTopBack
    private var charBottomBackColor = SKColor.bevelBottomBack
    private var charArrowColor      = SKColor.arrowCream

    // MARK: - 맵 데이터
    // 외부 읽기 가능, 내부에서만 쓰기 가능
    private(set) var mapData: MapData

    // MARK: - 캐릭터 현재 상태
    // GameViewModel에서 직접 수정 가능 (external write 허용)
    var characterPosition: Position   // 현재 캐릭터가 있는 타일 좌표
    var characterDirection: Direction // 현재 캐릭터가 바라보는 방향

    // MARK: - 노드 참조
    private var characterNode: SKNode?  // 캐릭터 SKNode — 이동/회전 애니메이션 적용 대상

    // MARK: - 기믹 상태 (챕터 6+ 전용)
    // setupMap()이 리사이즈·다크모드 전환마다 전체 노드를 재생성하므로,
    // "이미 수집한 보석/이미 열린 문"은 씬이 자체적으로 기억해뒀다가 재생성 시 그대로 반영한다
    // (기믹 없는 스테이지는 이 두 Set이 항상 비어있어 아래 로직이 전부 조용히 스킵됨)
    private var itemNodes: [Position: SKNode] = [:]        // 아직 안 먹은 보석 노드 (setupMap마다 재생성)
    private var collectedItemPositions: Set<Position> = []  // 이미 수집한 보석 — 재구성 시에도 숨김 유지
    private var openGatePositions: Set<Position> = []       // 이미 열린 문 — 재구성 시에도 열림 유지

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
            : SKColor.darkInk // #2a2520

        // 바닥 타일 테두리 — 다크에선 바닥 채우기(블루그레이)보다 살짝 밝은 쿨톤으로
        floorStrokeColor = isDark
            ? SKColor(red: 0.33, green: 0.37, blue: 0.47, alpha: 1.0)
            : SKColor(red: 210/255, green: 198/255, blue: 172/255, alpha: 1.0) // 라이트: 기존 탄색 유지

        // 벽 3D 베벨 — 다크에선 벽 채우기(짙은 네이비) 기준으로 위는 살짝 밝게, 아래는 살짝 어둡게
        wallTopColor = isDark
            ? SKColor(red: 0.165, green: 0.18, blue: 0.235, alpha: 1.0)
            : SKColor(red: 199/255, green: 182/255, blue: 148/255, alpha: 1.0)  // 라이트: #c7b694 유지
        wallBotColor = isDark
            ? SKColor(red: 0.065, green: 0.07, blue: 0.095, alpha: 1.0)
            : SKColor(red: 159/255, green: 139/255, blue: 101/255, alpha: 1.0)  // 라이트: #9f8b65 유지

        // 캐릭터 베벨/화살표 — 다크에선 밝은 몸체에 맞춰 쿨 그레이 베벨 + 다크 잉크 화살표
        // (홈 화면 미니 아이콘의 characterTopBack/BottomBack/Arrow 다크 값과 동일)
        charTopBackColor = isDark
            ? SKColor(red: 0.70, green: 0.71, blue: 0.75, alpha: 1.0)
            : SKColor.bevelTopBack      // 라이트: #807869 유지
        charBottomBackColor = isDark
            ? SKColor(red: 0.52, green: 0.53, blue: 0.60, alpha: 1.0)
            : SKColor.bevelBottomBack   // 라이트: #beb59f 유지
        charArrowColor = isDark
            ? SKColor(red: 42/255, green: 37/255, blue: 32/255, alpha: 1.0)     // 다크: 다크 잉크 화살표
            : SKColor.arrowCream        // 라이트: #f4ecd7 유지

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

    // MARK: - 레이아웃 계산

    /// 맵 렌더링과 캐릭터 배치에 공통으로 쓰는 타일 레이아웃 수치
    private struct MapLayout {
        let tileSize: CGFloat   // 타일 한 변 크기
        let cellSize: CGFloat   // 타일 + 간격 (한 칸 크기)
        let originX: CGFloat    // 맵 좌측 시작 x (씬 중앙 정렬)
        let originY: CGFloat    // 맵 하단 시작 y (씬 중앙 정렬)
    }

    /// 현재 씬 크기와 맵 크기로 타일 레이아웃 수치를 계산
    /// setupMap()과 updateCharacterTransform()이 같은 값을 쓰도록 단일화한 계산부
    /// (호출 전 size.width/height > 0 가드 필요)
    private func layoutMetrics() -> MapLayout {
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

        let cellSize  = tileSize + gap  // 하나의 셀 크기 (타일 + 간격)
        let mapWidth  = CGFloat(cols) * cellSize - gap
        let mapHeight = CGFloat(rows) * cellSize - gap

        // 맵을 씬 중앙에 배치하기 위한 오프셋 계산
        let originX = (size.width  - mapWidth)  / 2
        let originY = (size.height - mapHeight) / 2

        return MapLayout(tileSize: tileSize, cellSize: cellSize, originX: originX, originY: originY)
    }

    // MARK: - 맵 설정

    /// 모든 자식 노드를 제거하고 맵, 목표 지점, 캐릭터를 새로 렌더링
    func setupMap() {
        // 기존 노드 전체 제거
        removeAllChildren()
        itemNodes = [:]  // 노드 자체는 removeAllChildren으로 이미 제거됨 — 참조만 비움
        guard size.width > 0, size.height > 0 else { return }

        let cols = mapData.width
        let rows = mapData.height

        // 타일 레이아웃 수치 (캐릭터 배치와 동일한 값을 쓰도록 단일화)
        let layout = layoutMetrics()
        let tileSize = layout.tileSize
        let cellSize = layout.cellSize
        let originX  = layout.originX
        let originY  = layout.originY
        let cornerRadius = tileSize * 0.22  // 타일 모서리 반지름 (타일 크기의 22%)

        // MARK: 타일 렌더링 — 경로 + 빈 칸 + 기믹(문/보석/스위치/포탈) 모두 그리기
        for row in 0..<rows {
            for col in 0..<cols {
                let pos = Position(x: col, y: row)

                // 문(게이트) 타일인지 확인 — grid 원본은 항상 벽(0)이고, 열렸으면 바닥처럼 통행 가능
                // (mapData.switches가 nil인 기존 35개 스테이지는 isGateTile이 항상 false라 아래 로직 전부 무해)
                let isGateTile = mapData.switches?.contains(where: { $0.gateAt == pos }) ?? false
                let isOpenGate = isGateTile && openGatePositions.contains(pos)
                let isFloor = mapData.grid[row][col] == TileType.floor.rawValue || isOpenGate

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

                // 문 표시 마커 — 닫힘: 벽 위에 진한 링 / 열림: 바닥 위에 옅은 링(잔상)
                if isGateTile {
                    let marker = makeGateMarkerNode(size: tileSize, isOpen: isOpenGate)
                    marker.position = CGPoint(x: x, y: y)
                    marker.zPosition = 1
                    addChild(marker)
                }

                // 스위치 — 바닥 위에 눌리는 버튼 표시
                if mapData.switches?.contains(where: { $0.switchAt == pos }) == true {
                    let switchNode = makeSwitchNode(size: tileSize)
                    switchNode.position = CGPoint(x: x, y: y)
                    switchNode.zPosition = 1
                    addChild(switchNode)
                }

                // 보석 — 이미 수집한 위치는 다시 그리지 않음(재구성해도 숨김 유지)
                if mapData.items?.contains(pos) == true, !collectedItemPositions.contains(pos) {
                    let itemNode = makeItemNode(size: tileSize)
                    itemNode.position = CGPoint(x: x, y: y)
                    itemNode.zPosition = 1
                    addChild(itemNode)
                    itemNodes[pos] = itemNode
                }

                // 포탈 — 양쪽 위치 모두에 표시
                if mapData.portals?.contains(where: { $0.a == pos || $0.b == pos }) == true {
                    let portalNode = makePortalNode(size: tileSize)
                    portalNode.position = CGPoint(x: x, y: y)
                    portalNode.zPosition = 1
                    addChild(portalNode)
                }
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
            // 연한 테두리로 바닥 타일 구분 (라이트: 탄색 / 다크: 쿨톤 — updateColorScheme에서 결정)
            node.strokeColor = floorStrokeColor
            node.lineWidth   = 1.5
            node.zPosition   = 0  // 맨 아래 레이어
            return node
        } else {
            // 벽 타일 — 3D 레이어 구조로 입체감 표현
            // (베벨 색은 라이트/다크에 따라 updateColorScheme에서 결정)
            let node = make3DBlockNode(
                at: position,
                size: size,
                radius: radius,
                color: wallColor,
                topDepth: 0.8,  // 위 뒷면 두께
                botDepth: 3.0,  // 아래 뒷면 두께 (그림자 효과)
                baseZ: 0,
                topColor: wallTopColor,
                botColor: wallBotColor
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

    // MARK: - 기믹 노드 생성 (챕터 6+ 전용)

    /// 보석 노드 — 민트 다이아몬드 모양
    private func makeItemNode(size: CGFloat) -> SKShapeNode {
        let s = size * 0.28
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: s))
        path.addLine(to: CGPoint(x: s, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -s))
        path.addLine(to: CGPoint(x: -s, y: 0))
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = itemColor
        node.strokeColor = .clear
        return node
    }

    /// 스위치 노드 — 주황 원형 버튼
    private func makeSwitchNode(size: CGFloat) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: size * 0.24)
        node.fillColor = switchColor
        node.strokeColor = .clear
        return node
    }

    /// 문(게이트) 표시 마커 — 닫힘: 진한 링(벽 위) / 열림: 옅은 링(바닥 위 잔상)
    private func makeGateMarkerNode(size: CGFloat, isOpen: Bool) -> SKShapeNode {
        let ring = SKShapeNode(circleOfRadius: size * 0.22)
        ring.fillColor = .clear
        ring.strokeColor = gateMarkerColor.withAlphaComponent(isOpen ? 0.35 : 0.9)
        ring.lineWidth = isOpen ? 2 : 3
        return ring
    }

    /// 포탈 노드 — 보라 이중 원형
    private func makePortalNode(size: CGFloat) -> SKNode {
        let container = SKNode()
        let outer = SKShapeNode(circleOfRadius: size * 0.32)
        outer.fillColor = .clear
        outer.strokeColor = portalColor
        outer.lineWidth = 3
        let inner = SKShapeNode(circleOfRadius: size * 0.16)
        inner.fillColor = portalColor.withAlphaComponent(0.5)
        inner.strokeColor = .clear
        container.addChild(outer)
        container.addChild(inner)
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
        // 베벨 색은 라이트(탄색)/다크(쿨 그레이)에 따라 updateColorScheme에서 결정
        let body3D = make3DBlockNode(
            at: .zero,
            size: bodySize,
            radius: bodyRadius,
            color: characterColor,
            topDepth: 0.5,
            botDepth: 2.0,
            baseZ: 0,
            topColor: charTopBackColor,
            botColor: charBottomBackColor
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
        node.fillColor   = charArrowColor // 라이트: 크림 #f4ecd7 / 다크: 다크 잉크 (몸체 밝음에 맞춘 반전)
        node.strokeColor = .clear
        return node
    }

    // MARK: - 캐릭터 이동

    /// 현재 characterPosition과 characterDirection에 맞게 캐릭터 노드 위치/각도 업데이트
    /// - Parameter animated: true이면 부드러운 이동 애니메이션 적용
    func updateCharacterTransform(animated: Bool) {
        guard size.width > 0, size.height > 0 else { return }

        // setupMap과 동일한 타일 레이아웃 수치 사용 (layoutMetrics로 단일화)
        let rows = mapData.height
        let layout = layoutMetrics()

        placeCharacter(originX: layout.originX, originY: layout.originY,
                       rows: rows, cellSize: layout.cellSize,
                       tileSize: layout.tileSize, animated: animated)
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

    // MARK: - 기믹 효과 (챕터 6+ 전용 — GameViewModel.applyTileEffects가 호출)

    /// 보석 수집 — 노드를 사라지는 애니메이션과 함께 제거, 재구성 시에도 숨김 유지
    func collectItem(at position: Position) {
        collectedItemPositions.insert(position)
        itemNodes[position]?.run(.sequence([
            .scale(to: 1.4, duration: 0.1),
            .group([.fadeOut(withDuration: 0.15), .scale(to: 0.1, duration: 0.15)]),
            .removeFromParent()
        ]))
        itemNodes[position] = nil
    }

    /// 문 열기 — 벽→바닥 전환은 타일 자체를 다시 그려야 해서 맵 전체를 재구성
    /// (updateColorScheme도 색만 바꾸려고 동일하게 setupMap()을 다시 부르는 기존 패턴과 동일)
    func openGate(at position: Position) {
        openGatePositions.insert(position)
        setupMap()
    }

    /// 포탈 이동 — 캐릭터를 목적지로 즉시 재배치 (짧은 페이드 효과로 순간이동 느낌)
    func teleportCharacter(to destination: Position) {
        guard let character = characterNode else { return }
        characterPosition = destination

        let rows = mapData.height
        let layout = layoutMetrics()
        let x = layout.originX + CGFloat(destination.x) * layout.cellSize + layout.tileSize / 2
        let y = layout.originY + CGFloat(rows - 1 - destination.y) * layout.cellSize + layout.tileSize / 2

        character.run(.sequence([
            .fadeOut(withDuration: 0.12),
            .move(to: CGPoint(x: x, y: y), duration: 0),
            .fadeIn(withDuration: 0.12)
        ]))
    }

    // MARK: - 리셋

    /// 캐릭터를 시작 위치와 방향으로 되돌림 (애니메이션 포함)
    /// 기믹 상태(수집한 보석/열린 문)가 없으면 기존과 완전히 동일한 슬라이드 애니메이션만 실행
    /// 기믹 상태가 있으면 맵을 통째로 재구성해 보석 재등장·문 다시 닫힘까지 함께 복원
    func resetCharacter() {
        characterPosition = mapData.start
        characterDirection = mapData.startDirection

        if collectedItemPositions.isEmpty && openGatePositions.isEmpty {
            // 기믹 없는(또는 아직 발동 전인) 스테이지 — 기존 그대로 부드러운 슬라이드
            updateCharacterTransform(animated: true)
        } else {
            collectedItemPositions = []
            openGatePositions = []
            setupMap()  // 내부에서 캐릭터도 시작 위치에 즉시 배치됨
        }
    }
}
