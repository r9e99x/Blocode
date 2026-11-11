//
//  CodeRendererTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/12/26.
//

import Testing
@testable import Blocode

/// 블럭 → 텍스트 코드 변환 검증
@MainActor
@Suite("코드로 보기 변환")
struct CodeRendererTests {

    /// 안내에 쓴 예시 — 반복 3번 { 앞으로, 오른쪽 회전 } 다음에 앞이 막혀있으면 { 왼쪽 회전 }
    private var sample: [Block] {
        [Block(type: .repeatBlock, repeatCount: 3,
               children: [Block(type: .moveForward), Block(type: .turnRight)]),
         Block(type: .ifBlock, children: [Block(type: .turnLeft)], ifCondition: .pathBlocked)]
    }

    @Test("Python")
    func python() {
        #expect(CodeRenderer.render(sample, language: .python) == """
        for i in range(3):
            move_forward()
            turn_right()
        if is_blocked():
            turn_left()
        """)
    }

    @Test("Swift")
    func swift() {
        #expect(CodeRenderer.render(sample, language: .swift) == """
        for i in 0..<3 {
            moveForward()
            turnRight()
        }
        if isBlocked() {
            turnLeft()
        }
        """)
    }

    @Test("C")
    func c() {
        #expect(CodeRenderer.render(sample, language: .c) == """
        #include <stdio.h>

        int main(void) {
            for (int i = 0; i < 3; i++) {
                move_forward();
                turn_right();
            }
            if (is_blocked()) {
                turn_left();
            }
            return 0;
        }
        """)
    }

    @Test("C++는 전위 증가")
    func cpp() {
        #expect(CodeRenderer.render(sample, language: .cpp) == """
        #include <iostream>
        using namespace std;

        int main() {
            for (int i = 0; i < 3; ++i) {
                moveForward();
                turnRight();
            }
            if (isBlocked()) {
                turnLeft();
            }
            return 0;
        }
        """)
    }

    @Test("Java")
    func java() {
        #expect(CodeRenderer.render(sample, language: .java) == """
        public class Main {
            public static void main(String[] args) {
                for (int i = 0; i < 3; i++) {
                    moveForward();
                    turnRight();
                }
                if (isBlocked()) {
                    turnLeft();
                }
            }
        }
        """)
    }

    @Test("중첩 반복은 변수 이름이 i, j로 구분됨")
    func nestedLoops() {
        let blocks = [Block(type: .repeatBlock, repeatCount: 2, children: [
            Block(type: .repeatBlock, repeatCount: 4, children: [Block(type: .moveForward)])])]
        #expect(CodeRenderer.render(blocks, language: .python) == """
        for i in range(2):
            for j in range(4):
                move_forward()
        """)
    }

    @Test("함수 블럭은 이름 붙인 보조 함수로 위에 정의되고 그 자리에서 호출됨")
    func functionBlock() {
        let blocks = [Block(type: .functionBlock, children: [Block(type: .moveForward), Block(type: .turnLeft)]),
                      Block(type: .moveForward)]
        #expect(CodeRenderer.render(blocks, language: .python) == """
        def step1():
            move_forward()
            turn_left()

        step1()
        move_forward()
        """)
    }

    @Test("함수 안의 함수는 안쪽이 먼저 정의됨")
    func nestedFunctions() {
        let inner = Block(type: .functionBlock, children: [Block(type: .turnRight)])
        let outer = Block(type: .functionBlock, children: [inner])
        let text = CodeRenderer.render([outer], language: .swift)
        #expect(text == """
        func step2() {
            turnRight()
        }

        func step1() {
            step2()
        }

        step1()
        """)
    }

    @Test("자바는 함수 블럭이 클래스 안의 정적 메서드로 정의됨")
    func javaHelper() {
        let blocks = [Block(type: .functionBlock, children: [Block(type: .moveForward)])]
        #expect(CodeRenderer.render(blocks, language: .java) == """
        public class Main {
            static void step1() {
                moveForward();
            }

            public static void main(String[] args) {
                step1();
            }
        }
        """)
    }

    @Test("C 함수 블럭은 main 위에 정의됨")
    func cHelper() {
        let blocks = [Block(type: .functionBlock, children: [Block(type: .turnLeft)])]
        #expect(CodeRenderer.render(blocks, language: .c) == """
        #include <stdio.h>

        void step1(void) {
            turn_left();
        }

        int main(void) {
            step1();
            return 0;
        }
        """)
    }

    @Test("보석·스위치 블럭과 앞이 뚫려있으면 조건")
    func itemsAndClearCondition() {
        let blocks = [Block(type: .ifBlock, children: [Block(type: .collectItem), Block(type: .activateSwitch)],
                            ifCondition: .pathClear)]
        #expect(CodeRenderer.render(blocks, language: .java).contains("if (isClear()) {\n            collectItem();\n            activateSwitch();\n        }"))
        #expect(CodeRenderer.render(blocks, language: .c).contains("collect_item();"))
    }

    @Test("빈 블럭 목록과 빈 컨테이너도 문법이 깨지지 않는 자리 채움이 들어감")
    func emptyCases() {
        #expect(CodeRenderer.render([], language: .python) == "pass")
        #expect(CodeRenderer.render([Block(type: .repeatBlock, repeatCount: 2)], language: .python)
                == "for i in range(2):\n    pass")
        #expect(CodeRenderer.render([], language: .c)
                == "#include <stdio.h>\n\nint main(void) {\n    // (비어 있음)\n    return 0;\n}")
    }

    @Test("모든 언어에서 여는 중괄호와 닫는 중괄호 수가 같음")
    func bracesBalanced() {
        let blocks = sample + [Block(type: .functionBlock, children: sample)]
        for language in CodeLanguage.allCases where language != .python {
            let text = CodeRenderer.render(blocks, language: language)
            #expect(text.filter { $0 == "{" }.count == text.filter { $0 == "}" }.count)
        }
    }
}
