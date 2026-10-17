//
//  EventForm.swift
//  OshiCon
//

import Foundation

/// 予定の追加・編集の入力と、その規則（画面から切り離してテストする）。
///
/// タイトル・会場は打っている途中では切らない（日本語の変換中に切らないため）。上限を超えたら保存できない。
nonisolated struct EventForm: Equatable, Sendable {
    /// 選んでいる推し。nil は「推しなし」。
    var oshiID: Oshi.ID?
    private(set) var kind: EventKind
    var title: String
    var day: CalendarDay
    var startTime: TimeOfDay?
    var venue: String
    var repeatsYearly: Bool

    /// 開始時刻を初めて決めるときの時刻。
    static let defaultStartTime = TimeOfDay(hour: 18, minute: 0)

    /// 新しく追加するときは `event` に nil を渡す。
    ///
    /// - 追加: 日付は今日、種類はライブ。推しは `preselectedOshiID`（登録した推しにあれば）か、先頭の推し。推しがいなければ「推しなし」
    /// - 編集: 予定の中身から始める。結び付いた推しが見つからなければ「推しなし」
    init(event: OshiEvent?, oshis: [Oshi], today: CalendarDay, preselectedOshiID: Oshi.ID? = nil) {
        let oshiIDs = Set(oshis.map(\.id))
        if let event {
            oshiID = event.oshiID.flatMap { oshiIDs.contains($0) ? $0 : nil }
            kind = event.kind
            title = event.title
            day = event.day
            startTime = event.startTime
            venue = event.venue
            repeatsYearly = event.repeatsYearly
        } else {
            oshiID = preselectedOshiID.flatMap { oshiIDs.contains($0) ? $0 : nil } ?? oshis.first?.id
            kind = .live
            title = ""
            day = today
            startTime = nil
            venue = ""
            repeatsYearly = EventKind.live.repeatsYearlyWhenSelected
        }
    }

    /// 種類を選ぶ。誕生日を選ぶと「毎年くり返す」を ON、ほかの種類を選ぶと OFF にする（あとから切り替えられる）。
    mutating func selectKind(_ kind: EventKind) {
        guard kind != self.kind else {
            return
        }
        self.kind = kind
        repeatsYearly = kind.repeatsYearlyWhenSelected
    }

    /// 保存できるか。タイトルが空白だけ・タイトルか会場が上限を超えるときは保存できない。
    var canSave: Bool {
        InputField.eventTitle.isValid(title)
            && !InputField.eventTitle.exceedsLimit(title)
            && !InputField.eventVenue.exceedsLimit(venue)
    }

    /// 保存する予定。保存できないときは nil。
    ///
    /// - Parameters:
    ///   - existing: 編集中の予定。ピン留めと登録した時刻は引き継ぐ。
    ///   - newEventID: 新しく追加するときの id。画面で一度だけ作って渡す（保存のやり直しで重ねて追加しないため）。
    ///   - now: 新しく追加するときの登録した時刻。
    func makeEvent(existing: OshiEvent?, newEventID: OshiEvent.ID, now: Date) -> OshiEvent? {
        guard canSave else {
            return nil
        }
        return OshiEvent(
            id: existing?.id ?? newEventID,
            oshiID: oshiID,
            kind: kind,
            title: InputField.eventTitle.normalized(title),
            day: day,
            startTime: startTime,
            venue: InputField.eventVenue.normalized(venue),
            repeatsYearly: repeatsYearly,
            isPinned: existing?.isPinned ?? false,
            createdAt: existing?.createdAt ?? now
        )
    }
}
