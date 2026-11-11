//
//  ReminderServiceTests.swift
//  BlocodeTests
//
//  Created by 조준희 on 11/12/26.
//
//  복습 알림 검증 — 알릴 시각 계산, 문구, 권한에 따른 예약, 켜기 흐름, 설정 저장.
//  실제 알림 센터 대신 예약만 기록하는 가짜를 쓰므로 기기에 알림이 남지 않는다.

import Testing
import Foundation
@testable import Blocode

// MARK: - 가짜 알림 센터

/// 예약을 기록만 하는 알림 센터 — 취소하면 예약에서 빠짐
final class FakeNotificationCenter: NotificationScheduling {
    var permissionState: NotificationPermission
    var grantsRequest: Bool
    private(set) var pending: [String: (body: String, date: Date)] = [:]
    private(set) var cancelCount = 0
    private(set) var requestCount = 0

    init(permission: NotificationPermission = .authorized, grantsRequest: Bool = true) {
        permissionState = permission
        self.grantsRequest = grantsRequest
    }

    func permission() async -> NotificationPermission { permissionState }

    func requestPermission() async -> Bool {
        requestCount += 1
        permissionState = grantsRequest ? .authorized : .denied
        return grantsRequest
    }

    func schedule(id: String, body: String, at date: Date, calendar: Calendar) async {
        pending[id] = (body, date)
    }

    func cancel(ids: [String]) async {
        cancelCount += 1
        for id in ids { pending[id] = nil }
    }
}

@MainActor
@Suite("복습 알림")
struct ReminderServiceTests {

    private var seoul: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }

    private func date(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        seoul.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    // MARK: - 알릴 시각

    @Test("오늘 아직 안 풀었고 시각 전이면 오늘부터 3일")
    func startsTodayWhenNotClearedAndBeforeTime() {
        let dates = ReminderService.fireDates(now: date(11, 12, 10), minutes: 20 * 60, clearedToday: false, calendar: seoul)
        #expect(dates == [date(11, 12, 20), date(11, 13, 20), date(11, 14, 20)])
    }

    @Test("오늘 이미 풀었으면 내일부터")
    func startsTomorrowWhenCleared() {
        let dates = ReminderService.fireDates(now: date(11, 12, 10), minutes: 20 * 60, clearedToday: true, calendar: seoul)
        #expect(dates == [date(11, 13, 20), date(11, 14, 20), date(11, 15, 20)])
    }

    @Test("시각이 이미 지났거나 정확히 같으면 내일부터")
    func startsTomorrowWhenTimePassed() {
        #expect(ReminderService.fireDates(now: date(11, 12, 21), minutes: 20 * 60, clearedToday: false, calendar: seoul).first == date(11, 13, 20))
        #expect(ReminderService.fireDates(now: date(11, 12, 20), minutes: 20 * 60, clearedToday: false, calendar: seoul).first == date(11, 13, 20))
        #expect(ReminderService.fireDates(now: date(11, 12, 10), minutes: 7 * 60 + 30, clearedToday: false, calendar: seoul).first == date(11, 13, 7, 30))
    }

    @Test("월말을 넘겨도 날짜가 이어짐")
    func crossesMonthEnd() {
        let dates = ReminderService.fireDates(now: date(11, 30, 22), minutes: 20 * 60, clearedToday: false, calendar: seoul)
        #expect(dates == [date(12, 1, 20), date(12, 2, 20), date(12, 3, 20)])
    }

    @Test("문구는 연속 일수에 따라 달라짐")
    func messages() {
        #expect(ReminderService.message(streak: 0).contains("퍼즐이 기다리고"))
        #expect(ReminderService.message(streak: 1) == "오늘의 퍼즐로 연속 기록을 이어 가요.")
        #expect(ReminderService.message(streak: 5) == "5일 연속이 끊기기 전에 한 판만 풀어 볼까요?")
    }

    // MARK: - 예약

    private struct Fixture {
        let center: FakeNotificationCenter
        let settings: SettingsService
        let progress: ProgressService
        let service: ReminderService
        let now: Date
    }

    /// 격리된 저장소와 가짜 센터로 서비스 만들기 — streak이 3이고 마지막 클리어가 오늘/어제
    private func makeFixture(permission: NotificationPermission = .authorized, enabled: Bool = true,
                             clearedToday: Bool = false, minutes: Int = 20 * 60,
                             grantsRequest: Bool = true) -> Fixture {
        let now = Date()
        let defaults = isolatedDefaults()
        defaults.set(3, forKey: "blocode_streak")
        let day = Calendar.current.startOfDay(for: now)
        defaults.set(clearedToday ? day : Calendar.current.date(byAdding: .day, value: -1, to: day)!,
                     forKey: "blocode_last_clear_date")
        let settings = SettingsService(defaults: isolatedDefaults())
        settings.reminderEnabled = enabled
        settings.reminderMinutes = minutes
        let progress = ProgressService.makeForTesting(defaults: defaults)
        let center = FakeNotificationCenter(permission: permission, grantsRequest: grantsRequest)
        let service = ReminderService(center: center, settings: settings, progress: progress, now: { now })
        return Fixture(center: center, settings: settings, progress: progress, service: service, now: now)
    }

    @Test("켜져 있고 허용되면 3일치를 예약하고 첫 알림에만 연속 일수를 넣음")
    func schedulesThreeDays() async {
        let f = makeFixture(minutes: 20 * 60)
        await f.service.refresh()
        #expect(f.center.pending.count == 3)
        let expected = ReminderService.fireDates(now: f.now, minutes: 20 * 60, clearedToday: false, calendar: .current)
        for (index, id) in ReminderService.identifiers.enumerated() {
            #expect(f.center.pending[id]?.date == expected[index])
        }
        #expect(f.center.pending["blocode.reminder.0"]?.body == "3일 연속이 끊기기 전에 한 판만 풀어 볼까요?")
        #expect(f.center.pending["blocode.reminder.1"]?.body == ReminderService.message(streak: 0))
    }

    @Test("오늘 이미 풀었으면 첫 알림이 내일 이후")
    func clearedTodaySkipsToday() async {
        let f = makeFixture(clearedToday: true)
        await f.service.refresh()
        let first = f.center.pending["blocode.reminder.0"]?.date
        #expect(first != nil)
        #expect(first! > Calendar.current.startOfDay(for: f.now).addingTimeInterval(24 * 3600))
    }

    @Test("꺼져 있으면 예약을 모두 지움")
    func disabledCancelsEverything() async {
        let f = makeFixture(enabled: true)
        await f.service.refresh()
        #expect(f.center.pending.count == 3)
        f.settings.reminderEnabled = false
        await f.service.refresh()
        #expect(f.center.pending.isEmpty)
    }

    @Test("권한이 없으면 예약하지 않음")
    func noPermissionSchedulesNothing() async {
        for permission in [NotificationPermission.denied, .notDetermined] {
            let f = makeFixture(permission: permission)
            await f.service.refresh()
            #expect(f.center.pending.isEmpty)
        }
    }

    @Test("다시 계산해도 예약이 쌓이지 않고 시간 변경이 반영됨")
    func refreshReplaces() async {
        let f = makeFixture(minutes: 20 * 60)
        await f.service.refresh()
        await f.service.refresh()
        #expect(f.center.pending.count == 3)
        let before = f.center.pending["blocode.reminder.1"]?.date

        f.settings.reminderMinutes = 8 * 60
        await f.service.refresh()
        #expect(f.center.pending.count == 3)
        #expect(f.center.pending["blocode.reminder.1"]?.date != before)
        let hour = Calendar.current.component(.hour, from: f.center.pending["blocode.reminder.1"]!.date)
        #expect(hour == 8)
    }

    // MARK: - 켜기

    @Test("처음 켜면 권한을 묻고 허용되면 켜져서 예약됨")
    func enableAsksPermission() async {
        let f = makeFixture(permission: .notDetermined, enabled: false, grantsRequest: true)
        let result = await f.service.enable()
        #expect(result == .authorized)
        #expect(f.center.requestCount == 1)
        #expect(f.settings.reminderEnabled)
        #expect(f.center.pending.count == 3)
    }

    @Test("권한을 거부하면 꺼진 채로 두고, 이미 거부된 상태면 다시 묻지 않음")
    func enableDenied() async {
        let first = makeFixture(permission: .notDetermined, enabled: false, grantsRequest: false)
        #expect(await first.service.enable() == .denied)
        #expect(!first.settings.reminderEnabled)
        #expect(first.center.pending.isEmpty)

        let blocked = makeFixture(permission: .denied, enabled: false)
        #expect(await blocked.service.enable() == .denied)
        #expect(blocked.center.requestCount == 0)
        #expect(!blocked.settings.reminderEnabled)
    }

    @Test("이미 허용된 상태면 묻지 않고 켬")
    func enableWhenAuthorized() async {
        let f = makeFixture(permission: .authorized, enabled: false)
        #expect(await f.service.enable() == .authorized)
        #expect(f.center.requestCount == 0)
        #expect(f.settings.reminderEnabled)
    }

    // MARK: - 설정 저장과 화면 상태

    @Test("설정 기본값은 꺼짐·오후 8시이고 저장되어 다시 읽힘")
    func settingsDefaultsAndPersistence() {
        let defaults = isolatedDefaults()
        let first = SettingsService(defaults: defaults)
        #expect(!first.reminderEnabled)
        #expect(first.reminderMinutes == 1200)
        first.reminderEnabled = true
        first.reminderMinutes = 7 * 60 + 15
        let second = SettingsService(defaults: defaults)
        #expect(second.reminderEnabled)
        #expect(second.reminderMinutes == 435)
    }

    @Test("오늘 클리어했는지는 마지막 클리어 날짜로 판단")
    func hasClearedOnDate() {
        let defaults = isolatedDefaults()
        let progress = ProgressService.makeForTesting(defaults: defaults)
        #expect(!progress.hasCleared(on: Date()))
        progress.recordClear(stageId: "ch1_stage1", stars: 3, blockCount: 4)
        #expect(progress.hasCleared(on: Date()))
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        #expect(!progress.hasCleared(on: tomorrow))
    }

    @Test("설정 화면 상태 — 시간 변환과 켜기·거부 흐름")
    func settingsViewModelFlow() async throws {
        let f = makeFixture(permission: .notDetermined, enabled: false, grantsRequest: false)
        let vm = SettingsViewModel(settings: f.settings, progress: f.progress, reminder: f.service)

        vm.reminderTime = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!
        #expect(f.settings.reminderMinutes == 450)
        let parts = Calendar.current.dateComponents([.hour, .minute], from: vm.reminderTime)
        #expect(parts.hour == 7 && parts.minute == 30)

        vm.setReminderEnabled(true)  // 거부되는 흐름
        for _ in 0..<200 where !vm.reminderDenied { try await Task.sleep(for: .milliseconds(5)) }
        #expect(vm.reminderDenied)
        #expect(!vm.reminderEnabled)

        f.center.permissionState = .authorized
        vm.setReminderEnabled(true)
        for _ in 0..<200 where !vm.reminderEnabled { try await Task.sleep(for: .milliseconds(5)) }
        #expect(vm.reminderEnabled)
        #expect(!vm.reminderDenied)

        vm.setReminderEnabled(false)
        #expect(!vm.reminderEnabled)
    }
}
