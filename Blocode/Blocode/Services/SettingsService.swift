//
//  SettingsService.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - SettingsService
/// 앱 설정값을 UserDefaults에 저장하는 싱글톤
/// @Published 프로퍼티로 SwiftUI 뷰에서 실시간 반응 가능
final class SettingsService: ObservableObject {

    // 앱 전역에서 단일 인스턴스로 사용
    static let shared = SettingsService()

    // MARK: - 테마

    /// 앱 테마 설정 열거형
    enum ThemePreference: String, CaseIterable {
        case light, dark, system

        /// SwiftUI colorScheme 값으로 변환 (system이면 nil → OS 기본 따름)
        var colorScheme: ColorScheme? {
            switch self {
            case .light:  return .light
            case .dark:   return .dark
            case .system: return nil   // nil이면 preferredColorScheme에서 시스템 따름
            }
        }

        /// 설정 화면에 표시할 레이블 (한국어)
        var label: String {
            switch self {
            case .light:  return "라이트"
            case .dark:   return "다크"
            case .system: return "시스템"
            }
        }
    }

    // MARK: - Published 설정값

    /// 앱 테마 — 변경 시 UserDefaults에 자동 저장
    @Published var theme: ThemePreference {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "theme") }
    }

    /// 햅틱 피드백 활성화 여부 — 변경 시 UserDefaults에 자동 저장
    @Published var hapticEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticEnabled, forKey: "hapticEnabled") }
    }

    /// 효과음 활성화 여부 — 변경 시 UserDefaults에 자동 저장
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }

    /// 블럭 실행 속도 배율 (0.5 / 1.0 / 2.0) — 변경 시 UserDefaults에 자동 저장
    @Published var executionSpeed: Double {
        didSet { UserDefaults.standard.set(executionSpeed, forKey: "executionSpeed") }
    }

    /// 남은 힌트 사용 횟수 — 변경 시 UserDefaults에 자동 저장
    @Published var hintsRemaining: Int {
        didSet { UserDefaults.standard.set(hintsRemaining, forKey: "hintsRemaining") }
    }

    // MARK: - Init

    /// private init으로 외부 인스턴스 생성 방지 (싱글톤 패턴)
    private init() {
        let ud = UserDefaults.standard
        // 저장된 테마 값 로드 (없으면 시스템 기본값)
        let themeRaw = ud.string(forKey: "theme") ?? ThemePreference.system.rawValue
        self.theme          = ThemePreference(rawValue: themeRaw) ?? .system
        // 저장된 햅틱 설정 로드 (없으면 기본값 true)
        self.hapticEnabled  = ud.object(forKey: "hapticEnabled") as? Bool   ?? true
        // 저장된 효과음 설정 로드 (없으면 기본값 true)
        self.soundEnabled   = ud.object(forKey: "soundEnabled")  as? Bool   ?? true
        // 저장된 실행 속도 로드 (없으면 기본값 1.0배속)
        self.executionSpeed = ud.object(forKey: "executionSpeed") as? Double ?? 1.0
        // 저장된 힌트 횟수 로드 (없으면 기본값 3회)
        self.hintsRemaining = ud.object(forKey: "hintsRemaining") as? Int   ?? 3
    }

    // MARK: - 햅틱

    /// 스타일에 맞는 햅틱 피드백 실행 — hapticEnabled가 false이면 무시
    func triggerHaptic(_ style: HapticStyle = .light) {
        guard hapticEnabled else { return }
        #if os(iOS)
        // iOS에서만 UIImpactFeedbackGenerator 사용
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light:  generator = UIImpactFeedbackGenerator(style: .light)
        case .medium: generator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:  generator = UIImpactFeedbackGenerator(style: .heavy)
        }
        generator.impactOccurred()
        #endif
    }

    /// 햅틱 피드백 강도 종류
    enum HapticStyle { case light, medium, heavy }

    // MARK: - 진행도 초기화

    /// 모든 스테이지 클리어 기록 초기화 — ProgressService에 위임
    func resetProgress() {
        ProgressService.shared.resetAll()
    }
}
