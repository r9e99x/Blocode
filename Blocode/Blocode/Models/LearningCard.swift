//
//  LearningCard.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import Foundation

// MARK: - LearningCategory
/// 학습 보관함의 탭 — 블럭 개념은 진도에 따라 열리고, 초급·중급·고급 카드는 처음부터 열려 있음
enum LearningCategory: String, CaseIterable, Identifiable {
    case block         // 블럭 개념
    case beginner      // 초급
    case intermediate  // 중급
    case advanced      // 고급

    var id: String { rawValue }

    var title: String {
        switch self {
        case .block:        return "블럭 개념"
        case .beginner:     return "초급"
        case .intermediate: return "중급"
        case .advanced:     return "고급"
        }
    }
}

// MARK: - LearningTopic
/// 초급·중급·고급 탭 안의 갈래 — 프로그래밍 언어 이야기(코딩)와 컴퓨터가 일하는 원리(CS)
/// 블럭 개념 카드에는 갈래가 없음
enum LearningTopic: String, CaseIterable, Identifiable {
    case coding   // 코딩
    case cs       // CS

    var id: String { rawValue }

    var title: String {
        switch self {
        case .coding: return "코딩"
        case .cs:     return "CS"
        }
    }
}

// MARK: - LearningCard
/// 학습 보관함의 카드 한 장 — 한 줄 요약, 쉬운 설명, 팁, 코드 예시
struct LearningCard: Identifiable, Equatable {

    /// 열리는 조건
    enum Unlock: Equatable {
        case alwaysOpen          // 처음부터 열려 있음 (초급·중급·고급)
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
    var topic: LearningTopic? = nil   // 초급·중급·고급 탭 안의 갈래 (블럭 개념은 nil)
    let title: String
    let summary: String      // 한 줄 요약
    let body: String         // 쉬운 설명 (두세 문장)
    let tip: String?         // 덧붙이는 팁
    let unlock: Unlock
    let example: Example?

    /// 카드 상세 머리글에 쓰는 분류 이름 — "초급 · 코딩"처럼 탭과 갈래를 함께 보여 줌
    var categoryLabel: String {
        guard let topic else { return category.title }
        return "\(category.title) · \(topic.title)"
    }

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
