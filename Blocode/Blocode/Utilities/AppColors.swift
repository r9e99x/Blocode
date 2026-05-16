//
//  AppColors.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI

// MARK: - 크로스 플랫폼 시맨틱 컬러
/// iOS의 UIColor.* 시스템 색상을 iOS / macOS 모두에서 동작하는 SwiftUI Color로 래핑
extension Color {

    /// UIColor.tertiaryLabel / NSColor.tertiaryLabelColor 대응
    /// — 비활성화된 텍스트, 보조 설명 등 가장 흐린 텍스트 색상
    static var tertiaryLabelColor: Color {
        Color.primary.opacity(0.3)  // primary의 30% 불투명도로 흐리게 표현
    }

    /// UIColor.secondarySystemBackground 대응 (카드 배경 등)
    /// — 주 배경보다 한 단계 어두운 보조 배경색
    static var secondaryBackground: Color {
        Color.primary.opacity(0.06)  // primary의 6% 불투명도
    }

    /// UIColor.tertiarySystemBackground 대응 (뱃지, 캡슐 배경 등)
    /// — 가장 연한 배경색, 작은 UI 요소의 배경으로 사용
    static var tertiaryBackground: Color {
        Color.primary.opacity(0.04)  // primary의 4% 불투명도
    }

    /// UIColor.separator 대응 (구분선)
    /// — 섹션 구분선이나 경계선에 사용하는 반투명 색상
    static var separatorColor: Color {
        Color.primary.opacity(0.12)  // primary의 12% 불투명도
    }

    /// UIColor.systemGray3 대응 (비활성 버튼 등)
    /// — 중간 회색조 색상, 비활성 상태 UI에 사용
    static var systemGray3Color: Color {
        Color.primary.opacity(0.35)  // primary의 35% 불투명도
    }

    /// 앱 전체 페이지 배경 — 라이트: 따뜻한 아이보리 / 다크: 짙은 네이비 차콜
    /// Color.primary.opacity()는 다크모드에서 검정이라 UIColor dynamic provider 사용
    static var appBackground: Color {
        #if canImport(UIKit)
        // iOS: UIColor dynamic provider로 다크/라이트 모드 자동 전환
        return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.09, green: 0.10, blue: 0.13, alpha: 1.0) // 다크: #171A21 — 짙은 네이비 차콜
                : UIColor(red: 0.957, green: 0.925, blue: 0.843, alpha: 1.0) // 라이트: #f4ecd7 — 따뜻한 아이보리
        })
        #else
        // macOS: 기본 윈도우 배경색 사용
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
}
