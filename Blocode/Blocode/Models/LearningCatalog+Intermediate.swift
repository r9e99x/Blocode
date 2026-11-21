//
//  LearningCatalog+Intermediate.swift
//  Blocode
//
//  Created by 조준희 on 11/22/26.
//

import Foundation

// MARK: - 중급 카드 (처음부터 열려 있음)
/// 초급을 마친 뒤 만나는 개념 15장 — 코딩 8장, CS 7장
/// 코드 예시는 `code(swift:python:c:cpp:java:)`로 다섯 언어를 모두 채움 (C에 없는 기능은 주석으로 이유를 적음)
extension LearningCatalog {

    static let intermediateCards: [LearningCard] = [

        // MARK: 코딩

        LearningCard(
            id: "intermediate.class", category: .intermediate, topic: .coding, title: "클래스와 객체",
            summary: "데이터와 그 데이터를 다루는 동작을 한 덩어리로 묶은 설계도예요.",
            body: "클래스는 설계도이고, 객체는 그 설계도로 만든 실제 물건이에요. 캐릭터라면 위치(데이터)와 앞으로 가기(동작)를 하나로 묶어 두고, 객체를 여러 개 만들어 각자 따로 움직이게 할 수 있어요.",
            tip: "C에는 클래스가 없어서 struct와 함수를 짝지어 비슷하게 써요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                class Robot {
                    var x = 0
                    func moveForward() { x += 1 }
                }

                let robot = Robot()
                robot.moveForward()   // robot.x 는 1
                """#,
                python: #"""
                class Robot:
                    def __init__(self):
                        self.x = 0

                    def move_forward(self):
                        self.x += 1

                robot = Robot()
                robot.move_forward()   # robot.x 는 1
                """#,
                c: #"""
                typedef struct { int x; } Robot;

                void move_forward(Robot *robot) { robot->x += 1; }

                Robot robot = {0};
                move_forward(&robot);   // robot.x 는 1
                """#,
                cpp: #"""
                class Robot {
                public:
                    int x = 0;
                    void moveForward() { x += 1; }
                };

                Robot robot;
                robot.moveForward();   // robot.x 는 1
                """#,
                java: #"""
                class Robot {
                    int x = 0;
                    void moveForward() { x += 1; }
                }

                Robot robot = new Robot();
                robot.moveForward();   // robot.x 는 1
                """#)),

        LearningCard(
            id: "intermediate.dictionary", category: .intermediate, topic: .coding, title: "딕셔너리(맵)",
            summary: "이름표(키)로 값을 찾는 저장 방식이에요.",
            body: "배열은 번호로 값을 찾지만, 딕셔너리는 'minsu' 같은 이름표(키)로 값을 찾아요. 학생 이름으로 점수를 찾는 것처럼 이름과 값이 짝일 때 편해요. 같은 키는 하나만 있을 수 있어요.",
            tip: "언어에 따라 Dictionary, dict, Map, HashMap이라고 불러요. C에는 기본으로 들어 있지 않아요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                var scores = ["minsu": 90, "jia": 85]
                scores["hajun"] = 77
                print(scores["minsu"] ?? 0)   // 90
                """#,
                python: #"""
                scores = {"minsu": 90, "jia": 85}
                scores["hajun"] = 77
                print(scores["minsu"])   # 90
                """#,
                c: #"""
                // C에는 딕셔너리가 없어서 이름 배열과 점수 배열을 짝지어 찾아요 (string.h 필요)
                const char *names[] = {"minsu", "jia"};
                int scores[] = {90, 85};

                for (int i = 0; i < 2; i++) {
                    if (strcmp(names[i], "minsu") == 0) {
                        printf("%d\n", scores[i]);   // 90
                    }
                }
                """#,
                cpp: #"""
                #include <map>
                #include <string>

                std::map<std::string, int> scores = {{"minsu", 90}, {"jia", 85}};
                scores["hajun"] = 77;
                int minsu = scores["minsu"];   // 90
                """#,
                java: #"""
                Map<String, Integer> scores = new HashMap<>();
                scores.put("minsu", 90);
                scores.put("jia", 85);
                int minsu = scores.get("minsu");   // 90
                """#)),

        LearningCard(
            id: "intermediate.exception", category: .intermediate, topic: .coding, title: "예외 처리",
            summary: "실패할 수 있는 일을 미리 대비해서 프로그램이 멈추지 않게 해요.",
            body: "파일이 없거나 0으로 나누는 것처럼 잘못될 수 있는 상황을 예외라고 해요. try로 시도하고, 실패하면 catch(Python은 except)에서 대신 할 일을 정해요. 대비하지 않으면 프로그램이 그 자리에서 멈춰요.",
            tip: "에러를 조용히 무시하면 원인을 찾기 어려워져요. 최소한 무슨 일이 있었는지는 남겨 두세요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                enum MathError: Error { case divideByZero }

                func divide(_ a: Int, _ b: Int) throws -> Int {
                    if b == 0 { throw MathError.divideByZero }
                    return a / b
                }

                do {
                    let result = try divide(10, 0)
                    print(result)
                } catch {
                    print("0으로 나눌 수 없어요")
                }
                """#,
                python: #"""
                try:
                    result = 10 / 0
                except ZeroDivisionError:
                    print("0으로 나눌 수 없어요")
                """#,
                c: #"""
                // C에는 예외가 없어서 반환값으로 성공/실패를 알려요
                int divide(int a, int b, int *result) {
                    if (b == 0) return -1;   // 실패
                    *result = a / b;
                    return 0;                // 성공
                }

                int result;
                if (divide(10, 0, &result) != 0) {
                    printf("0으로 나눌 수 없어요\n");
                }
                """#,
                cpp: #"""
                #include <stdexcept>

                try {
                    int b = 0;
                    if (b == 0) throw std::runtime_error("divide by zero");
                } catch (const std::exception &e) {
                    // 여기서 대신 할 일을 정해요
                }
                """#,
                java: #"""
                try {
                    int result = 10 / 0;
                } catch (ArithmeticException e) {
                    System.out.println("0으로 나눌 수 없어요");
                }
                """#)),

        LearningCard(
            id: "intermediate.closure", category: .intermediate, topic: .coding, title: "클로저와 람다",
            summary: "이름 없이 만들어 값처럼 넘길 수 있는 작은 함수예요.",
            body: "함수를 변수에 담거나 다른 함수에 인자로 넘길 수 있어요. 그 자리에서 이름 없이 만든 짧은 함수를 Swift에서는 클로저, Python·C++·Java에서는 람다라고 불러요. 정렬 기준이나 버튼을 눌렀을 때 할 일을 넘길 때 자주 써요.",
            tip: "클로저는 만들어진 곳의 변수를 기억해 두었다가 나중에 불릴 때 써요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                let twice = { (n: Int) in n * 2 }
                print(twice(4))   // 8

                let descending = [3, 1, 2].sorted { $0 > $1 }   // [3, 2, 1]
                """#,
                python: #"""
                twice = lambda n: n * 2
                print(twice(4))   # 8

                descending = sorted([3, 1, 2], key=lambda n: -n)   # [3, 2, 1]
                """#,
                c: #"""
                // C에는 람다가 없어서 함수 이름(함수 포인터)을 넘겨요
                int twice(int n) { return n * 2; }

                int apply(int (*f)(int), int n) { return f(n); }

                int result = apply(twice, 4);   // 8
                """#,
                cpp: #"""
                auto twice = [](int n) { return n * 2; };
                int result = twice(4);   // 8
                """#,
                java: #"""
                Function<Integer, Integer> twice = n -> n * 2;
                int result = twice.apply(4);   // 8
                """#)),

        LearningCard(
            id: "intermediate.mapfilter", category: .intermediate, topic: .coding, title: "map과 filter",
            summary: "목록을 한꺼번에 바꾸거나 걸러 내는 도구예요.",
            body: "map은 목록의 모든 값에 같은 일을 해서 새 목록을 만들고, filter는 조건에 맞는 값만 남겨요. 반복문을 직접 쓰지 않아도 돼서 짧고 읽기 쉬워요. 원래 목록은 그대로 두고 새 목록을 돌려줘요.",
            tip: "map과 filter를 이어 붙이면 '짝수만 골라서 두 배로' 같은 말을 그대로 코드로 쓸 수 있어요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                let numbers = [1, 2, 3, 4]
                let evens = numbers.filter { $0 % 2 == 0 }   // [2, 4]
                let doubled = evens.map { $0 * 2 }           // [4, 8]
                """#,
                python: #"""
                numbers = [1, 2, 3, 4]
                evens = [n for n in numbers if n % 2 == 0]   # [2, 4]
                doubled = [n * 2 for n in evens]             # [4, 8]
                """#,
                c: #"""
                int numbers[] = {1, 2, 3, 4};
                int doubled[4];
                int count = 0;

                for (int i = 0; i < 4; i++) {
                    if (numbers[i] % 2 == 0) {              // 거르기 (filter)
                        doubled[count++] = numbers[i] * 2;  // 바꾸기 (map)
                    }
                }
                // doubled 는 {4, 8}, count 는 2
                """#,
                cpp: #"""
                #include <vector>

                std::vector<int> numbers = {1, 2, 3, 4};
                std::vector<int> doubled;

                for (int n : numbers) {
                    if (n % 2 == 0) doubled.push_back(n * 2);   // {4, 8}
                }
                """#,
                java: #"""
                List<Integer> numbers = List.of(1, 2, 3, 4);
                List<Integer> doubled = numbers.stream()
                    .filter(n -> n % 2 == 0)
                    .map(n -> n * 2)
                    .toList();   // [4, 8]
                """#)),

        LearningCard(
            id: "intermediate.scope", category: .intermediate, topic: .coding, title: "스코프(변수의 유효 범위)",
            summary: "변수를 쓸 수 있는 범위예요.",
            body: "함수나 중괄호 안에서 만든 변수는 그 안에서만 쓸 수 있어요. 바깥에서 만든 변수는 안쪽에서도 보이지만, 안쪽에서 만든 변수는 바깥에서 보이지 않아요. 범위를 좁게 쓰면 실수로 값을 바꾸는 일이 줄어요.",
            tip: "전역 변수는 어디서든 바뀔 수 있어서 버그를 찾기 어려워져요. 꼭 필요할 때만 쓰세요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                let total = 10             // 바깥(전역) 변수

                func show() {
                    let message = "합계"    // 이 함수 안에서만 보여요
                    print(message, total)
                }

                show()
                // print(message)  ← 오류: 여기서는 message 가 보이지 않아요
                """#,
                python: #"""
                total = 10                 # 바깥(전역) 변수

                def show():
                    message = "합계"        # 이 함수 안에서만 보여요
                    print(message, total)

                show()
                # print(message)  ← 오류: 여기서는 message 가 보이지 않아요
                """#,
                c: #"""
                int total = 10;            // 바깥(전역) 변수

                void show(void) {
                    char *message = "합계"; // 이 함수 안에서만 보여요
                    printf("%s %d\n", message, total);
                }
                // 다른 함수에서 message 를 쓰면 오류
                """#,
                cpp: #"""
                int total = 10;            // 바깥(전역) 변수

                void show() {
                    std::string message = "합계";   // 이 함수 안에서만 보여요
                    std::cout << message << total;
                }
                // 다른 함수에서 message 를 쓰면 오류
                """#,
                java: #"""
                class Main {
                    static int total = 10;   // 클래스 전체에서 보여요

                    static void show() {
                        String message = "합계";   // 이 메서드 안에서만 보여요
                        System.out.println(message + total);
                    }
                }
                """#)),

        LearningCard(
            id: "intermediate.unittest", category: .intermediate, topic: .coding, title: "단위 테스트",
            summary: "작은 기능이 맞게 동작하는지 코드로 자동 확인해요.",
            body: "함수에 입력을 주고 기대한 결과가 나오는지 확인하는 코드를 따로 써 두는 거예요. 코드를 고칠 때마다 테스트를 돌리면 어딘가 망가졌는지 바로 알 수 있어요. 이 앱도 퍼즐 규칙을 수백 개의 테스트로 지키고 있어요.",
            tip: "버그를 고칠 때 그 버그를 재현하는 테스트를 먼저 쓰면 같은 버그가 다시 생기는 걸 막아 줘요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                func add(_ a: Int, _ b: Int) -> Int { a + b }

                assert(add(2, 3) == 5)
                assert(add(-1, 1) == 0)
                // 실제 프로젝트에서는 Swift Testing 의 @Test 와 #expect 를 써요
                """#,
                python: #"""
                def add(a, b):
                    return a + b

                assert add(2, 3) == 5
                assert add(-1, 1) == 0
                # 실제 프로젝트에서는 pytest 를 많이 써요
                """#,
                c: #"""
                #include <assert.h>

                int add(int a, int b) { return a + b; }

                int main(void) {
                    assert(add(2, 3) == 5);
                    assert(add(-1, 1) == 0);
                    return 0;
                }
                """#,
                cpp: #"""
                #include <cassert>

                int add(int a, int b) { return a + b; }

                int main() {
                    assert(add(2, 3) == 5);
                    assert(add(-1, 1) == 0);
                }
                """#,
                java: #"""
                static int add(int a, int b) { return a + b; }

                // 실행할 때 java -ea 옵션을 켜야 assert 가 검사돼요
                assert add(2, 3) == 5;
                assert add(-1, 1) == 0;
                // 실제 프로젝트에서는 JUnit 을 써요
                """#)),

        LearningCard(
            id: "intermediate.git", category: .intermediate, topic: .coding, title: "Git과 버전 관리",
            summary: "코드의 변경 기록을 저장하고 언제든 되돌릴 수 있게 해 줘요.",
            body: "커밋은 '지금 상태'를 설명과 함께 저장하는 거예요. 잘못 고쳐도 이전 커밋으로 돌아갈 수 있고, 브랜치로 원래 코드를 건드리지 않은 채 새 기능을 실험할 수 있어요. 여럿이 함께 개발할 때 서로의 변경을 합치는 데에도 써요.",
            tip: "커밋 메시지에 '무엇을 왜 바꿨는지'를 한 줄로 적으면 나중에 기록을 읽기 쉬워요.",
            unlock: .alwaysOpen,
            example: nil),

        // MARK: CS

        LearningCard(
            id: "intermediate.hash", category: .intermediate, topic: .cs, title: "해시 테이블",
            summary: "키를 숫자로 바꿔서 값을 바로 찾는 자료구조예요.",
            body: "해시 함수가 키를 배열 칸 번호로 바꿔 주니까, 처음부터 뒤지지 않고 그 칸으로 곧장 가요. 그래서 평균적으로 아주 빠르게 찾고, 넣고, 지울 수 있어요. 서로 다른 키가 같은 칸에 걸리는 충돌은 칸마다 목록을 달아 두는 식으로 해결해요.",
            tip: "딕셔너리, HashMap, set은 대부분 해시 테이블로 만들어져 있어요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "intermediate.linkedlist", category: .intermediate, topic: .cs, title: "배열과 연결 리스트",
            summary: "배열은 번호로 바로 접근하고, 연결 리스트는 중간에 끼우기 쉬워요.",
            body: "배열은 값들이 붙어서 저장되어 번호로 바로 찾을 수 있지만, 중간에 끼우려면 뒤쪽을 전부 밀어야 해요. 연결 리스트는 각 칸이 다음 칸의 위치를 들고 있어서 끼우고 빼기는 쉽지만, n번째를 찾으려면 처음부터 따라가야 해요.",
            tip: "실제로는 배열이 메모리를 효율적으로 쓰는 덕분에 더 빠른 경우가 많아서 기본으로 많이 써요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "intermediate.tree", category: .intermediate, topic: .cs, title: "트리",
            summary: "뿌리에서 가지가 갈라지는 계층 구조예요.",
            body: "폴더 안에 폴더가 있는 구조처럼, 하나의 뿌리에서 자식 노드들이 갈라져 나가요. 이진 트리는 자식이 최대 둘이고, 이진 탐색 트리는 왼쪽엔 작은 값 오른쪽엔 큰 값을 두어서 빠르게 찾을 수 있어요. 이 앱의 '블럭 안의 블럭'도 트리 모양이에요.",
            tip: "화면의 뷰 계층과 HTML 문서도 트리예요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "intermediate.binarysearch", category: .intermediate, topic: .cs, title: "이진 탐색",
            summary: "정렬된 목록에서 절반씩 버려 가며 찾아요.",
            body: "가운데 값과 찾는 값을 비교해서, 더 큰지 작은지에 따라 절반을 통째로 버려요. 1000개도 10번 안에, 100만 개도 20번 안에 찾아요. 단, 목록이 미리 정렬되어 있어야 해요.",
            tip: "시간복잡도로는 O(log n)이에요. 데이터가 두 배가 되어도 한 번만 더 비교하면 돼요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                func binarySearch(_ list: [Int], _ target: Int) -> Int? {
                    var low = 0
                    var high = list.count - 1
                    while low <= high {
                        let mid = (low + high) / 2
                        if list[mid] == target { return mid }
                        if list[mid] < target { low = mid + 1 } else { high = mid - 1 }
                    }
                    return nil   // 없음
                }
                """#,
                python: #"""
                def binary_search(items, target):
                    low, high = 0, len(items) - 1
                    while low <= high:
                        mid = (low + high) // 2
                        if items[mid] == target:
                            return mid
                        if items[mid] < target:
                            low = mid + 1
                        else:
                            high = mid - 1
                    return -1   # 없음
                """#,
                c: #"""
                int binary_search(int items[], int count, int target) {
                    int low = 0, high = count - 1;
                    while (low <= high) {
                        int mid = (low + high) / 2;
                        if (items[mid] == target) return mid;
                        if (items[mid] < target) low = mid + 1;
                        else high = mid - 1;
                    }
                    return -1;   // 없음
                }
                """#,
                cpp: #"""
                int binarySearch(const std::vector<int> &items, int target) {
                    int low = 0, high = (int)items.size() - 1;
                    while (low <= high) {
                        int mid = (low + high) / 2;
                        if (items[mid] == target) return mid;
                        if (items[mid] < target) low = mid + 1;
                        else high = mid - 1;
                    }
                    return -1;   // 없음
                }
                """#,
                java: #"""
                static int binarySearch(int[] items, int target) {
                    int low = 0, high = items.length - 1;
                    while (low <= high) {
                        int mid = (low + high) / 2;
                        if (items[mid] == target) return mid;
                        if (items[mid] < target) low = mid + 1;
                        else high = mid - 1;
                    }
                    return -1;   // 없음
                }
                """#)),

        LearningCard(
            id: "intermediate.process", category: .intermediate, topic: .cs, title: "프로세스와 스레드",
            summary: "프로세스는 실행 중인 프로그램, 스레드는 그 안의 작업 흐름이에요.",
            body: "앱 하나를 켜면 프로세스가 하나 생기고 자기만의 메모리를 가져요. 한 프로세스 안에서는 여러 스레드가 같은 메모리를 나눠 쓰며 동시에 일할 수 있어요. 화면을 그리는 스레드와 파일을 내려받는 스레드를 나누면 앱이 멈춘 것처럼 보이지 않아요.",
            tip: "스레드끼리 같은 데이터를 건드리면 문제가 생길 수 있어서 조심해야 해요. 고급에서 자세히 다뤄요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "intermediate.http", category: .intermediate, topic: .cs, title: "HTTP와 API",
            summary: "앱과 서버가 약속된 형식으로 요청과 응답을 주고받아요.",
            body: "앱이 서버에 GET이나 POST 같은 요청을 보내면 서버가 결과를 응답으로 돌려줘요. 응답에는 200(성공), 404(없음) 같은 상태 코드가 붙고, 내용은 보통 JSON 형식이에요. 서버가 이렇게 쓸 수 있게 열어 둔 창구를 API라고 해요.",
            tip: "상태 코드가 4로 시작하면 요청한 쪽의 문제, 5로 시작하면 서버 쪽 문제예요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "intermediate.database", category: .intermediate, topic: .cs, title: "데이터베이스와 SQL",
            summary: "데이터를 표 형태로 오래 저장하고, 질문으로 꺼내 써요.",
            body: "관계형 데이터베이스는 데이터를 행과 열이 있는 표로 저장해요. SQL로 조회(SELECT), 추가(INSERT), 수정(UPDATE), 삭제(DELETE)를 해요. 표들을 서로 연결해서 '이 학생이 듣는 수업' 같은 것도 한 번에 찾을 수 있어요.",
            tip: "인덱스를 만들어 두면 조회가 빨라지는 대신 저장이 조금 느려져요.",
            unlock: .alwaysOpen,
            example: nil),
    ]
}
