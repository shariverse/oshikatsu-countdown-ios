//
//  EventText.swift
//  OshiCon
//

import Foundation

/// 予定の日付・時刻・残り日数の書き方（Android 版と同じ）。アプリとウィジェットで使う。
nonisolated enum EventText {
    /// 一覧の行の日付（`10月18日(日)`）。
    static func monthDayWeekday(_ day: CalendarDay) -> String {
        "\(day.month)月\(day.day)日(\(japaneseWeekdays[weekdayIndex(of: day)]))"
    }

    /// 読み上げの日付（`10月18日 日曜日`）。「(日)」や「·」をそのまま読ませない。
    static func spokenMonthDayWeekday(_ day: CalendarDay) -> String {
        "\(day.month)月\(day.day)日 \(japaneseWeekdays[weekdayIndex(of: day)])曜日"
    }

    /// 年まで出す日付（`2026年10月18日(日)`）。
    static func fullDate(_ day: CalendarDay) -> String {
        "\(day.year)年\(monthDayWeekday(day))"
    }

    /// 進み具合のバーの両端の日付（`10/18`）。
    static func shortDate(_ day: CalendarDay) -> String {
        "\(day.month)/\(day.day)"
    }

    /// 先頭のカードの日付（`10.18 SUN`）。曜日は英語の大文字で、数字と並べたときの見た目をそろえる。
    static func dateBadge(_ day: CalendarDay) -> String {
        "\(day.month).\(day.day) \(englishWeekdays[weekdayIndex(of: day)])"
    }

    /// 時刻（`17:00`、`9:30`）。
    static func time(_ time: TimeOfDay) -> String {
        "\(time.hour):\(String(format: "%02d", time.minute))"
    }

    /// 開始の時刻の呼び名（`開演 17:00` の `開演`）。
    static func startLabel(of kind: EventKind) -> String {
        switch kind {
        case .live:
            "開演"
        case .release:
            "発売"
        case .stream:
            "配信開始"
        case .birthday, .other:
            "開始"
        }
    }

    /// 開始の時刻（`開演 17:00`）。
    static func startTime(_ time: TimeOfDay, kind: EventKind) -> String {
        "\(startLabel(of: kind)) \(Self.time(time))"
    }

    /// 残り日数の読み上げ・1 行の表示（`あと 3 日`・`今日！`・`2 日前`）。
    static func countdown(daysUntil: Int, status: CountdownStatus) -> String {
        switch status {
        case .upcoming:
            "あと \(daysUntil) 日"
        case .today:
            "今日！"
        case .ended:
            "\(-daysUntil) 日前"
        }
    }

    private static let japaneseWeekdays = ["日", "月", "火", "水", "木", "金", "土"]
    private static let englishWeekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    /// 曜日（0 が日曜）。日付だけで決まるので、タイムゾーンに左右されない UTC の西暦の暦で求める。
    private static func weekdayIndex(of day: CalendarDay) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar.component(.weekday, from: day.date(at: nil, calendar: calendar)) - 1
    }
}
