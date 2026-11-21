//
//  MapElementMetrics.swift
//  Blocode
//
//  Created by 조준희 on 11/21/26.
//

import CoreGraphics

// MARK: - MapElementMetrics
/// 맵 위 요소 크기 비율 (칸 한 변 대비) — 게임 화면(GameScene)과 맵 에디터 격자가 함께 씀
/// 한쪽만 고치면 게임과 에디터의 모양이 달라지므로 한 곳에서 정의 (값은 기존 그대로)
enum MapElementMetrics {
    static let tileCorner: CGFloat = 0.22      // 타일 모서리 반지름
    static let gem: CGFloat = 0.28             // 보석 다이아몬드 반폭
    static let switchRadius: CGFloat = 0.24    // 스위치 원 반지름
    static let gateRing: CGFloat = 0.22        // 문 표시 링 반지름
    static let portalOuter: CGFloat = 0.32     // 포탈 바깥 링 반지름
    static let portalInner: CGFloat = 0.16     // 포탈 안쪽 원 반지름
    static let goalRadius: CGFloat = 0.34      // 목표 원 반지름
    static let goalHighlight: CGFloat = 0.45   // 목표 광택 원 (목표 반지름 대비)
}
