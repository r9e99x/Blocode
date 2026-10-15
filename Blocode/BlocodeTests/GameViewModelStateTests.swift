//
//  GameViewModelStateTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 10/15/26.
//
//  재도전(retry) · 걸린 시간 · 실행 중 리셋 등 실행 전후 상태 검증.
//  주의: 클리어 시 handleSuccess()가 실제 ProgressService.shared에 기록을 남기므로
//  GameViewModelExecutionTests와 동일하게 "unittest_" 접두사 가짜 id만 사용한다.

import Testing
import Foundation
@testable import Blocode

@MainActor
@Suite("GameViewModel 상태 — 재도전·시간·중단")
struct GameViewModelStateTests {

    /// 3x3 세로 통로: (1,2)에서 위로 두 칸 가면 (1,0) 골인
    private func makeFixture() -> (viewModel: GameViewModel, scene: GameScene) {
        let mapData = MapData(grid: [[0, 1, 0], [0, 1, 0], [0, 1, 0]],
                              start: Position(x: 1, y: 2), startDirection: .up, goal: Position(x: 1, y: 0))
        let stage = Stage(id: "unittest_\(UUID().uuidString)", chapter: 0, stageNumber: 0,
                          name: "State Test", mapData: mapData,
                          starThresholds: StarThresholds(threeStar: 99, twoStar: 99))
        let viewModel = GameViewModel(stage: stage)
        let scene = GameScene(mapData: mapData)
        scene.size = CGSize(width: 400, height: 400)  // size가 0이면 캐릭터 노드가 안 만들어짐
        scene.setupMap()
        viewModel.scene = scene  // weak 참조 — 호출부가 scene을 테스트 끝까지 붙잡아야 함
        return (viewModel, scene)
    }

    private func waitUntilFinished(_ viewModel: GameViewModel, timeout: TimeInterval = 5) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while viewModel.gameState == .running {
            if Date() > deadline {
                Issue.record("실행이 \(timeout)초 안에 끝나지 않음")
                return
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    @Test("retry()는 블럭을 유지하고 도전 횟수만 새로 시작 (B2)")
    func retry_keepsBlocks_resetsAttempts() async throws {
        let (vm, scene) = makeFixture()
        vm.codeBlocks = [Block(type: .moveForward), Block(type: .moveForward)]
        vm.run()
        try await waitUntilFinished(vm)
        #expect(vm.gameState == .success)
        #expect(vm.attemptCount == 1)

        vm.retry()
        #expect(vm.gameState == .idle)
        #expect(vm.codeBlocks.count == 2)  // 예전엔 fullReset()이라 블럭이 전부 지워졌음
        #expect(vm.attemptCount == 0)
        #expect(scene.characterPosition == Position(x: 1, y: 2))
    }

    @Test("걸린 시간은 실행 시간이 아니라 화면 진입부터 잼 (B3)")
    func elapsedTime_countsFromStageEntry() async throws {
        let (vm, scene) = makeFixture()
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1초 동안 "고민"
        vm.codeBlocks = [Block(type: .moveForward), Block(type: .moveForward)]
        vm.run()  // 실행 자체는 약 0.6초
        try await waitUntilFinished(vm)
        #expect(vm.gameState == .success)
        #expect(vm.elapsedTime >= 1.0)  // 예전 방식이면 실행 시간(약 0.6초)만 나왔음
        _ = scene
    }

    @Test("실행 중 리셋하면 실패로 바뀌지 않고 멈춤 (B8 — 화면 이탈 시 onDisappear가 하는 일)")
    func resetWhileRunning_doesNotFail() async throws {
        let (vm, _) = makeFixture()
        vm.codeBlocks = [Block(type: .moveForward), Block(type: .moveForward)]
        vm.run()
        try await Task.sleep(nanoseconds: 100_000_000)  // 첫 이동 애니메이션 도중
        vm.reset()
        vm.scene = nil  // 화면이 사라지며 씬도 해제되는 상황 재현
        try await Task.sleep(nanoseconds: 800_000_000)  // 남은 이동 대기 시간이 다 지나도록
        #expect(vm.gameState == .idle)
        #expect(vm.failedBlockPath == nil)
        #expect(vm.failureMessage.isEmpty)
    }
}
