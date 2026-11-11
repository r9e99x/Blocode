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

    // MARK: - 코딩 기초 (처음부터 열려 있음)

    /// 다섯 언어 코드 예시를 한 번에 만드는 도우미 — 모든 언어를 빠짐없이 채워야 함 (테스트가 확인)
    private static func code(swift: String, python: String, c: String, cpp: String, java: String) -> LearningCard.Example {
        .text([.swift: swift, .python: python, .c: c, .cpp: cpp, .java: java])
    }

    private static let codingCards: [LearningCard] = [
        LearningCard(
            id: "coding.variable", category: .coding, title: "변수",
            summary: "값을 담아 두는 이름표 붙은 상자예요.",
            body: "점수나 위치처럼 바뀌는 값을 이름을 붙여 저장해 두고, 나중에 그 이름으로 꺼내 써요. 같은 이름에 새 값을 넣으면 이전 값은 덮어써져요.",
            tip: "이름은 값의 뜻이 보이게 지으면 코드가 읽기 쉬워져요. (예: x 보다 score)",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                var score = 10
                score = score + 5   // 이제 15
                """#,
                python: #"""
                score = 10
                score = score + 5   # 이제 15
                """#,
                c: #"""
                int score = 10;
                score = score + 5;   // 이제 15
                """#,
                cpp: #"""
                int score = 10;
                score = score + 5;   // 이제 15
                """#,
                java: #"""
                int score = 10;
                score = score + 5;   // 이제 15
                """#)),

        LearningCard(
            id: "coding.types", category: .coding, title: "자료형",
            summary: "값의 종류예요. 정수, 소수, 글자, 참/거짓이 기본이에요.",
            body: "컴퓨터는 값의 종류를 구분해서 다뤄요. 3은 정수, 1.5는 소수, \"Blocode\"는 문자열, 참과 거짓은 불리언이에요. 종류가 다르면 할 수 있는 계산도 달라요.",
            tip: "Python은 종류를 자동으로 알아내고, Swift·C·C++·Java는 대부분 종류를 분명히 적어요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                let age: Int = 20
                let price: Double = 1.5
                let name: String = "Blocode"
                let isOpen: Bool = true
                """#,
                python: #"""
                age = 20
                price = 1.5
                name = "Blocode"
                is_open = True
                """#,
                c: #"""
                int age = 20;
                double price = 1.5;
                char name[] = "Blocode";
                int is_open = 1;   // 참/거짓을 정수(1/0)로 나타내요
                """#,
                cpp: #"""
                int age = 20;
                double price = 1.5;
                string name = "Blocode";
                bool isOpen = true;
                """#,
                java: #"""
                int age = 20;
                double price = 1.5;
                String name = "Blocode";
                boolean isOpen = true;
                """#)),

        LearningCard(
            id: "coding.operators", category: .coding, title: "연산자",
            summary: "값을 계산하고 비교하는 기호예요.",
            body: "+, -, *, / 로 계산하고, 나머지는 % 로 구해요. 두 값을 비교하는 ==, !=, <, > 는 결과가 참이나 거짓으로 나와서 조건문과 함께 많이 써요.",
            tip: "= 는 \"넣는다\", == 는 \"같은지 비교한다\"는 뜻이라 서로 달라요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                let a = 7
                let b = 3
                print(a + b)   // 10
                print(a % b)   // 1 (나머지)
                print(a > b)   // true
                """#,
                python: #"""
                a = 7
                b = 3
                print(a + b)   # 10
                print(a % b)   # 1 (나머지)
                print(a > b)   # True
                """#,
                c: #"""
                int a = 7, b = 3;
                printf("%d\n", a + b);   // 10
                printf("%d\n", a % b);   // 1 (나머지)
                printf("%d\n", a > b);   // 1 (참)
                """#,
                cpp: #"""
                int a = 7, b = 3;
                cout << a + b << endl;     // 10
                cout << a % b << endl;     // 1 (나머지)
                cout << (a > b) << endl;   // 1 (참)
                """#,
                java: #"""
                int a = 7, b = 3;
                System.out.println(a + b);   // 10
                System.out.println(a % b);   // 1 (나머지)
                System.out.println(a > b);   // true
                """#)),

        LearningCard(
            id: "coding.conditional", category: .coding, title: "조건문",
            summary: "조건이 참일 때와 아닐 때 다른 일을 해요.",
            body: "if 는 조건이 참일 때만 실행하고, else 를 붙이면 참이 아닐 때 실행할 일을 정해요. 블럭의 \"만약에\"가 이 if 예요.",
            tip: "조건이 여러 개면 else if 로 이어 붙일 수 있어요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                if hp > 0 {
                    print("살아 있어요")
                } else {
                    print("쓰러졌어요")
                }
                """#,
                python: #"""
                if hp > 0:
                    print("살아 있어요")
                else:
                    print("쓰러졌어요")
                """#,
                c: #"""
                if (hp > 0) {
                    printf("살아 있어요\n");
                } else {
                    printf("쓰러졌어요\n");
                }
                """#,
                cpp: #"""
                if (hp > 0) {
                    cout << "살아 있어요" << endl;
                } else {
                    cout << "쓰러졌어요" << endl;
                }
                """#,
                java: #"""
                if (hp > 0) {
                    System.out.println("살아 있어요");
                } else {
                    System.out.println("쓰러졌어요");
                }
                """#)),

        LearningCard(
            id: "coding.loops", category: .coding, title: "반복문",
            summary: "같은 일을 여러 번 되풀이해요. for 와 while 두 가지가 기본이에요.",
            body: "정해진 횟수만큼 돌릴 땐 for, 조건이 참인 동안 계속 돌릴 땐 while 을 써요. while 은 조건이 영원히 참이면 끝나지 않으니, 반복 안에서 조건이 바뀌게 해야 해요.",
            tip: "블럭의 \"반복\"은 for 와 같고, 반복 횟수가 정해져 있어요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                var n = 3
                while n > 0 {
                    print(n)   // 3, 2, 1
                    n -= 1
                }
                """#,
                python: #"""
                n = 3
                while n > 0:
                    print(n)   # 3, 2, 1
                    n -= 1
                """#,
                c: #"""
                int n = 3;
                while (n > 0) {
                    printf("%d\n", n);   // 3, 2, 1
                    n--;
                }
                """#,
                cpp: #"""
                int n = 3;
                while (n > 0) {
                    cout << n << endl;   // 3, 2, 1
                    n--;
                }
                """#,
                java: #"""
                int n = 3;
                while (n > 0) {
                    System.out.println(n);   // 3, 2, 1
                    n--;
                }
                """#)),

        LearningCard(
            id: "coding.function", category: .coding, title: "함수와 반환값",
            summary: "이름 붙인 코드 묶음이에요. 값을 받고 결과를 돌려줄 수 있어요.",
            body: "자주 쓰는 일을 함수로 묶으면 필요한 곳에서 이름만 불러 쓸 수 있어요. 함수는 입력(인자)을 받아 계산하고, return 으로 결과(반환값)를 돌려줘요.",
            tip: "함수 하나는 한 가지 일만 하게 만들면 고치기 쉬워요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                func add(_ a: Int, _ b: Int) -> Int {
                    return a + b
                }
                // add(2, 3) 의 결과는 5
                """#,
                python: #"""
                def add(a, b):
                    return a + b

                # add(2, 3) 의 결과는 5
                """#,
                c: #"""
                int add(int a, int b) {
                    return a + b;
                }
                // add(2, 3) 의 결과는 5
                """#,
                cpp: #"""
                int add(int a, int b) {
                    return a + b;
                }
                // add(2, 3) 의 결과는 5
                """#,
                java: #"""
                static int add(int a, int b) {
                    return a + b;
                }
                // add(2, 3) 의 결과는 5
                """#)),

        LearningCard(
            id: "coding.array", category: .coding, title: "배열(리스트)",
            summary: "여러 값을 순서대로 한 줄로 담아 두는 묶음이에요.",
            body: "점수 여러 개처럼 같은 종류의 값을 한꺼번에 저장해요. 각 값은 번호(인덱스)로 꺼내는데, 번호는 1이 아니라 0부터 시작해요. 반복문과 함께 쓰면 모든 값을 차례로 다룰 수 있어요.",
            tip: "C와 Java의 배열은 만들 때 크기가 정해지고, Python·Swift·C++의 리스트는 나중에 늘릴 수 있어요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                var scores = [80, 95, 70]
                print(scores[0])   // 80 (번호는 0부터)
                scores.append(100)
                """#,
                python: #"""
                scores = [80, 95, 70]
                print(scores[0])   # 80 (번호는 0부터)
                scores.append(100)
                """#,
                c: #"""
                int scores[3] = {80, 95, 70};
                int first = scores[0];   // 80 (번호는 0부터)
                """#,
                cpp: #"""
                vector<int> scores = {80, 95, 70};
                int first = scores[0];   // 80 (번호는 0부터)
                scores.push_back(100);
                """#,
                java: #"""
                int[] scores = {80, 95, 70};
                int first = scores[0];   // 80 (번호는 0부터)
                """#)),

        LearningCard(
            id: "coding.string", category: .coding, title: "문자열",
            summary: "글자들을 이어 붙인 값이에요.",
            body: "\"안녕\", \"Blocode\"처럼 따옴표로 감싼 글자의 나열이에요. 문자열끼리 이어 붙이거나, 일부를 잘라 내거나, 길이를 셀 수 있어요. 숫자 10과 문자열 \"10\"은 다른 값이에요.",
            tip: "C에서는 문자열이 글자 배열이라 + 로 이어 붙일 수 없어요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                let name = "Block" + "ode"   // "Blocode"
                """#,
                python: #"""
                name = "Block" + "ode"   # "Blocode"
                """#,
                c: #"""
                char name[] = "Blocode";   // 글자 배열이라 + 로 이어 붙일 수 없어요
                """#,
                cpp: #"""
                string name = string("Block") + "ode";   // "Blocode"
                """#,
                java: #"""
                String name = "Block" + "ode";   // "Blocode"
                """#)),

        LearningCard(
            id: "coding.debugging", category: .coding, title: "디버깅",
            summary: "버그(실수)를 찾아 고치는 과정이에요.",
            body: "코드가 생각대로 움직이지 않을 땐, 어디까지는 맞고 어디부터 틀어지는지 좁혀 가며 원인을 찾아요. 값을 출력해 보거나, 한 줄씩 따라가며 확인해요. 이 앱의 단계별 실행이 바로 이 방법이에요.",
            tip: "추측하지 말고 직접 확인하는 것이 가장 빠른 길이에요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "coding.comments", category: .coding, title: "주석",
            summary: "사람을 위한 설명이에요. 컴퓨터는 실행하지 않아요.",
            body: "코드 옆에 왜 이렇게 썼는지 적어 두면 나중에 읽기 쉬워요. 주석은 실행에 영향을 주지 않아요. 코드를 잠시 꺼 둘 때도 써요.",
            tip: "무엇을 하는지보다 왜 그렇게 했는지를 적으면 좋아요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                // 한 줄 주석
                var score = 10   // 점수
                """#,
                python: #"""
                # 한 줄 주석
                score = 10   # 점수
                """#,
                c: #"""
                // 한 줄 주석
                int score = 10;   // 점수
                """#,
                cpp: #"""
                // 한 줄 주석
                int score = 10;   // 점수
                """#,
                java: #"""
                // 한 줄 주석
                int score = 10;   // 점수
                """#)),

        LearningCard(
            id: "coding.naming", category: .coding, title: "읽기 쉬운 코드",
            summary: "이름과 모양만 잘 지어도 코드가 달라 보여요.",
            body: "변수와 함수 이름은 뜻이 보이게 짓고, 같은 규칙으로 통일해요. Python과 C는 move_forward 처럼 밑줄로 잇고, Swift·Java는 moveForward 처럼 대문자로 이어요. 들여쓰기로 구조도 보여 줘요.",
            tip: "코드는 쓰는 시간보다 읽는 시간이 훨씬 길어요.",
            unlock: .alwaysOpen,
            example: nil),
    ]

    // MARK: - CS 기초 (처음부터 열려 있음)

    private static let csCards: [LearningCard] = [
        LearningCard(
            id: "cs.algorithm", category: .cs, title: "알고리즘",
            summary: "문제를 푸는 단계별 절차예요.",
            body: "요리 레시피처럼 정해진 순서대로 따라 하면 답이 나오는 방법이에요. 같은 문제도 여러 알고리즘으로 풀 수 있고, 더 빠르거나 더 적은 자원을 쓰는 방법이 좋은 알고리즘이에요. 이 앱의 퍼즐 풀이도 하나의 알고리즘이에요.",
            tip: "같은 길을 가는 블럭 조합이 여러 개인 것처럼, 알고리즘도 하나가 아니에요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.binary", category: .cs, title: "이진수와 비트",
            summary: "컴퓨터는 0과 1로만 모든 것을 표현해요.",
            body: "전기가 켜짐/꺼짐 두 상태를 쓰기 때문에 값을 0과 1로 적어요. 이 하나를 비트라고 하고, 8비트가 1바이트예요. 10진수 5는 이진수로 101이고, 1바이트로는 0부터 255까지 나타낼 수 있어요.",
            tip: "자리가 하나 늘 때마다 표현할 수 있는 값의 수가 두 배가 돼요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.compiler", category: .cs, title: "컴파일러와 인터프리터",
            summary: "사람이 쓴 코드를 컴퓨터가 실행하게 바꿔 주는 도구예요.",
            body: "C, C++, Swift는 실행 전에 컴파일러가 코드를 기계어로 한 번에 바꿔서 빠르게 실행해요. Python은 인터프리터가 코드를 읽어 가며 바로 실행하는 방식이 기본이에요. Java는 중간 코드로 컴파일한 뒤 가상 머신이 실행해요.",
            tip: "컴파일 방식은 실행 전에 문법 오류를 미리 알려 주는 경우가 많아요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.memory", category: .cs, title: "메모리와 스택",
            summary: "프로그램이 값을 잠깐 올려 두는 작업 공간이에요.",
            body: "변수의 값은 메모리에 저장돼요. 함수를 부르면 그 함수가 쓸 공간이 쌓이고, 함수가 끝나면 맨 위부터 하나씩 치워져요. 이렇게 먼저 들어간 것이 나중에 나오는 구조가 스택이에요.",
            tip: "함수 안에서 만든 변수는 함수가 끝나면 사라져요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.complexity", category: .cs, title: "시간복잡도",
            summary: "입력이 커질 때 걸리는 시간이 얼마나 늘어나는지 재는 감각이에요.",
            body: "값이 n개일 때 n번 도는 코드는 O(n), 반복 안에 반복이 있으면 보통 O(n²)이에요. n이 10배가 되면 O(n)은 10배, O(n²)은 100배 느려져요. 입력이 작을 땐 티가 안 나지만 커질수록 차이가 커요.",
            tip: "이 앱에서 반복 안에 반복을 쓰면 실행하는 칸 수가 곱해지는 것과 같아요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.searchsort", category: .cs, title: "탐색과 정렬",
            summary: "값을 찾는 방법과 순서대로 늘어놓는 방법이에요.",
            body: "하나씩 처음부터 확인하는 방법은 단순하지만 느려요. 이미 정렬된 목록은 가운데 값과 비교해 절반씩 버리며 찾는 이진 탐색을 쓸 수 있어서, 100만 개도 스무 번 안팎의 비교로 찾아요.",
            tip: "정렬해 두면 찾기가 훨씬 빨라져요. 사전이 가나다순인 이유예요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.recursion", category: .cs, title: "재귀",
            summary: "함수가 자기 자신을 다시 불러서 문제를 쪼개 풀어요.",
            body: "큰 문제를 같은 모양의 더 작은 문제로 나누고, 더 쪼갤 수 없는 가장 작은 경우에서 멈추는 방식이에요. 멈추는 조건이 없으면 계속 불러서 스택이 넘쳐요. 아래는 1부터 n까지 곱하는 팩토리얼이에요.",
            tip: "반복문으로 바꿔 쓸 수 있는 경우가 많지만, 재귀가 더 짧고 자연스러운 문제도 있어요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                func factorial(_ n: Int) -> Int {
                    if n <= 1 { return 1 }   // 멈추는 조건
                    return n * factorial(n - 1)
                }
                """#,
                python: #"""
                def factorial(n):
                    if n <= 1:
                        return 1   # 멈추는 조건
                    return n * factorial(n - 1)
                """#,
                c: #"""
                int factorial(int n) {
                    if (n <= 1) { return 1; }   // 멈추는 조건
                    return n * factorial(n - 1);
                }
                """#,
                cpp: #"""
                int factorial(int n) {
                    if (n <= 1) { return 1; }   // 멈추는 조건
                    return n * factorial(n - 1);
                }
                """#,
                java: #"""
                static int factorial(int n) {
                    if (n <= 1) { return 1; }   // 멈추는 조건
                    return n * factorial(n - 1);
                }
                """#)),

        LearningCard(
            id: "cs.datastructure", category: .cs, title: "자료구조: 스택과 큐",
            summary: "값을 담는 방식과 꺼내는 순서를 정한 틀이에요.",
            body: "스택은 마지막에 넣은 것을 먼저 꺼내요. 쌓아 둔 접시를 위에서부터 집는 것과 같아요. 큐는 먼저 넣은 것을 먼저 꺼내요. 줄 서서 기다리는 것과 같아요. 문제에 맞는 구조를 고르면 코드가 간단해져요.",
            tip: "되돌리기(undo)는 스택, 인쇄 대기열은 큐가 대표적인 예예요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.os", category: .cs, title: "운영체제와 프로세스",
            summary: "프로그램들이 컴퓨터 자원을 나눠 쓰도록 관리하는 소프트웨어예요.",
            body: "운영체제는 CPU, 메모리, 저장 장치를 여러 프로그램에 나눠 주고 서로 방해하지 않게 지켜 줘요. 실행 중인 프로그램 하나를 프로세스라고 하고, 한 프로세스 안에서 동시에 일하는 흐름을 스레드라고 해요. 여러 앱이 동시에 도는 것처럼 보이는 건 빠르게 번갈아 실행하거나 여러 코어에 나눠 실행하기 때문이에요.",
            tip: "iOS, macOS, Windows, Android가 모두 운영체제예요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.clientserver", category: .cs, title: "클라이언트와 서버",
            summary: "요청하는 쪽과 응답하는 쪽이에요.",
            body: "앱이나 웹 브라우저가 서버에 요청을 보내면, 서버가 데이터를 찾아 응답으로 돌려줘요. 서버는 여러 사용자의 요청을 동시에 받아요. 앱은 받은 응답을 화면에 보여 주는 역할을 해요.",
            tip: "이 앱은 지금 서버 없이 기기 안에서만 동작해요.",
            unlock: .alwaysOpen,
            example: nil),
    ]
}
