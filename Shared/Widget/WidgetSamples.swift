//
//  WidgetSamples.swift
//  OshiCon
//

import Foundation

extension CountdownWidgetContent {
    /// ウィジェットの一覧とアプリの Preview に出す見本。
    nonisolated static var sample: Self {
        let oshi = Oshi(name: "LUMINA", color: .pink)
        let today = CalendarDay(.now, calendar: .autoupdatingCurrent)
        let event = OshiEvent(
            oshiID: oshi.id,
            kind: .live,
            title: String(localized: "5th LIVE 東京公演", comment: "ウィジェットの一覧に出す見本の予定名"),
            day: CalendarDay(Date.now.addingTimeInterval(86_400 * 11), calendar: .autoupdatingCurrent),
            createdAt: .now
        )
        // ロック画面の丸の輪の見本（登録してから開始までの 3 分の 2 ほど）
        return .event(.init(event: event, oshi: oshi, today: today, progress: 0.65))
    }
}

extension PhotoWidgetContent {
    /// ウィジェットの一覧とアプリの Preview に出す見本（Plus が使えるとき）。写真は持たないので、推し色の模様で描く。
    nonisolated static var sample: Self {
        sample(isPlusUnlocked: true)
    }

    /// Plus が使える・使えないときの見本。
    nonisolated static func sample(isPlusUnlocked: Bool) -> Self {
        let oshi = Oshi(name: "LUMINA", color: .pink)
        let today = CalendarDay(.now, calendar: .autoupdatingCurrent)
        let event = OshiEvent(
            oshiID: oshi.id,
            kind: .live,
            title: String(localized: "5th LIVE 東京公演", comment: "ウィジェットの一覧に出す見本の予定名"),
            day: CalendarDay(Date.now.addingTimeInterval(86_400 * 11), calendar: .autoupdatingCurrent),
            createdAt: .now
        )
        return .event(.init(event: event, oshi: oshi, isPlusUnlocked: isPlusUnlocked, today: today))
    }
}

extension UpcomingWidgetContent {
    /// ウィジェットの一覧とアプリの Preview に出す見本。
    nonisolated static var sample: Self {
        let calendar = Calendar.autoupdatingCurrent
        let today = CalendarDay(.now, calendar: calendar)
        let day = { (days: Double) in CalendarDay(Date.now.addingTimeInterval(86_400 * days), calendar: calendar) }
        let lumina = Oshi(name: "LUMINA", color: .pink)
        let minato = Oshi(name: String(localized: "ミナト"), color: .navy)
        let sora = Oshi(name: String(localized: "ソラ"), color: .mint)
        // 見本の名前と予定名はアプリの言語で出す
        let events = [
            OshiEvent(oshiID: minato.id, kind: .birthday, title: String(localized: "ミナトの誕生日"), day: today, createdAt: .now),
            OshiEvent(oshiID: lumina.id, kind: .live, title: String(localized: "5th LIVE 東京公演"), day: day(12), createdAt: .now),
            OshiEvent(oshiID: sora.id, kind: .release, title: String(localized: "2nd シングル発売"), day: day(25), createdAt: .now)
        ]
        return Self(events: events, oshis: [lumina, minato, sora], today: today, maxRows: maxRows)
    }
}

extension EventActivityAttributes {
    /// ライブアクティビティの Preview に出す見本（開演まであと 1 時間 30 分）。
    nonisolated static var sample: Self {
        let start = Date.now.addingTimeInterval(90 * 60)
        return Self(
            eventID: UUID(),
            heading: "LUMINA",
            title: String(localized: "5th LIVE 東京公演", comment: "ウィジェットの一覧に出す見本の予定名"),
            colorRawValue: OshiColor.pink.rawValue,
            startDate: start,
            countdownBegin: start.addingTimeInterval(-3 * 3_600),
            untilText: EventText.untilLabel(kind: .live, hasStartTime: true),
            startText: EventText.startTime(TimeOfDay(hour: 18, minute: 0), kind: .live),
            startedText: String(localized: "今日は当日！")
        )
    }
}
