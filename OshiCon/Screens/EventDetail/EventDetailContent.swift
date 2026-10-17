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

    init(event: OshiEvent, oshi: Oshi?, now: Date, calendar: Calendar) {
        self.event = event
        self.oshi = oshi
        countdown = EventCountdown(event: event, now: now, calendar: calendar)
    }

    /// 推し色。推しなしの予定は、どの推し色とも紛れない無彩色（ホームと同じ）。
    var color: OshiColor {
        oshi?.color ?? .black
    }

    /// 種類の横に出す推しの名前。
    var oshiName: String {
        oshi?.name ?? "推しなし"
    }

    /// 残りの見出し（`開演まで`。時刻が無ければ `当日まで`）。
    var untilLabel: String {
        event.startTime == nil ? "当日まで" : "\(EventText.startLabel(of: event.kind))まで"
    }

    /// 時:分:秒（`07:05:09`）。
    var clockText: String {
        let parts = countdown.remainingParts
        return String(format: "%02d:%02d:%02d", parts.hours, parts.minutes, parts.seconds)
    }

    /// 残りの読み上げ（`残り 3 日 7 時間 5 分`。秒は毎秒変わるので読まない）。
    var remainingDescription: String {
        let parts = countdown.remainingParts
        return "残り \(parts.days) 日 \(parts.hours) 時間 \(parts.minutes) 分"
    }

    /// 終わった予定の「N 日前」。
    var daysAgoText: String {
        EventText.countdown(daysUntil: countdown.daysUntil, status: .ended)
    }

    /// 進み具合の割合（`76`）。進み具合を出せないときは nil。
    var progressPercent: Int? {
        countdown.progress.map { Int(($0 * 100).rounded()) }
    }

    /// 進み具合のバーの左端（`登録 9/2`）。
    var progressStartText: String {
        "登録 \(EventText.shortDate(countdown.progressStartDay))"
    }

    /// 進み具合のバーの右端（`当日 10/18`）。
    var progressEndText: String {
        "当日 \(EventText.shortDate(countdown.occurrenceDay))"
    }

    /// 日時（`10月18日(日) 開演 17:00`。時刻が無ければ日付だけ）。
    var dateText: String {
        let date = EventText.monthDayWeekday(countdown.occurrenceDay)
        guard let startTime = event.startTime else {
            return date
        }
        return "\(date) \(EventText.startTime(startTime, kind: event.kind))"
    }

    /// 削除の確認の本文。
    var deleteMessage: String {
        "「\(event.title)」を削除します。元に戻せません。"
    }
}
