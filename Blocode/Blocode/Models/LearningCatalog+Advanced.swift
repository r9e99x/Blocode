//
//  LearningCatalog+Advanced.swift
//  Blocode
//
//  Created by 조준희 on 11/22/26.
//

import Foundation

// MARK: - 고급 카드 (처음부터 열려 있음)
/// 실무와 면접에서 자주 나오는 개념 15장 — 코딩 8장, CS 7장
/// 코드 예시는 비교가 잘 되는 카드(인터페이스·제네릭·동적 계획법)에만 다섯 언어로 채움
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
    ]
}
