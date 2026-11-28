//
//  StageSolutionTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/2/26.
//
//  챕터 11~15와 함수 스테이지(4장 전부·6-7·10-1)의 기준 풀이를 실제 실행 엔진(GameViewModel)으로 돌려
//  별 3개를 받을 수 있는지 검증. 별 3개 기준(threeStar)은 이 풀이의 블럭 수와 같아야 한다.
//  함수 스테이지는 함수 없이 풀면 별 3개가 안 나오게 설계함 (반복만 쓴 최소 블럭 수 = twoStar, 설계 때 전수 탐색으로 확인)
//  맵이나 별 기준을 고치면 여기 풀이도 함께 고칠 것.

import Testing
import Foundation
@testable import Blocode

@Suite("기준 풀이로 별 3개", .timeLimit(.minutes(1)))
struct StageSolutionTests {

    // 기본 블럭 — 풀이를 읽기 쉽게 쓰기 위한 이름 (실행은 위치 기준이라 같은 값을 재사용해도 됨)
    private static let forward = Block(type: .moveForward)
    private static let backward = Block(type: .moveBackward)
    private static let left = Block(type: .turnLeft)
    private static let right = Block(type: .turnRight)
    private static let collect = Block(type: .collectItem)
    private static let press = Block(type: .activateSwitch)
    private static let call = Block(type: .callFunction)

    /// 함수 정의 — 몸통은 "함수 부르기"를 놓은 자리마다 실행됨
    private static func function(_ children: [Block]) -> Block {
        Block(type: .functionBlock, children: children)
    }

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
        case "ch11_stage1": [loop(4, [forward, forward, collect])]
        case "ch11_stage2": [loop(6, [forward, right, forward, collect, left])]
        case "ch11_stage3": [loop(3, [ifClear([loop(6, [forward])]), right])]
        case "ch11_stage4": [loop(4, [ifClear([loop(2, [forward])]), left, ifClear([loop(2, [forward])]), collect, ifBlocked([loop(2, [backward])]), right])]
        case "ch11_stage5": [loop(4, [ifClear([loop(2, [forward, right, forward, left])]), collect])]
        case "ch11_stage6": [loop(4, [ifClear([loop(2, [forward, forward, forward, collect])]), right])]
        case "ch11_stage7": [loop(3, [ifClear([loop(2, [forward])]), left, ifClear([loop(2, [forward])]), collect, ifBlocked([loop(2, [backward])]), right]), loop(10, [ifBlocked([left]), ifClear([loop(2, [forward])])])]
        case "ch12_stage1": [loop(10, [ifBlocked([right]), forward])]
        case "ch12_stage2": [loop(10, [ifBlocked([right]), forward])]
        case "ch12_stage3": [loop(8, [ifBlocked([right]), ifClear([loop(4, [forward])])])]
        case "ch12_stage4": [loop(10, [ifBlocked([right]), forward, collect])]
        case "ch12_stage5": [loop(10, [ifBlocked([right]), ifBlocked([right, right]), forward])]
        case "ch12_stage6": [loop(8, [ifBlocked([right]), ifBlocked([right, right]), ifClear([loop(2, [forward])])])]
        case "ch12_stage7": [loop(10, [ifBlocked([right]), forward]), collect, loop(10, [ifBlocked([right]), forward])]
        case "ch13_stage1": [loop(4, [forward, press, forward])]
        case "ch13_stage2": [loop(3, [backward]), press, loop(9, [forward])]
        case "ch13_stage3": [loop(2, [forward]), press, loop(5, [backward]), press, loop(8, [forward])]
        case "ch13_stage4": [loop(4, [backward]), press, loop(8, [forward]), press, loop(4, [backward]), left, loop(2, [forward])]
        case "ch13_stage5": [left, loop(4, [ifClear([loop(3, [forward])]), press, ifBlocked([loop(3, [backward])]), right])]
        case "ch13_stage6": [loop(4, [forward, collect, forward, press, forward, right])]
        case "ch13_stage7": [loop(4, [backward]), press, loop(2, [forward]), left, loop(4, [forward]), press, loop(4, [backward]), right, loop(3, [forward]), right, loop(3, [forward]), collect, forward, press, loop(4, [backward]), left, loop(3, [forward])]
        case "ch14_stage1": [loop(6, [forward])]
        case "ch14_stage2": [loop(2, [backward]), loop(4, [forward])]
        case "ch14_stage3": [loop(3, [forward]), collect, backward, loop(3, [forward])]
        case "ch14_stage4": [loop(6, [backward]), collect, loop(9, [backward])]
        case "ch14_stage5": [loop(4, [ifClear([loop(2, [forward])]), collect, ifClear([loop(2, [forward])])])]
        case "ch14_stage6": [backward, loop(2, [forward]), press, loop(2, [backward]), loop(5, [forward])]
        case "ch14_stage7": [loop(6, [forward]), collect, loop(2, [forward]), press, loop(5, [backward]), loop(8, [forward]), collect, loop(5, [forward]), right, loop(2, [forward]), left, loop(6, [forward])]
        case "ch15_stage1": [loop(7, [ifBlocked([collect, left]), ifClear([loop(2, [forward])])])]
        case "ch15_stage2": [loop(4, [ifClear([loop(3, [forward])]), collect, ifBlocked([loop(3, [backward])]), right])]
        case "ch15_stage3": [loop(8, [ifBlocked([right]), forward]), collect, loop(5, [ifBlocked([right]), forward]), press, loop(10, [ifBlocked([right]), forward])]
        case "ch15_stage4": [loop(3, [ifClear([loop(2, [forward])]), press, left, forward, collect, backward, right, ifClear([loop(2, [forward])])])]
        case "ch15_stage5": [loop(4, [forward, left, forward, collect, forward, press, ifBlocked([loop(2, [backward])]), right, forward])]
        case "ch15_stage6": [loop(9, [ifBlocked([right]), ifClear([loop(2, [forward])])]), press, loop(2, [left]), loop(10, [ifBlocked([left]), ifClear([loop(2, [forward])])])]
        // 함수 스테이지 — 함수 몸통을 한 번 만들고 여러 번 부름
        case "ch4_stage1": [function([loop(3, [forward]), left, loop(3, [forward]), left, loop(3, [forward])]), loop(2, [call, right]), loop(2, [call])]
        case "ch4_stage2": [function([loop(2, [forward]), left, loop(3, [forward]), right, loop(3, [forward])]), loop(2, [call, right]), loop(2, [call])]
        case "ch4_stage3": [function([loop(2, [forward]), left, loop(2, [forward]), right, loop(2, [forward])]), call, left, loop(2, [call, right]), loop(2, [call])]
        case "ch4_stage4": [function([loop(3, [forward]), left, loop(3, [forward]), right, forward, left]), loop(2, [call, forward]), forward, loop(2, [call])]
        case "ch4_stage5": [function([loop(2, [forward]), loop(2, [right, forward, forward])]), loop(2, [forward, call, forward, left, call, left, forward])]
        case "ch4_stage6": [function([loop(2, [forward]), right, forward]), loop(2, [call]), loop(2, [left, call]), loop(2, [call, left]), loop(3, [call]), left, call]
        case "ch4_stage7": [function([loop(3, [forward]), left, loop(3, [forward]), right, forward]), call, left, loop(2, [call, left, forward]), loop(2, [forward]), left, loop(2, [call])]
        case "ch6_stage7": [function([loop(3, [forward]), right, forward, left, loop(2, [forward]), collect]), call, right, call, left, loop(3, [forward]), left, loop(2, [call])]
        case "ch10_stage1": [function([loop(2, [forward]), right, loop(3, [forward]), collect, right, forward]), loop(2, [call, left, forward]), loop(2, [forward, call, left, call])]
        case "ch15_stage7": [loop(2, [ifClear([loop(2, [forward])]), left, ifClear([loop(2, [forward])]), collect, ifBlocked([loop(2, [backward])]), right]), loop(5, [ifBlocked([right]), ifClear([loop(2, [forward])])]), press, loop(6, [ifBlocked([right]), ifClear([loop(2, [forward])])]), press, loop(2, [left]), loop(10, [ifBlocked([left]), ifClear([loop(2, [forward])])]), right, loop(2, [forward])]
        default: nil
        }
    }

    /// 새 챕터 한 곳의 모든 스테이지
    private func newStages(in chapter: Int) -> [Stage] {
        StageLoader.loadChapter(chapter, stageCount: ChapterCatalog.chapter(chapter)?.stageCount ?? 0)
    }

    /// 앱에서 실제로 만들 수 있는 블럭인지 검사 — 팔레트, 중첩 규칙, 반복 횟수 1 이상, 함수는 하나만
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
                if let count = block.repeatCount, count < 1 {
                    violations.append("\(path): 반복 횟수 \(count)")
                }
                visit(block.children ?? [], parentPath: path)
            }
        }

        visit(blocks, parentPath: [])
        if blocks.filter({ $0.type == .functionBlock }).count > 1 {
            violations.append("함수가 두 개 이상")
        }
        return violations
    }

    /// 풀이를 끝까지 실행 — 시간 안에 안 끝나면 running 상태로 돌아옴
    private func run(_ solution: [Block], on stage: Stage) async throws -> GameViewModel {
        let vm = GameViewModel(stage: stage, progress: .makeForTesting(), executionSpeed: { 1000 })
        vm.codeBlocks = solution
        vm.run()
        try await waitWhileRunning(vm)
        return vm
    }

    @Test("챕터 11~15마다 모든 스테이지를 기준 풀이로 별 3개 클리어함", arguments: 11...15)
    func everyNewStage_clearsWithThreeStars(chapter: Int) async throws {
        let stages = newStages(in: chapter)  // 챕터별 매개변수 테스트 — 실패하면 어느 챕터인지 결과에 바로 보임
        #expect(stages.count == 7)
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
        // 반복 횟수는 위쪽 제한이 없음 — 0회만 잘못
        #expect(ruleViolations(in: [Self.loop(50, [Self.forward])], stage: stage).isEmpty)
        #expect(!ruleViolations(in: [Self.loop(0, [Self.forward])], stage: stage).isEmpty)
    }

    @Test("함수 스테이지마다 기준 풀이로 별 3개 클리어함",
          arguments: ["ch4_stage1", "ch4_stage2", "ch4_stage3", "ch4_stage4", "ch4_stage5", "ch4_stage6", "ch4_stage7",
                      "ch6_stage7", "ch10_stage1"])
    func functionStages_clearWithThreeStars(stageID: String) async throws {
        let parts = stageID.dropFirst(2).split(separator: "_stage").compactMap { Int($0) }
        let stage = try #require(StageLoader.load(chapter: parts[0], stage: parts[1]))
        let solution = try #require(Self.solution(for: stage.id))
        #expect(ruleViolations(in: solution, stage: stage).isEmpty,
                "\(stage.id): 앱에서 만들 수 없는 풀이 \(ruleViolations(in: solution, stage: stage))")

        let vm = try await run(solution, on: stage)
        #expect(vm.gameState == .success, "\(stage.id): 클리어하지 못함 (\(vm.failureMessage))")
        #expect(vm.clearedStars == 3, "\(stage.id): 별 \(vm.clearedStars)개")
        #expect(vm.totalBlockCount == stage.starThresholds.threeStar,
                "\(stage.id): 풀이 \(vm.totalBlockCount)개인데 별 3개 기준은 \(stage.starThresholds.threeStar)개")
    }
}
