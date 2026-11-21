//
//  CodeLanguageViewModel.swift
//  Blocode
//
//  Created by 조준희 on 11/21/26.
//

import Foundation
import Combine

// MARK: - CodeLanguageViewModel
/// "코드로 보기"와 개념 카드 상세가 함께 쓰는 코드 언어 선택 상태
/// 고른 언어는 설정에 저장되어 두 화면이 같은 언어를 보여 줌 (화면이 설정 저장소를 직접 만지지 않도록 감쌈)
final class CodeLanguageViewModel: ObservableObject {

    // 설정 저장소 — 테스트는 격리된 저장소를 주입
    private let settings: SettingsService
    private var cancellables = Set<AnyCancellable>()

    init(settings: SettingsService = .shared) {
        self.settings = settings
        // 다른 화면에서 언어를 바꿔도 함께 갱신되도록 설정 변경을 그대로 전파
        settings.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    /// 지금 고른 언어 — 바꾸면 바로 저장
    var language: CodeLanguage {
        get { settings.codeLanguage }
        set { settings.codeLanguage = newValue }
    }

    /// 블럭 목록을 지금 언어의 코드로
    func code(for blocks: [Block]) -> String {
        CodeRenderer.render(blocks, language: language)
    }
}
