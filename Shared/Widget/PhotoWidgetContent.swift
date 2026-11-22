//
//  PhotoWidgetContent.swift
//  OshiCon
//

import Foundation

/// 推しの写真ウィジェット（Plus。予定 1 件）に出す中身。ウィジェットから切り離してテストする。
/// 選んでいない・削除された・読めないときは、カウントダウンウィジェット（`CountdownWidgetContent`）と同じに扱う。
nonisolated enum PhotoWidgetContent: Equatable, Sendable {
    /// 選んだ予定。
    case event(Event)
    /// 予定をまだ選んでいない（置いたばかり）。
    case notSelected
    /// 選んだ予定が削除された。
    case missing
    /// ストアを読めなかった（再起動後の最初のロック解除前など）。しばらくしてから読み直す。
    case unavailable

    /// 選んだ予定の中身。
    struct Event: Equatable, Sendable {
        let eventID: OshiEvent.ID
        let title: String
        /// 推しの名前。推しなしの予定は nil。
        let oshiName: String?
        /// 推しの名前の代わりに出す名前。推しの名前、推しなしの予定は種類。
        let heading: String
        /// 推し色。推しなしの予定は無彩色。写真が無いときの模様の色。
        let color: OshiColor
        /// 推しの写真（App Group の Photos のファイル名）。推しなし・写真なしは nil。
        let photoFileName: String?
        let status: CountdownStatus
        let daysUntil: Int
        /// 数える開催日（毎年くり返す予定は次の回）。
        let occurrenceDay: CalendarDay
        /// Plus が使えるか。使えなければ、薄くした見本に「Plus で使えます」を重ねて出す。
        let isPlusUnlocked: Bool
        /// 文言の言語。
        let locale: Locale

        init(event: OshiEvent, oshi: Oshi?, isPlusUnlocked: Bool, today: CalendarDay, locale: Locale = .app) {
            let scheduled = ScheduledEvent(event: event, today: today)
            self.locale = locale
            eventID = event.id
            title = event.title
            oshiName = oshi?.name
            heading = oshi?.name ?? event.kind.label(locale: locale)
            color = oshi?.color ?? .black
            photoFileName = oshi?.photoFileName
            status = scheduled.status
            daysUntil = scheduled.daysUntil
            occurrenceDay = scheduled.occurrenceDay
            self.isPlusUnlocked = isPlusUnlocked
        }

        /// 読み上げ・1 行の表示（`あと 3 日`・`今日！`・`2 日前`）。
        var countdownText: String {
            EventText.countdown(daysUntil: daysUntil, status: status, locale: locale)
        }

        /// 「あと N 日」を数字と前後の文言に分けたもの。
        var countdownParts: EventText.CountdownParts {
            EventText.countdownParts(days: daysUntil, withPrefix: true, locale: locale)
        }

        /// 中のサイズの日付（ja `10月18日(日)`、en `Sun, Oct 18`）。
        var dateText: String {
            EventText.monthDayWeekday(occurrenceDay, locale: locale)
        }

        /// 読み上げ（`ミナト、5th LIVE、あと 3 日、10月21日 水曜日`）。
        var accessibilityLabel: String {
            EventText.joinedForSpeech(
                [heading, title, countdownText, EventText.spokenMonthDayWeekday(occurrenceDay, locale: locale)],
                locale: locale
            )
        }

        /// 押したときに開く画面。Plus が使えれば予定の詳細、使えなければ課金画面。
        var link: WidgetLink {
            isPlusUnlocked ? .eventDetail(eventID) : .plusPaywall(eventID)
        }
    }

    /// `eventID` の予定を `events` から探して中身を作る。選んでいなければ `.notSelected`、見つからなければ `.missing`。
    /// タイムラインでは、エントリの時刻を端末のタイムゾーンの日付にして `today` に渡す（`CalendarDay(_:calendar:)`）。
    init(eventID: OshiEvent.ID?, events: [OshiEvent], oshis: [Oshi], isPlusUnlocked: Bool, today: CalendarDay, locale: Locale = .app) {
        guard let eventID else {
            self = .notSelected
            return
        }
        guard let event = events.first(where: { $0.id == eventID }) else {
            self = .missing
            return
        }
        let oshi = event.oshiID.flatMap { id in oshis.first { $0.id == id } }
        self = .event(Event(event: event, oshi: oshi, isPlusUnlocked: isPlusUnlocked, today: today, locale: locale))
    }

    /// 押したときに開く画面。予定はその中身のリンク、ほかはカウントダウンウィジェットと同じくアプリを開くだけ。
    var link: WidgetLink {
        switch self {
        case let .event(event):
            event.link
        case .notSelected, .missing, .unavailable:
            .home
        }
    }
}
