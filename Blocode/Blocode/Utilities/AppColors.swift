//
//  AppColors.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import SwiftUI
import SpriteKit   // 3D 베벨 색상을 SwiftUI(Color)·SpriteKit(SKColor) 양쪽에서 공유하기 위함

// MARK: - 크로스플랫폼 다이나믹 컬러 헬퍼
extension Color {
    /// 라이트/다크 분기 다이나믹 컬러 생성 — iOS: UIColor / macOS: NSColor 기반
    /// ⚠️ light에는 기존 고정색 리터럴을 그대로 전달할 것 (라이트 모드 외형 불변 원칙)
    static func dynamic(light: (red: Double, green: Double, blue: Double),
                        dark: (red: Double, green: Double, blue: Double)) -> Color {
        #if canImport(UIKit)
        // iOS/iPadOS — trait 기반 다이나믹 프로바이더
        return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: dark.red, green: dark.green, blue: dark.blue, alpha: 1.0)
                : UIColor(red: light.red, green: light.green, blue: light.blue, alpha: 1.0)
        })
        #else
        // macOS — NSAppearance 기반 다이나믹 프로바이더
        return Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: dark.red, green: dark.green, blue: dark.blue, alpha: 1.0)
                : NSColor(red: light.red, green: light.green, blue: light.blue, alpha: 1.0)
        })
        #endif
    }
}

// MARK: - 크로스 플랫폼 시맨틱 컬러
/// iOS의 UIColor.* 시스템 색상을 iOS / macOS 모두에서 동작하는 SwiftUI Color로 래핑
extension Color {

    /// UIColor.tertiaryLabel / NSColor.tertiaryLabelColor 대응
    /// — 비활성화된 텍스트, 보조 설명 등 가장 흐린 텍스트 색상
    static var tertiaryLabelColor: Color {
        Color.primary.opacity(0.3)  // primary의 30% 불투명도로 흐리게 표현
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
    /// (iOS/macOS 공통 — Color.dynamic 헬퍼가 플랫폼별 다이나믹 프로바이더를 처리)
    static var appBackground: Color {
        Color.dynamic(light: (0.957, 0.925, 0.843),   // 라이트: #f4ecd7 — 따뜻한 아이보리
                      dark: (0.09, 0.10, 0.13))       // 다크: #171A21 — 짙은 네이비 차콜
    }

    // MARK: - 공통 UI 색상

    /// 별점 골드 색상 — 획득한 별 아이콘에 일괄 사용
    static var starGold: Color {
        Color(red: 0.95, green: 0.72, blue: 0.28)
    }

    /// 카드/소형 버튼 배경 — 설정 버튼, 홈 버튼 등
    /// 라이트: #fbf6e8 (크림) / 다크: #23262e (짙은 남색)
    static var cardBackground: Color {
        Color.dynamic(light: (0.984, 0.965, 0.910),
                      dark: (0.14, 0.15, 0.18))
    }

    /// 코드 패널 배경 — 게임 화면 하단 코드 편집 패널
    /// 라이트: #fbf6e8 (크림) / 다크: #1c1f29 (더 짙은 남색)
    static var panelBackground: Color {
        Color.dynamic(light: (0.984, 0.965, 0.910),
                      dark: (0.11, 0.12, 0.16))
    }

    /// 통계 카드 배경 — 홈 화면 별/챕터/연속 카드
    /// 라이트: #fbf6e8 (크림) / 다크: #2e3148 (미드 남색)
    static var statCardBackground: Color {
        Color.dynamic(light: (251/255, 246/255, 232/255),
                      dark: (0.18, 0.19, 0.23))
    }

    /// 잠금 상태 배경 — 잠긴 스테이지/챕터 아이콘 배경
    /// 라이트: #e5ded1 (연한 베이지) / 다크: #33353f (차콜 그레이)
    static var lockedBackground: Color {
        Color.dynamic(light: (229/255, 222/255, 209/255),
                      dark: (0.20, 0.21, 0.25))
    }

    /// 게임 맵 배경 — SpriteKit 맵 영역 배경
    /// 라이트: #efe5cd (따뜻한 크림) / 다크: #1a1f2e (짙은 남색)
    static var mapBackground: Color {
        Color.dynamic(light: (239/255, 229/255, 205/255),
                      dark: (0.10, 0.12, 0.18))
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
    /// 실행 버튼 비활성/실행 중 색 — 따뜻한 회색 (라이트/다크 동일 고정값, iOS 컨트롤 바·맥 상단바 공용)
    static let runButtonInactiveGray = Color(red: 0.72, green: 0.70, blue: 0.67)

    // MARK: - 다크모드 전용 파생 색상
    // 다크 배경(네이비)과 따뜻한 탄색 트림이 충돌하는 화면에서만 쓰는 다이나믹 컬러 모음.
    // ⚠️ 라이트 분기는 기존 고정색 리터럴과 완전히 동일한 값 — 라이트 모드 외형은 절대 바뀌지 않음.

    /// 캐릭터/미니 블럭 아이콘 몸체
    /// 라이트: #2a2520 (darkInk와 동일) / 다크: 밝은 회백색 (게임 캐릭터 다크 몸체와 동일 값)
    static var characterBody: Color {
        Color.dynamic(light: (42/255, 37/255, 32/255),
                      dark: (0.88, 0.88, 0.90))
    }

    /// 캐릭터/미니 블럭 아이콘 위 뒷면 — 라이트: #807869 / 다크: 쿨 그레이 림
    static var characterTopBack: Color {
        Color.dynamic(light: (128/255, 120/255, 105/255),
                      dark: (0.70, 0.71, 0.75))
    }

    /// 캐릭터/미니 블럭 아이콘 아래 뒷면 — 라이트: #beb59f / 다크: 중간 쿨 그레이 (그림자)
    static var characterBottomBack: Color {
        Color.dynamic(light: (190/255, 181/255, 159/255),
                      dark: (0.52, 0.53, 0.60))
    }

    /// 캐릭터/미니 블럭 아이콘 화살표
    /// 라이트: 크림 #f4ecd7 / 다크: 다크 잉크 (다크에선 몸체가 밝아지므로 화살표를 어둡게 반전)
    static var characterArrow: Color {
        Color.dynamic(light: (244/255, 236/255, 215/255),
                      dark: (42/255, 37/255, 32/255))
    }

    /// 슬레이트 3D 버튼 앞면 — 잠금 팝업 확인 / 클리어 화면 버튼 / "지금 여기" 스테이지 아이콘
    /// 라이트: #2a2520 (darkInk와 동일) / 다크: 슬레이트 블루그레이
    static var slateButtonFace: Color {
        Color.dynamic(light: (42/255, 37/255, 32/255),
                      dark: (72/255, 78/255, 96/255))
    }

    /// 슬레이트 3D 버튼 위 뒷면 — 라이트: #807869 / 다크: 밝은 슬레이트
    static var slateButtonTopBack: Color {
        Color.dynamic(light: (128/255, 120/255, 105/255),
                      dark: (104/255, 112/255, 134/255))
    }

    /// 슬레이트 3D 버튼 아래 뒷면 — 라이트: #beb59f / 다크: 앞면보다 약간 어두운 슬레이트 (그림자 방향)
    static var slateButtonBottomBack: Color {
        Color.dynamic(light: (190/255, 181/255, 159/255),
                      dark: (56/255, 61/255, 76/255))
    }

    /// 실행 버튼 활성(민트) — 라이트: 기존 accentMint와 동일 / 다크: 톤 다운한 딥 민트
    /// (비활성·실행 중 회색은 기존 값을 그대로 사용하므로 여기 포함하지 않음)
    static var runButtonActiveMint: Color {
        Color.dynamic(light: (0.27, 0.72, 0.58),
                      dark: (0.20, 0.56, 0.45))
    }

    /// 게임 화면 되돌리기/설정 버튼 앞면
    /// 라이트: panelBackground 라이트와 동일한 크림 / 다크: 배경보다 살짝 밝은 슬레이트 (버튼 면이 배경에 묻히지 않도록)
    static var controlIconButtonFace: Color {
        Color.dynamic(light: (0.984, 0.965, 0.910),
                      dark: (0.16, 0.17, 0.22))
    }

    /// UIColor.systemGray2 대응 (설정 화면 비활성 아이콘 배지 등)
    /// 라이트/다크 값 모두 iOS systemGray2 공식 값과 동일 — macOS에서도 같은 톤 유지
    static var systemGray2Color: Color {
        Color.dynamic(light: (174/255, 174/255, 178/255),
                      dark: (99/255, 99/255, 102/255))
    }
}

// MARK: - SpriteKit 색상 (GameScene 전용 — 위 Color와 동일 RGB 공유)
/// SwiftUI Color와 같은 값을 SpriteKit에서도 쓰도록 SKColor로 제공
/// (SKColor는 iOS에선 UIColor, macOS에선 NSColor의 별칭이라 양쪽 모두 동작)
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
