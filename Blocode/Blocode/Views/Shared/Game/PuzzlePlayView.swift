//
//  PuzzlePlayView.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import SwiftUI

// MARK: - PuzzlePlayView
/// 일일 퍼즐·랜덤 퍼즐을 플레이하는 화면 — 어떤 퍼즐인지만 게임 화면(StageView)에 넘김
/// 퍼즐 생성은 게임 ViewModel이 처음 한 번만 하므로, 이 화면이 다시 만들어져도 퍼즐을 다시 만들지 않음
struct PuzzlePlayView: View {

    /// 어떤 퍼즐인지 — 일일 퍼즐은 날짜(yyyyMMdd), 랜덤 퍼즐은 씨앗
    typealias Kind = PuzzleKind

    private let kind: Kind
    private let showsOwnBackButton: Bool
    private let onExit: () -> Void
    private let onNewPuzzle: (() -> Void)?

    /// - Parameter onNewPuzzle: 랜덤 퍼즐 클리어 후 "한 판 더"로 새 퍼즐을 여는 동작 (일일 퍼즐은 nil)
    init(kind: Kind, showsOwnBackButton: Bool = true, onNewPuzzle: (() -> Void)? = nil,
         onExit: @escaping () -> Void) {
        self.kind = kind
        self.showsOwnBackButton = showsOwnBackButton
        self.onNewPuzzle = onNewPuzzle
        self.onExit = onExit
    }

    var body: some View {
        StageView(puzzle: kind, navPath: .constant(NavigationPath()),
                  showsOwnBackButton: showsOwnBackButton, onExit: onExit, onNewPuzzle: onNewPuzzle)
            .id(kind.stageID)  // 퍼즐마다 화면 정체성을 구분 — "한 판 더"에서 이전 게임 상태가 재사용되지 않게
    }
}
