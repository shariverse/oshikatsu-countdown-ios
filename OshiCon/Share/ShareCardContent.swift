//
//  ShareCardContent.swift
//  OshiCon
//

import Foundation

/// シェアのカード（予定の「あと N 日」の画像）に載せる中身（画面から切り離してテストする）。
/// `now` の時点の日数を `calendar` のタイムゾーンで数える。推しの名前は載せない。
nonisolated struct ShareCardContent: Equatable, Sendable {
    /// プレビューで切り替える、カードに載せる項目。
    struct Options: Equatable, Sendable {
        /// 会場。既定では載せない。
        var includesVenue = false
        /// 推しの写真。既定では載せる（写真が無ければ推し色の模様）。
        var includesPhoto = true
    }

    /// 日数の見せ方。
    enum Days: Equatable, Sendable {
        /// 開催日はまだ先（`あと`・`3`・`日`）。
        case remaining(EventText.CountdownParts)
        /// 当日（`今日！`）。開始の時刻があれば添える（`開演 17:00`）。
        case today(startTime: String?)
        /// 終わった予定（``・`3`・`日前`）。
        case ago(EventText.CountdownParts)
    }

    let title: String
    /// 開催日（毎年くり返す予定は次の回。ja `2026年10月18日(日)`）。くり返しの印は付けない。
    let dateText: String
    let days: Days
    /// 日数の 1 行（ja `あと 3 日`・`今日！ 開演 17:00`・`3 日前`）。
    let daysText: String
    /// 載せる会場。会場を載せない・会場の無い予定は nil。
    let venueText: String?
    /// 推し色。推しなしの予定は、どの推し色とも紛れない無彩色（ホームと同じ）。
    let color: OshiColor
    /// 載せる推しの写真のファイル名。写真を載せない・写真の無い推し・推しなしの予定は nil（推し色の模様にする）。
    let photoFileName: String?
    /// 透かし（App Store の名前のブランド部分。ja `推し活カウントダウン`、en `Oshi Countdown`）。
    let watermark: String
    /// 会場を載せる切り替えを出せるか（会場のある予定）。
    let canIncludeVenue: Bool
    /// 写真を載せる切り替えを出せるか（写真のある推しの予定）。
    let canIncludePhoto: Bool
    /// 文言と日付の書き方の言語（本文の書体を決める）。
    let locale: Locale

    init(event: OshiEvent, oshi: Oshi?, now: Date, calendar: Calendar, options: Options = Options(), locale: Locale = .app) {
        let countdown = EventCountdown(event: event, now: now, calendar: calendar)
        let venue = event.venue.trimmingCharacters(in: .whitespacesAndNewlines)
        let photoFileName = oshi?.photoFileName

        title = event.title
        dateText = EventText.fullDate(countdown.occurrenceDay, locale: locale)
        // 詳細の秒のカウントダウンと違い、当日は開始の時刻の前でも「今日」にする
        if countdown.daysUntil > 0 {
            days = .remaining(EventText.countdownParts(days: countdown.daysUntil, withPrefix: true, locale: locale))
            daysText = EventText.countdown(daysUntil: countdown.daysUntil, status: .upcoming, locale: locale)
        } else if countdown.daysUntil == 0 {
            let startTime = event.startTime.map { EventText.startTime($0, kind: event.kind, locale: locale) }
            days = .today(startTime: startTime)
            daysText = [EventText.today(locale: locale), startTime].compactMap { $0 }.joined(separator: " ")
        } else {
            days = .ago(EventText.daysAgoParts(days: -countdown.daysUntil, locale: locale))
            daysText = EventText.countdown(daysUntil: countdown.daysUntil, status: .ended, locale: locale)
        }
        canIncludeVenue = !venue.isEmpty
        venueText = options.includesVenue && !venue.isEmpty ? venue : nil
        color = oshi?.color ?? .black
        canIncludePhoto = photoFileName != nil
        self.photoFileName = options.includesPhoto ? photoFileName : nil
        watermark = Self.watermark(locale: locale)
        self.locale = locale
    }

    /// 読み上げ（`5th LIVE、2026年10月18日(日)、あと 3 日、東京ドーム`）。透かしは読まない。
    var accessibilityLabel: String {
        EventText.joinedForSpeech([title, dateText, daysText, venueText].compactMap { $0 }, locale: locale)
    }

    /// 透かしの文言。App Store の名前（`docs/app-store/metadata/`）のコロンより前のブランド名を言語ごとに出す。
    /// ホームのバーのタイトル（読み上げ用）と同じ文言を使う。
    static func watermark(locale: Locale = .app) -> String {
        String(localized: LocalizedStringResource("推し活カウントダウン", locale: locale))
    }
}
