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

    /// 時:分:秒（`07:05:09`）。
    var clockText: String {
        let parts = countdown.remainingParts
        return String(format: "%02d:%02d:%02d", parts.hours, parts.minutes, parts.seconds)
    }

    /// 残りの日数を数字と単位に分けたもの（ja `3`・`日`、en `3`・`days`）。
    var remainingDaysParts: EventText.CountdownParts {
        EventText.countdownParts(days: countdown.remainingParts.days, withPrefix: false, locale: locale)
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

    /// 詳細の残りの読み上げ（`開演まで、残り 3日 7時間 5分`）。
    var countdownAccessibilityLabel: String {
        EventText.joinedForSpeech([untilLabel, remainingDescription], locale: locale)
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
