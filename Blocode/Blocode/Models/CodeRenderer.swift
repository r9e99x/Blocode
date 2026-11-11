//
//  CodeRenderer.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import Foundation

// MARK: - CodeLanguage
/// "코드로 보기"에서 고를 수 있는 언어
enum CodeLanguage: String, CaseIterable, Codable, Identifiable {
    case swift, python, c, cpp, java

    var id: String { rawValue }

    /// 화면에 보이는 이름
    var title: String {
        switch self {
        case .swift:  return "Swift"
        case .python: return "Python"
        case .c:      return "C"
        case .cpp:    return "C++"
        case .java:   return "Java"
        }
    }
}

// MARK: - CodeRenderer
/// 블럭 목록을 선택한 언어의 텍스트 코드로 바꿈 — 화면과 게임 엔진을 전혀 모르는 순수 변환
///  - 실제로 실행되는 전체 프로그램 모양으로 보여 줌 — Python·Swift는 위에서부터 바로 실행되는 코드,
///    C는 `#include` + `main`, C++은 `#include` + `main`, Java는 `Main` 클래스 + `main` 메서드
///  - 함수 블럭은 "그 자리에서 한 번 실행하는 묶음"이라, 이름을 붙인 보조 함수로 위에 정의하고 그 자리에서 호출
///  - 중첩 반복은 변수 이름을 i, j, k 순서로 구분
enum CodeRenderer {

    /// 렌더링 결과 — 보조 함수 정의들과 본문을 합친 전체 프로그램 텍스트
    static func render(_ blocks: [Block], language: CodeLanguage) -> String {
        var helpers: [String] = []      // 위에 정의할 보조 함수(함수 블럭) 코드
        var counter = 0                 // 보조 함수 이름 번호 — 등장 순서대로 1부터

        // 본문 들여쓰기 단계 — Python·Swift는 맨 위 줄에서 바로 시작, C·C++은 main 안, Java는 클래스 > main 안
        let bodyDepth: Int
        switch language {
        case .python, .swift: bodyDepth = 0
        case .c, .cpp:        bodyDepth = 1
        case .java:           bodyDepth = 2
        }
        let body = renderList(blocks, language: language, depth: bodyDepth, loopDepth: 0,
                              helpers: &helpers, counter: &counter)
        let lines = body.isEmpty ? [String(repeating: "    ", count: bodyDepth) + pass(language)] : body
        let text = lines.joined(separator: "\n")
        let helperText = helpers.joined(separator: "\n\n")

        switch language {
        case .python:
            return (helpers.isEmpty ? "" : helperText + "\n\n") + text
        case .swift:
            return (helpers.isEmpty ? "" : helperText + "\n\n") + text
        case .c:
            return "#include <stdio.h>\n\n" + (helpers.isEmpty ? "" : helperText + "\n\n")
                + "int main(void) {\n\(text)\n    return 0;\n}"
        case .cpp:
            return "#include <iostream>\nusing namespace std;\n\n" + (helpers.isEmpty ? "" : helperText + "\n\n")
                + "int main() {\n\(text)\n    return 0;\n}"
        case .java:
            let classBody = (helpers.isEmpty ? "" : helperText + "\n\n")
                + "    public static void main(String[] args) {\n\(text)\n    }"
            return "public class Main {\n\(classBody)\n}"
        }
    }

    // MARK: - 내부 변환

    /// 블럭 목록 → 들여쓴 줄들 (depth는 들여쓰기 단계, loopDepth는 지금까지 겹친 반복 수)
    private static func renderList(_ blocks: [Block], language: CodeLanguage, depth: Int, loopDepth: Int,
                                   helpers: inout [String], counter: inout Int) -> [String] {
        var lines: [String] = []
        let pad = String(repeating: "    ", count: depth)

        for block in blocks {
            switch block.type {
            case .repeatBlock:
                let variable = loopVariable(loopDepth)
                let inner = renderList(block.children ?? [], language: language, depth: depth + 1,
                                       loopDepth: loopDepth + 1, helpers: &helpers, counter: &counter)
                lines.append(pad + loopHeader(count: block.repeatCount ?? 2, variable: variable, language: language))
                lines.append(contentsOf: inner.isEmpty ? [pad + "    " + pass(language)] : inner)
                if let closing = closingBrace(language) { lines.append(pad + closing) }

            case .ifBlock:
                let inner = renderList(block.children ?? [], language: language, depth: depth + 1,
                                       loopDepth: loopDepth, helpers: &helpers, counter: &counter)
                lines.append(pad + ifHeader(block.ifCondition ?? .pathBlocked, language: language))
                lines.append(contentsOf: inner.isEmpty ? [pad + "    " + pass(language)] : inner)
                if let closing = closingBrace(language) { lines.append(pad + closing) }

            case .functionBlock:
                counter += 1
                let name = "step\(counter)"
                // 함수 안쪽은 새 함수 본문이라 반복 변수도 처음부터 다시 센다 (Java는 클래스 안이라 한 단계 더 안쪽)
                let inner = renderList(block.children ?? [], language: language, depth: language == .java ? 2 : 1,
                                       loopDepth: 0, helpers: &helpers, counter: &counter)
                helpers.append(function(named: name, body: inner, language: language))
                lines.append(pad + call(name, language: language))

            default:
                lines.append(pad + call(commandName(block.type, language: language), language: language))
            }
        }
        return lines
    }

    /// 함수 정의 — 본문이 비어 있으면 "아무것도 안 함"을 뜻하는 자리 채움을 넣음
    private static func function(named name: String, body: [String], language: CodeLanguage) -> String {
        let bodyPad = language == .java ? "        " : "    "
        let lines = body.isEmpty ? [bodyPad + pass(language)] : body
        let text = lines.joined(separator: "\n")
        switch language {
        case .python: return "def \(name)():\n\(text)"
        case .swift:  return "func \(name)() {\n\(text)\n}"
        case .c:      return "void \(name)(void) {\n\(text)\n}"
        case .cpp:    return "void \(name)() {\n\(text)\n}"
        // 자바는 클래스 안의 정적 메서드라 한 단계 안쪽에 놓임
        case .java:   return "    static void \(name)() {\n\(text)\n    }"
        }
    }

    /// 반복문 머리 — 반복 횟수와 변수 이름으로 언어별 문법을 만듦
    private static func loopHeader(count: Int, variable: String, language: CodeLanguage) -> String {
        switch language {
        case .python: return "for \(variable) in range(\(count)):"
        case .swift:  return "for \(variable) in 0..<\(count) {"
        case .c, .java: return "for (int \(variable) = 0; \(variable) < \(count); \(variable)++) {"
        case .cpp:    return "for (int \(variable) = 0; \(variable) < \(count); ++\(variable)) {"
        }
    }

    /// 조건문 머리
    private static func ifHeader(_ condition: IfCondition, language: CodeLanguage) -> String {
        let test = conditionCall(condition, language: language)
        switch language {
        case .python: return "if \(test):"
        case .swift:  return "if \(test) {"
        case .c, .cpp, .java: return "if (\(test)) {"
        }
    }

    /// 조건 판별 함수 호출 — 이름 규칙은 명령과 같음 (Python·C는 스네이크, 나머지는 카멜)
    private static func conditionCall(_ condition: IfCondition, language: CodeLanguage) -> String {
        let base = condition == .pathClear ? ("is_clear", "isClear") : ("is_blocked", "isBlocked")
        return (isSnake(language) ? base.0 : base.1) + "()"
    }

    /// 명령(앞으로, 회전 등) 함수 이름
    private static func commandName(_ type: BlockType, language: CodeLanguage) -> String {
        let names: (snake: String, camel: String)
        switch type {
        case .moveForward:    names = ("move_forward", "moveForward")
        case .moveBackward:   names = ("move_backward", "moveBackward")
        case .turnLeft:       names = ("turn_left", "turnLeft")
        case .turnRight:      names = ("turn_right", "turnRight")
        case .collectItem:    names = ("collect_item", "collectItem")
        case .activateSwitch: names = ("activate_switch", "activateSwitch")
        // 컨테이너 블럭은 renderList에서 따로 처리하므로 여기 오지 않음
        case .repeatBlock, .ifBlock, .functionBlock: names = ("", "")
        }
        return isSnake(language) ? names.snake : names.camel
    }

    /// 호출 한 줄 — 세미콜론은 Python·Swift만 없음
    private static func call(_ name: String, language: CodeLanguage) -> String {
        let hasSemicolon = !(language == .python || language == .swift)
        let text = name.hasSuffix(")") ? name : name + "()"
        return text + (hasSemicolon ? ";" : "")
    }

    /// 반복 변수 이름 — 겹칠 때마다 i, j, k, l...
    private static func loopVariable(_ depth: Int) -> String {
        let letters = ["i", "j", "k", "l", "m", "n"]
        return depth < letters.count ? letters[depth] : "i\(depth)"
    }

    /// 파이썬·C는 스네이크 표기, 스위프트·C++·자바는 카멜 표기
    private static func isSnake(_ language: CodeLanguage) -> Bool {
        language == .python || language == .c
    }

    /// 중괄호를 쓰는 언어의 닫는 줄 (파이썬은 없음)
    private static func closingBrace(_ language: CodeLanguage) -> String? {
        language == .python ? nil : "}"
    }

    /// 빈 블록에 넣는 자리 채움
    private static func pass(_ language: CodeLanguage) -> String {
        switch language {
        case .python: return "pass"
        default:      return "// (비어 있음)"
        }
    }
}
