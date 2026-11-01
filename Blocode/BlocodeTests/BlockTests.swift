//
//  BlockTests.swift
//  BlocodeTests
//

import Testing
@testable import Blocode

@Suite("Block 모델 — flatCount·기본값")
struct BlockTests {

    // MARK: - flatCount

    @Test("일반 블럭 하나는 flatCount 1")
    func simpleBlock_flatCountIsOne() {
        let block = Block(type: .moveForward)
        #expect(block.flatCount == 1)
    }

    @Test("빈 컨테이너는 flatCount 0 — 컨테이너 자체는 카운트 안 함")
    func emptyContainer_flatCountIsZero() {
        let repeatBlock = Block(type: .repeatBlock, repeatCount: 5, children: [])
        #expect(repeatBlock.flatCount == 0)
    }

    @Test("repeat(7)[moveForward] → flatCount는 1 (반복 횟수를 곱하지 않음)")
    func repeatWithChildren_countsChildrenOnlyNotRepeatCount() {
        let repeatBlock = Block(
            type: .repeatBlock,
            repeatCount: 7,
            children: [Block(type: .moveForward)]
        )
        #expect(repeatBlock.flatCount == 1)
    }

    @Test("if 블럭은 자식 개수만 카운트")
    func ifBlock_countsChildrenOnly() {
        let ifBlock = Block(
            type: .ifBlock,
            children: [Block(type: .turnRight), Block(type: .moveForward)]
        )
        #expect(ifBlock.flatCount == 2)
    }

    @Test("function 블럭은 재사용 가중치 없이 자식 합만 카운트")
    func functionBlock_countsChildrenOnly_noSpecialWeight() {
        let functionBlock = Block(
            type: .functionBlock,
            children: [Block(type: .moveForward), Block(type: .turnLeft), Block(type: .moveForward)]
        )
        #expect(functionBlock.flatCount == 3)
    }

    @Test("중첩 컨테이너는 재귀적으로 평탄화됨")
    func nestedContainers_flattenRecursively() {
        // repeat(3)[ if(pathBlocked)[ turnRight ], moveForward ] → if(1) + moveForward(1) = 2
        let inner = Block(type: .ifBlock, children: [Block(type: .turnRight)])
        let outer = Block(type: .repeatBlock, repeatCount: 10, children: [inner, Block(type: .moveForward)])
        #expect(outer.flatCount == 2)
    }

    @Test("4단 중첩(function→repeat→if→moveForward)도 재귀로 1까지 내려감")
    func threeLevelNesting_flattenRecursively() {
        let leaf = Block(type: .moveForward)
        let level3 = Block(type: .ifBlock, children: [leaf])
        let level2 = Block(type: .repeatBlock, repeatCount: 4, children: [level3])
        let level1 = Block(type: .functionBlock, children: [level2])
        #expect(level1.flatCount == 1)
    }

    @Test("기믹 블럭(collectItem/activateSwitch)도 일반 블럭처럼 1로 카운트")
    func gimmickBlocks_countAsOne() {
        #expect(Block(type: .collectItem).flatCount == 1)
        #expect(Block(type: .activateSwitch).flatCount == 1)
    }

    // MARK: - 기본값

    @Test("repeat 블럭 기본 반복 횟수는 2")
    func repeatBlock_defaultRepeatCountIsTwo() {
        let block = Block(type: .repeatBlock)
        #expect(block.repeatCount == 2)
    }

    @Test("if 블럭 기본 조건은 pathBlocked")
    func ifBlock_defaultConditionIsPathBlocked() {
        let block = Block(type: .ifBlock)
        #expect(block.ifCondition == .pathBlocked)
    }

    @Test("컨테이너가 아닌 블럭은 children이 nil")
    func nonContainerBlocks_haveNilChildren() {
        #expect(Block(type: .moveForward).children == nil)
        #expect(Block(type: .turnLeft).children == nil)
    }

    @Test("컨테이너 블럭만 hasChildren이 true")
    func containerBlocks_hasChildrenIsTrue() {
        #expect(Block(type: .repeatBlock).hasChildren)
        #expect(Block(type: .ifBlock).hasChildren)
        #expect(Block(type: .functionBlock).hasChildren)
        #expect(!Block(type: .moveForward).hasChildren)
    }

    // MARK: - StarThresholds

    @Test("별점 경계값 계산")
    func starThresholds_boundaryValues() {
        let thresholds = StarThresholds(threeStar: 4, twoStar: 6)
        #expect(thresholds.stars(for: 4) == 3)  // 경계값 — 별 3개
        #expect(thresholds.stars(for: 5) == 2)  // threeStar 초과, twoStar 이하 — 별 2개
        #expect(thresholds.stars(for: 6) == 2)  // 경계값 — 별 2개
        #expect(thresholds.stars(for: 7) == 1)  // twoStar 초과 — 별 1개
        #expect(thresholds.stars(for: 1) == 3)  // 최소값도 3개 기준 이하면 3개
    }
}

// MARK: - 블럭 트리 편집

@Suite("Block 트리 편집 — ViewModel 없이 경로로")
struct BlockTreeTests {

    /// 함수 → 반복 → 만약에 → 앞으로 (4단)
    private func nestedTree() -> [Block] {
        [Block(type: .functionBlock, children: [
            Block(type: .repeatBlock, children: [
                Block(type: .ifBlock, children: [Block(type: .moveForward)])
            ])
        ])]
    }

    @Test("경로로 깊이별 블럭을 찾고, 잘못된 경로는 nil")
    func blockAtPath() {
        let tree = nestedTree()
        #expect(tree.block(at: [0])?.type == .functionBlock)
        #expect(tree.block(at: [0, 0, 0, 0])?.type == .moveForward)
        #expect(tree.block(at: []) == nil)
        #expect(tree.block(at: [1]) == nil)
        #expect(tree.block(at: [0, 0, 0, 0, 0]) == nil)
    }

    @Test("중첩 규칙 — 팔레트 안에서 function·동일 타입 제외, 증손자는 기본 동작만")
    func allowedChildTypes_followRules() {
        let palette: [BlockType] = [.moveForward, .repeatBlock, .ifBlock, .functionBlock]
        let tree = nestedTree()
        let expectedForFunction: [BlockType] = [.moveForward, .repeatBlock, .ifBlock]
        let expectedForRepeat: [BlockType] = [.moveForward, .ifBlock]
        let expectedForDeepest: [BlockType] = [.moveForward]
        #expect(tree.allowedChildTypes(at: [0], palette: palette) == expectedForFunction)
        #expect(tree.allowedChildTypes(at: [0, 0], palette: palette) == expectedForRepeat)
        #expect(tree.allowedChildTypes(at: [0, 0, 0], palette: palette) == expectedForDeepest)
        #expect(tree.allowedChildTypes(at: [0, 0, 0, 0], palette: palette).isEmpty)  // 기본 동작 블럭은 컨테이너 아님
    }

    @Test("자식 추가는 허용된 블럭만")
    func addChild_respectsRules() {
        var tree = nestedTree()
        tree.addChild(.turnLeft, at: [0], palette: [.moveForward])  // 팔레트에 없음
        #expect(tree[0].children?.count == 1)
        tree.addChild(.moveForward, at: [0], palette: [.moveForward])
        #expect(tree[0].children?.count == 2)
    }

    @Test("삭제는 최상위와 중첩 모두 가능, 잘못된 경로는 무시")
    func removeBlock_atAnyDepth() {
        var tree = nestedTree()
        tree.removeBlock(at: [0, 5])
        tree.removeBlock(at: [])
        #expect(tree[0].children?.count == 1)

        tree.removeBlock(at: [0, 0, 0, 0])
        #expect(tree.block(at: [0, 0, 0])?.children?.isEmpty == true)
        tree.removeBlock(at: [0])
        #expect(tree.isEmpty)
    }

    @Test("반복 횟수와 조건은 해당 블럭 종류에만 적용")
    func settings_applyToMatchingType() {
        var tree = nestedTree()
        tree.setRepeatCount(99, at: [0, 0])
        #expect(tree.block(at: [0, 0])?.repeatCount == 10)
        tree.setRepeatCount(5, at: [0])              // 함수 블럭 — 무시
        #expect(tree[0].repeatCount == nil)

        tree.setIfCondition(.pathClear, at: [0, 0, 0])
        #expect(tree.block(at: [0, 0, 0])?.ifCondition == .pathClear)
        tree.setIfCondition(.pathClear, at: [0, 0])  // 반복 블럭 — 무시
        #expect(tree.block(at: [0, 0])?.ifCondition == nil)
    }

    @Test("순서 변경 — 뒤로·앞으로 이동과 잘못된 위치")
    func moveBlock_reorders() {
        var tree = [Block(type: .moveForward), Block(type: .turnLeft), Block(type: .turnRight)]
        let movedBack = tree.moveBlock(from: 0, to: 3)
        #expect(movedBack)
        #expect(tree.map(\.type) == [.turnLeft, .turnRight, .moveForward])

        let movedFront = tree.moveBlock(from: 2, to: 0)
        #expect(movedFront)
        #expect(tree.map(\.type) == [.moveForward, .turnLeft, .turnRight])

        let invalid = tree.moveBlock(from: 5, to: 0)
        #expect(invalid == false)
        #expect(tree.count == 3)
    }
}
