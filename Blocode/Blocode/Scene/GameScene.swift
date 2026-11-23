//
//  GameScene.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SpriteKit

// MARK: - GameScene
/// SpriteKit 기반 2D 탑뷰 맵 렌더링 씬
/// 타일, 캐릭터, 목표 지점을 그리고 캐릭터 이동 애니메이션을 담당
class GameScene: SKScene, GameBoardRendering {

    // MARK: - 색상

    /// 라이트/다크별 맵 색 묶음 — 각 색을 한 곳에서만 정의 (예전엔 라이트 값이 초기값과 updateColorScheme 두 군데에 있었음)
    private struct Palette {
        let floor: SKColor           // 길(경로) — 연한 색
        let wall: SKColor            // 벽 — 짙은 색
        let floorStroke: SKColor     // 바닥 타일 테두리
        let wallTop: SKColor         // 벽 3D 위 베벨
        let wallBottom: SKColor      // 벽 3D 아래 베벨
        let character: SKColor       // 캐릭터 몸체
        let charTopBack: SKColor     // 캐릭터 3D 위 베벨
        let charBottomBack: SKColor  // 캐릭터 3D 아래 베벨
        let charArrow: SKColor       // 캐릭터 방향 화살표

        /// 라이트 — 기존 고정값 그대로 (절대 변경 금지)
        static let light = Palette(
            floor:          SKColor(red: 232/255, green: 221/255, blue: 194/255, alpha: 1.0), // #e8ddc2
            wall:           SKColor(red: 187/255, green: 167/255, blue: 126/255, alpha: 1.0), // #bba77e
            floorStroke:    SKColor(red: 210/255, green: 198/255, blue: 172/255, alpha: 1.0), // #d2c6ac
            wallTop:        SKColor(red: 199/255, green: 182/255, blue: 148/255, alpha: 1.0), // #c7b694
            wallBottom:     SKColor(red: 159/255, green: 139/255, blue: 101/255, alpha: 1.0), // #9f8b65
            character:      .darkInk,         // #2a2520
            charTopBack:    .bevelTopBack,    // #807869
            charBottomBack: .bevelBottomBack, // #beb59f
            charArrow:      .arrowCream       // #f4ecd7
        )

        /// 다크 — 바닥은 밝은 블루그레이, 벽은 짙은 네이비, 캐릭터는 밝은 회백색 몸체 + 쿨 그레이 베벨 + 다크 잉크 화살표
        /// (캐릭터 값은 홈 화면 미니 아이콘의 characterTopBack/BottomBack/Arrow 다크 값과 동일)
        static let dark = Palette(
            floor:          SKColor(red: 0.24, green: 0.27, blue: 0.36, alpha: 1.0),
            wall:           SKColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1.0),
            floorStroke:    SKColor(red: 0.33, green: 0.37, blue: 0.47, alpha: 1.0),
            wallTop:        SKColor(red: 0.165, green: 0.18, blue: 0.235, alpha: 1.0),
            wallBottom:     SKColor(red: 0.065, green: 0.07, blue: 0.095, alpha: 1.0),
            character:      SKColor(red: 0.88, green: 0.88, blue: 0.90, alpha: 1.0),
            charTopBack:    SKColor(red: 0.70, green: 0.71, blue: 0.75, alpha: 1.0),
            charBottomBack: SKColor(red: 0.52, green: 0.53, blue: 0.60, alpha: 1.0),
            charArrow:      SKColor(red: 42/255, green: 37/255, blue: 32/255, alpha: 1.0)
        )
    }

    /// 현재 색 묶음 — updateColorScheme으로 전환
    private var palette = Palette.light

    /// 목표 지점 골드 (라이트/다크 공통 고정값)
    private let goalColor = SKColor(red: 0.93, green: 0.67, blue: 0.24, alpha: 1.0)

    // MARK: - 맵 데이터
    // 외부 읽기 가능, 내부에서만 쓰기 가능
    private(set) var mapData: MapData

    // MARK: - 판 상태
    // VM이 update로 넘겨준 값을 보관 — 화면 크기·다크 모드가 바뀌어 맵을 다시 그릴 때 사용
    private(set) var board: GameBoard
    private var animationSpeed: Double = 1  // 애니메이션 시간에 적용할 실행 속도 배율

    // MARK: - 노드 참조
    private var characterNode: SKNode?  // 캐릭터 SKNode — 이동/회전 애니메이션 적용 대상

    // MARK: - 기믹 노드 (챕터 6+ 전용)
    private var itemNodes: [Position: SKNode] = [:]  // 보석 노드 전부 — 먹으면 지우지 않고 숨겨 두었다가 리셋 때 다시 보임 (setupMap마다 재생성)
    /// 문 칸의 타일·링 노드와 지금 그려진 열림 상태 — 문이 열리고 닫힐 때 이 칸만 바꿔 그림 (setupMap마다 재생성)
    private var gateNodes: [Position: (tile: SKNode, marker: SKNode, isOpen: Bool)] = [:]

    // MARK: - 초기화
    init(mapData: MapData) {
        self.mapData = mapData
        // 시작 상태로 초기화
        self.board = GameBoard(map: mapData)
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
        palette = isDark ? .dark : .light

        // 색상 변경 후 맵 전체 다시 그리기
        setupMap()
    }

    // MARK: - 라이프사이클

    /// 씬이 뷰에 표시될 때 호출 — 초기 맵 설정 (크기 변경 때 이미 같은 크기로 만들었으면 다시 만들지 않음)
    override func didMove(to view: SKView) {
        if builtLayout == nil || builtSize != size { setupMap() }
    }

    /// 씬 크기가 변경될 때 호출
    /// 이미 만든 맵은 묶음 노드의 배율만 맞춰 바로 보여 주고, 크기 변화가 멈추면 한 번만 다시 그림
    /// (예전엔 바뀔 때마다 노드 수백 개를 전부 다시 만들었음 — 패널 접기·펼치기 애니메이션, 아이패드 창 크기 조절 중 반복)
    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        guard let built = builtLayout else {
            setupMap()  // 처음 크기가 정해지면 바로 만듦
            return
        }
        wakeRendering()
        if size == builtSize {
            // 원래 크기로 돌아왔으면 배율만 되돌리고 다시 그리기 예약 취소
            mapLayer.setScale(1)
            mapLayer.position = .zero
            rebuildCountdown = nil
            return
        }
        let scale = layoutMetrics().cellSize / built.cellSize
        mapLayer.setScale(scale)
        // 맵은 늘 씬 가운데 정렬이라, 만들 때의 씬 가운데를 새 씬 가운데로 옮김
        mapLayer.position = CGPoint(x: size.width / 2 - builtSize.width / 2 * scale,
                                    y: size.height / 2 - builtSize.height / 2 * scale)
        rebuildCountdown = framesBeforeRebuild
    }

    /// 매 프레임 씬 크기를 지금 표시 중인 뷰에 맞춤
    /// 회전으로 배치가 바뀌면 사라지는 이전 뷰가 이 씬의 크기를 늦게 덮어써 타일이 작게 그려지는 일이 생김
    override func update(_ currentTime: TimeInterval) {
        if let viewSize = view?.bounds.size, viewSize.width > 0, viewSize.height > 0, size != viewSize {
            size = viewSize
        }
        // 크기 변화가 멈추고 몇 프레임 지나면 새 크기로 한 번 다시 그림 (배율로 늘인 모양을 정확한 모양으로 바꿈)
        if let countdown = rebuildCountdown {
            if countdown <= 0 { setupMap() } else { rebuildCountdown = countdown - 1 }
        }
        pauseRenderingWhenIdle()
    }

    // MARK: - 크기 변경 (배율 먼저, 다시 그리기는 한 번)

    /// 맵 노드를 모두 담는 묶음 — 크기가 바뀌면 이 묶음만 늘이거나 줄여 바로 보여 줌
    private let mapLayer = SKNode()
    /// 노드를 만들 때 쓴 배치 — 캐릭터 이동·문 교체 같은 좌표 계산은 늘 이 기준 (묶음이 늘어나 있어도 안쪽 좌표는 그대로)
    private var builtLayout: MapLayout?
    /// 노드를 만들 때의 씬 크기
    private var builtSize: CGSize = .zero
    /// 크기 변화가 멈춘 뒤 다시 그리기까지 남은 프레임 (nil이면 예약 없음)
    private var rebuildCountdown: Int?
    /// 크기 변화가 이만큼(60fps 기준 약 0.1초) 멈추면 다시 그림
    private let framesBeforeRebuild = 6

    // MARK: - 그리기 멈춤 (배터리)
    // 맵이 멈춰 있어도 SpriteKit은 매 프레임 다시 그림 — 움직이는 것이 없으면 뷰를 멈추고, 바뀔 때 다시 켬

    /// 움직이는 노드가 없던 연속 프레임 수
    private var idleFrames = 0
    /// 이만큼(60fps 기준 약 0.5초) 움직임이 없으면 그리기를 멈춤
    private let idleFramesBeforePause = 30

    /// 진행 중인 애니메이션(캐릭터 이동·순간이동, 보석 사라짐)이 없으면 잠시 뒤 그리기를 멈춤
    private func pauseRenderingWhenIdle() {
        let isAnimating = characterNode?.hasActions() == true || itemNodes.values.contains { $0.hasActions() }
            || rebuildCountdown != nil  // 다시 그리기를 기다리는 동안에도 멈추지 않음
        idleFrames = isAnimating ? 0 : idleFrames + 1
        if idleFrames >= idleFramesBeforePause { view?.isPaused = true }
    }

    /// 화면을 바꾸기 직전에 부름 — 멈춰 있던 그리기를 다시 켬 (맵 다시 그리기·판 변화가 모두 여기를 지남)
    private func wakeRendering() {
        idleFrames = 0
        view?.isPaused = false
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
        wakeRendering()
        // 기존 노드 전체 제거 — 맵 노드는 모두 묶음(mapLayer) 안에 있음, 배율도 원래대로
        if mapLayer.parent == nil { addChild(mapLayer) }
        mapLayer.removeAllChildren()
        mapLayer.setScale(1)
        mapLayer.position = .zero
        rebuildCountdown = nil
        builtLayout = nil
        itemNodes = [:]  // 노드 자체는 removeAllChildren으로 이미 제거됨 — 참조만 비움
        gateNodes = [:]
        guard size.width > 0, size.height > 0 else { return }

        let cols = mapData.width
        let rows = mapData.height

        // 타일 레이아웃 수치 (캐릭터 배치와 동일한 값을 쓰도록 단일화)
        let layout = layoutMetrics()
        builtLayout = layout
        builtSize = size
        let tileSize = layout.tileSize
        let cellSize = layout.cellSize
        let originX  = layout.originX
        let originY  = layout.originY
        let cornerRadius = tileSize * MapElementMetrics.tileCorner  // 타일 모서리 반지름 (타일 크기의 22%)

        // MARK: 타일 렌더링 — 경로 + 빈 칸 + 기믹(문/보석/스위치/포탈) 모두 그리기
        for row in 0..<rows {
            for col in 0..<cols {
                let pos = Position(x: col, y: row)

                // 문(게이트) 타일인지 확인 — grid 원본은 항상 벽(0)이고, 열렸으면 바닥처럼 통행 가능
                // (mapData.switches가 nil인 기존 35개 스테이지는 isGateTile이 항상 false라 아래 로직 전부 무해)
                let isGateTile = mapData.switches?.contains(where: { $0.gateAt == pos }) ?? false
                let isOpenGate = isGateTile && board.openedGates.contains(pos)
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
                mapLayer.addChild(tile)

                // 문 표시 마커 — 닫힘: 벽 위에 진한 링 / 열림: 바닥 위에 옅은 링(잔상)
                if isGateTile {
                    let marker = makeGateMarkerNode(size: tileSize, isOpen: isOpenGate)
                    marker.position = CGPoint(x: x, y: y)
                    marker.zPosition = 1
                    mapLayer.addChild(marker)
                    gateNodes[pos] = (tile, marker, isOpenGate)
                }

                // 스위치 — 바닥 위에 눌리는 버튼 표시
                if mapData.switches?.contains(where: { $0.switchAt == pos }) == true {
                    let switchNode = makeSwitchNode(size: tileSize)
                    switchNode.position = CGPoint(x: x, y: y)
                    switchNode.zPosition = 1
                    mapLayer.addChild(switchNode)
                }

                // 보석 — 이미 수집한 위치는 숨긴 채로 만듦(재구성해도 숨김 유지, 리셋 때 다시 보임)
                if mapData.items?.contains(pos) == true {
                    let itemNode = makeItemNode(size: tileSize)
                    itemNode.position = CGPoint(x: x, y: y)
                    itemNode.zPosition = 1
                    itemNode.isHidden = board.collectedItems.contains(pos)
                    mapLayer.addChild(itemNode)
                    itemNodes[pos] = itemNode
                }

                // 포탈 — 양쪽 위치 모두에 표시
                if mapData.portals?.contains(where: { $0.a == pos || $0.b == pos }) == true {
                    let portalNode = makePortalNode(size: tileSize)
                    portalNode.position = CGPoint(x: x, y: y)
                    portalNode.zPosition = 1
                    mapLayer.addChild(portalNode)
                }
            }
        }

        // MARK: 목표 지점 렌더링
        let goalX = originX + CGFloat(mapData.goal.x) * cellSize + tileSize / 2
        let goalY = originY + CGFloat(rows - 1 - mapData.goal.y) * cellSize + tileSize / 2
        let goal  = makeGoalNode(at: CGPoint(x: goalX, y: goalY), tileSize: tileSize)
        mapLayer.addChild(goal)

        // MARK: 캐릭터 렌더링
        let character = makeCharacterNode(tileSize: tileSize, cornerRadius: cornerRadius)
        characterNode = character  // 이동/회전 애니메이션을 위한 참조 저장
        mapLayer.addChild(character)

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
            node.fillColor   = palette.floor
            // 연한 테두리로 바닥 타일 구분 (라이트: 탄색 / 다크: 쿨톤 — updateColorScheme에서 결정)
            node.strokeColor = palette.floorStroke
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
                color: palette.wall,
                topDepth: 0.8,  // 위 뒷면 두께
                botDepth: 3.0,  // 아래 뒷면 두께 (그림자 효과)
                baseZ: 0,
                topColor: palette.wallTop,
                botColor: palette.wallBottom
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
        if let topColor {
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
        if let botColor {
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
        let radius = tileSize * MapElementMetrics.goalRadius
        let circle = SKShapeNode(circleOfRadius: radius)
        circle.fillColor  = goalColor
        circle.strokeColor = .clear
        container.addChild(circle)

        // 하이라이트 (입체감) — 왼쪽 상단에 작은 흰 원으로 광택 표현
        let highlightRadius = radius * MapElementMetrics.goalHighlight
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
        let s = size * MapElementMetrics.gem
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: s))
        path.addLine(to: CGPoint(x: s, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -s))
        path.addLine(to: CGPoint(x: -s, y: 0))
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = .gemMint
        node.strokeColor = .clear
        return node
    }

    /// 스위치 노드 — 주황 원형 버튼
    private func makeSwitchNode(size: CGFloat) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: size * MapElementMetrics.switchRadius)
        node.fillColor = .switchOrange
        node.strokeColor = .clear
        return node
    }

    /// 문(게이트) 표시 마커 — 닫힘: 진한 링(벽 위) / 열림: 옅은 링(바닥 위 잔상)
    private func makeGateMarkerNode(size: CGFloat, isOpen: Bool) -> SKShapeNode {
        let ring = SKShapeNode(circleOfRadius: size * MapElementMetrics.gateRing)
        ring.fillColor = .clear
        ring.strokeColor = SKColor.switchOrange.withAlphaComponent(isOpen ? 0.35 : 0.9)
        ring.lineWidth = isOpen ? 2 : 3
        return ring
    }

    /// 포탈 노드 — 보라 이중 원형
    private func makePortalNode(size: CGFloat) -> SKNode {
        let container = SKNode()
        let outer = SKShapeNode(circleOfRadius: size * MapElementMetrics.portalOuter)
        outer.fillColor = .clear
        outer.strokeColor = .portalPurple
        outer.lineWidth = 3
        let inner = SKShapeNode(circleOfRadius: size * MapElementMetrics.portalInner)
        inner.fillColor = SKColor.portalPurple.withAlphaComponent(0.5)
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
            color: palette.character,
            topDepth: 0.5,
            botDepth: 2.0,
            baseZ: 0,
            topColor: palette.charTopBack,
            botColor: palette.charBottomBack
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
        node.fillColor   = palette.charArrow // 라이트: 크림 #f4ecd7 / 다크: 다크 잉크 (몸체 밝음에 맞춘 반전)
        node.strokeColor = .clear
        return node
    }

    // MARK: - 캐릭터 이동

    /// 현재 characterPosition과 characterDirection에 맞게 캐릭터 노드 위치/각도 업데이트
    /// - Parameter animated: true이면 부드러운 이동 애니메이션 적용
    private func updateCharacterTransform(animated: Bool) {
        // 노드를 만들 때의 배치 기준 (크기가 바뀌는 중이면 묶음 배율이 화면 크기를 맞춰 줌)
        guard let layout = builtLayout else { return }
        let rows = mapData.height

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
        let x = originX + CGFloat(board.position.x) * cellSize + tileSize / 2
        let y = originY + CGFloat(rows - 1 - board.position.y) * cellSize + tileSize / 2
        let targetPos   = CGPoint(x: x, y: y)
        let targetAngle = rotationAngle(for: board.direction)

        if animated {
            // 설정된 실행 속도에 맞춰 애니메이션 시간 조절
            let speed  = animationSpeed
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
        case .up: 0           // 위: 회전 없음 (기본 방향)
        case .left: .pi / 2     // 왼쪽: 90도 반시계
        case .down: .pi         // 아래: 180도
        case .right: -.pi / 2    // 오른쪽: 90도 시계
        }
    }

    // MARK: - 판 변화 그리기 (GameBoardRendering)

    /// VM이 판을 바꿀 때마다 호출 — 새 상태를 저장하고 변화 종류에 맞는 연출로 그림
    func update(board newBoard: GameBoard, event: BoardEvent, speed: Double) {
        wakeRendering()
        let hadGimmickChanges = board.hasGimmickChanges
        board = newBoard
        animationSpeed = speed

        switch event {
        case .moved, .turned:
            updateCharacterTransform(animated: true)
        case .teleported:
            teleportCharacter()
        case .itemCollected(let position):
            removeItemNode(at: position)
        case .gateOpened:
            // 열린 문 칸만 벽→바닥으로 바꿔 그림 (예전엔 맵 전체를 다시 만들었음)
            refreshGates()
        case .reset:
            // 기믹 상태가 있었으면 보석 재등장·문 닫힘을 그 칸만 복원하고, 캐릭터는 부드럽게 시작점으로
            if hadGimmickChanges {
                refreshGates()
                restoreItems()
            }
            updateCharacterTransform(animated: true)
        }
    }

    /// 보석 노드를 사라지는 애니메이션과 함께 숨김 — 리셋 때 다시 보이도록 노드는 남겨 둠
    private func removeItemNode(at position: Position) {
        itemNodes[position]?.run(.sequence([
            .scale(to: 1.4, duration: 0.1),
            .group([.fadeOut(withDuration: 0.15), .scale(to: 0.1, duration: 0.15)]),
            .hide()
        ]))
    }

    /// 아직 안 먹은 상태가 된 보석을 원래 모습으로 되돌림 (리셋)
    private func restoreItems() {
        for (position, node) in itemNodes where !board.collectedItems.contains(position) {
            node.removeAllActions()  // 사라지는 중이던 애니메이션 중단
            node.alpha = 1
            node.setScale(1)
            node.isHidden = false
        }
    }

    /// 열림 상태가 바뀐 문 칸만 타일·링을 새로 만들어 교체
    /// 벽의 3D 아래면이 아래 칸에 살짝 걸치므로, 원래 노드가 있던 순서 자리에 넣어 겹침 순서를 그대로 유지
    private func refreshGates() {
        guard let layout = builtLayout else { return }  // 노드를 만들 때의 배치 기준
        let cornerRadius = layout.tileSize * MapElementMetrics.tileCorner
        for (position, old) in gateNodes {
            let isOpen = board.openedGates.contains(position)
            guard isOpen != old.isOpen else { continue }
            let center = old.marker.position  // 링은 칸 가운데에 있음
            let tile = makeTileNode(at: center, size: layout.tileSize, radius: cornerRadius, isFloor: isOpen)
            let marker = makeGateMarkerNode(size: layout.tileSize, isOpen: isOpen)
            marker.position = center
            marker.zPosition = 1
            replace(old.tile, with: tile)
            replace(old.marker, with: marker)
            gateNodes[position] = (tile, marker, isOpen)
        }
    }

    /// 노드를 같은 순서 자리의 새 노드로 바꿈
    private func replace(_ old: SKNode, with new: SKNode) {
        let index = mapLayer.children.firstIndex(of: old) ?? mapLayer.children.count
        old.removeFromParent()
        mapLayer.insertChild(new, at: index)
    }

    /// 포탈 이동 — 캐릭터를 현재 칸으로 즉시 재배치 (짧은 페이드 효과로 순간이동 느낌)
    private func teleportCharacter() {
        guard let character = characterNode, let layout = builtLayout else { return }

        let rows = mapData.height
        let x = layout.originX + CGFloat(board.position.x) * layout.cellSize + layout.tileSize / 2
        let y = layout.originY + CGFloat(rows - 1 - board.position.y) * layout.cellSize + layout.tileSize / 2

        character.run(.sequence([
            .fadeOut(withDuration: 0.12),
            .move(to: CGPoint(x: x, y: y), duration: 0),
            .fadeIn(withDuration: 0.12)
        ]))
    }
}
