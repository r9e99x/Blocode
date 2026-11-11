//
//  SettingsService.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation
import Combine

// MARK: - SettingsService
/// 앱 설정값을 UserDefaults에 저장하는 싱글톤
/// @Published 프로퍼티로 SwiftUI 뷰에서 실시간 반응 가능
final class SettingsService: ObservableObject {

    // 앱 전역에서 단일 인스턴스로 사용
    static let shared = SettingsService()

    /// 설정값 저장소
    private let defaults: UserDefaults

    // MARK: - 테마

    /// 앱 테마 설정 열거형
    enum ThemePreference: String, CaseIterable {
        case light, dark, system

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
        didSet { defaults.set(theme.rawValue, forKey: "theme") }
    }

    /// 효과음 활성화 여부 — 변경 시 UserDefaults에 자동 저장
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: "soundEnabled") }
    }

    /// 배경음악 활성화 여부 — 변경 시 UserDefaults에 자동 저장 (재생 반영은 SettingsViewModel 담당)
    @Published var musicEnabled: Bool {
        didSet { defaults.set(musicEnabled, forKey: "musicEnabled") }
    }

    /// 블럭 실행 속도 배율 (0.5 / 1.0 / 2.0) — 변경 시 UserDefaults에 자동 저장
    @Published var executionSpeed: Double {
        didSet { defaults.set(executionSpeed, forKey: "executionSpeed") }
    }

    /// 복습 알림 사용 여부 — 기본은 꺼짐, 켤 때 알림 권한을 물음
    @Published var reminderEnabled: Bool {
        didSet { defaults.set(reminderEnabled, forKey: "reminderEnabled") }
    }

    /// 복습 알림 시각 — 자정부터의 분 (기본 오후 8시 = 1200)
    @Published var reminderMinutes: Int {
        didSet { defaults.set(reminderMinutes, forKey: "reminderMinutes") }
    }

    /// "코드로 보기"에서 마지막에 고른 언어 — 기본은 Swift
    @Published var codeLanguage: CodeLanguage {
        didSet { defaults.set(codeLanguage.rawValue, forKey: "codeLanguage") }
    }

    // MARK: - Init

    /// 앱은 항상 `shared`(UserDefaults.standard)를 쓰고, 테스트만 격리된 UserDefaults를 주입
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let ud = defaults
        // 저장된 테마 값 로드 (없으면 시스템 기본값)
        let themeRaw = ud.string(forKey: "theme") ?? ThemePreference.system.rawValue
        self.theme          = ThemePreference(rawValue: themeRaw) ?? .system
        // 저장된 효과음 설정 로드 (없으면 기본값 true)
        self.soundEnabled   = ud.object(forKey: "soundEnabled")  as? Bool   ?? true
        // 저장된 배경음악 설정 로드 (없으면 기본값 true)
        self.musicEnabled   = ud.object(forKey: "musicEnabled")  as? Bool   ?? true
        // 저장된 실행 속도 로드 (없으면 기본값 1.0배속)
        self.executionSpeed = ud.object(forKey: "executionSpeed") as? Double ?? 1.0
        // 저장된 복습 알림 설정 로드 (없으면 꺼짐, 오후 8시)
        self.reminderEnabled = ud.object(forKey: "reminderEnabled") as? Bool ?? false
        self.reminderMinutes = ud.object(forKey: "reminderMinutes") as? Int ?? 20 * 60
        // 저장된 코드 보기 언어 로드 (없거나 알 수 없는 값이면 Swift)
        self.codeLanguage = CodeLanguage(rawValue: ud.string(forKey: "codeLanguage") ?? "") ?? .swift
    }

    // MARK: - 온보딩

    /// 온보딩을 다시 보게 함 — BlocodeApp의 @AppStorage가 같은 키를 관찰하므로
    /// 값만 바꿔도 앱 진입점이 자동으로 온보딩 화면으로 전환됨
    func resetOnboarding() {
        defaults.set(false, forKey: Self.hasSeenOnboardingKey)
    }

    /// 온보딩을 봤는지 저장하는 UserDefaults 키 — BlocodeApp의 @AppStorage와 진행도 초기화가 같은 키를 쓰도록 한 곳에서 정의
    static let hasSeenOnboardingKey = "hasSeenOnboarding"
}
