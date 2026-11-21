//
//  SettingsViewModel.swift
//  Blocode
//
//  Created by 조준희 on 11/1/26.
//

import Foundation
import Observation

// MARK: - SettingsViewModel
/// 설정 화면(SettingsView)의 상태/로직 담당 ViewModel
/// 설정값 변경, 실행 속도 슬라이더 변환, 진행도 초기화, 개발자 해금을 담당한다.
/// 계산 속성이 SettingsService(@Observable)를 읽으므로 설정이 바뀌면 화면이 자동으로 갱신됨
@Observable
final class SettingsViewModel {

    /// 실행 속도 슬라이더 단계 — 슬라이더 값은 이 배열의 인덱스
    static let speedValues: [Double] = [0.5, 1.0, 2.0]

    // 설정·진행도 저장소 — 테스트는 격리된 저장소를 주입
    private let settings: SettingsService
    private let progress: ProgressService
    /// 배경음악 켜기/끄기를 실제 재생에 반영 — 테스트는 소리가 나지 않도록 주입
    private let applyMusicEnabled: (Bool) -> Void
    private let reminder: ReminderService
    private let learning: LearningService  // 진행도를 지우면 학습 보관함 수집도 함께 비움

    init(settings: SettingsService = .shared,
         progress: ProgressService = .shared,
         reminder: ReminderService? = nil,
         learning: LearningService? = nil,
         applyMusicEnabled: @escaping (Bool) -> Void = { SoundService.shared.setMusicEnabled($0) }) {
        self.settings = settings
        self.progress = progress
        self.reminder = reminder ?? .shared
        self.learning = learning ?? .shared
        self.applyMusicEnabled = applyMusicEnabled
    }

    // MARK: - 테마

    /// 앱 테마 — 변경 즉시 저장
    var theme: SettingsService.ThemePreference {
        get { settings.theme }
        set { settings.theme = newValue }
    }

    /// "시스템 따르기" 토글 — 끄면 라이트 테마로 돌아감
    var followsSystemTheme: Bool {
        get { settings.theme == .system }
        set { settings.theme = newValue ? .system : .light }
    }

    // MARK: - 피드백

    /// 효과음 켜기/끄기
    var soundEnabled: Bool {
        get { settings.soundEnabled }
        set { settings.soundEnabled = newValue }
    }

    /// 배경음악 켜기/끄기 — 설정을 먼저 저장해야 재생 쪽이 바뀐 값을 읽음
    var musicEnabled: Bool {
        get { settings.musicEnabled }
        set {
            settings.musicEnabled = newValue
            applyMusicEnabled(newValue)
        }
    }

    // MARK: - 복습 알림

    /// 알림 권한이 거부돼 켜지 못한 상태 — 화면이 기기 설정 안내를 보여 줌
    private(set) var reminderDenied = false

    var reminderEnabled: Bool { settings.reminderEnabled }
    /// 일일 퍼즐이 열렸는지 — 잠긴 동안은 복습 알림 설정을 숨김
    var dailyPuzzleUnlocked: Bool { progress.isUnlocked(.dailyPuzzle) }

    /// 알림 시각 — 화면의 시간 선택기가 쓰는 Date(날짜는 오늘)와 저장값(자정부터의 분) 사이를 변환
    var reminderTime: Date {
        get {
            Calendar.current.date(bySettingHour: settings.reminderMinutes / 60, minute: settings.reminderMinutes % 60,
                                  second: 0, of: Date()) ?? Date()
        }
        set {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            settings.reminderMinutes = (parts.hour ?? 20) * 60 + (parts.minute ?? 0)
            Task { await reminder.refresh() }
        }
    }

    /// 알림 켜기/끄기 — 켤 때 권한을 묻고, 거부되면 꺼진 채로 두고 안내 상태를 켬
    func setReminderEnabled(_ enabled: Bool) {
        if enabled {
            Task {
                let permission = await reminder.enable()
                // 알림 켜짐 여부는 설정 저장소가 바꾸고, 거부 안내는 이 값이 바꿔서 둘 다 자동으로 화면에 반영됨
                reminderDenied = (permission != .authorized)
            }
        } else {
            settings.reminderEnabled = false
            reminderDenied = false
            Task { await reminder.refresh() }
        }
    }

    // MARK: - 실행 속도

    /// 슬라이더 위치(0~2) ↔ 실제 실행 속도 배율 변환 — 목록에 없는 저장값은 가운데(1배속)로 표시
    var speedIndex: Double {
        get { Double(Self.speedValues.firstIndex(of: settings.executionSpeed) ?? 1) }
        set {
            let index = max(0, min(Self.speedValues.count - 1, Int(newValue.rounded())))
            settings.executionSpeed = Self.speedValues[index]
        }
    }

    // MARK: - 데이터

    /// 진행도 초기화 — 온보딩도 다시 보게 함
    /// 앱 진입점이 같은 키를 관찰하므로 화면은 자동으로 온보딩으로 바뀌고, 설정·게임 화면도 함께 사라짐
    func resetProgress() {
        progress.resetAll()
        learning.reset()
        settings.resetOnboarding()
    }

    // MARK: - 개발자 (테스트 편의용 임시 기능, 정식 배포 전 제거 예정)

    /// 개발자 섹션에 표시할 챕터 목록
    var chapters: [ChapterInfo] { ChapterCatalog.all }

    /// 1번 챕터부터 지정 챕터까지 모든 스테이지를 3별 클리어 처리
    func devUnlock(throughChapter number: Int) {
        progress.devUnlock(throughChapter: number,
                           chapters: chapters)
    }
}
