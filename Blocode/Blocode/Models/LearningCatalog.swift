//
//  LearningCatalog.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import Foundation

// MARK: - LearningCatalog
/// 학습 보관함의 모든 카드 — 블럭 개념 12장 (코딩·CS 기초 카드는 이어서 채움)
/// 카드를 늘릴 땐 `all`에 항목만 더하면 됨 (id는 겹치면 안 됨 — 테스트가 확인)
enum LearningCatalog {

    static let all: [LearningCard] = blockCards + codingCards + csCards

    /// 탭별 카드
    static func cards(in category: LearningCategory) -> [LearningCard] {
        all.filter { $0.category == category }
    }

    /// 그 블럭 자신을 설명하는 카드 — 블럭이 처음 등장할 때 띄우는 설명이 이 카드
    static func card(for block: BlockType) -> LearningCard? {
        all.first { $0.category == .block && $0.id == "block.\(block.rawValue)" }
    }

    // MARK: - 블럭 개념

    private static let blockCards: [LearningCard] = [
        LearningCard(
            id: "block.moveForward", category: .block, title: "앞으로",
            summary: "캐릭터가 바라보는 방향으로 한 칸 가요.",
            body: "가장 기본이 되는 명령이에요. 블럭을 쌓으면 위에서 아래로 하나씩 실행돼요. 벽이나 맵 밖으로는 갈 수 없어요.",
            tip: "코드에서는 move_forward() 같은 함수 호출로 써요.",
            unlock: .block(.moveForward),
            example: .blocks([Block(type: .moveForward), Block(type: .moveForward), Block(type: .moveForward)])),

        LearningCard(
            id: "block.moveBackward", category: .block, title: "뒤로",
            summary: "바라보는 방향은 그대로 두고 한 칸 물러나요.",
            body: "방향을 돌리지 않고 뒤로 한 칸 가요. 앞으로, 뒤로, 회전을 섞으면 같은 길도 여러 방법으로 갈 수 있어요.",
            tip: "여러 방법 중 블럭이 가장 적은 길이 좋은 풀이예요.",
            unlock: .block(.moveBackward),
            example: .blocks([Block(type: .moveForward), Block(type: .moveBackward)])),

        LearningCard(
            id: "block.turnLeft", category: .block, title: "왼쪽 회전",
            summary: "제자리에서 왼쪽으로 90도 돌아요.",
            body: "위치는 그대로이고 바라보는 방향만 바뀌어요. 이동 블럭은 항상 바라보는 방향을 기준으로 움직여서, 회전이 길을 정해 줘요.",
            tip: "왼쪽으로 네 번 돌면 처음 방향으로 돌아와요.",
            unlock: .block(.turnLeft),
            example: .blocks([Block(type: .turnLeft), Block(type: .moveForward)])),

        LearningCard(
            id: "block.turnRight", category: .block, title: "오른쪽 회전",
            summary: "제자리에서 오른쪽으로 90도 돌아요.",
            body: "위치는 그대로이고 바라보는 방향만 바뀌어요. 앞으로 가다 모퉁이를 만나면 회전 블럭으로 방향을 바꿔요.",
            tip: "오른쪽 회전 세 번은 왼쪽 회전 한 번과 같아요.",
            unlock: .block(.turnRight),
            example: .blocks([Block(type: .moveForward), Block(type: .turnRight), Block(type: .moveForward)])),

        LearningCard(
            id: "block.repeat", category: .block, title: "반복",
            summary: "같은 동작을 정해진 횟수만큼 되풀이해요.",
            body: "앞으로를 열 번 쌓는 대신 반복 블럭 안에 앞으로를 넣고 횟수를 10으로 정하면 돼요. 코드에서는 for 반복문이에요. 같은 일을 짧게 쓰면 실수도 줄어요.",
            tip: "블럭 수가 줄어서 별 3개를 얻기 쉬워져요.",
            unlock: .block(.repeatBlock),
            example: .blocks([Block(type: .repeatBlock, repeatCount: 3, children: [Block(type: .moveForward)])])),

        LearningCard(
            id: "block.if", category: .block, title: "만약에",
            summary: "조건이 맞을 때만 안의 블럭을 실행해요.",
            body: "앞이 막혀 있는지 같은 상황을 보고 움직임을 고를 수 있어요. 코드에서는 if 조건문이에요. 조건이 맞지 않으면 안의 블럭은 건너뛰어요.",
            tip: "앞이 뚫려 있으면, 앞이 막혀 있으면 두 가지 조건이 있어요.",
            unlock: .block(.ifBlock),
            example: .blocks([Block(type: .ifBlock, children: [Block(type: .turnRight)], ifCondition: .pathBlocked)])),

        LearningCard(
            id: "block.function", category: .block, title: "함수",
            summary: "여러 블럭을 하나로 묶어 이름을 붙여요.",
            body: "자주 쓰는 동작 묶음을 하나로 묶으면 코드가 읽기 쉬워져요. 코드로 보면 step1() 처럼 이름 붙인 함수가 위에 정의되고, 그 자리에서 불러 써요.",
            tip: "코드로 보기에서 함수 블럭이 보조 함수가 되는 모습을 확인해 보세요.",
            unlock: .block(.functionBlock),
            example: .blocks([Block(type: .functionBlock, children: [Block(type: .moveForward), Block(type: .turnRight)])])),

        LearningCard(
            id: "block.collectItem", category: .block, title: "보석 획득",
            summary: "지금 서 있는 칸의 보석을 주워요.",
            body: "보석이 있는 칸에서만 성공해요. 다른 칸에서 쓰면 실패하니, 먼저 이동한 다음 정확한 위치에서 써야 해요. 보석을 다 모아야 별 3개를 받을 수 있어요.",
            tip: "보석 칸에 도착한 바로 다음에 놓으면 돼요.",
            unlock: .block(.collectItem),
            example: .blocks([Block(type: .moveForward), Block(type: .collectItem)])),

        LearningCard(
            id: "block.activateSwitch", category: .block, title: "스위치 작동",
            summary: "서 있는 칸의 스위치를 눌러 문을 열어요.",
            body: "스위치가 있는 칸에서만 작동해요. 스위치를 누르면 닫혀 있던 문이 열려서 막혀 있던 길로 갈 수 있어요. 누르는 순서가 틀리면 길이 막힌 채로 남아요.",
            tip: "문을 지나기 전에 스위치를 먼저 눌러야 해요.",
            unlock: .block(.activateSwitch),
            example: .blocks([Block(type: .moveForward), Block(type: .activateSwitch), Block(type: .moveForward)])),

        // 개념 카드 — 블럭 하나가 처음 나오면 함께 열림
        LearningCard(
            id: "concept.sequence", category: .block, title: "순서가 곧 논리",
            summary: "컴퓨터는 위에서 아래로, 쓴 순서대로 실행해요.",
            body: "같은 블럭이라도 순서가 바뀌면 결과가 달라져요. 앞으로 다음에 오른쪽 회전과, 오른쪽 회전 다음에 앞으로는 가는 곳이 달라요. 이렇게 차례대로 실행하는 것을 순차 실행이라고 해요.",
            tip: "막히면 단계별 실행으로 한 칸씩 따라가 보세요.",
            unlock: .block(.moveForward),
            example: .blocks([Block(type: .moveForward), Block(type: .turnRight), Block(type: .moveForward)])),

        LearningCard(
            id: "concept.nesting", category: .block, title: "블럭 안의 블럭",
            summary: "반복이나 조건 안에 또 다른 반복이나 조건을 넣을 수 있어요.",
            body: "이런 구조를 중첩이라고 해요. 코드에서는 for 안에 for를 쓰는 것처럼 들여쓰기가 한 단계 깊어져요. 안쪽 반복은 바깥 반복의 횟수만큼 다시 실행돼요.",
            tip: "2번 반복 안에 3번 반복이 있으면 안쪽 동작은 모두 6번 실행돼요.",
            unlock: .block(.repeatBlock),
            example: .blocks([Block(type: .repeatBlock, repeatCount: 2, children: [
                Block(type: .repeatBlock, repeatCount: 3, children: [Block(type: .moveForward)]),
                Block(type: .turnRight)])])),

        LearningCard(
            id: "concept.fewerBlocks", category: .block, title: "적은 블럭이 좋은 코드",
            summary: "같은 일을 더 짧게 쓰는 것이 좋은 코드예요.",
            body: "별 3개의 기준이 블럭 수인 이유예요. 짧은 코드는 읽기 쉽고 고치기 쉬워요. 같은 부분이 보이면 반복이나 함수로 묶어 보세요.",
            tip: "일일 퍼즐에서 최단 블럭 수에 도전해 보세요.",
            unlock: .block(.repeatBlock),
            example: nil),
    ]

    // MARK: - 코딩 기초 · CS 기초 (카드 글은 다음 단계에서 채움)

    private static let codingCards: [LearningCard] = []
    private static let csCards: [LearningCard] = []
}
