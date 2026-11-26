//
//  SampleData+Screenshots.swift
//  OshiCon
//

import Foundation

/// App Store 用スクリーンショットで、見本の撮り方を替える（起動引数。`LaunchOptions` の `-sampleStreamStartsSoon`・`-sampleTopOshi`）。
nonisolated extension SampleData {
    /// 当日の配信の開始の時刻（`Content.startingStreamSoon(now:calendar:)`）。
    static func streamStartTime(now: Date, calendar: Calendar) -> TimeOfDay {
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let current = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let latest = 23 * 60 + 55
        let rounded = Int((Double(current + 38) / 5).rounded(.up)) * 5
        let minutes = rounded <= latest ? rounded : (current < latest ? latest : 23 * 60 + 59)
        return TimeOfDay(hour: minutes / 60, minute: minutes % 60)
    }
}

nonisolated extension SampleData.Content {
    /// 当日の配信（種類が配信の予定）の開始を `now` から 40 分ほど先にする（App Store 用スクリーンショット。`LaunchOptions.startsSampleStreamSoon`）。
    /// 開始は 38 分後を 5 分単位に切り上げた時刻。日付をまたがないよう 23:55 までにし、それも過ぎていれば 23:59 にする。
    func startingStreamSoon(now: Date, calendar: Calendar) -> Self {
        let start = SampleData.streamStartTime(now: now, calendar: calendar)
        let events = events.map { event in
            guard event.kind == .stream else {
                return event
            }
            var event = event
            event.startTime = start
            return event
        }
        return Self(oshis: oshis, events: events)
    }

    /// 役どころ `role` の推しを、推しの一覧のいちばん上（1 位。テーマの色になる）に移す（App Store 用スクリーンショット。`LaunchOptions.sampleTopOshi`）。
    /// ほかの推しの並びは変えない。
    func movingToTop(_ role: SampleData.Role) -> Self {
        guard let index = SampleData.Role.allCases.firstIndex(of: role), oshis.indices.contains(index) else {
            return self
        }
        var oshis = oshis
        let top = oshis.remove(at: index)
        oshis.insert(top, at: 0)
        return Self(oshis: oshis, events: events)
    }
}
