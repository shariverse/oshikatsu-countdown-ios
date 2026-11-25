//
//  EventDetailContent.swift
//  OshiCon
//

import Foundation

/// 予定の詳細に出す中身（画面から切り離してテストする）。`now` の時点の残りと進み具合を、`calendar` のタイムゾーンで求める。
nonisolated struct EventDetailContent: Equatable, Sendable {
    let event: OshiEvent
    /// 結び付いた推し。推しなしの予定・推しが見つからない予定は nil。
    let oshi: Oshi?
    let countdown: EventCountdown
    /// 文言と日付の書き方の言語。
    let locale: Locale

    init(event: OshiEvent, oshi: Oshi?, now: Date, calendar: Calendar, locale: Locale = .app) {
        self.event = event
        self.oshi = oshi
        self.locale = locale
        countdown = EventCountdown(event: event, now: now, calendar: calendar)
    }

    /// 推し色。推しなしの予定は、どの推し色とも紛れない無彩色（ホームと同じ）。
    var color: OshiColor {
        oshi?.color ?? .black
    }

    /// 種類の横に出す推しの名前。
    var oshiName: String {
        oshi?.name ?? String(localized: LocalizedStringResource("推しなし", locale: locale))
    }

    /// 種類の名前。
    var kindLabel: String {
        event.kind.label(locale: locale)
    }

    /// 残りの見出し（`開演まで`。時刻が無ければ `当日まで`）。
    var untilLabel: String {
        EventText.untilLabel(kind: event.kind, hasStartTime: event.startTime != nil, locale: locale)
    }

    /// 残りの見せ方（何を大きく出すか）。何を数えるかの規則（`EventCountdown`）は変えず、当日の開始の前だけ日数の代わりに「今日！」を出す。
    var countdownDisplay: CountdownDisplay {
        switch countdown.status {
        case .upcoming:
            // 当日の開始の時刻の前。時刻の無い予定は当日の 0:00 に `.today` になるので、ここには来ない
            countdown.daysUntil == 0 ? .countingOnTheDay : .counting
        case .today:
            .today
        case .ended:
            .ended
        }
    }

    /// 残りの日数を「あと N 日」の数字と前後の文言に分けたもの（ja `あと`・`3`・`日`、en ``・`3`・`days left`）。
    /// 日数は 24 時間単位で、下に並べる時間・分・秒のタイルと合わせて残りになる。
    var remainingDaysParts: EventText.CountdownParts {
        EventText.countdownParts(days: countdown.remainingParts.days, withPrefix: true, locale: locale)
    }

    /// 残りの時間・分・秒のタイル（`07`・`05`・`09`）。数えているとき（開始の前）だけ出す。
    /// 時刻の無い予定は、その日の 0:00 までを数える。開始を過ぎた当日と終わった予定は空。
    var clockTiles: [ClockTile] {
        guard countdown.status == .upcoming else {
            return []
        }
        let parts = countdown.remainingParts
        return [
            ClockTile(unit: .hours, value: parts.hours, label: String(localized: LocalizedStringResource("時間", locale: locale))),
            ClockTile(unit: .minutes, value: parts.minutes, label: String(localized: LocalizedStringResource("分", locale: locale))),
            ClockTile(unit: .seconds, value: parts.seconds, label: String(localized: LocalizedStringResource("秒", locale: locale)))
        ]
    }

    /// 残りの読み上げ（ja `残り 3日 7時間 5分`、en `3 days, 7 hours, 5 minutes left`。秒は毎秒変わるので読まない）。
    var remainingDescription: String {
        let parts = countdown.remainingParts
        let formatter = DateComponentsFormatter()
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        formatter.calendar = calendar
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.zeroFormattingBehavior = .dropLeading
        let duration = formatter.string(from: DateComponents(day: parts.days, hour: parts.hours, minute: parts.minutes)) ?? ""
        return String(localized: LocalizedStringResource("残り \(duration)", locale: locale))
    }

    /// 詳細の残りの読み上げ（`開演まで、残り 3日 7時間 5分`。当日の開始の前は `今日！、開演まで、残り 7時間 5分`）。
    /// 大きな日数とタイルをまとめて 1 つの要素として読み、秒は読まない（毎秒読み上げ直さない）。
    var countdownAccessibilityLabel: String {
        let countdown = [untilLabel, remainingDescription]
        let parts = countdownDisplay == .countingOnTheDay ? [EventText.today(locale: locale)] + countdown : countdown
        return EventText.joinedForSpeech(parts, locale: locale)
    }

    /// 終わった予定の「N 日前」。
    var daysAgoText: String {
        EventText.countdown(daysUntil: countdown.daysUntil, status: .ended, locale: locale)
    }

    /// 進み具合の割合（`76`）。進み具合を出せないときは nil。
    var progressPercent: Int? {
        countdown.progress.map { Int(($0 * 100).rounded()) }
    }

    /// 進み具合の割合の文言（`76% 経過`）。進み具合を出せないときは nil。
    var progressPercentText: String? {
        progressPercent.map { percent in String(localized: LocalizedStringResource("\(percent)% 経過", locale: locale)) }
    }

    /// 進み具合の読み上げ（`登録 9/2、76% 経過、当日 10/18`）。進み具合を出せないときは nil。
    var progressAccessibilityLabel: String? {
        progressPercentText.map { EventText.joinedForSpeech([progressStartText, $0, progressEndText], locale: locale) }
    }

    /// 進み具合のバーの左端（`登録 9/2`）。
    var progressStartText: String {
        let day = EventText.shortDate(countdown.progressStartDay, locale: locale)
        return String(localized: LocalizedStringResource("登録 \(day)", locale: locale))
    }

    /// 進み具合のバーの右端（`当日 10/18`）。
    var progressEndText: String {
        let day = EventText.shortDate(countdown.occurrenceDay, locale: locale)
        return String(localized: LocalizedStringResource("当日 \(day)", locale: locale))
    }

    /// 日時（`10月18日(日) 開演 17:00`。時刻が無ければ日付だけ）。
    var dateText: String {
        let date = EventText.monthDayWeekday(countdown.occurrenceDay, locale: locale)
        guard let startTime = event.startTime else {
            return date
        }
        return "\(date) \(EventText.startTime(startTime, kind: event.kind, locale: locale))"
    }

    /// 削除の確認の本文。
    var deleteMessage: String {
        String(localized: LocalizedStringResource("「\(event.title)」を削除します。元に戻せません。", locale: locale))
    }
}

extension EventDetailContent {
    /// 残りの見せ方。
    nonisolated enum CountdownDisplay: Equatable, Sendable {
        /// 開始の前（当日より前）。「あと N 日」を大きく出し、時間・分・秒のタイルを並べる。
        case counting
        /// 当日の、開始の時刻の前。日数の代わりに「今日！」を大きく出し、開始までの時間・分・秒のタイルを並べる。
        case countingOnTheDay
        /// 当日の、開始の時刻を過ぎた後（時刻が無ければ当日）。「今日は当日！」「楽しんできてね」。数えないのでタイルは出さない。
        case today
        /// 終わった予定。「終わった予定」「N 日前」。
        case ended
    }

    /// タイルの単位。
    nonisolated enum ClockUnit: Equatable, Sendable {
        case hours
        case minutes
        case seconds
    }

    /// 残りの時間・分・秒のタイル 1 つ。
    nonisolated struct ClockTile: Equatable, Sendable, Identifiable {
        let unit: ClockUnit
        /// 2 桁にそろえた数字（`07`）。
        let number: String
        /// 単位（`時間`）。
        let label: String

        init(unit: ClockUnit, value: Int, label: String) {
            self.unit = unit
            number = String(format: "%02d", value)
            self.label = label
        }

        var id: ClockUnit {
            unit
        }

        /// 1 秒ごとに進むタイル（推し色の枠と数字で目立たせる）。
        var isLive: Bool {
            unit == .seconds
        }
    }
}
