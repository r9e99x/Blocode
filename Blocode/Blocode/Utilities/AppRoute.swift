//
//  AppRoute.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation

// MARK: - AppRoute
/// NavigationStack의 경로를 타입 안전하게 표현하는 열거형
/// ContentView의 NavigationStack에 등록하고, 하위 뷰에서 append/removeLast로 이동 제어
enum AppRoute: Hashable {
    /// 챕터 선택 화면 (모든 챕터 목록 표시)
    case chapterSelect

    /// 특정 챕터의 스테이지 목록 화면
    /// - Parameter: 챕터 번호 (Int)
    case chapter(Int)

    /// 게임 스테이지 화면 (챕터 번호와 스테이지 번호로 식별)
    /// - Parameters:
    ///   - chapter: 챕터 번호
    ///   - number: 스테이지 번호
    case stage(chapter: Int, number: Int)

    /// 내 맵 목록 화면 (사용자가 만든 맵)
    case customMaps

    /// 내 맵 플레이 화면 — 저장된 맵의 번호
    case customMapPlay(UUID)

    /// 맵 에디터 화면 — 고칠 저장된 맵의 번호 (nil이면 새 맵)
    case mapEditor(UUID?)
}
