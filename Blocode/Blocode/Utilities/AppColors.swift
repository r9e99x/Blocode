//
//  AppColors.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI
import SpriteKit   // 3D 베벨 색상을 SwiftUI(Color)·SpriteKit(SKColor) 양쪽에서 공유하기 위함

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

    // MARK: - 공통 UI 색상

    /// 별점 골드 색상 — 획득한 별 아이콘에 일괄 사용
    static var starGold: Color {
        Color(red: 0.95, green: 0.72, blue: 0.28)
    }

    /// 카드/소형 버튼 배경 — 설정 버튼, 홈 버튼 등
    /// 라이트: #fbf6e8 (크림) / 다크: #23262e (짙은 남색)
    static var cardBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.14, green: 0.15, blue: 0.18, alpha: 1.0)
                : UIColor(red: 0.984, green: 0.965, blue: 0.910, alpha: 1.0)
        })
    }

    /// 코드 패널 배경 — 게임 화면 하단 코드 편집 패널
    /// 라이트: #fbf6e8 (크림) / 다크: #1c1f29 (더 짙은 남색)
    static var panelBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1.0)
                : UIColor(red: 0.984, green: 0.965, blue: 0.910, alpha: 1.0)
        })
    }

    /// 통계 카드 배경 — 홈 화면 별/챕터/연속 카드
    /// 라이트: #fbf6e8 (크림) / 다크: #2e3148 (미드 남색)
    static var statCardBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.19, blue: 0.23, alpha: 1.0)
                : UIColor(red: 251/255, green: 246/255, blue: 232/255, alpha: 1.0)
        })
    }

    /// 잠금 상태 배경 — 잠긴 스테이지/챕터 아이콘 배경
    /// 라이트: #e5ded1 (연한 베이지) / 다크: #33353f (차콜 그레이)
    static var lockedBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.20, green: 0.21, blue: 0.25, alpha: 1.0)
                : UIColor(red: 229/255, green: 222/255, blue: 209/255, alpha: 1.0)
        })
    }

    /// 게임 맵 배경 — SpriteKit 맵 영역 배경
    /// 라이트: #efe5cd (따뜻한 크림) / 다크: #1a1f2e (짙은 남색)
    static var mapBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1.0)
                : UIColor(red: 239/255, green: 229/255, blue: 205/255, alpha: 1.0)
        })
    }

    // MARK: - 3D 베벨/캐릭터 공용 색상
    // 3D 버튼·아이콘·캐릭터에 반복되던 하드코딩 색을 한 곳에서 관리
    // (라이트/다크 무관 고정값 — 각 화면이 동일 RGB를 직접 박아 쓰던 값 그대로)

    /// 다크 잉크 #2a2520 — 캐릭터 본체 / 다크 버튼 앞면
    static let darkInk = Color(red: 42/255, green: 37/255, blue: 32/255)
    /// 3D 위 뒷면 #807869
    static let bevelTopBack = Color(red: 128/255, green: 120/255, blue: 105/255)
    /// 3D 아래 뒷면 #beb59f (그림자 효과)
    static let bevelBottomBack = Color(red: 190/255, green: 181/255, blue: 159/255)
    /// 방향 화살표 크림 #f4ecd7
    static let arrowCream = Color(red: 244/255, green: 236/255, blue: 215/255)
    /// 강조 민트그린 #27b894 — 실행 버튼 / 클리어 강조
    static let accentMint = Color(red: 0.27, green: 0.72, blue: 0.58)

    // MARK: - 다크모드 전용 파생 색상
    // 다크 배경(네이비)과 따뜻한 탄색 트림이 충돌하는 화면에서만 쓰는 다이나믹 컬러 모음.
    // ⚠️ 라이트 분기는 기존 고정색 리터럴과 완전히 동일한 값 — 라이트 모드 외형은 절대 바뀌지 않음.

    /// 캐릭터/미니 블럭 아이콘 몸체
    /// 라이트: #2a2520 (darkInk와 동일) / 다크: 밝은 회백색 (게임 캐릭터 다크 몸체와 동일 값)
    static var characterBody: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.88, green: 0.88, blue: 0.90, alpha: 1.0)
                : UIColor(red: 42/255, green: 37/255, blue: 32/255, alpha: 1.0)
        })
    }

    /// 캐릭터/미니 블럭 아이콘 위 뒷면 — 라이트: #807869 / 다크: 쿨 그레이 림
    static var characterTopBack: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.70, green: 0.71, blue: 0.75, alpha: 1.0)
                : UIColor(red: 128/255, green: 120/255, blue: 105/255, alpha: 1.0)
        })
    }

    /// 캐릭터/미니 블럭 아이콘 아래 뒷면 — 라이트: #beb59f / 다크: 중간 쿨 그레이 (그림자)
    static var characterBottomBack: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.52, green: 0.53, blue: 0.60, alpha: 1.0)
                : UIColor(red: 190/255, green: 181/255, blue: 159/255, alpha: 1.0)
        })
    }

    /// 캐릭터/미니 블럭 아이콘 화살표
    /// 라이트: 크림 #f4ecd7 / 다크: 다크 잉크 (다크에선 몸체가 밝아지므로 화살표를 어둡게 반전)
    static var characterArrow: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 42/255, green: 37/255, blue: 32/255, alpha: 1.0)
                : UIColor(red: 244/255, green: 236/255, blue: 215/255, alpha: 1.0)
        })
    }

    /// 슬레이트 3D 버튼 앞면 — 잠금 팝업 확인 / 클리어 화면 버튼 / "지금 여기" 스테이지 아이콘
    /// 라이트: #2a2520 (darkInk와 동일) / 다크: 슬레이트 블루그레이
    static var slateButtonFace: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 72/255, green: 78/255, blue: 96/255, alpha: 1.0)
                : UIColor(red: 42/255, green: 37/255, blue: 32/255, alpha: 1.0)
        })
    }

    /// 슬레이트 3D 버튼 위 뒷면 — 라이트: #807869 / 다크: 밝은 슬레이트
    static var slateButtonTopBack: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 104/255, green: 112/255, blue: 134/255, alpha: 1.0)
                : UIColor(red: 128/255, green: 120/255, blue: 105/255, alpha: 1.0)
        })
    }

    /// 슬레이트 3D 버튼 아래 뒷면 — 라이트: #beb59f / 다크: 앞면보다 약간 어두운 슬레이트 (그림자 방향)
    static var slateButtonBottomBack: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 56/255, green: 61/255, blue: 76/255, alpha: 1.0)
                : UIColor(red: 190/255, green: 181/255, blue: 159/255, alpha: 1.0)
        })
    }

    /// 실행 버튼 활성(민트) — 라이트: 기존 accentMint와 동일 / 다크: 톤 다운한 딥 민트
    /// (비활성·실행 중 회색은 기존 값을 그대로 사용하므로 여기 포함하지 않음)
    static var runButtonActiveMint: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.20, green: 0.56, blue: 0.45, alpha: 1.0)
                : UIColor(red: 0.27, green: 0.72, blue: 0.58, alpha: 1.0)
        })
    }

    /// 게임 화면 되돌리기/설정 버튼 앞면
    /// 라이트: panelBackground 라이트와 동일한 크림 / 다크: 배경보다 살짝 밝은 슬레이트 (버튼 면이 배경에 묻히지 않도록)
    static var controlIconButtonFace: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.16, green: 0.17, blue: 0.22, alpha: 1.0)
                : UIColor(red: 0.984, green: 0.965, blue: 0.910, alpha: 1.0)
        })
    }
}

// MARK: - SpriteKit 색상 (GameScene 전용 — 위 Color와 동일 RGB 공유)
/// SwiftUI Color와 같은 값을 SpriteKit에서도 쓰도록 SKColor로 제공
/// (민트는 GameScene에서 쓰지 않아 제외)
extension SKColor {
    /// 다크 잉크 #2a2520 — 캐릭터 본체 (라이트 모드)
    static let darkInk = SKColor(red: 42/255, green: 37/255, blue: 32/255, alpha: 1.0)
    /// 3D 위 뒷면 #807869
    static let bevelTopBack = SKColor(red: 128/255, green: 120/255, blue: 105/255, alpha: 1.0)
    /// 3D 아래 뒷면 #beb59f (그림자 효과)
    static let bevelBottomBack = SKColor(red: 190/255, green: 181/255, blue: 159/255, alpha: 1.0)
    /// 방향 화살표 크림 #f4ecd7
    static let arrowCream = SKColor(red: 244/255, green: 236/255, blue: 215/255, alpha: 1.0)
}
