//
//  NotificationRouter.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import Foundation
import Combine
import UserNotifications

// MARK: - NotificationRouter
/// 알림을 눌러 앱이 열렸을 때 어디로 갈지 전달하는 창구 — 앱이 아직 화면을 그리기 전에 눌려도 요청이 남아 있다가,
/// 홈 화면이 준비되면 가져가서 이동함
final class NotificationRouter: ObservableObject {

    static let shared = NotificationRouter()

    /// 오늘의 퍼즐을 열라는 요청이 대기 중인지
    @Published private(set) var pendingDailyPuzzle = false

    func requestDailyPuzzle() {
        pendingDailyPuzzle = true
    }

    /// 대기 중인 요청을 한 번만 가져감 — 요청이 있었으면 true
    @discardableResult
    func consumeDailyPuzzle() -> Bool {
        let wasPending = pendingDailyPuzzle
        pendingDailyPuzzle = false
        return wasPending
    }
}

// MARK: - ReminderNotificationDelegate
/// 알림을 눌렀을 때 호출되는 시스템 델리게이트 — 복습 알림이면 오늘의 퍼즐 열기를 요청
/// 앱이 시작될 때 한 번 연결해야 앱이 꺼진 상태에서 알림으로 열렸을 때도 받을 수 있음
final class ReminderNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    /// 알림 내용에 담는 이동 목적지 키와 값
    nonisolated static let destinationKey = "destination"
    nonisolated static let dailyPuzzleDestination = "dailyPuzzle"

    private static let shared = ReminderNotificationDelegate()

    /// 시스템 알림 센터에 델리게이트를 연결 (앱 시작 때 호출)
    static func install() {
        UNUserNotificationCenter.current().delegate = shared
    }

    /// 알림 내용이 오늘의 퍼즐 열기를 뜻하는지
    nonisolated static func opensDailyPuzzle(_ userInfo: [AnyHashable: Any]) -> Bool {
        userInfo[destinationKey] as? String == dailyPuzzleDestination
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let opensDailyPuzzle = Self.opensDailyPuzzle(response.notification.request.content.userInfo)
        if opensDailyPuzzle {
            Task { @MainActor in NotificationRouter.shared.requestDailyPuzzle() }
        }
        completionHandler()
    }
}
