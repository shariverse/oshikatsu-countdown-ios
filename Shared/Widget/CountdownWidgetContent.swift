//
//  CountdownWidgetContent.swift
//  OshiCon
//

import Foundation

/// カウントダウンウィジェット（予定 1 件）に出す中身。ウィジェットから切り離してテストする。
nonisolated enum CountdownWidgetContent: Equatable, Sendable {
    /// 選んだ予定。
    case event(Event)
    /// 予定をまだ選んでいない（置いたばかり）。
    case notSelected
    /// 選んだ予定が削除された。
    case missing

    /// 選んだ予定の中身。
    struct Event: Equatable, Sendable {
        let eventID: OshiEvent.ID
        /// 上に出す名前。推しの名前、推しなしの予定は種類。
        let heading: String
        let title: String
        let color: OshiColor
        let status: CountdownStatus
        let daysUntil: Int

        init(event: OshiEvent, oshi: Oshi?, today: CalendarDay) {
            let scheduled = ScheduledEvent(event: event, today: today)
            eventID = event.id
            heading = oshi?.name ?? event.kind.label
            title = event.title
            color = oshi?.color ?? .black
            status = scheduled.status
            daysUntil = scheduled.daysUntil
        }

        /// 読み上げ・1 行の表示（`あと 3 日`・`今日！`・`2 日前`）。
        var countdownText: String {
            EventText.countdown(daysUntil: daysUntil, status: status)
        }
    }

    /// `eventID` の予定を `events` から探して中身を作る。選んでいなければ `.notSelected`、見つからなければ `.missing`。
    init(eventID: OshiEvent.ID?, events: [OshiEvent], oshis: [Oshi], today: CalendarDay) {
        guard let eventID else {
            self = .notSelected
            return
        }
        guard let event = events.first(where: { $0.id == eventID }) else {
            self = .missing
            return
        }
        self = .event(Event(event: event, oshi: event.oshiID.flatMap { id in oshis.first { $0.id == id } }, today: today))
    }

    /// ウィジェットで選べる予定（当日とこれからの予定を近い順）。
    static func selectableEvents(_ events: [OshiEvent], today: CalendarDay) -> [OshiEvent] {
        EventSchedule(events: events, today: today).upcoming.map(\.event)
    }
}

/// ウィジェットのタイムラインの時刻。
nonisolated enum WidgetTimeline {
    /// `now` の後の 0:00 を `count` 回分。日付が変わったら残り日数を数え直すために、その時刻のエントリを作る。
    static func nextMidnights(after now: Date, count: Int, calendar: Calendar) -> [Date] {
        let gregorian = CalendarDay.gregorian(matching: calendar)
        guard count > 0 else {
            return []
        }
        let startOfToday = gregorian.startOfDay(for: now)
        return (1...count).compactMap { offset in
            gregorian.date(byAdding: .day, value: offset, to: startOfToday)
        }
    }
}

/// ウィジェットを押したときにアプリで開く画面のリンク（`oshicon://event/<id>` など）。アプリの外には出さない。
nonisolated enum WidgetLink: Equatable, Sendable {
    /// 予定の詳細。
    case eventDetail(OshiEvent.ID)
    /// 予定の追加。
    case addEvent
    /// アプリ（ホーム）を開くだけ。
    case home

    static let scheme = "oshicon"

    var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        switch self {
        case let .eventDetail(id):
            components.host = "event"
            components.path = "/\(id.uuidString)"
        case .addEvent:
            components.host = "add-event"
        case .home:
            components.host = "home"
        }
        guard let url = components.url else {
            preconditionFailure("ウィジェットのリンクを作れなかった: \(self)")
        }
        return url
    }

    /// アプリで受け取ったリンクを読む。知らないリンクは nil。
    init?(url: URL) {
        guard url.scheme == Self.scheme else {
            return nil
        }
        switch url.host() {
        case "event":
            guard let id = UUID(uuidString: String(url.path().dropFirst())) else {
                return nil
            }
            self = .eventDetail(id)
        case "add-event":
            self = .addEvent
        case "home":
            self = .home
        default:
            return nil
        }
    }
}
