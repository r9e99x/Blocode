//
//  LearningCatalog+Beginner.swift
//  Blocode
//
//  Created by 조준희 on 11/24/26.
//

import Foundation

// MARK: - 초급 카드 (처음부터 열려 있음)
/// 처음 시작하는 개념 29장 — 코딩 15장, CS 14장
/// 카드를 더할 땐 갈래에 맞는 배열 끝에 이어 붙이면 됨. 코드 예시는 `code(swift:python:c:cpp:java:)`로 다섯 언어를 모두 채움
extension LearningCatalog {

    // MARK: 코딩

    static let beginnerCodingCards: [LearningCard] = [
        LearningCard(
            id: "coding.variable", category: .beginner, topic: .coding, title: "변수",
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
            id: "coding.types", category: .beginner, topic: .coding, title: "자료형",
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
            id: "coding.operators", category: .beginner, topic: .coding, title: "연산자",
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
            id: "coding.conditional", category: .beginner, topic: .coding, title: "조건문",
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
            id: "coding.loops", category: .beginner, topic: .coding, title: "반복문",
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
            id: "coding.function", category: .beginner, topic: .coding, title: "함수와 반환값",
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
            id: "coding.array", category: .beginner, topic: .coding, title: "배열(리스트)",
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
            id: "coding.string", category: .beginner, topic: .coding, title: "문자열",
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
            id: "coding.debugging", category: .beginner, topic: .coding, title: "디버깅",
            summary: "버그(실수)를 찾아 고치는 과정이에요.",
            body: "코드가 생각대로 움직이지 않을 땐, 어디까지는 맞고 어디부터 틀어지는지 좁혀 가며 원인을 찾아요. 값을 출력해 보거나, 한 줄씩 따라가며 확인해요. 이 앱의 단계별 실행이 바로 이 방법이에요.",
            tip: "추측하지 말고 직접 확인하는 것이 가장 빠른 길이에요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "coding.comments", category: .beginner, topic: .coding, title: "주석",
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
            id: "coding.naming", category: .beginner, topic: .coding, title: "읽기 쉬운 코드",
            summary: "이름과 모양만 잘 지어도 코드가 달라 보여요.",
            body: "변수와 함수 이름은 뜻이 보이게 짓고, 같은 규칙으로 통일해요. Python과 C는 move_forward 처럼 밑줄로 잇고, Swift·Java는 moveForward 처럼 대문자로 이어요. 들여쓰기로 구조도 보여 줘요.",
            tip: "코드는 쓰는 시간보다 읽는 시간이 훨씬 길어요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "coding.io", category: .beginner, topic: .coding, title: "입력과 출력",
            summary: "프로그램이 사용자에게 보여 주고, 사용자에게서 받는 방법이에요.",
            body: "출력은 화면에 글자를 보여 주는 일이고, 입력은 사용자가 넣은 값을 프로그램이 받아 오는 일이에요. 계산기든 게임이든 입력을 받아 처리하고 결과를 출력해요. 입력은 대부분 글자로 들어와서, 숫자로 쓰려면 숫자로 바꿔 줘야 해요.",
            tip: "막힐 땐 값을 출력해서 코드가 어떻게 움직이는지 직접 확인해 보세요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                print("이름을 입력하세요")
                let name = readLine() ?? ""
                print("안녕하세요, \(name)님!")
                """#,
                python: #"""
                print("이름을 입력하세요")
                name = input()
                print(f"안녕하세요, {name}님!")
                """#,
                c: #"""
                #include <stdio.h>

                char name[50];
                printf("이름을 입력하세요\n");
                scanf("%49s", name);
                printf("안녕하세요, %s님!\n", name);
                """#,
                cpp: #"""
                #include <iostream>
                #include <string>

                std::string name;
                std::cout << "이름을 입력하세요\n";
                std::cin >> name;
                std::cout << "안녕하세요, " << name << "님!\n";
                """#,
                java: #"""
                Scanner scanner = new Scanner(System.in);
                System.out.println("이름을 입력하세요");
                String name = scanner.next();
                System.out.println("안녕하세요, " + name + "님!");
                """#)),

        LearningCard(
            id: "coding.boolean", category: .beginner, topic: .coding, title: "불리언과 비교",
            summary: "참과 거짓, 두 값으로 질문에 답해요.",
            body: "점수가 60 이상인가요? 같은 질문의 답은 참 아니면 거짓이에요. 이런 두 값을 불리언이라고 해요. 비교 연산자(>, <=, ==)가 불리언을 만들고, 조건문과 반복문이 그 값을 보고 움직여요. 그리고(&&), 또는(||), 아니다(!)로 여러 조건을 합칠 수 있어요.",
            tip: "같은지 비교할 때는 =가 아니라 ==를 써요. =는 값을 넣는 기호예요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                let score = 75
                let passed = score >= 60            // true
                let perfect = score == 100          // false
                let canRetry = !passed || perfect   // false
                """#,
                python: #"""
                score = 75
                passed = score >= 60                # True
                perfect = score == 100              # False
                can_retry = not passed or perfect   # False
                """#,
                c: #"""
                #include <stdbool.h>

                int score = 75;
                bool passed = score >= 60;            // true
                bool perfect = score == 100;          // false
                bool canRetry = !passed || perfect;   // false
                """#,
                cpp: #"""
                int score = 75;
                bool passed = score >= 60;            // true
                bool perfect = score == 100;          // false
                bool canRetry = !passed || perfect;   // false
                """#,
                java: #"""
                int score = 75;
                boolean passed = score >= 60;            // true
                boolean perfect = score == 100;          // false
                boolean canRetry = !passed || perfect;   // false
                """#)),

        LearningCard(
            id: "coding.constant", category: .beginner, topic: .coding, title: "상수",
            summary: "한 번 정하면 바뀌지 않는 값이에요.",
            body: "게임의 최대 체력이나 한 줄의 칸 수처럼 프로그램 내내 같아야 하는 값은 상수로 만들어요. 실수로 바꾸려 하면 컴파일러가 막아 주고, 숫자에 이름이 붙어서 뜻이 보여요. 나중에 값을 바꿀 때도 한 곳만 고치면 돼요.",
            tip: "코드에 갑자기 나오는 숫자(예: 76)에 이름을 붙이면 무슨 뜻인지 바로 보여요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                let maxHealth = 100
                var health = maxHealth
                health -= 30                 // 70
                // maxHealth = 50            // 오류: 상수는 바꿀 수 없어요
                """#,
                python: #"""
                MAX_HEALTH = 100             # 대문자는 "바꾸지 말자"는 약속이에요 (막아 주지는 않아요)
                health = MAX_HEALTH
                health -= 30                 # 70
                """#,
                c: #"""
                const int MAX_HEALTH = 100;
                int health = MAX_HEALTH;
                health -= 30;                // 70
                // MAX_HEALTH = 50;          // 오류: const는 바꿀 수 없어요
                """#,
                cpp: #"""
                const int MAX_HEALTH = 100;
                int health = MAX_HEALTH;
                health -= 30;                // 70
                // MAX_HEALTH = 50;          // 오류: const는 바꿀 수 없어요
                """#,
                java: #"""
                final int MAX_HEALTH = 100;
                int health = MAX_HEALTH;
                health -= 30;                // 70
                // MAX_HEALTH = 50;          // 오류: final은 바꿀 수 없어요
                """#)),

        LearningCard(
            id: "coding.nothing", category: .beginner, topic: .coding, title: "값이 없음: nil과 null",
            summary: "'아직 값이 없다'는 상태를 나타내는 특별한 값이에요.",
            body: "친구 목록에서 이름을 찾았는데 없으면 무엇을 돌려줄까요? 0이나 빈 글자와는 다른 '아무것도 없음'이 필요해요. Swift는 nil, Python은 None, Java는 null, C와 C++는 NULL이나 nullptr로 나타내요. 값이 없는 상태에서 그 값을 쓰려고 하면 앱이 멈추기 쉬워서 쓰기 전에 항상 확인해야 해요.",
            tip: "Swift의 옵셔널(?)은 이 확인을 잊지 않도록 컴파일러가 강제해 주는 장치예요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                let ages = ["지민": 20, "서준": 22]
                let age = ages["하늘"]          // nil — 없는 이름이에요
                if let age {
                    print("나이는 \(age)")
                } else {
                    print("찾을 수 없어요")
                }
                """#,
                python: #"""
                ages = {"지민": 20, "서준": 22}
                age = ages.get("하늘")          # None — 없는 이름이에요
                if age is not None:
                    print(f"나이는 {age}")
                else:
                    print("찾을 수 없어요")
                """#,
                c: #"""
                int *found = NULL;                 // 아직 가리키는 곳이 없어요

                if (found != NULL) {
                    printf("나이는 %d\n", *found);
                } else {
                    printf("찾을 수 없어요\n");
                }
                """#,
                cpp: #"""
                int *found = nullptr;              // 아직 가리키는 곳이 없어요

                if (found != nullptr) {
                    std::cout << "나이는 " << *found << "\n";
                } else {
                    std::cout << "찾을 수 없어요\n";
                }
                """#,
                java: #"""
                Map<String, Integer> ages = Map.of("지민", 20, "서준", 22);
                Integer age = ages.get("하늘");    // null — 없는 이름이에요
                if (age != null) {
                    System.out.println("나이는 " + age);
                } else {
                    System.out.println("찾을 수 없어요");
                }
                """#)),
    ]

    // MARK: CS

    static let beginnerCSCards: [LearningCard] = [
        LearningCard(
            id: "cs.algorithm", category: .beginner, topic: .cs, title: "알고리즘",
            summary: "문제를 푸는 단계별 절차예요.",
            body: "요리 레시피처럼 정해진 순서대로 따라 하면 답이 나오는 방법이에요. 같은 문제도 여러 알고리즘으로 풀 수 있고, 더 빠르거나 더 적은 자원을 쓰는 방법이 좋은 알고리즘이에요. 이 앱의 퍼즐 풀이도 하나의 알고리즘이에요.",
            tip: "같은 길을 가는 블럭 조합이 여러 개인 것처럼, 알고리즘도 하나가 아니에요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.binary", category: .beginner, topic: .cs, title: "이진수와 비트",
            summary: "컴퓨터는 0과 1로만 모든 것을 표현해요.",
            body: "전기가 켜짐/꺼짐 두 상태를 쓰기 때문에 값을 0과 1로 적어요. 이 하나를 비트라고 하고, 8비트가 1바이트예요. 10진수 5는 이진수로 101이고, 1바이트로는 0부터 255까지 나타낼 수 있어요.",
            tip: "자리가 하나 늘 때마다 표현할 수 있는 값의 수가 두 배가 돼요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.compiler", category: .beginner, topic: .cs, title: "컴파일러와 인터프리터",
            summary: "사람이 쓴 코드를 컴퓨터가 실행하게 바꿔 주는 도구예요.",
            body: "C, C++, Swift는 실행 전에 컴파일러가 코드를 기계어로 한 번에 바꿔서 빠르게 실행해요. Python은 인터프리터가 코드를 읽어 가며 바로 실행하는 방식이 기본이에요. Java는 중간 코드로 컴파일한 뒤 가상 머신이 실행해요.",
            tip: "컴파일 방식은 실행 전에 문법 오류를 미리 알려 주는 경우가 많아요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.memory", category: .beginner, topic: .cs, title: "메모리와 스택",
            summary: "프로그램이 값을 잠깐 올려 두는 작업 공간이에요.",
            body: "변수의 값은 메모리에 저장돼요. 함수를 부르면 그 함수가 쓸 공간이 쌓이고, 함수가 끝나면 맨 위부터 하나씩 치워져요. 이렇게 먼저 들어간 것이 나중에 나오는 구조가 스택이에요.",
            tip: "함수 안에서 만든 변수는 함수가 끝나면 사라져요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.complexity", category: .beginner, topic: .cs, title: "시간복잡도",
            summary: "입력이 커질 때 걸리는 시간이 얼마나 늘어나는지 재는 감각이에요.",
            body: "값이 n개일 때 n번 도는 코드는 O(n), 반복 안에 반복이 있으면 보통 O(n²)이에요. n이 10배가 되면 O(n)은 10배, O(n²)은 100배 느려져요. 입력이 작을 땐 티가 안 나지만 커질수록 차이가 커요.",
            tip: "이 앱에서 반복 안에 반복을 쓰면 실행하는 칸 수가 곱해지는 것과 같아요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.searchsort", category: .beginner, topic: .cs, title: "탐색과 정렬",
            summary: "값을 찾는 방법과 순서대로 늘어놓는 방법이에요.",
            body: "하나씩 처음부터 확인하는 방법은 단순하지만 느려요. 이미 정렬된 목록은 가운데 값과 비교해 절반씩 버리며 찾는 이진 탐색을 쓸 수 있어서, 100만 개도 스무 번 안팎의 비교로 찾아요.",
            tip: "정렬해 두면 찾기가 훨씬 빨라져요. 사전이 가나다순인 이유예요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.recursion", category: .beginner, topic: .cs, title: "재귀",
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
            id: "cs.datastructure", category: .beginner, topic: .cs, title: "자료구조: 스택과 큐",
            summary: "값을 담는 방식과 꺼내는 순서를 정한 틀이에요.",
            body: "스택은 마지막에 넣은 것을 먼저 꺼내요. 쌓아 둔 접시를 위에서부터 집는 것과 같아요. 큐는 먼저 넣은 것을 먼저 꺼내요. 줄 서서 기다리는 것과 같아요. 문제에 맞는 구조를 고르면 코드가 간단해져요.",
            tip: "되돌리기(undo)는 스택, 인쇄 대기열은 큐가 대표적인 예예요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.os", category: .beginner, topic: .cs, title: "운영체제와 프로세스",
            summary: "프로그램들이 컴퓨터 자원을 나눠 쓰도록 관리하는 소프트웨어예요.",
            body: "운영체제는 CPU, 메모리, 저장 장치를 여러 프로그램에 나눠 주고 서로 방해하지 않게 지켜 줘요. 실행 중인 프로그램 하나를 프로세스라고 하고, 한 프로세스 안에서 동시에 일하는 흐름을 스레드라고 해요. 여러 앱이 동시에 도는 것처럼 보이는 건 빠르게 번갈아 실행하거나 여러 코어에 나눠 실행하기 때문이에요.",
            tip: "iOS, macOS, Windows, Android가 모두 운영체제예요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.clientserver", category: .beginner, topic: .cs, title: "클라이언트와 서버",
            summary: "요청하는 쪽과 응답하는 쪽이에요.",
            body: "앱이나 웹 브라우저가 서버에 요청을 보내면, 서버가 데이터를 찾아 응답으로 돌려줘요. 서버는 여러 사용자의 요청을 동시에 받아요. 앱은 받은 응답을 화면에 보여 주는 역할을 해요.",
            tip: "이 앱은 지금 서버 없이 기기 안에서만 동작해요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.cpu", category: .beginner, topic: .cs, title: "CPU와 클럭",
            summary: "명령을 하나씩 가져와 해석하고 실행하는 컴퓨터의 계산 담당이에요.",
            body: "CPU는 메모리에서 명령을 하나 가져와서 무슨 뜻인지 해석하고 실행하는 일을 엄청나게 빠르게 되풀이해요. 1초에 이 일을 몇 번 할 수 있는지가 클럭이고 GHz로 나타내요. 코어가 여러 개면 서로 다른 일을 동시에 처리할 수 있어요.",
            tip: "메모리는 작업대, 저장 장치는 서랍이라고 생각하면 쉬워요. CPU는 작업대 위의 것만 바로 다룰 수 있어요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.filesystem", category: .beginner, topic: .cs, title: "파일과 폴더",
            summary: "데이터에 이름을 붙여 저장하고 폴더로 정리하는 방법이에요.",
            body: "저장 장치의 데이터는 파일로 나뉘고, 파일은 폴더 안에 나무처럼 계층으로 정리돼요. 파일의 위치를 적은 것이 경로예요. /Users/me/a.txt처럼 맨 위부터 적으면 절대 경로이고, 지금 있는 위치 기준으로 적으면 상대 경로예요. 앱도 설정과 기록을 파일로 저장해 둬요.",
            tip: "앱은 보통 자기 전용 폴더 안에서만 읽고 쓸 수 있어서, 다른 앱의 파일은 함부로 볼 수 없어요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.internet", category: .beginner, topic: .cs, title: "인터넷과 IP 주소",
            summary: "전 세계 컴퓨터가 주소를 알고 데이터를 주고받는 네트워크예요.",
            body: "인터넷에 연결된 기기에는 IP 주소라는 번호가 있어요. 번호는 외우기 어려워서 example.com 같은 도메인 이름을 쓰고, DNS가 이름을 IP 주소로 바꿔 줘요. 데이터는 작은 조각(패킷)으로 나뉘어 여러 길로 목적지까지 가서 다시 합쳐져요.",
            tip: "주소창에 이름을 치면 이름 찾기(DNS), 서버 연결, 요청 보내기 순서로 일이 일어나요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "cs.pseudocode", category: .beginner, topic: .cs, title: "의사코드와 순서도",
            summary: "코드를 쓰기 전에 순서를 사람의 말로 먼저 정리해요.",
            body: "의사코드는 프로그래밍 언어의 문법 없이 순서를 말로 적은 설계 초안이고, 순서도는 그 순서를 그림으로 그린 거예요. '점수가 60 이상이면 합격, 아니면 불합격'처럼 적어요. 흐름을 먼저 정리하면 어떤 언어로든 옮기기 쉬워요. Blocode에서 블럭을 쌓는 것도 같은 연습이에요.",
            tip: "막막할 땐 코드를 열기 전에 종이에 해야 할 일을 세 줄로 적어 보세요.",
            unlock: .alwaysOpen,
            example: nil),
    ]
}
