//
//  ReminderService.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import Foundation
import UserNotifications

// MARK: - NotificationPermission
/// 알림 권한 상태 — 시스템 값을 앱이 쓰는 세 가지로 줄임
enum NotificationPermission: Equatable {
    case notDetermined  // 아직 묻지 않음
    case denied         // 거부됨 — 기기 설정에서만 바꿀 수 있음
    case authorized     // 허용됨
}

// MARK: - NotificationScheduling
/// 알림 예약 창구 — 실제 앱은 시스템 알림 센터, 테스트는 기록만 하는 가짜를 씀
protocol NotificationScheduling {
    func permission() async -> NotificationPermission
    func requestPermission() async -> Bool
    func schedule(id: String, body: String, at date: Date, calendar: Calendar) async
    func cancel(ids: [String]) async
}

// MARK: - SystemNotificationCenter
/// UNUserNotificationCenter로 예약하는 실제 구현
struct SystemNotificationCenter: NotificationScheduling {

    func permission() async -> NotificationPermission {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        default: return .authorized  // authorized·provisional·ephemeral
        }
    }

    func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func schedule(id: String, body: String, at date: Date, calendar: Calendar) async {
        let content = UNMutableNotificationContent()
        content.title = "Blocode"
        content.body = body
        content.sound = .default
        content.userInfo = [ReminderNotificationDelegate.destinationKey: ReminderNotificationDelegate.dailyPuzzleDestination]  // 누르면 오늘의 퍼즐로
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func cancel(ids: [String]) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}

// MARK: - ReminderService
/// 복습 알림 — 정해 둔 시각에 "한 판 풀어 볼까요?"를 알려 연속 일수를 이어 가게 함
/// 앞으로 3일치만 예약하고, 앱을 켜거나 나갈 때마다 다시 계산함 — 오늘 이미 풀었으면 오늘 알림은 빠지고,
/// 앱을 며칠 안 열면 3번만 알리고 조용해져서 귀찮게 하지 않음
final class ReminderService {

    /// 앱 전역에서 공유 — 실제 알림 센터와 설정·진행도를 사용
    static let shared = ReminderService(center: SystemNotificationCenter(), settings: .shared, progress: .shared)

    /// 미리 예약하는 날 수
    static let daysAhead = 3
    static let identifiers = (0..<daysAhead).map { "blocode.reminder.\($0)" }

    private let center: NotificationScheduling
    private let settings: SettingsService
    private let progress: ProgressService
    private let now: () -> Date
    private let calendar: Calendar

    init(center: NotificationScheduling, settings: SettingsService, progress: ProgressService,
         now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.center = center
        self.settings = settings
        self.progress = progress
        self.now = now
        self.calendar = calendar
    }

    // MARK: - 계산 (순수 함수)

    /// 알릴 시각들 — 오늘 아직 안 풀었고 그 시각이 안 지났으면 오늘부터, 아니면 내일부터 연달아 count일
    static func fireDates(now: Date, minutes: Int, clearedToday: Bool, calendar: Calendar,
                          count: Int = daysAhead) -> [Date] {
        let hour = minutes / 60
        let minute = minutes % 60
        guard let today = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) else { return [] }
        let startsToday = !clearedToday && today > now
        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .day, value: offset + (startsToday ? 0 : 1), to: today)
        }
    }

    /// 알림 문구 — 첫 알림은 연속 일수를 넣고, 뒤쪽 알림은 일반 문구
    static func message(streak: Int) -> String {
        switch streak {
        case ..<1: return "오늘의 퍼즐이 기다리고 있어요. 한 판 풀어 볼까요?"
        case 1: return "오늘의 퍼즐로 연속 기록을 이어 가요."
        default: return "\(streak)일 연속이 끊기기 전에 한 판만 풀어 볼까요?"
        }
    }

    // MARK: - 예약

    /// 설정과 진행 상태에 맞춰 알림을 다시 예약 — 꺼져 있거나 권한이 없으면 예약을 모두 지움
    func refresh() async {
        await center.cancel(ids: Self.identifiers)
        guard settings.reminderEnabled, await center.permission() == .authorized else { return }

        let current = now()
        let dates = Self.fireDates(now: current, minutes: settings.reminderMinutes,
                                   clearedToday: progress.hasCleared(on: current, calendar: calendar),
                                   calendar: calendar)
        for (index, date) in dates.enumerated() {
            let body = Self.message(streak: index == 0 ? progress.streak : 0)
            await center.schedule(id: Self.identifiers[index], body: body, at: date, calendar: calendar)
        }
    }

    /// 복습 알림 켜기 — 필요하면 권한을 묻고, 허용되면 켜고 예약, 거부되면 꺼 둠
    @discardableResult
    func enable() async -> NotificationPermission {
        var permission = await center.permission()
        if permission == .notDetermined {
            permission = await center.requestPermission() ? .authorized : .denied
        }
        settings.reminderEnabled = (permission == .authorized)
        await refresh()
        return permission
    }
}
