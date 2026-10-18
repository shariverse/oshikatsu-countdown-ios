//
//  EventText.swift
//  OshiCon
//

import Foundation

/// 予定の日付・時刻・残り日数の書き方。アプリとウィジェットで使う。
/// 文言は String Catalog（`Localizable.xcstrings`）の `locale` の言語で、日付・時刻は `locale` の書き方で出す（日本語は Android 版と同じ）。
nonisolated enum EventText {
    /// 残り日数を、数字の前後の文言と数字に分けたもの（数字だけ大きく出すため）。
    struct CountdownParts: Equatable, Sendable {
        /// 数字の前（`あと`。言語によっては空）。
        let prefix: String
        let number: String
        /// 数字の後（`日`）。
        let suffix: String
    }

    /// 一覧の行の日付（ja `10月18日(日)`、en `Sun, Oct 18`）。
    static func monthDayWeekday(_ day: CalendarDay, locale: Locale = .app) -> String {
        format(day, .dateTime.month(.abbreviated).day().weekday(.abbreviated), locale: locale)
    }

    /// 読み上げの日付（ja `10月18日 日曜日`、en `Sunday, October 18`）。「(日)」や「·」をそのまま読ませない。
    static func spokenMonthDayWeekday(_ day: CalendarDay, locale: Locale = .app) -> String {
        format(day, .dateTime.month(.wide).day().weekday(.wide), locale: locale)
    }

    /// 年まで出す日付（ja `2026年10月18日(日)`、en `Sun, Oct 18, 2026`）。
    static func fullDate(_ day: CalendarDay, locale: Locale = .app) -> String {
        format(day, .dateTime.year().month(.abbreviated).day().weekday(.abbreviated), locale: locale)
    }

    /// 進み具合のバーの両端の日付（ja・en `10/18`、de `18.10.`）。
    static func shortDate(_ day: CalendarDay, locale: Locale = .app) -> String {
        format(day, .dateTime.month(.defaultDigits).day(), locale: locale)
    }

    /// 先頭のカードの日付（`10.18 SUN`。日が先の言語は `18.10 SUN`）。
    /// 曜日はどの言語でも英語の大文字にし、数字の書体（Outfit）で数字と並べたときの見た目をそろえる。
    static func dateBadge(_ day: CalendarDay, locale: Locale = .app) -> String {
        let pattern = DateFormatter.dateFormat(fromTemplate: "Md", options: 0, locale: locale) ?? "M/d"
        let dayFirst = (pattern.firstIndex(of: "d") ?? pattern.endIndex) < (pattern.firstIndex(of: "M") ?? pattern.endIndex)
        let numbers = dayFirst ? "\(day.day).\(day.month)" : "\(day.month).\(day.day)"
        return "\(numbers) \(englishWeekdays[weekdayIndex(of: day)])"
    }

    /// 時刻（ja `17:00`・`9:30`）。端末の設定にかかわらず 24 時間表記で出す。
    static func time(_ time: TimeOfDay, locale: Locale = .app) -> String {
        var style = Date.FormatStyle.dateTime.hour(.defaultDigits(amPM: .omitted)).minute()
        style.timeZone = .gmt
        return gregorianDate(of: CalendarDay(year: 2000, month: 1, day: 1), at: time).formatted(style.locale(locale.twentyFourHour))
    }

    /// 開始の時刻（ja `開演 17:00`）。呼び名は種類で変わる。
    static func startTime(_ time: TimeOfDay, kind: EventKind, locale: Locale = .app) -> String {
        let time = Self.time(time, locale: locale)
        return switch kind {
        case .live:
            String(localized: LocalizedStringResource("開演 \(time)", locale: locale))
        case .release:
            String(localized: LocalizedStringResource("発売 \(time)", locale: locale))
        case .stream:
            String(localized: LocalizedStringResource("配信開始 \(time)", locale: locale))
        case .birthday, .other:
            String(localized: LocalizedStringResource("開始 \(time)", locale: locale))
        }
    }

    /// 残りの見出し（ja `開演まで`。時刻が無ければ `当日まで`）。
    static func untilLabel(kind: EventKind, hasStartTime: Bool, locale: Locale = .app) -> String {
        guard hasStartTime else {
            return String(localized: LocalizedStringResource("当日まで", locale: locale))
        }
        return switch kind {
        case .live:
            String(localized: LocalizedStringResource("開演まで", locale: locale))
        case .release:
            String(localized: LocalizedStringResource("発売まで", locale: locale))
        case .stream:
            String(localized: LocalizedStringResource("配信開始まで", locale: locale))
        case .birthday, .other:
            String(localized: LocalizedStringResource("開始まで", locale: locale))
        }
    }

    /// 当日の残り日数の代わりの「今日！」。
    static func today(locale: Locale = .app) -> String {
        String(localized: LocalizedStringResource("今日！", locale: locale))
    }

    /// 残り日数の読み上げ・1 行の表示（ja `あと 3 日`・`今日！`・`2 日前`）。日数の単位は複数形を言語ごとに変える。
    static func countdown(daysUntil: Int, status: CountdownStatus, locale: Locale = .app) -> String {
        switch status {
        case .upcoming:
            String(localized: LocalizedStringResource("あと \(daysUntil) 日", locale: locale))
        case .today:
            today(locale: locale)
        case .ended:
            String(localized: LocalizedStringResource("\(-daysUntil) 日前", locale: locale))
        }
    }

    /// 残り日数を数字と前後の文言に分ける。`withPrefix` なら「あと N 日」（ja `あと`・`3`・`日`、en ``・`3`・`days left`）、
    /// そうでなければ「N 日」（ja ``・`3`・`日`、en ``・`3`・`days`）。
    static func countdownParts(days: Int, withPrefix: Bool, locale: Locale = .app) -> CountdownParts {
        let text = if withPrefix {
            String(localized: LocalizedStringResource("あと \(days) 日", locale: locale))
        } else {
            String(localized: LocalizedStringResource("\(days) 日", locale: locale))
        }
        let number = String(days)
        guard let range = text.range(of: number) else {
            return CountdownParts(prefix: "", number: number, suffix: text)
        }
        return CountdownParts(
            prefix: text[..<range.lowerBound].trimmingCharacters(in: .whitespaces),
            number: number,
            suffix: text[range.upperBound...].trimmingCharacters(in: .whitespaces)
        )
    }

    /// ウィジェットの一覧の短い残り日数（ja `3日`、en `3 days`。当日は `今日！`）。
    static func compactDays(daysUntil: Int, status: CountdownStatus, locale: Locale = .app) -> String {
        status == .today ? today(locale: locale) : String(localized: LocalizedStringResource("\(daysUntil)日", locale: locale))
    }

    /// 読み上げで、いくつかの文言をつなぐ（ja `、`、en `, `）。
    static func joinedForSpeech(_ parts: [String], locale: Locale = .app) -> String {
        parts.joined(separator: String(localized: LocalizedStringResource("、", locale: locale, comment: "読み上げで項目をつなぐ区切り")))
    }

    private static let englishWeekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    /// 日付だけで決まるので、タイムゾーンに左右されない UTC の西暦の暦で日付を作り、`locale` の暦（タイ語は仏暦など）で書く。
    private static func format(_ day: CalendarDay, _ style: Date.FormatStyle, locale: Locale) -> String {
        var style = style
        var calendar = Calendar(identifier: locale.calendar.identifier)
        calendar.timeZone = .gmt
        calendar.locale = locale
        style.calendar = calendar
        style.timeZone = .gmt
        return gregorianDate(of: day, at: nil).formatted(style.locale(locale))
    }

    private static func gregorianDate(of day: CalendarDay, at time: TimeOfDay?) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return day.date(at: time, calendar: calendar)
    }

    /// 曜日（0 が日曜）。日付だけで決まるので、タイムゾーンに左右されない UTC の西暦の暦で求める。
    private static func weekdayIndex(of day: CalendarDay) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar.component(.weekday, from: gregorianDate(of: day, at: nil)) - 1
    }
}
