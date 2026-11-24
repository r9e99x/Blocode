//
//  LearningCatalog+Advanced.swift
//  Blocode
//
//  Created by 조준희 on 11/22/26.
//

import Foundation

// MARK: - 고급 카드 (처음부터 열려 있음)
/// 실무와 면접에서 자주 나오는 개념 23장 — 코딩 12장, CS 11장 (카드를 더할 땐 갈래에 맞는 자리 끝에 이어 붙이면 됨)
/// 코드 예시는 비교가 잘 되는 카드(인터페이스·제네릭·불변성·동적 계획법)에만 다섯 언어로 채움
extension LearningCatalog {

    static let advancedCards: [LearningCard] = [

        // MARK: 코딩

        LearningCard(
            id: "advanced.protocol", category: .advanced, topic: .coding, title: "인터페이스와 프로토콜",
            summary: "'이런 일을 할 수 있어야 한다'는 약속만 정해 두는 거예요.",
            body: "인터페이스(Swift에서는 프로토콜)는 구현 없이 어떤 동작을 할 수 있는지만 약속해요. 새와 비행기는 전혀 다르지만 둘 다 '날 수 있다'는 약속만 지키면 같은 방식으로 다룰 수 있어요. 구체적인 종류를 몰라도 코드를 짤 수 있어서 바꾸고 테스트하기가 쉬워져요.",
            tip: "'무엇을 할지'와 '어떻게 할지'를 나누는 것이 좋은 설계의 출발점이에요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                protocol Flyable {
                    func fly()
                }

                struct Bird: Flyable {
                    func fly() { print("날갯짓으로 날아요") }
                }

                func takeOff(_ thing: Flyable) { thing.fly() }
                takeOff(Bird())
                """#,
                python: #"""
                from typing import Protocol

                class Flyable(Protocol):
                    def fly(self) -> None: ...

                class Bird:
                    def fly(self) -> None:
                        print("날갯짓으로 날아요")

                def take_off(thing: Flyable) -> None:
                    thing.fly()

                take_off(Bird())
                """#,
                c: #"""
                // C에는 인터페이스가 없어서 함수 포인터를 담은 구조체로 약속을 표현해요
                typedef struct {
                    void (*fly)(void);
                } Flyable;

                void bird_fly(void) { printf("날갯짓으로 날아요\n"); }

                void take_off(Flyable thing) { thing.fly(); }

                Flyable bird = { bird_fly };
                take_off(bird);
                """#,
                cpp: #"""
                class Flyable {
                public:
                    virtual void fly() = 0;   // 구현 없는 약속
                    virtual ~Flyable() = default;
                };

                class Bird : public Flyable {
                public:
                    void fly() override { std::cout << "날갯짓으로 날아요\n"; }
                };

                void takeOff(Flyable &thing) { thing.fly(); }
                """#,
                java: #"""
                interface Flyable {
                    void fly();
                }

                class Bird implements Flyable {
                    public void fly() { System.out.println("날갯짓으로 날아요"); }
                }

                static void takeOff(Flyable thing) { thing.fly(); }
                """#)),

        LearningCard(
            id: "advanced.generic", category: .advanced, topic: .coding, title: "제네릭",
            summary: "담을 종류를 나중에 정하는 틀이에요.",
            body: "숫자 상자, 글자 상자를 따로 만드는 대신 '무언가를 담는 상자'를 한 번만 만들고, 담을 종류는 쓸 때 정해요. 코드 중복이 없어지고, 종류가 안 맞으면 실행 전에 알려 줘요. 배열과 딕셔너리도 제네릭으로 만들어져 있어요.",
            tip: "Python은 종류를 따로 적지 않아도 돼서 타입 힌트로만 표시해요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                struct Box<T> {
                    var value: T
                }

                let number = Box(value: 3)        // Box<Int>
                let word = Box(value: "block")    // Box<String>
                """#,
                python: #"""
                from typing import Generic, TypeVar

                T = TypeVar("T")

                class Box(Generic[T]):
                    def __init__(self, value: T):
                        self.value = value

                number = Box(3)        # Box[int]
                word = Box("block")    # Box[str]
                """#,
                c: #"""
                // C에는 제네릭이 없어서 매크로 같은 방법으로 흉내 내요
                #define MAX(a, b) ((a) > (b) ? (a) : (b))

                int bigger = MAX(3, 7);          // 정수에도
                double longer = MAX(1.5, 0.5);   // 소수에도 쓸 수 있어요
                """#,
                cpp: #"""
                template <typename T>
                struct Box {
                    T value;
                };

                Box<int> number{3};
                Box<std::string> word{"block"};
                """#,
                java: #"""
                class Box<T> {
                    T value;
                    Box(T value) { this.value = value; }
                }

                Box<Integer> number = new Box<>(3);
                Box<String> word = new Box<>("block");
                """#)),

        LearningCard(
            id: "advanced.async", category: .advanced, topic: .coding, title: "비동기와 async/await",
            summary: "기다리는 동안 다른 일을 할 수 있게 해 줘요.",
            body: "서버 응답이나 파일 읽기는 오래 걸려요. 그동안 화면이 멈추면 안 되니까, 작업을 맡겨 두고 다른 일을 하다가 끝나면 이어서 처리해요. async/await는 이 흐름을 위에서 아래로 읽히는 코드로 쓰게 해 줘요. Swift와 Python이 지원하고, Java와 C++은 Future 같은 다른 도구를 써요.",
            tip: "화면을 그리는 메인 스레드에서 오래 걸리는 일을 직접 하면 앱이 버벅여요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.race", category: .advanced, topic: .coding, title: "동시성과 경쟁 상태",
            summary: "여럿이 같은 값을 동시에 바꾸면 결과가 엉킬 수 있어요.",
            body: "두 스레드가 점수 10을 동시에 읽고 각자 1을 더해 쓰면, 12가 아니라 11이 돼요. 이런 타이밍 문제를 경쟁 상태라고 하고, 매번 일어나지 않아서 찾기 어려운 버그예요. 락이나 Swift의 actor처럼 한 번에 하나만 접근하게 막아서 해결해요.",
            tip: "가장 좋은 방법은 여럿이 함께 쓰는 데이터 자체를 줄이는 거예요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.pattern", category: .advanced, topic: .coding, title: "디자인 패턴",
            summary: "자주 만나는 설계 문제의 검증된 해법이에요.",
            body: "싱글턴은 객체를 하나만 두고 공유하고, 옵저버는 값이 바뀌면 구독한 쪽에 알려 주고, 팩토리는 객체 만드는 일을 한곳에 모아요. 이름이 정해져 있어서 개발자끼리 '여기는 옵저버로 하자' 한마디로 설계를 나눌 수 있어요. 이 앱의 설정 저장소도 하나만 공유하는 싱글턴이에요.",
            tip: "패턴을 외워서 쓰기보다 문제가 생겼을 때 맞는 패턴을 떠올리는 게 중요해요. 억지로 쓰면 코드가 오히려 복잡해져요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.mvvm", category: .advanced, topic: .coding, title: "MVC와 MVVM",
            summary: "화면, 데이터, 규칙을 나눠 담는 앱 구조예요.",
            body: "Model은 데이터와 규칙, View는 화면, ViewModel은 화면이 쓸 상태를 가공해서 View에 건네주는 역할이에요. 화면과 로직이 섞이지 않아서 화면 없이도 로직을 테스트할 수 있어요. 이 앱도 퍼즐 규칙은 Model, 화면은 View, 그 사이는 ViewModel이 맡아요.",
            tip: "MVC는 Controller가 화면과 데이터를 이어 주는데, 커지면 Controller가 너무 뚱뚱해지기 쉬워요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.di", category: .advanced, topic: .coding, title: "의존성 주입",
            summary: "필요한 것을 안에서 만들지 않고 밖에서 받아요.",
            body: "클래스가 필요한 저장소나 서버 연결을 직접 만들면, 테스트할 때도 진짜를 쓸 수밖에 없어요. 대신 만들 때 밖에서 넣어 주면 테스트에서는 가짜를 넣을 수 있어요. 이 앱의 테스트도 진행도 저장소를 격리된 것으로 바꿔 끼워서 돌려요.",
            tip: "모든 걸 주입하려 하기보다, 테스트하기 어렵게 만드는 것부터 바깥에서 받도록 바꿔 보세요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.memory", category: .advanced, topic: .coding, title: "메모리 관리: ARC와 GC",
            summary: "쓰지 않는 메모리를 언제 치울지 정하는 방식이에요.",
            body: "Swift는 참조 개수를 세는 ARC를 써서, 개수가 0이 되면 바로 치워요. Java는 쓰이지 않는 객체를 가끔 찾아 치우는 가비지 컬렉터를 쓰고, Python은 참조 개수와 가비지 컬렉터를 함께 써요. C와 C++은 개발자가 직접 만들고 해제하는 일이 많아요.",
            tip: "서로를 붙잡는 순환 참조가 생기면 ARC는 영영 치우지 못해서, weak으로 한쪽을 끊어 줘야 해요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.solid", category: .advanced, topic: .coding, title: "SOLID 원칙",
            summary: "유지보수하기 좋은 객체지향 설계의 다섯 가지 길잡이예요.",
            body: "단일 책임(한 클래스는 한 가지 일만), 개방-폐쇄(확장에는 열려 있고 수정에는 닫혀 있게), 리스코프 치환(자식은 부모 자리에 들어가도 문제없게), 인터페이스 분리(쓰지 않는 기능을 강요하지 않기), 의존성 역전(구체적인 클래스 대신 추상에 의존하기)의 앞글자예요. 규칙이라기보다 코드가 커져도 고치기 쉽게 하려는 경험에서 나온 방향이에요.",
            tip: "처음부터 전부 지키려 하지 말고, 한 클래스가 너무 많은 일을 하거나 수정이 여러 곳으로 번질 때 떠올리세요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.immutable", category: .advanced, topic: .coding, title: "불변성과 함수형 프로그래밍",
            summary: "값을 바꾸지 않고 새 값을 만들어서 버그를 줄여요.",
            body: "불변 값은 한 번 만들면 바뀌지 않아요. 어디선가 몰래 값이 바뀌는 일이 없어서 예측하기 쉽고, 여러 스레드가 동시에 읽어도 안전해요. 함수형 프로그래밍은 같은 입력이면 항상 같은 출력을 내고 바깥 상태를 바꾸지 않는 순수한 함수를 조립해서 프로그램을 만드는 방식이에요.",
            tip: "Swift의 let과 struct, map과 filter 같은 함수가 이런 생각에서 나왔어요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                let original = [1, 2, 3]
                let doubled = original.map { $0 * 2 }   // 새 배열을 만들어요
                print(original, doubled)                // [1, 2, 3] [2, 4, 6]
                """#,
                python: #"""
                original = [1, 2, 3]
                doubled = [n * 2 for n in original]   # 새 리스트를 만들어요
                print(original, doubled)              # [1, 2, 3] [2, 4, 6]
                """#,
                c: #"""
                const int original[] = {1, 2, 3};
                int doubled[3];
                for (int i = 0; i < 3; i++) doubled[i] = original[i] * 2;   // 원본은 그대로 두고 새 배열을 채워요
                // original 은 {1, 2, 3}, doubled 는 {2, 4, 6}
                """#,
                cpp: #"""
                const std::vector<int> original = {1, 2, 3};
                std::vector<int> doubled;
                for (int n : original) doubled.push_back(n * 2);   // 원본은 그대로 두고 새 벡터를 만들어요
                // original 은 {1, 2, 3}, doubled 는 {2, 4, 6}
                """#,
                java: #"""
                List<Integer> original = List.of(1, 2, 3);   // 바꿀 수 없는 리스트
                List<Integer> doubled = original.stream().map(n -> n * 2).toList();
                System.out.println(original + " " + doubled);   // [1, 2, 3] [2, 4, 6]
                """#)),

        LearningCard(
            id: "advanced.tdd", category: .advanced, topic: .coding, title: "테스트 더블과 TDD",
            summary: "테스트를 먼저 쓰고, 진짜 대신 가짜를 끼워서 빠르게 확인해요.",
            body: "TDD는 실패하는 테스트를 먼저 쓰고, 통과할 만큼만 코드를 짜고, 코드를 정리하는 순서를 되풀이하는 개발 방식이에요. 네트워크나 데이터베이스처럼 느리고 불안정한 부분은 테스트에서 가짜(목, 스텁)로 바꿔 끼워서, 빠르고 항상 같은 결과가 나오게 만들어요.",
            tip: "가짜를 끼우려면 의존성 주입이 필요해요. 그래서 테스트하기 쉬운 코드는 설계도 좋은 경우가 많아요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.refactor", category: .advanced, topic: .coding, title: "리팩토링과 코드 스멜",
            summary: "동작은 그대로 두고 코드의 구조만 깔끔하게 고쳐요.",
            body: "리팩토링은 기능을 바꾸지 않고 읽기 쉽고 고치기 쉽게 정리하는 일이에요. 함수 하나가 너무 길거나, 같은 코드가 여러 곳에 복사돼 있거나, 이름이 뜻을 말해 주지 않는 것처럼 '뭔가 이상한 냄새'가 나는 신호를 코드 스멜이라고 불러요. 테스트가 있어야 고친 뒤에도 같은 동작인지 안심하고 확인할 수 있어요.",
            tip: "정리하는 중에 새 기능을 섞지 마세요. 정리하고, 테스트하고, 그다음에 기능을 더하는 순서로 나누세요.",
            unlock: .alwaysOpen,
            example: nil),

        // MARK: CS

        LearningCard(
            id: "advanced.graph", category: .advanced, topic: .cs, title: "그래프와 BFS·DFS",
            summary: "점과 선으로 관계를 나타내고, 길을 찾는 방법이에요.",
            body: "지도의 도시와 도로처럼 노드와 간선으로 이루어진 구조예요. BFS(너비 우선 탐색)는 가까운 곳부터 한 겹씩 넓게 탐색해서 가장 짧은 길을 찾을 수 있고, DFS(깊이 우선 탐색)는 한 길로 끝까지 갔다가 되돌아와요. 이 앱이 퍼즐의 가장 짧은 풀이를 찾는 것도 BFS예요.",
            tip: "BFS는 큐, DFS는 스택(또는 재귀)을 써서 구현해요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.dp", category: .advanced, topic: .cs, title: "동적 계획법",
            summary: "한 번 푼 작은 문제의 답을 저장해서 다시 풀지 않아요.",
            body: "피보나치 수를 그냥 재귀로 구하면 같은 값을 수없이 다시 계산해요. 한 번 구한 값을 표에 적어 두고 꺼내 쓰면 훨씬 빨라져요. 큰 문제를 겹치는 작은 문제로 나눌 수 있을 때 쓰는 방법이에요.",
            tip: "위에서 아래로 내려가며 저장하는 메모이제이션과, 아래에서 위로 표를 채우는 방식 두 가지가 있어요.",
            unlock: .alwaysOpen,
            example: code(
                swift: #"""
                var memo: [Int: Int] = [:]

                func fib(_ n: Int) -> Int {
                    if n < 2 { return n }
                    if let saved = memo[n] { return saved }   // 이미 구한 값
                    let result = fib(n - 1) + fib(n - 2)
                    memo[n] = result                           // 저장해 두기
                    return result
                }
                """#,
                python: #"""
                memo = {}

                def fib(n):
                    if n < 2:
                        return n
                    if n in memo:
                        return memo[n]                  # 이미 구한 값
                    memo[n] = fib(n - 1) + fib(n - 2)   # 저장해 두기
                    return memo[n]
                """#,
                c: #"""
                long long memo[91];   // 처음엔 모두 0 (n 이 90 이하일 때)

                long long fib(int n) {
                    if (n < 2) return n;
                    if (memo[n] != 0) return memo[n];    // 이미 구한 값
                    memo[n] = fib(n - 1) + fib(n - 2);   // 저장해 두기
                    return memo[n];
                }
                """#,
                cpp: #"""
                #include <unordered_map>

                std::unordered_map<int, long long> memo;

                long long fib(int n) {
                    if (n < 2) return n;
                    if (memo.count(n)) return memo[n];   // 이미 구한 값
                    long long result = fib(n - 1) + fib(n - 2);
                    memo[n] = result;                    // 저장해 두기
                    return result;
                }
                """#,
                java: #"""
                static Map<Integer, Long> memo = new HashMap<>();

                static long fib(int n) {
                    if (n < 2) return n;
                    if (memo.containsKey(n)) return memo.get(n);   // 이미 구한 값
                    long result = fib(n - 1) + fib(n - 2);
                    memo.put(n, result);                           // 저장해 두기
                    return result;
                }
                """#)),

        LearningCard(
            id: "advanced.mergesort", category: .advanced, topic: .cs, title: "정렬 알고리즘",
            summary: "반으로 나눠 각각 정렬한 뒤 합치는 빠른 정렬이에요.",
            body: "병합 정렬은 목록을 반으로 계속 쪼개고, 정렬된 두 조각을 앞에서부터 비교하며 하나로 합쳐요. 어떤 입력에서도 O(n log n)으로 일정하게 빨라요. 단순한 버블 정렬은 O(n²)이라 데이터가 커지면 훨씬 느려져요.",
            tip: "대부분의 언어 기본 정렬 함수는 이미 빠른 알고리즘을 써요. 직접 만들기보다 기본 정렬을 쓰세요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.deadlock", category: .advanced, topic: .cs, title: "교착 상태(데드락)",
            summary: "서로 상대가 가진 것을 기다리며 영원히 멈춰요.",
            body: "A는 열쇠 1을 쥐고 열쇠 2를 기다리고, B는 열쇠 2를 쥐고 열쇠 1을 기다리면 둘 다 영영 움직이지 못해요. 서로 양보 없이 자원을 붙잡고 있을 때 생겨요. 자원을 항상 같은 순서로 잡도록 정하면 피할 수 있어요.",
            tip: "앱이 오류 없이 그냥 멈춰 있다면 데드락을 의심해 볼 수 있어요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.virtualmemory", category: .advanced, topic: .cs, title: "가상 메모리",
            summary: "프로그램마다 자기만의 넓은 메모리가 있는 것처럼 보이게 해요.",
            body: "운영체제가 프로세스마다 가짜 주소 공간을 주고, 실제 메모리와의 연결을 관리해요. 덕분에 다른 프로그램의 메모리를 건드리지 못해서 안전하고, 실제 메모리가 모자라면 덜 쓰는 부분을 저장 장치로 내려 둬요. 내려 둔 부분을 다시 읽어 오느라 느려지는 현상을 스왑이라고 해요.",
            tip: "메모리를 너무 많이 쓰는 앱은 이런 이유로 갑자기 느려지거나 시스템에 의해 종료될 수 있어요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.tcp", category: .advanced, topic: .cs, title: "TCP와 네트워크 계층",
            summary: "데이터가 순서대로 빠짐없이 도착하도록 약속해요.",
            body: "인터넷은 여러 계층으로 나뉘어 있어요. IP가 목적지 주소로 데이터 조각(패킷)을 보내고, 그 위의 TCP가 조각이 사라지거나 순서가 바뀌면 다시 보내서 맞춰 줘요. HTTP 같은 앱 규약은 보통 TCP 위에서 동작해요.",
            tip: "속도가 중요한 영상 통화나 게임은 확인 과정을 줄인 UDP를 쓰기도 해요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.crypto", category: .advanced, topic: .cs, title: "해시와 암호화",
            summary: "비밀번호를 지키고, 데이터가 바뀌지 않았는지 확인해요.",
            body: "해시는 어떤 데이터든 고정된 길이의 지문으로 바꾸는 한 방향 계산이라서 되돌릴 수 없어요. 그래서 서버는 비밀번호 자체가 아니라 그 해시를 저장해요. 암호화는 열쇠가 있으면 원래 데이터로 되돌릴 수 있는 방식이고, HTTPS가 통신 내용을 이렇게 지켜 줘요.",
            tip: "해시와 암호화 알고리즘은 직접 만들지 말고 검증된 라이브러리를 쓰세요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.acid", category: .advanced, topic: .cs, title: "트랜잭션과 ACID",
            summary: "여러 단계의 작업을 전부 성공하거나 전부 취소해요.",
            body: "계좌 이체는 내 계좌에서 빼고 상대 계좌에 더하는 두 단계예요. 중간에 실패하면 돈이 사라지니, 둘을 하나로 묶어 전부 성공(커밋)하거나 전부 취소(롤백)해야 해요. 이 묶음이 트랜잭션이고, 원자성(전부 아니면 전무), 일관성(규칙 유지), 격리성(동시에 실행해도 서로 간섭하지 않음), 지속성(성공하면 장애가 나도 남음) 네 가지를 지켜요.",
            tip: "격리성이 약하면 다른 사람이 아직 끝나지 않은 중간 상태를 보게 될 수 있어서, 성능과 안전 사이에서 수준을 고를 수 있어요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.cap", category: .advanced, topic: .cs, title: "CAP 정리와 분산 시스템",
            summary: "여러 서버에 나눠 저장하면 세 가지를 동시에 다 가질 수는 없어요.",
            body: "분산 시스템에는 일관성(모든 서버가 같은 값을 보여 줌), 가용성(언제나 응답함), 분할 허용(서버 사이 연결이 끊겨도 동작함)이 있어요. 네트워크가 끊기는 순간에는 일관성과 가용성 중 하나만 고를 수 있다는 것이 CAP 정리예요. 은행처럼 정확해야 하면 일관성을, SNS 좋아요 수처럼 조금 늦어도 괜찮으면 가용성을 택해요.",
            tip: "네트워크는 언제든 끊길 수 있다는 전제에서 시작해요. 그래서 현실에서는 일관성과 가용성 사이의 균형을 정하는 일이에요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.scaling", category: .advanced, topic: .cs, title: "확장성과 로드 밸런싱",
            summary: "사용자가 늘어도 버티도록 서버를 늘리고 일을 나눠요.",
            body: "서버 한 대의 성능을 올리는 것을 스케일 업, 서버 대수를 늘리는 것을 스케일 아웃이라고 해요. 서버가 여러 대면 로드 밸런서가 들어오는 요청을 골고루 나눠 주고, 한 대가 고장 나도 나머지가 이어서 일해요. 스케일 아웃하려면 서버가 요청 사이의 정보를 자기 메모리에 쥐고 있지 않게(무상태) 만들어야 해요.",
            tip: "서버를 무상태로 설계하는 것이 확장의 첫걸음이에요. 사용자 정보는 데이터베이스나 캐시에 두세요.",
            unlock: .alwaysOpen,
            example: nil),

        LearningCard(
            id: "advanced.auth", category: .advanced, topic: .cs, title: "인증과 인가",
            summary: "'누구인지' 확인하고, 그 사람이 '무엇을 할 수 있는지' 정해요.",
            body: "인증은 로그인처럼 사용자가 누구인지 확인하는 일이고, 인가는 확인된 사용자에게 어떤 기능과 데이터를 허용할지 정하는 일이에요. 로그인한 뒤에는 서버가 발급한 토큰(예: JWT)을 요청마다 함께 보내서, 매번 비밀번호를 보내지 않아도 돼요. OAuth는 'Apple로 로그인'처럼 비밀번호를 넘기지 않고 다른 서비스에 접근 권한만 주는 약속이에요.",
            tip: "토큰은 비밀번호만큼 소중해요. iOS에서는 키체인 같은 안전한 저장소에 보관하세요.",
            unlock: .alwaysOpen,
            example: nil),
    ]
}
