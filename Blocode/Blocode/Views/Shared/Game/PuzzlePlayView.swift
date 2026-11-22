//
//  PuzzlePlayView.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import SwiftUI

// MARK: - PuzzlePlayView
/// 일일 퍼즐·랜덤 퍼즐을 플레이하는 화면 — 퍼즐을 메인 스레드 밖에서 만들어 받은 뒤 게임 화면(StageView)에 넘김
/// 만드는 동안엔 맵 자리에 로딩 표시만 보임 (출시 빌드에선 대부분 순간이라 거의 안 보임)
struct PuzzlePlayView: View {

    /// 어떤 퍼즐인지 — 일일 퍼즐은 날짜(yyyyMMdd), 랜덤 퍼즐은 씨앗
    typealias Kind = PuzzleKind

    private let kind: Kind
    private let showsOwnBackButton: Bool
    private let onExit: () -> Void
    private let onNewPuzzle: (() -> Void)?
    /// 만들어 받은 퍼즐 — 받기 전엔 nil (로딩 표시)
    @State private var stage: Stage?

    /// - Parameter onNewPuzzle: 랜덤 퍼즐 클리어 후 "한 판 더"로 새 퍼즐을 여는 동작 (일일 퍼즐은 nil)
    init(kind: Kind, showsOwnBackButton: Bool = true, onNewPuzzle: (() -> Void)? = nil,
         onExit: @escaping () -> Void) {
        self.kind = kind
        self.showsOwnBackButton = showsOwnBackButton
        self.onNewPuzzle = onNewPuzzle
        self.onExit = onExit
    }

    var body: some View {
        Group {
            if let stage, stage.id == kind.stageID {
                StageView(stage: stage, navPath: .constant(NavigationPath()),
                          showsOwnBackButton: showsOwnBackButton, onExit: onExit, onNewPuzzle: onNewPuzzle)
                    .id(stage.id)  // 퍼즐마다 화면 정체성을 구분 — "한 판 더"에서 이전 게임 상태가 재사용되지 않게
            } else {
                loadingView
            }
        }
        // 퍼즐 받기 — 최근에 만든 퍼즐이면 바로, 아니면 메인 밖에서 만들어 옴. 화면을 떠나면 자동 취소
        .task(id: kind.stageID) {
            stage = await kind.stage()
        }
    }

    /// 퍼즐을 만드는 동안 — 게임 화면의 맵 로딩 표시와 같은 모양
    private var loadingView: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.mapBackground)
                .overlay(ProgressView())
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 520)
                .padding(24)
        }
    }
}
