//
//  OshiEvent.swift
//  OshiCon
//

import Foundation

/// カウントダウンする予定。
nonisolated struct OshiEvent: Identifiable, Hashable, Sendable {
    let id: UUID
    /// 結び付く推し。推しを登録せずに作った予定は nil。
    var oshiID: Oshi.ID?
    var kind: EventKind
    var title: String
    /// 開催日。毎年くり返す予定は最初の回の日付。
    var day: CalendarDay
    /// 開演・開始の時刻。決まっていなければ nil で、その日の 0:00 までを数える。
    var startTime: TimeOfDay?
    var venue: String
    /// 毎年くり返す（誕生日・記念日）。過ぎたら翌年の同じ日を数え、終わった予定にはならない。
    var repeatsYearly: Bool
    /// ホームの先頭に大きく出す。ピン留めできる予定は 1 件だけ。
    var isPinned: Bool
    /// 登録した時刻。詳細の進み具合の起点と、同じ日・同じ時刻の予定の並びに使う。
    let createdAt: Date

    init(
        id: UUID = UUID(),
        oshiID: Oshi.ID?,
        kind: EventKind,
        title: String,
        day: CalendarDay,
        startTime: TimeOfDay? = nil,
        venue: String = "",
        repeatsYearly: Bool = false,
        isPinned: Bool = false,
        createdAt: Date
    ) {
        self.id = id
        self.oshiID = oshiID
        self.kind = kind
        self.title = title
        self.day = day
        self.startTime = startTime
        self.venue = venue
        self.repeatsYearly = repeatsYearly
        self.isPinned = isPinned
        self.createdAt = createdAt
    }

    /// `today` から見て数える開催日。
    ///
    /// くり返さない予定は、過ぎていても登録した日付のまま。
    /// 毎年くり返す予定は、登録した日付がまだ来ていなければその日、過ぎていれば今年か来年の同じ日（今日を含む）。
    /// 2/29 の予定は、平年には 2/28 に数える。
    func occurrence(from today: CalendarDay) -> CalendarDay {
        guard repeatsYearly, day < today else {
            return day
        }
        let thisYear = day.withYear(today.year)
        return thisYear >= today ? thisYear : day.withYear(today.year + 1)
    }

    /// `occurrence` の 1 回前の開催日。くり返さない予定と、最初の回（登録した日付）は nil。
    /// 1 回前が最初の回より前になるとき（`occurrence(from:)` の値でない日付を渡したとき）も nil。
    func previousOccurrence(before occurrence: CalendarDay) -> CalendarDay? {
        guard repeatsYearly, day < occurrence else {
            return nil
        }
        let previous = day.withYear(occurrence.year - 1)
        return previous >= day ? previous : nil
    }
}

/// 予定の種類。並びは選ぶ画面に出す順。
nonisolated enum EventKind: String, CaseIterable, Codable, Sendable {
    case live
    case birthday
    case release
    case stream
    case other

    var label: String {
        switch self {
        case .live:
            "ライブ"
        case .birthday:
            "誕生日"
        case .release:
            "発売日"
        case .stream:
            "配信"
        case .other:
            "その他"
        }
    }

    /// この種類を選んだときの「毎年くり返す」。誕生日を選ぶと ON、ほかの種類を選ぶと OFF にする（あとから切り替えられる）。
    var repeatsYearlyWhenSelected: Bool {
        self == .birthday
    }
}
