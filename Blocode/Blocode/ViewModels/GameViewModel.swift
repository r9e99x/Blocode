//
//  GameViewModel.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation
import SwiftUI
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
/// 게임 상태, 코드 블럭 목록, 실행 로직을 관리하는 ViewModel
/// View ↔ GameScene 사이의 중간 역할
class GameViewModel: ObservableObject {

    // MARK: - Published 프로퍼티 (View에서 감지)

    /// 현재 게임 상태 — 상태 변경 시 UI 자동 갱신
    @Published var gameState: GameState = .idle

    /// 사용자가 추가한 코드 블럭 목록 (순서대로 실행)
    @Published var codeBlocks: [Block] = []

    /// 현재 실행 중인 블럭 인덱스 (하이라이트용) — nil이면 하이라이트 없음
    @Published var currentBlockIndex: Int? = nil

    /// 실패한 블럭 인덱스 (빨간 하이라이트용) — nil이면 표시 안 함
    @Published var failedBlockIndex: Int? = nil

    /// 실패 이유 메시지 — 토스트 배너에 표시
    @Published var failureMessage: String = ""

    /// 클리어 시 획득한 별 수 — ClearOverlayView에 전달
    @Published var clearedStars: Int = 0

    /// 클리어 시 걸린 시간 (초) — 타이머로 측정
    @Published var elapsedTime: TimeInterval = 0

    /// 도전 횟수 — run() 호출 시마다 증가
    @Published var attemptCount: Int = 0

    /// 캐릭터가 시작 위치에서 벗어났는지 (리셋 버튼 아이콘 결정용)
    @Published var characterMoved: Bool = false

    // MARK: - 내부 상태

    /// 현재 스테이지 데이터 — 별점 기준, 맵 정보 포함
    private(set) var stage: Stage

    /// 스테이지 로딩 실패 여부 — true이면 View가 폴백 UI를 표시
    /// (init에서 한 번만 결정되며 이후 변하지 않음)
    let loadFailed: Bool

    /// GameScene 참조 (캐릭터 이동 명령용) — weak으로 순환 참조 방지
    weak var scene: GameScene?

    /// 실행 속도 배율 — SettingsService에서 실시간으로 읽어옴
    private var executionSpeed: Double { SettingsService.shared.executionSpeed }

    /// 실행 시간 측정 타이머
    private var timer: Timer?
    /// 타이머 시작 시각
    private var startTime: Date?

    // MARK: - 초기화

    /// 스테이지 데이터로 ViewModel 초기화 (프리뷰/테스트용 — 직접 주입)
    init(stage: Stage) {
        self.stage = stage
        self.loadFailed = false
    }

    /// 챕터/스테이지 번호로 ViewModel 초기화 (프로덕션)
    /// 데이터 소스(StageLoader) 접근은 View가 아닌 ViewModel의 책임
    init(chapter: Int, stageNumber: Int) {
        if let loaded = StageLoader.load(chapter: chapter, stage: stageNumber) {
            self.stage = loaded
            self.loadFailed = false
        } else {
            // 로딩 실패 — 타입 불변식(비옵셔널 Stage) 유지를 위한 안전 플레이스홀더
            // (실제로는 View가 loadFailed를 보고 폴백 UI를 띄우므로 사용되지 않음)
            self.stage = Stage.placeholder(chapter: chapter, stageNumber: stageNumber)
            self.loadFailed = true
        }
    }

    /// 다음 스테이지 존재 여부 — 챕터 마지막 스테이지이면 false
    /// (데이터 접근은 StageLoader(Service)에 위임)
    var hasNextStage: Bool {
        StageLoader.load(chapter: stage.chapter, stage: stage.stageNumber + 1) != nil
    }

    // MARK: - 블럭 관리

    /// 팔레트에서 블럭 추가 — idle 상태일 때만 허용
    func addBlock(_ type: BlockType) {
        guard gameState == .idle else { return }
        let block = Block(type: type)
        codeBlocks.append(block)
    }

    /// 특정 인덱스의 블럭 삭제 — idle 상태이고 유효한 인덱스일 때만 허용
    func removeBlock(at index: Int) {
        guard gameState == .idle,
              codeBlocks.indices.contains(index) else { return }
        codeBlocks.remove(at: index)
    }

    /// 블럭 순서 변경 (드래그 앤 드롭) — idle 상태일 때만 허용
    func moveBlock(from source: IndexSet, to destination: Int) {
        guard gameState == .idle else { return }
        codeBlocks.move(fromOffsets: source, toOffset: destination)
    }

    /// repeat 블럭의 자식 블럭 추가 — 해당 인덱스가 repeat 블럭일 때만 동작
    func addChildBlock(_ type: BlockType, to parentIndex: Int) {
        guard gameState == .idle,
              codeBlocks.indices.contains(parentIndex),
              codeBlocks[parentIndex].isRepeatBlock else { return }
        let child = Block(type: type)
        codeBlocks[parentIndex].children?.append(child)
    }

    /// repeat 블럭의 자식 블럭 삭제
    func removeChildBlock(at childIndex: Int, from parentIndex: Int) {
        guard gameState == .idle,
              codeBlocks.indices.contains(parentIndex),
              codeBlocks[parentIndex].isRepeatBlock,
              let children = codeBlocks[parentIndex].children,
              children.indices.contains(childIndex) else { return }
        codeBlocks[parentIndex].children?.remove(at: childIndex)
    }

    /// 특정 위치에 블럭 삽입 (팔레트 드래그-앤-드롭 위치 지정 삽입)
    func insertBlock(_ type: BlockType, at index: Int) {
        guard gameState == .idle else { return }
        let block = Block(type: type)
        // 인덱스가 범위를 벗어나지 않도록 클램핑
        let safeIndex = min(max(0, index), codeBlocks.count)
        codeBlocks.insert(block, at: safeIndex)
    }

    /// repeat 블럭의 반복 횟수 변경 (최소 1회 보장)
    func setRepeatCount(_ count: Int, at index: Int) {
        guard codeBlocks.indices.contains(index),
              codeBlocks[index].isRepeatBlock else { return }
        codeBlocks[index].repeatCount = max(1, count)  // 최소 1회
    }

    /// 현재 사용된 총 블럭 수 (별점 계산용) — flatCount로 repeat 내부 블럭 포함
    var totalBlockCount: Int {
        codeBlocks.reduce(0) { $0 + $1.flatCount }
    }

    // MARK: - 실행 제어

    /// 코드 블럭 실행 시작 — idle 상태이고 블럭이 있을 때만 동작
    func run() {
        guard gameState == .idle, !codeBlocks.isEmpty else { return }

        gameState = .running
        failedBlockIndex = nil
        failureMessage = ""
        characterMoved = true   // 실행 시작 = 캐릭터 이동 시작
        attemptCount += 1       // 도전 횟수 증가
        startTimer()            // 클리어 시간 측정 시작

        // 블럭 순서대로 비동기 실행 → 완료 시 idle 복귀
        Task {
            await executeBlocks(codeBlocks, startIndex: 0)
            // 성공/실패 처리가 안 됐으면 (목표 미도달로 자연 종료) idle로 복귀
            await MainActor.run {
                if gameState == .running {
                    gameState = .idle
                    currentBlockIndex = nil
                    stopTimer()
                }
            }
        }
    }

    /// 실행 중단 (■ 버튼) — running 상태일 때만 동작
    func stop() {
        guard gameState == .running else { return }
        gameState = .idle
        stopTimer()
        scene?.resetCharacter()  // 캐릭터를 시작 위치로 되돌림
        currentBlockIndex = nil
    }

    /// 캐릭터만 리셋 — 블럭 목록은 유지
    func reset() {
        gameState = .idle
        stopTimer()
        currentBlockIndex = nil
        failedBlockIndex = nil
        failureMessage = ""
        characterMoved = false
        scene?.resetCharacter()  // 캐릭터를 시작 위치로 되돌림
    }

    /// 전체 초기화 — 캐릭터 + 블럭 + 도전 횟수 모두 삭제
    func fullReset() {
        reset()
        codeBlocks = []    // 블럭 목록 초기화
        attemptCount = 0   // 도전 횟수 초기화
    }

    // MARK: - 블럭 실행 로직

    /// 블럭 배열을 순서대로 실행 (재귀 지원 — repeat 블럭 처리)
    /// - Parameters:
    ///   - blocks: 실행할 블럭 배열
    ///   - startIndex: 글로벌 인덱스 오프셋 (하이라이트 계산용)
    private func executeBlocks(_ blocks: [Block], startIndex: Int) async {
        for (offset, block) in blocks.enumerated() {

            // 실행 중단됐으면 멈춤 (stop() 호출 등)
            guard await isRunning() else { return }

            // 전체 블럭 목록에서의 절대 인덱스 (하이라이트용)
            let globalIndex = startIndex + offset

            // 현재 실행 중인 블럭 하이라이트 갱신
            await updateCurrentIndex(globalIndex)

            // 블럭 종류에 따라 실행
            switch block.type {
            case .moveForward:
                // 앞으로 이동 — 실패 시 실패 처리 후 종료
                let success = await moveCharacter(direction: .forward)
                if !success {
                    await handleFailure(at: globalIndex, message: "벽에 부딪혔어요 · 라인 \(globalIndex + 1)")
                    return
                }

            case .moveBackward:
                // 뒤로 이동 — 실패 시 실패 처리 후 종료
                let success = await moveCharacter(direction: .backward)
                if !success {
                    await handleFailure(at: globalIndex, message: "벽에 부딪혔어요 · 라인 \(globalIndex + 1)")
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
                    guard await isRunning() else { return }
                    // 자식 블럭을 재귀적으로 실행 (startIndex는 부모 인덱스 + 1)
                    await executeBlocks(children, startIndex: globalIndex + 1)
                }
            }

            // 각 블럭 실행 후 목표 도달 여부 확인
            if await checkGoal() {
                await handleSuccess()
                return
            }
        }
    }

    // MARK: - 캐릭터 이동 (GameScene에 명령)

    /// 앞으로/뒤로 이동 — 성공 여부 반환 (벽이면 false)
    private func moveCharacter(direction: MoveDirection) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let scene = self.scene else {
                    continuation.resume(returning: false)
                    return
                }

                // 이동 방향에 따라 다음 위치 계산
                let nextPos: Position
                switch direction {
                case .forward:
                    // 캐릭터가 바라보는 방향으로 한 칸 이동
                    nextPos = scene.characterPosition.next(direction: scene.characterDirection)
                case .backward:
                    // 캐릭터가 바라보는 방향의 반대 방향으로 한 칸 이동
                    nextPos = scene.characterPosition.previous(direction: scene.characterDirection)
                }

                // 이동 가능 여부 확인 (맵 범위 & 바닥 타일)
                guard scene.mapData.isFloor(nextPos) else {
                    continuation.resume(returning: false)  // 벽: 이동 실패
                    return
                }

                // 캐릭터 위치 업데이트 및 애니메이션 적용
                scene.characterPosition = nextPos
                scene.updateCharacterTransform(animated: true)

                // 이동 애니메이션 완료 후 다음 블럭 실행 (속도 배율 적용)
                let delay = 0.3 / self.executionSpeed
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    continuation.resume(returning: true)  // 이동 성공
                }
            }
        }
    }

    /// 캐릭터 좌우 회전 — 애니메이션 완료 후 continuation 재개
    private func turnCharacter(left: Bool) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                guard let scene = self?.scene else {
                    continuation.resume()
                    return
                }
                // 방향 값 갱신 (왼쪽/오른쪽 90도 회전)
                scene.characterDirection = left
                    ? scene.characterDirection.turnedLeft
                    : scene.characterDirection.turnedRight
                // 회전 애니메이션 적용
                scene.updateCharacterTransform(animated: true)

                // 회전 애니메이션 완료 후 다음 블럭 실행 (속도 배율 적용)
                let delay = 0.2 / (self?.executionSpeed ?? 1.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - 결과 처리

    /// 현재 캐릭터 위치가 목표 지점인지 확인
    private func checkGoal() async -> Bool {
        return await MainActor.run {
            // scene이 없으면 false (클리어 불가)
            scene?.mapData.isGoal(scene?.characterPosition ?? Position(x: -1, y: -1)) ?? false
        }
    }

    /// 클리어 성공 처리 — 별점 계산 후 ProgressService에 기록 저장
    private func handleSuccess() async {
        await MainActor.run {
            stopTimer()
            // 사용한 블럭 수 기준으로 별점 계산
            let stars = stage.starThresholds.stars(for: totalBlockCount)
            clearedStars = stars
            currentBlockIndex = nil
            gameState = .success

            // ProgressService에 클리어 기록 저장 (더 좋은 기록이면 갱신)
            ProgressService.shared.recordClear(
                stageId: stage.id,
                stars: stars,
                blockCount: totalBlockCount
            )
        }
    }

    /// 실패 처리 (벽 충돌 등) — 실패 블럭 인덱스와 메시지 설정
    private func handleFailure(at index: Int, message: String) async {
        await MainActor.run {
            stopTimer()
            failedBlockIndex = index  // 실패한 블럭 빨간 하이라이트
            failureMessage = message  // 토스트 배너 메시지
            gameState = .failure
        }
    }

    // MARK: - 헬퍼

    /// 게임이 현재 running 상태인지 확인 (MainActor에서 실행)
    private func isRunning() async -> Bool {
        await MainActor.run { gameState == .running }
    }

    /// 현재 실행 중인 블럭 인덱스 갱신 (MainActor에서 실행)
    private func updateCurrentIndex(_ index: Int) async {
        await MainActor.run { currentBlockIndex = index }
    }

    // MARK: - 타이머

    /// 클리어 시간 측정 타이머 시작 (0.1초 간격으로 elapsedTime 갱신)
    private func startTimer() {
        startTime = Date()
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
    }

    /// 타이머 중지 — 타이머 인스턴스 무효화 및 nil 처리
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - MoveDirection (내부용)
/// 이동 방향 — 앞으로/뒤로만 구분 (회전은 별도 처리)
private enum MoveDirection {
    case forward   // 캐릭터가 바라보는 방향으로 이동
    case backward  // 캐릭터가 바라보는 반대 방향으로 이동
}
