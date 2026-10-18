//
//  DomainFixtures.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon

/// 規則のテストで使う暦と予定の作り方。
nonisolated enum DomainFixtures {
    static let tokyo = calendar(timeZone: "Asia/Tokyo")
    /// 文言と日付の書き方を確かめる言語（Simulator の言語に左右されないよう、テストでは locale を渡す）。
    static let japanese = Locale(identifier: "ja_JP")
    static let english = Locale(identifier: "en_US")

    static func calendar(timeZone identifier: String, identifier calendarIdentifier: Calendar.Identifier = .gregorian) -> Calendar {
        var calendar = Calendar(identifier: calendarIdentifier)
        guard let timeZone = TimeZone(identifier: identifier) else {
            preconditionFailure("タイムゾーンが見つからない: \(identifier)")
        }
        calendar.timeZone = timeZone
        return calendar
    }

    /// `calendar` のタイムゾーンでの日時。
    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0,
        _ second: Int = 0,
        calendar: Calendar = tokyo
    ) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
        guard let date = calendar.date(from: components) else {
            preconditionFailure("日時を作れない: \(components)")
        }
        return date
    }

    static func day(_ year: Int, _ month: Int, _ day: Int) -> CalendarDay {
        CalendarDay(year: year, month: month, day: day)
    }

    static func event(
        title: String = "ライブ",
        day: CalendarDay,
        startTime: TimeOfDay? = nil,
        repeatsYearly: Bool = false,
        isPinned: Bool = false,
        createdAt: Date = date(2026, 1, 1)
    ) -> OshiEvent {
        OshiEvent(
            oshiID: nil,
            kind: repeatsYearly ? .birthday : .live,
            title: title,
            day: day,
            startTime: startTime,
            repeatsYearly: repeatsYearly,
            isPinned: isPinned,
            createdAt: createdAt
        )
    }
}
