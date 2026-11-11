//
//  LearningCard.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import Foundation

// MARK: - LearningCategory
/// 학습 보관함의 탭 — 블럭 개념은 진도에 따라 열리고, 코딩·CS 기초는 처음부터 열려 있음
enum LearningCategory: String, CaseIterable, Identifiable {
    case block    // 블럭 개념
    case coding   // 코딩 기초
    case cs       // CS 기초

    var id: String { rawValue }

    var title: String {
        switch self {
        case .block:  return "블럭 개념"
        case .coding: return "코딩 기초"
        case .cs:     return "CS 기초"
        }
    }
}

// MARK: - LearningCard
/// 학습 보관함의 카드 한 장 — 한 줄 요약, 쉬운 설명, 팁, 코드 예시
struct LearningCard: Identifiable, Equatable {

    /// 열리는 조건
    enum Unlock: Equatable {
        case alwaysOpen          // 처음부터 열려 있음 (코딩·CS 기초)
        case block(BlockType)    // 그 블럭이 처음 등장해서 수집되면 열림 (블럭 개념)
    }

    /// 코드 예시 — 블럭 묶음이면 "코드로 보기"와 같은 렌더러로 다섯 언어를 만들고,
    /// 블럭으로 표현하기 어려운 내용은 언어별 텍스트를 직접 적음
    enum Example {
        case blocks([Block])
        case text([CodeLanguage: String])
    }

    let id: String
    let category: LearningCategory
    let title: String
    let summary: String      // 한 줄 요약
    let body: String         // 쉬운 설명 (두세 문장)
    let tip: String?         // 덧붙이는 팁
    let unlock: Unlock
    let example: Example?

    /// 지정 언어의 코드 예시 텍스트 (예시가 없거나 그 언어 예시가 없으면 nil)
    func exampleCode(in language: CodeLanguage) -> String? {
        switch example {
        case .blocks(let blocks)?: return CodeRenderer.render(blocks, language: language)
        case .text(let table)?:    return table[language]
        case nil:                  return nil
        }
    }

    static func == (lhs: LearningCard, rhs: LearningCard) -> Bool { lhs.id == rhs.id }
}
