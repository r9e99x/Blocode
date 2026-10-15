//
//  BlockEditingTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 10/15/26.
//
//  GameViewModel의 블럭 편집 함수(추가·삽입·삭제·이동·중첩·반복 횟수) 검증.
//  리팩토링(블럭 트리 재귀화) 전후로 편집 동작이 똑같은지 증명하는 안전망 역할.
//  실행을 하지 않으므로 GameScene·ProgressService를 전혀 쓰지 않는다.

import Testing
import Foundation  // IndexSet (Testing은 Foundation을 자동으로 가져오지 않음)
@testable import Blocode

@MainActor
@Suite("블럭 편집")
struct BlockEditingTests {

    /// 편집 테스트용 VM — palette가 nil이면 모든 블럭 허용(기존 JSON 하위호환 규칙과 동일)
    private func makeViewModel(palette: [BlockType]? = nil) -> GameViewModel {
        let stage = Stage(
            id: "unittest_editing",
            chapter: 0,
            stageNumber: 0,
            name: "Editing Test",
            mapData: MapData(grid: [[1]], start: Position(x: 0, y: 0), startDirection: .up, goal: Position(x: 0, y: 0)),
            starThresholds: StarThresholds(threeStar: 99, twoStar: 99),
            availableBlocks: palette
        )
        return GameViewModel(stage: stage)
    }

    private func types(_ blocks: [Block]?) -> [BlockType] {
        (blocks ?? []).map(\.type)
    }

    // MARK: - 최상위 편집

    @Test("addBlock은 맨 뒤에 추가")
    func addBlock_appends() {
        let vm = makeViewModel()
        vm.addBlock(.moveForward)
        vm.addBlock(.turnLeft)
        #expect(types(vm.codeBlocks) == [.moveForward, .turnLeft])
    }

    @Test("insertBlock은 범위 밖 인덱스를 앞/뒤 끝으로 보정")
    func insertBlock_clampsIndex() {
        let vm = makeViewModel()
        vm.addBlock(.moveForward)
        vm.insertBlock(.turnLeft, at: -5)   // 음수 → 맨 앞
        vm.insertBlock(.turnRight, at: 99)  // 초과 → 맨 뒤
        #expect(types(vm.codeBlocks) == [.turnLeft, .moveForward, .turnRight])
    }

    @Test("removeBlock은 범위 밖 인덱스를 무시")
    func removeBlock_ignoresInvalidIndex() {
        let vm = makeViewModel()
        vm.addBlock(.moveForward)
        vm.removeBlock(at: 5)
        #expect(vm.codeBlocks.count == 1)
        vm.removeBlock(at: 0)
        #expect(vm.codeBlocks.isEmpty)
    }

    @Test("moveBlock은 순서를 바꿈 (삽입 위치 기준)")
    func moveBlock_reorders() {
        let vm = makeViewModel()
        vm.addBlock(.moveForward)
        vm.addBlock(.turnLeft)
        vm.addBlock(.turnRight)
        vm.moveBlock(from: IndexSet(integer: 0), to: 3)  // 첫 블럭을 맨 뒤로
        #expect(types(vm.codeBlocks) == [.turnLeft, .turnRight, .moveForward])
    }

    // MARK: - 중첩 편집

    @Test("컨테이너에만 자식을 추가할 수 있음")
    func addChild_onlyIntoContainers() {
        let vm = makeViewModel()
        vm.addBlock(.repeatBlock)
        vm.addBlock(.moveForward)
        vm.addChildBlock(.turnLeft, to: 0)
        vm.addChildBlock(.turnLeft, to: 1)  // 일반 블럭 — 무시
        #expect(types(vm.codeBlocks[0].children) == [.turnLeft])
        #expect(vm.codeBlocks[1].children == nil)
    }

    @Test("손자·증손자 추가와 삭제 (function→repeat→if→앞으로 4단)")
    func nestedAddAndRemove() {
        let vm = makeViewModel()
        vm.addBlock(.functionBlock)
        vm.addChildBlock(.repeatBlock, to: 0)
        vm.addGrandchildBlock(.ifBlock, parentIndex: 0, childIndex: 0)
        vm.addGreatGrandchildBlock(.moveForward, parentIndex: 0, childIndex: 0, grandchildIndex: 0)
        #expect(vm.totalBlockCount == 1)  // 컨테이너는 0, 맨 안쪽 앞으로만 1

        vm.removeGreatGrandchildBlock(greatGrandchildIndex: 0, parentIndex: 0, childIndex: 0, grandchildIndex: 0)
        #expect(vm.codeBlocks[0].children?[0].children?[0].children?.isEmpty == true)
        vm.removeGrandchildBlock(grandchildIndex: 0, parentIndex: 0, childIndex: 0)
        #expect(vm.codeBlocks[0].children?[0].children?.isEmpty == true)
        vm.removeChildBlock(at: 0, from: 0)
        #expect(vm.codeBlocks[0].children?.isEmpty == true)
    }

    @Test("반복 횟수는 모든 깊이에서 1~10으로 보정")
    func repeatCount_clampedAtEveryDepth() {
        let vm = makeViewModel()
        vm.addBlock(.repeatBlock)
        vm.setRepeatCount(0, at: 0)
        #expect(vm.codeBlocks[0].repeatCount == 1)

        vm.addBlock(.functionBlock)
        vm.addChildBlock(.repeatBlock, to: 1)
        vm.setChildRepeatCount(99, parentIndex: 1, childIndex: 0)
        #expect(vm.codeBlocks[1].children?[0].repeatCount == 10)

        vm.addChildBlock(.ifBlock, to: 1)
        vm.addGrandchildBlock(.repeatBlock, parentIndex: 1, childIndex: 1)
        vm.setGrandchildRepeatCount(-3, parentIndex: 1, childIndex: 1, grandchildIndex: 0)
        #expect(vm.codeBlocks[1].children?[1].children?[0].repeatCount == 1)
    }

    @Test("실행 중에는 블럭을 편집할 수 없음")
    func editingBlockedWhileRunning() {
        let vm = makeViewModel()
        vm.addBlock(.moveForward)
        vm.run()  // 동기적으로 running 진입 (실제 실행 Task는 이후에 돎)
        vm.addBlock(.turnLeft)
        vm.removeBlock(at: 0)
        #expect(types(vm.codeBlocks) == [.moveForward])
    }

    // MARK: - 팔레트 제한 (B4)

    @Test("팔레트에 없는 블럭은 어떤 깊이에도 추가되지 않음")
    func blocksOutsidePalette_areRejected() {
        // 2챕터처럼 "만약에"가 없는 팔레트
        let vm = makeViewModel(palette: [.moveForward, .turnRight, .repeatBlock])
        vm.addBlock(.ifBlock)
        vm.insertBlock(.turnLeft, at: 0)
        #expect(vm.codeBlocks.isEmpty)

        vm.addBlock(.repeatBlock)
        vm.addChildBlock(.ifBlock, to: 0)        // 반복 안에 만약에 — 차단 (예전엔 3챕터 기법을 쓸 수 있었음)
        vm.addChildBlock(.moveForward, to: 0)    // 팔레트에 있는 블럭은 정상 추가
        #expect(types(vm.codeBlocks[0].children) == [.moveForward])
    }
}
