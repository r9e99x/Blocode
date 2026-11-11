//
//  PuzzlePlayView.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import SwiftUI

// MARK: - PuzzlePlayView
/// 일일 퍼즐·랜덤 퍼즐을 플레이하는 화면 — 퍼즐을 만들어 게임 화면(StageView)에 넣음
/// 같은 날짜·씨앗이면 언제나 같은 퍼즐이라, 화면이 다시 그려져도 게임이 처음부터 시작되지 않음
struct PuzzlePlayView: View {

    /// 어떤 퍼즐인지 — 일일 퍼즐은 날짜(yyyyMMdd), 랜덤 퍼즐은 씨앗
    enum Kind {
        case daily(Int)
        case random(UInt64)
    }

    private let stage: Stage
    private let showsOwnBackButton: Bool
    private let onExit: () -> Void
    private let onNewPuzzle: (() -> Void)?

    /// - Parameter onNewPuzzle: 랜덤 퍼즐 클리어 후 "한 판 더"로 새 퍼즐을 여는 동작 (일일 퍼즐은 nil)
    init(kind: Kind, showsOwnBackButton: Bool = true, onNewPuzzle: (() -> Void)? = nil,
         onExit: @escaping () -> Void) {
        switch kind {
        case .daily(let key):
            // 날짜를 읽지 못하면 오늘의 퍼즐로 대체
            stage = PuzzleGenerator.dailyStage(forKey: key) ?? PuzzleGenerator.dailyStage(for: Date())
        case .random(let seed):
            stage = PuzzleGenerator.randomStage(seed: seed)
        }
        self.showsOwnBackButton = showsOwnBackButton
        self.onNewPuzzle = onNewPuzzle
        self.onExit = onExit
    }

    var body: some View {
        StageView(stage: stage, navPath: .constant(NavigationPath()),
                  showsOwnBackButton: showsOwnBackButton, onExit: onExit, onNewPuzzle: onNewPuzzle)
            .id(stage.id)
    }
}
