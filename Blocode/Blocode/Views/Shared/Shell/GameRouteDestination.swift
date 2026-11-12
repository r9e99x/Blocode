//
//  GameRouteDestination.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import SwiftUI

// MARK: - GameRouteDestination
/// 게임·에디터 화면으로 가는 경로의 목적지 — 아이폰 홈(ContentView)과 아이패드·맥 셸(SidebarShell)이 함께 씀
/// (예전엔 두 화면에 같은 연결 코드가 따로 있어서 한쪽만 고치면 어긋났음)
/// 목록·보관함처럼 셸마다 모양이 다른 화면은 각 셸이 직접 처리하므로 여기서는 빈 화면
struct GameRouteDestination: View {

    let route: AppRoute

    /// 화면을 올린 내비게이션 스택 — 뒤로 가기와 다음 스테이지 이동에 사용
    @Binding var navPath: NavigationPath

    /// 스테이지 클리어 뒤 "챕터 목록으로" 동작 — nil이면 StageView 기본 동작 (아이폰: 챕터 선택 화면으로)
    var onReturnToChapterList: (() -> Void)? = nil

    /// 게임 화면 자체 뒤로가기 버튼 사용 여부 — 맥은 툴바 버튼을 따로 두고,
    /// 아이폰·아이패드는 게임 화면이 시스템 내비 바를 숨기므로 자체 버튼을 사용
    #if os(macOS)
    private let showsOwnBackButton = false
    #else
    private let showsOwnBackButton = true
    #endif

    var body: some View {
        switch route {
        case .stage(let chapter, let number):
            // 로딩은 StageView의 ViewModel이 담당 (View 계층 데이터 호출 없음)
            StageView(chapter: chapter, number: number, navPath: $navPath,
                      showsOwnBackButton: showsOwnBackButton,
                      onReturnToChapterList: onReturnToChapterList)
                // 스테이지 번호별로 뷰 정체성을 구분 — 없으면 다음 스테이지로 넘어갈 때 이전 GameViewModel(코드 블럭 포함)이 재사용됨
                .id("stage-\(chapter)-\(number)")
                .macBackToolbar(navPath: $navPath)

        case .customMapPlay(let id):
            // 내 맵 플레이 — 게임 화면과 같은 뒤로가기 규칙
            CustomMapPlayView(id: id, showsOwnBackButton: showsOwnBackButton) { navPath.pop() }
                .macBackToolbar(navPath: $navPath)

        case .dailyPuzzle(let key):
            PuzzlePlayView(kind: .daily(key), showsOwnBackButton: showsOwnBackButton) { navPath.pop() }
                .macBackToolbar(navPath: $navPath)

        case .randomPuzzle(let seed):
            PuzzlePlayView(kind: .random(seed), showsOwnBackButton: showsOwnBackButton, onNewPuzzle: {
                // 한 판 더 — 지금 퍼즐을 빼고 새 씨앗의 퍼즐로 교체
                navPath.pop()
                navPath.append(AppRoute.newRandomPuzzle())
            }) { navPath.pop() }
                .macBackToolbar(navPath: $navPath)

        case .mapEditor(let id):
            // 맵 에디터 — 자체 뒤로가기(저장 확인 포함)를 쓰므로 맥의 시스템 뒤로가기는 숨김
            MapEditorView(editingID: id) { navPath.pop() }
                #if os(macOS)
                .navigationBarBackButtonHidden(true)
                #endif

        case .chapterSelect, .chapter, .customMaps, .library:
            // 셸마다 모양이 다른 화면 — 각 셸이 직접 처리
            // (default를 쓰지 않아서, 경로를 새로 만들면 여기서 컴파일 오류가 나 빠뜨릴 수 없음)
            EmptyView()
        }
    }
}

// MARK: - 맥 게임 화면 뒤로가기 툴바
/// 맥 NavigationStack 툴바에 사각형 뒤로가기 버튼을 두고 시스템 뒤로가기는 숨김 (아이폰·아이패드는 그대로)
private extension View {
    @ViewBuilder
    func macBackToolbar(navPath: Binding<NavigationPath>) -> some View {
        #if os(macOS)
        self
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        SoundService.shared.play(.buttonTap)  // 아이폰 게임 화면 자체 뒤로가기와 동일하게 탭 효과음
                        navPath.wrappedValue.pop()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color.panelBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationBarBackButtonHidden(true)
        #else
        self
        #endif
    }
}
