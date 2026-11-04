//
//  StageSolutionTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/2/26.
//
//  챕터 11~15의 기준 풀이를 실제 실행 엔진(GameViewModel)으로 돌려
//  별 3개를 받을 수 있는지 검증. 별 3개 기준(threeStar)은 이 풀이의 블럭 수와 같아야 한다.
//  맵이나 별 기준을 고치면 여기 풀이도 함께 고칠 것.

import Testing
import Foundation
@testable import Blocode

@MainActor
@Suite("챕터 11~15 기준 풀이")
struct StageSolutionTests {

    // 기본 블럭 — 풀이를 읽기 쉽게 쓰기 위한 이름 (실행은 위치 기준이라 같은 값을 재사용해도 됨)
    private static let forward = Block(type: .moveForward)
    private static let backward = Block(type: .moveBackward)
    private static let left = Block(type: .turnLeft)
    private static let right = Block(type: .turnRight)
    private static let collect = Block(type: .collectItem)
    private static let press = Block(type: .activateSwitch)

    private static func loop(_ count: Int, _ children: [Block]) -> Block {
        Block(type: .repeatBlock, repeatCount: count, children: children)
    }

    private static func ifClear(_ children: [Block]) -> Block {
        Block(type: .ifBlock, children: children, ifCondition: .pathClear)
    }

    private static func ifBlocked(_ children: [Block]) -> Block {
        Block(type: .ifBlock, children: children, ifCondition: .pathBlocked)
    }

    /// 스테이지별 기준 풀이 — 없으면 nil
    private static func solution(for stageID: String) -> [Block]? {
        switch stageID {
        case "ch11_stage1": return [loop(4, [forward, forward, collect])]
        case "ch11_stage2": return [loop(6, [forward, right, forward, collect, left])]
        case "ch11_stage3": return [loop(3, [ifClear([loop(6, [forward])]), right])]
        case "ch11_stage4": return [loop(4, [ifClear([loop(2, [forward])]), left, ifClear([loop(2, [forward])]), collect, ifBlocked([loop(2, [backward])]), right])]
        case "ch11_stage5": return [loop(4, [ifClear([loop(2, [forward, right, forward, left])]), collect])]
        case "ch11_stage6": return [loop(4, [ifClear([loop(2, [forward, forward, forward, collect])]), right])]
        case "ch11_stage7": return [loop(3, [ifClear([loop(2, [forward])]), left, ifClear([loop(2, [forward])]), collect, ifBlocked([loop(2, [backward])]), right]), loop(10, [ifBlocked([left]), ifClear([loop(2, [forward])])])]
        case "ch12_stage1": return [loop(10, [ifBlocked([right]), forward])]
        case "ch12_stage2": return [loop(10, [ifBlocked([right]), forward])]
        case "ch12_stage3": return [loop(8, [ifBlocked([right]), ifClear([loop(4, [forward])])])]
        case "ch12_stage4": return [loop(10, [ifBlocked([right]), forward, collect])]
        case "ch12_stage5": return [loop(10, [ifBlocked([right]), ifBlocked([right, right]), forward])]
        case "ch12_stage6": return [loop(8, [ifBlocked([right]), ifBlocked([right, right]), ifClear([loop(2, [forward])])])]
        case "ch12_stage7": return [loop(10, [ifBlocked([right]), forward]), collect, loop(10, [ifBlocked([right]), forward])]
        case "ch13_stage1": return [loop(4, [forward, press, forward])]
        case "ch13_stage2": return [loop(3, [backward]), press, loop(9, [forward])]
        case "ch13_stage3": return [loop(2, [forward]), press, loop(5, [backward]), press, loop(8, [forward])]
        case "ch13_stage4": return [loop(4, [backward]), press, loop(8, [forward]), press, loop(4, [backward]), left, loop(2, [forward])]
        case "ch13_stage5": return [left, loop(4, [ifClear([loop(3, [forward])]), press, ifBlocked([loop(3, [backward])]), right])]
        case "ch13_stage6": return [loop(4, [forward, collect, forward, press, forward, right])]
        case "ch13_stage7": return [loop(4, [backward]), press, loop(2, [forward]), left, loop(4, [forward]), press, loop(4, [backward]), right, loop(3, [forward]), right, loop(3, [forward]), collect, forward, press, loop(4, [backward]), left, loop(3, [forward])]
        case "ch14_stage1": return [loop(6, [forward])]
        case "ch14_stage2": return [loop(2, [backward]), loop(4, [forward])]
        case "ch14_stage3": return [loop(3, [forward]), collect, backward, loop(3, [forward])]
        case "ch14_stage4": return [loop(6, [backward]), collect, loop(9, [backward])]
        case "ch14_stage5": return [loop(4, [ifClear([loop(2, [forward])]), collect, ifClear([loop(2, [forward])])])]
        case "ch14_stage6": return [backward, loop(2, [forward]), press, loop(2, [backward]), loop(5, [forward])]
        case "ch14_stage7": return [loop(6, [forward]), collect, loop(2, [forward]), press, loop(5, [backward]), loop(8, [forward]), collect, loop(5, [forward]), right, loop(2, [forward]), left, loop(6, [forward])]
        case "ch15_stage1": return [loop(7, [ifBlocked([collect, left]), ifClear([loop(2, [forward])])])]
        case "ch15_stage2": return [loop(4, [ifClear([loop(3, [forward])]), collect, ifBlocked([loop(3, [backward])]), right])]
        case "ch15_stage3": return [loop(8, [ifBlocked([right]), forward]), collect, loop(5, [ifBlocked([right]), forward]), press, loop(10, [ifBlocked([right]), forward])]
        case "ch15_stage4": return [loop(3, [ifClear([loop(2, [forward])]), press, left, forward, collect, backward, right, ifClear([loop(2, [forward])])])]
        case "ch15_stage5": return [loop(4, [forward, left, forward, collect, forward, press, ifBlocked([loop(2, [backward])]), right, forward])]
        case "ch15_stage6": return [loop(9, [ifBlocked([right]), ifClear([loop(2, [forward])])]), press, loop(2, [left]), loop(10, [ifBlocked([left]), ifClear([loop(2, [forward])])])]
        case "ch15_stage7": return [loop(2, [ifClear([loop(2, [forward])]), left, ifClear([loop(2, [forward])]), collect, ifBlocked([loop(2, [backward])]), right]), loop(5, [ifBlocked([right]), ifClear([loop(2, [forward])])]), press, loop(6, [ifBlocked([right]), ifClear([loop(2, [forward])])]), press, loop(2, [left]), loop(10, [ifBlocked([left]), ifClear([loop(2, [forward])])]), right, loop(2, [forward])]
        default: return nil
        }
    }

    /// 새 챕터의 모든 스테이지
    private var newStages: [Stage] {
        ChapterCatalog.all.filter { $0.number >= 11 }
            .flatMap { StageLoader.loadChapter($0.number, stageCount: $0.stageCount) }
    }

    /// 앱에서 실제로 만들 수 있는 블럭인지 검사 — 팔레트, 중첩 규칙, 반복 횟수 1~10
    /// - Returns: 규칙을 어긴 내용 (없으면 빈 배열)
    private func ruleViolations(in blocks: [Block], stage: Stage) -> [String] {
        var violations: [String] = []

        func visit(_ siblings: [Block], parentPath: [Int]) {
            let allowed = parentPath.isEmpty
                ? stage.paletteBlocks
                : blocks.allowedChildTypes(at: parentPath, palette: stage.paletteBlocks)
            for (index, block) in siblings.enumerated() {
                let path = parentPath + [index]
                if !allowed.contains(block.type) {
                    violations.append("\(path): \(block.type)는 이 자리에 넣을 수 없음")
                }
                if let count = block.repeatCount, !(1...10).contains(count) {
                    violations.append("\(path): 반복 횟수 \(count)")
                }
                visit(block.children ?? [], parentPath: path)
            }
        }

        visit(blocks, parentPath: [])
        return violations
    }

    /// 풀이를 끝까지 실행 — 시간 안에 안 끝나면 running 상태로 돌아옴
    private func run(_ solution: [Block], on stage: Stage) async throws -> GameViewModel {
        let vm = GameViewModel(stage: stage, progress: .makeForTesting(), executionSpeed: { 1000 })
        vm.codeBlocks = solution
        vm.run()
        let deadline = Date().addingTimeInterval(10)
        while vm.gameState == .running, Date() < deadline {
            try await Task.sleep(for: .milliseconds(5))
        }
        return vm
    }

    @Test("모든 새 스테이지를 기준 풀이로 별 3개 클리어함")
    func everyNewStage_clearsWithThreeStars() async throws {
        let stages = newStages
        #expect(stages.count == 35)
        for stage in stages {
            guard let solution = Self.solution(for: stage.id) else {
                Issue.record("\(stage.id): 기준 풀이가 없음")
                continue
            }
            #expect(ruleViolations(in: solution, stage: stage).isEmpty,
                    "\(stage.id): 앱에서 만들 수 없는 풀이 \(ruleViolations(in: solution, stage: stage))")

            let vm = try await run(solution, on: stage)
            #expect(vm.gameState == .success, "\(stage.id): 클리어하지 못함 (\(vm.failureMessage))")
            #expect(vm.clearedStars == 3, "\(stage.id): 별 \(vm.clearedStars)개")
            #expect(vm.totalBlockCount == stage.starThresholds.threeStar,
                    "\(stage.id): 풀이 \(vm.totalBlockCount)개인데 별 3개 기준은 \(stage.starThresholds.threeStar)개")
        }
    }

    @Test("규칙 검사가 앱에서 못 만드는 풀이를 잡아냄")
    func ruleCheck_rejectsInvalidSolutions() {
        let stage = Stage(id: "unittest_rule", chapter: 0, stageNumber: 0, name: "Rule Test",
                          mapData: MapData(grid: [[1, 1]], start: Position(x: 0, y: 0),
                                           startDirection: .right, goal: Position(x: 1, y: 0)),
                          starThresholds: StarThresholds(threeStar: 1, twoStar: 2),
                          availableBlocks: [.moveForward, .repeatBlock, .ifBlock])
        #expect(ruleViolations(in: [Self.loop(2, [Self.forward])], stage: stage).isEmpty)
        // 팔레트에 없는 블럭
        #expect(!ruleViolations(in: [Self.left], stage: stage).isEmpty)
        // 반복 안에 바로 반복
        #expect(!ruleViolations(in: [Self.loop(2, [Self.loop(2, [Self.forward])])], stage: stage).isEmpty)
        // 앱의 최대 횟수 초과
        #expect(!ruleViolations(in: [Self.loop(11, [Self.forward])], stage: stage).isEmpty)
    }
}
