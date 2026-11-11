//
//  DailyQuote.swift
//  Blocode
//
//  Created by 조준희 on 11/12/26.
//

import Foundation

// MARK: - DailyQuote
/// 홈 화면 "오늘의 한 줄" — 두 줄로 끊어 보여 주는 문구 (첫 번째가 기존 문구)
/// 날짜로 하나를 골라서 같은 날엔 항상 같고 매일 달라짐 (목록을 한 바퀴 돌면 처음부터 다시)
struct DailyQuote: Equatable {
    let first: String   // 윗줄
    let second: String  // 아랫줄

    /// 한 줄로 이어 붙인 문구 (아이패드·맥 홈)
    var joined: String { "\(first) \(second)" }

    /// 문구 목록 — 줄마다 아홉 글자 안팎으로 짧게 (아이폰 세로 폭에 한 줄로 들어가도록)
    static let all: [DailyQuote] = [
        ("적은 블럭이", "좋은 코드."),
        ("큰 문제도", "나누면 쉬워."),
        ("같은 일은", "한 번만 쓰자."),
        ("실패한 길도", "지도가 돼요."),
        ("한 칸씩", "꾸준히 가요."),
        ("막히면", "돌아가 보자."),
        ("단순함이", "가장 빠른 길."),
        ("먼저 생각하고", "그다음 놓자."),
        ("버그는", "배움의 흔적."),
        ("천천히", "그래도 앞으로."),
        ("조건을 따지면", "길이 열려요."),
        ("함수 하나가", "열 줄을 줄여요."),
        ("오늘의 한 판이", "내일의 실력."),
        ("틀려도 괜찮아", "다시 놓으면 돼."),
        ("줄일 수 있다면", "줄여 보자."),
        ("순서가 곧", "논리예요."),
        ("한 번 더", "해 보면 알아."),
        ("포기하지 않으면", "코드가 풀려요."),
        ("길은 늘", "하나가 아니야."),
        ("반복할수록", "짧아지는 코드."),
        ("작은 성공이", "쌓이는 중."),
        ("막힌 벽도", "문이 될 수 있어."),
        ("생각을 놓으면", "코드가 돼요."),
        ("쉬어 가도", "괜찮아요."),
        ("가장 짧은 길은", "늦게 보여요."),
        ("스위치 하나로", "문이 열려요."),
        ("포탈 너머엔", "지름길이 있어."),
        ("오늘도", "한 블럭 더."),
        ("별은", "천천히 모여요."),
        ("깔끔한 코드는", "친절한 코드."),
    ].map { DailyQuote(first: $0.0, second: $0.1) }

    /// 그날의 문구 — 날짜(연·월·일)가 같으면 같은 문구
    static func quote(for date: Date, calendar: Calendar = .current) -> DailyQuote {
        // 기준일(2026-01-01)부터 센 날짜 번호 — 하루의 시각과 상관없이 같고, 연도가 바뀌어도 하루에 하나씩 이어서 넘어감
        let reference = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? date
        let days = calendar.dateComponents([.day], from: reference, to: calendar.startOfDay(for: date)).day ?? 0
        return all[((days % all.count) + all.count) % all.count]  // 기준일 이전 날짜도 안전하게
    }
}
