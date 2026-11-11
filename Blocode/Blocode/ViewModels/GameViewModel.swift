//
//  GameViewModel.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation
import Combine

// MARK: - GameState
/// 게임의 현재 상태 — 뷰에서 상태에 따라 UI 분기 처리
enum GameState {
    case idle       // 대기 중 (블럭 편집 가능)
    case running    // 실행 중 (블럭 순서대로 캐릭터 이동 중)
    case success    // 클리어 성공
    case failure    // 실패 (벽 충돌 등)
}

// MARK: - GameViewModel
/// 게임 상태, 코드 블럭 목록, 실행 흐름을 관리하는 ViewModel
/// 판의 규칙은 GameBoard(Model)가, 그리기는 GameBoardRendering을 구현한 화면이 맡음
/// @MainActor: 모든 상태·실행 로직이 항상 메인 스레드에서만 처리됨을 보장
/// (수동 MainActor.run/DispatchQueue 디스패치 없이 @Published 접근이 안전해짐)
@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published 프로퍼티 (View에서 감지)

    /// 현재 게임 상태 — 상태 변경 시 UI 자동 갱신
    @Published private(set) var gameState: GameState = .idle

    /// 사용자가 추가한 코드 블럭 목록 (순서대로 실행)
    /// 쓰기를 열어 둔 이유: 테스트와 프리뷰가 초기 블럭을 넣는 데 사용 (화면은 편집 함수로만 변경)
    @Published var codeBlocks: [Block] = []

    /// 현재 실행 중인 블럭 경로 (하이라이트용) — nil이면 하이라이트 없음
    /// 경로 형식: [최상위 인덱스], [최상위, 자식], [최상위, 자식, 손자]
    /// (단일 Int는 중첩 블럭 실행 시 최상위 인덱스 공간과 충돌하므로 경로로 추적)
    @Published private(set) var currentBlockPath: [Int]? = nil

    /// 실패한 블럭 경로 (빨간 하이라이트용) — nil이면 표시 안 함 (형식은 currentBlockPath와 동일)
    @Published private(set) var failedBlockPath: [Int]? = nil

    /// 실패 이유 메시지 — 토스트 배너에 표시
    @Published private(set) var failureMessage: String = ""

    /// 클리어 시 획득한 별 수 — ClearOverlayView에 전달
    @Published private(set) var clearedStars: Int = 0

    /// 클리어 시 걸린 시간 (초) — 스테이지 진입(또는 재도전)부터 클리어까지, 클리어 순간에 한 번 계산
    @Published private(set) var elapsedTime: TimeInterval = 0

    /// 도전 횟수 — run() 호출 시마다 증가
    @Published private(set) var attemptCount: Int = 0

    /// 캐릭터가 시작 위치에서 벗어났는지 (리셋 버튼 아이콘 결정용)
    @Published private(set) var characterMoved: Bool = false

    /// 게임 판 상태의 원본 — 캐릭터 위치·방향, 모은 보석, 열린 문
    @Published private(set) var board: GameBoard

    /// 수집한 보석 위치 집합 — 상단바 보석 카운터 표시 + 별점 계산에 사용
    /// (기믹 없는 스테이지는 항상 빈 상태로 아무 영향 없음)
    var collectedItems: Set<Position> { board.collectedItems }

    // MARK: - 내부 상태

    /// 현재 스테이지 데이터 — 별점 기준, 맵 정보 포함
    private(set) var stage: Stage

    /// 스테이지 로딩 실패 여부 — true이면 View가 폴백 UI를 표시
    /// (init에서 한 번만 결정되며 이후 변하지 않음)
    let loadFailed: Bool

    /// 판을 그리는 화면 — 변화만 알리고 구체 타입은 모름, 없어도 규칙은 정상 동작 (순환 참조 방지로 weak)
    weak var renderer: GameBoardRendering?

    /// 클리어 기록 저장소 — 테스트는 메모리 저장소를 주입
    private let progress: ProgressService

    /// 실행 속도를 읽는 함수 — 기본은 설정값을 실시간으로 읽고, 테스트는 고정값을 주입
    private let executionSpeedProvider: () -> Double

    /// 진행 중인 실행 Task — reset()에서 취소해 이전 실행이 새 실행과 겹치지 않게 함
    private var runTask: Task<Void, Never>?

    /// 이 Task의 실행이 아직 유효한지 — 상태만 보면 리셋 후 재실행 때 이전 실행도 running으로 착각함
    private var isRunActive: Bool { gameState == .running && !Task.isCancelled }

    /// 실행 속도 배율
    private var executionSpeed: Double { executionSpeedProvider() }

    /// 걸린 시간 측정 시작 시각 — VM 생성(스테이지 화면 진입) 시 기록, retry()/fullReset()에서 다시 기록
    /// (생각하는 시간까지 포함해야 "걸린 시간"이라는 이름과 맞음 — 실행 시간만 재던 기존 방식 수정)
    private var startTime = Date()

    // MARK: - 초기화

    /// 스테이지 데이터로 ViewModel 초기화 (프리뷰/테스트용 — 직접 주입)
    init(stage: Stage,
         progress: ProgressService = .shared,
         executionSpeed: @escaping () -> Double = { SettingsService.shared.executionSpeed }) {
        self.stage = stage
        self.board = GameBoard(map: stage.mapData)
        self.loadFailed = false
        self.progress = progress
        self.executionSpeedProvider = executionSpeed
    }

    /// 챕터/스테이지 번호로 ViewModel 초기화 (프로덕션)
    /// 데이터 소스(StageLoader) 접근은 View가 아닌 ViewModel의 책임
    init(chapter: Int, stageNumber: Int) {
        self.progress = .shared
        self.executionSpeedProvider = { SettingsService.shared.executionSpeed }
        // 로딩 실패 시 플레이스홀더로 타입 불변식(비옵셔널 Stage) 유지
        // (실제로는 View가 loadFailed를 보고 폴백 UI를 띄우므로 사용되지 않음)
        let loaded = StageLoader.load(chapter: chapter, stage: stageNumber)
        let stage = loaded ?? Stage.placeholder(chapter: chapter, stageNumber: stageNumber)
        self.stage = stage
        self.board = GameBoard(map: stage.mapData)
        self.loadFailed = loaded == nil
    }

    /// 다음 스테이지 번호 — 챕터 마지막 스테이지이면 nil
    /// (ChapterCatalog의 스테이지 수로 판단 — 예전엔 화면을 그릴 때마다 다음 스테이지 JSON을 읽어 디코딩했음)
    var nextStageNumber: Int? {
        let next = stage.stageNumber + 1
        return next <= (ChapterCatalog.chapter(stage.chapter)?.stageCount ?? 0) ? next : nil
    }

    /// 블럭을 편집할 수 있는 상태인지 — 대기 중에만 가능
    var canEdit: Bool { gameState == .idle }

    // MARK: - 실행·실패 하이라이트 (코드 리스트 행 기준)

    /// 이 행이 실행 중인지 — 자식·손자가 실행 중이어도 부모 행 강조 유지
    func isRowActive(_ row: Int) -> Bool {
        gameState == .running && currentBlockPath?.first == row
    }

    /// 이 행(또는 그 안의 블럭)이 실패했는지
    func isRowFailed(_ row: Int) -> Bool {
        failedBlockPath?.first == row
    }

    /// 이 행 안에서 실행 중인 자식의 상대 경로 — 다른 행이 실행 중이면 빈 배열
    func activeChildPath(inRow row: Int) -> [Int] {
        isRowActive(row) ? Array((currentBlockPath ?? []).dropFirst()) : []
    }

    /// 이 행 안에서 실패한 자식의 상대 경로 — 다른 행이 실패했으면 빈 배열
    func failedChildPath(inRow row: Int) -> [Int] {
        isRowFailed(row) ? Array((failedBlockPath ?? []).dropFirst()) : []
    }

    // MARK: - 블럭 관리

    /// 이 스테이지 팔레트에 있는 블럭인지 — 중첩 미니 팔레트를 포함해 어떤 경로로도 허용 밖 블럭이 추가되지 않게 막음
    /// (예: 2챕터 반복 블럭 안에 "만약에"를 넣어 3챕터 벽따라가기 기법으로 별을 쉽게 얻던 문제 차단)
    private func isAllowed(_ type: BlockType) -> Bool {
        stage.paletteBlocks.contains(type)
    }

    /// 팔레트에서 블럭 추가 — idle 상태일 때만 허용
    func addBlock(_ type: BlockType) {
        guard canEdit, isAllowed(type) else { return }
        let block = Block(type: type)
        codeBlocks.append(block)
        SoundService.shared.play(.blockAdd)
    }

    /// 블럭 순서 변경 (드래그 앤 드롭) — idle 상태이고 유효한 위치일 때만 허용
    /// destination은 옮기기 전 배열 기준의 삽입 위치 (0...count)
    func moveBlock(from source: Int, to destination: Int) {
        guard canEdit, codeBlocks.moveBlock(from: source, to: destination) else { return }
        SoundService.shared.play(.blockReorder)
    }

    // MARK: - 경로 기반 블럭 편집
    // 트리 규칙은 Model(Block.swift)이 담당 — VM은 실행 중 편집 차단과 스테이지 팔레트 전달만 맡음

    /// 경로에 있는 블럭 — 경로가 잘못됐으면 nil
    func block(at path: [Int]) -> Block? {
        codeBlocks.block(at: path)
    }

    /// 경로의 컨테이너에 넣을 수 있는 블럭
    func allowedChildTypes(at path: [Int]) -> [BlockType] {
        codeBlocks.allowedChildTypes(at: path, palette: stage.paletteBlocks)
    }

    /// 경로의 컨테이너에 자식 블럭 추가 — 허용되지 않는 블럭은 무시
    func addChildBlock(_ type: BlockType, at path: [Int]) {
        guard canEdit else { return }
        codeBlocks.addChild(type, at: path, palette: stage.paletteBlocks)
    }

    /// 경로의 블럭 삭제 (최상위·중첩 공용)
    func removeBlock(at path: [Int]) {
        guard canEdit else { return }
        codeBlocks.removeBlock(at: path)
    }

    /// 경로의 if 블럭 조건 변경
    func setIfCondition(_ condition: IfCondition, at path: [Int]) {
        guard canEdit else { return }
        codeBlocks.setIfCondition(condition, at: path)
    }

    /// 경로의 repeat 블럭 반복 횟수 변경 (1~10회로 제한)
    func setRepeatCount(_ count: Int, at path: [Int]) {
        guard canEdit else { return }
        codeBlocks.setRepeatCount(count, at: path)
    }

    /// 특정 위치에 블럭 삽입 (팔레트 드래그-앤-드롭 위치 지정 삽입)
    func insertBlock(_ type: BlockType, at index: Int) {
        guard canEdit, isAllowed(type) else { return }
        let block = Block(type: type)
        // 인덱스가 범위를 벗어나지 않도록 클램핑
        let safeIndex = min(max(0, index), codeBlocks.count)
        codeBlocks.insert(block, at: safeIndex)
        SoundService.shared.play(.blockAdd)
    }

    /// 현재 사용된 총 블럭 수 (별점 계산용) — flatCount로 repeat 내부 블럭 포함
    var totalBlockCount: Int {
        codeBlocks.reduce(0) { $0 + $1.flatCount }
    }

    // MARK: - 실행 제어

    /// 실행 버튼을 누를 수 있는 상태인지 — 버튼 색상과 터치 허용 판단에 사용
    var canPressRun: Bool {
        !codeBlocks.isEmpty && gameState != .running
    }

    /// 되돌리기 버튼 동작 — 캐릭터가 움직였으면 위치만 되돌리고, 아니면 블럭까지 전체 초기화
    func resetOrClear() {
        if characterMoved { reset() } else { fullReset() }
    }

    /// 코드 블럭 실행 시작 — idle 상태이고 블럭이 있을 때만 동작
    func run() {
        guard gameState == .idle, !codeBlocks.isEmpty else { return }

        gameState = .running
        failedBlockPath = nil
        failureMessage = ""
        characterMoved = true   // 실행 시작 = 캐릭터 이동 시작
        attemptCount += 1       // 도전 횟수 증가

        // 블럭 순서대로 비동기 실행 → 완료 시 idle 복귀
        // (@MainActor 클래스라 Task도 메인에서 실행됨)
        runTask = Task {
            await executeBlocks(codeBlocks, parentPath: [])
            // 성공/실패 처리가 안 됐으면 (목표 미도달로 자연 종료) idle로 복귀
            if isRunActive {
                gameState = .idle
                currentBlockPath = nil
            }
        }
    }

    /// 캐릭터만 리셋 — 블럭 목록은 유지
    func reset() {
        runTask?.cancel()
        gameState = .idle
        currentBlockPath = nil
        failedBlockPath = nil
        failureMessage = ""
        characterMoved = false
        // 캐릭터·보석·문을 시작 상태로 되돌림 (기믹 스테이지는 화면이 보석 재등장·문 다시 닫힘까지 함께 그림)
        board.reset()
        render(.reset)
    }

    /// 전체 초기화 — 캐릭터 + 블럭 + 도전 횟수 모두 삭제
    func fullReset() {
        reset()
        codeBlocks = []    // 블럭 목록 초기화
        attemptCount = 0   // 도전 횟수 초기화
        startTime = Date() // 걸린 시간도 처음부터 다시 측정
    }

    /// 클리어 화면 "다시 도전" — 블럭은 유지한 채 캐릭터·도전 횟수·걸린 시간만 새 판으로 초기화
    /// (reset()만 쓰면 도전 횟수·시간이 이전 판에서 이어져 다음 클리어 화면의 TRIES/TIME이 부풀어짐)
    func retry() {
        reset()
        attemptCount = 0
        startTime = Date()
    }

    // MARK: - 블럭 실행 로직

    /// 블럭 배열을 순서대로 실행 (재귀 지원 — 컨테이너 블럭 처리)
    /// - Parameters:
    ///   - blocks: 실행할 블럭 배열
    ///   - parentPath: 부모 컨테이너까지의 경로 (최상위 호출은 빈 배열) — 하이라이트 경로 계산용
    private func executeBlocks(_ blocks: [Block], parentPath: [Int]) async {
        for (offset, block) in blocks.enumerated() {

            // 실행 중단됐으면 멈춤 (reset() 호출 등)
            guard isRunActive else { return }

            // 현재 블럭의 경로 — 부모 경로에 자신의 인덱스를 추가
            // (최상위 인덱스 공간과 충돌하지 않는 경로 기반 식별)
            let path = parentPath + [offset]

            // 현재 실행 중인 블럭 하이라이트 갱신 (경로 기반)
            currentBlockPath = path

            // 블럭 종류에 따라 실행
            switch block.type {
            case .moveForward:
                // 앞으로 이동 — 실패 시 실패 처리 후 종료
                let success = await moveCharacter(.forward)
                if !success {
                    // 라인 번호는 사용자에게 보이는 최상위 행 번호(1-based) 기준
                    handleFailure(at: path, message: "벽에 부딪혔어요 · 라인 \(path[0] + 1)")
                    return
                }

            case .moveBackward:
                // 뒤로 이동 — 실패 시 실패 처리 후 종료
                let success = await moveCharacter(.backward)
                if !success {
                    // 라인 번호는 사용자에게 보이는 최상위 행 번호(1-based) 기준
                    handleFailure(at: path, message: "벽에 부딪혔어요 · 라인 \(path[0] + 1)")
                    return
                }

            case .turnLeft:
                // 왼쪽으로 90도 회전
                await turnCharacter(left: true)

            case .turnRight:
                // 오른쪽으로 90도 회전
                await turnCharacter(left: false)

            case .repeatBlock:
                // repeat 블럭: 자식 블럭들을 repeatCount번 반복 실행
                let count = block.repeatCount ?? 1
                let children = block.children ?? []
                for _ in 0..<count {
                    guard isRunActive else { return }
                    // 자식 블럭을 재귀적으로 실행 (자신의 경로를 부모 경로로 전달)
                    await executeBlocks(children, parentPath: path)
                }

            case .ifBlock:
                // if 블럭: 앞 칸 상태를 확인하고 조건이 참이면 자식 블럭 실행
                let condition = block.ifCondition ?? .pathClear
                if board.satisfies(condition) {
                    let children = block.children ?? []
                    await executeBlocks(children, parentPath: path)
                }

            case .functionBlock:
                // function 블럭: 자식 블럭들을 서브루틴으로 한 번 실행 (블럭 수 계산에서는 자식만 셈 — 묶음 역할)
                let children = block.children ?? []
                await executeBlocks(children, parentPath: path)

            case .collectItem:
                // 보석 획득 — 현재 칸에 아직 안 모은 보석이 있을 때만 성공, 아니면 벽 부딪힘과 동일하게 실패
                if !collectItemAtCurrentPosition() {
                    handleFailure(at: path, message: "여기엔 보석이 없어요 · 라인 \(path[0] + 1)")
                    return
                }

            case .activateSwitch:
                // 스위치 작동 — 현재 칸에 스위치가 있을 때만 성공, 아니면 벽 부딪힘과 동일하게 실패
                if !activateSwitchAtCurrentPosition() {
                    handleFailure(at: path, message: "여기엔 스위치가 없어요 · 라인 \(path[0] + 1)")
                    return
                }
            }

            // 각 블럭 실행 후 목표 도달 여부 확인
            // 자식 재귀 안에서 이미 성공/실패 처리가 끝났으면 중복 처리하지 않도록 running일 때만 검사
            // (중첩 클리어 시 handleSuccess가 깊이만큼 반복 호출돼 recordClear가 중복 저장되던 문제 수정)
            guard isRunActive else { return }
            if board.isAtGoal {
                handleSuccess()
                return
            }
        }
    }

    // MARK: - 팔레트 블럭 목록

    /// 현재 스테이지 팔레트에 표시할 블럭 타입 목록
    /// Stage.paletteBlocks를 래핑 — CodePanelView/PaletteView에서 사용
    var availableBlocks: [BlockType] {
        stage.paletteBlocks
    }

    // MARK: - 기믹 표시용 (StageView 상단바 보석 카운터 / ClearOverlayView 안내 문구)

    /// 보석을 다 못 모아서 별 3개를 놓쳤을 때만 안내 문구 반환 (기믹 없는 스테이지·전부 수집 시 nil)
    var itemHint: String? {
        guard let items = stage.mapData.items, !items.isEmpty,
              collectedItems.count < items.count else { return nil }
        return "보석 \(collectedItems.count)/\(items.count)개 — 전부 모으면 별 3개!"
    }

    // MARK: - 판 변경 (규칙은 GameBoard, 그리기는 renderer)

    /// 현재 판 상태를 화면에 알림
    private func render(_ event: BoardEvent) {
        renderer?.update(board: board, event: event, speed: executionSpeed)
    }

    /// 애니메이션이 끝날 때까지 대기 (속도 배율 적용) — 리셋으로 실행이 취소되면 바로 깨어남
    private func waitForAnimation(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds / executionSpeed))
    }

    /// 앞으로/뒤로 이동 — 성공 여부 반환 (벽이면 false)
    private func moveCharacter(_ direction: GameBoard.MoveDirection) async -> Bool {
        guard board.move(direction) else { return false }
        render(.moved)
        await waitForAnimation(0.3)
        // 도착 칸의 포탈 — 대기 중 리셋됐으면 적용하지 않음 (리셋 직후 순간이동 방지)
        if isRunActive, board.enterPortal() != nil {
            render(.teleported)
            SoundService.shared.play(.portal)
        }
        return true
    }

    /// 캐릭터 좌우 회전
    private func turnCharacter(left: Bool) async {
        board.turn(left: left)
        render(.turned)
        await waitForAnimation(0.2)
    }

    /// "보석 획득" 블럭 실행 — 현재 칸에 아직 안 모은 보석이 있을 때만 성공
    private func collectItemAtCurrentPosition() -> Bool {
        guard board.collectItem() else { return false }
        render(.itemCollected(board.position))
        SoundService.shared.play(.itemCollect)
        return true
    }

    /// "스위치 작동" 블럭 실행 — 현재 칸에 스위치가 있을 때만 성공, 이미 열린 문이면 소리만 남 (무해한 재작동)
    private func activateSwitchAtCurrentPosition() -> Bool {
        switch board.activateSwitch() {
        case .noSwitch:
            return false
        case .alreadyOpen:
            break
        case .opened:
            render(.gateOpened)
        }
        SoundService.shared.play(.switchActivate)
        return true
    }

    // MARK: - 결과 처리

    /// 클리어 성공 처리 — 별점 계산 후 ProgressService에 기록 저장 (@MainActor라 동기 처리)
    private func handleSuccess() {
        // 걸린 시간 확정 — 스테이지 진입(또는 재도전)부터 지금까지
        elapsedTime = Date().timeIntervalSince(startTime)
        // 사용한 블럭 수 기준으로 별점 계산
        var stars = stage.starThresholds.stars(for: totalBlockCount)
        // 보석이 있는 스테이지인데 전부 수집하지 못했으면 별 3개는 주지 않음 (최대 2개)
        // (기믹 없는 스테이지는 items가 nil이라 이 분기 자체가 실행 안 됨 — 기존 계산과 완전히 동일)
        if let items = stage.mapData.items, !items.isEmpty, collectedItems.count < items.count {
            stars = min(stars, 2)
        }
        clearedStars = stars
        currentBlockPath = nil
        gameState = .success
        SoundService.shared.play(stars == 3 ? .clearThreeStar : .clearLowStar)

        // 클리어 기록 저장 (더 좋은 기록이면 갱신) — 사용자 맵은 별·진행도·연속 기록에 남기지 않음
        if !stage.isCustomMap {
            progress.recordClear(
                stageId: stage.id,
                stars: stars,
                blockCount: totalBlockCount
            )
        }
    }

    /// 실패 처리 (벽 충돌 등) — 실패 블럭 경로와 메시지 설정 (@MainActor라 동기 처리)
    private func handleFailure(at path: [Int], message: String) {
        // await(이동 애니메이션 대기) 사이에 reset·화면 이탈로 실행이 끝났으면 실패로 처리하지 않음
        guard isRunActive else { return }
        failedBlockPath = path    // 실패한 블럭 빨간 하이라이트 (경로 기반)
        failureMessage = message  // 토스트 배너 메시지
        gameState = .failure
        SoundService.shared.play(.gameFail)
    }
}
