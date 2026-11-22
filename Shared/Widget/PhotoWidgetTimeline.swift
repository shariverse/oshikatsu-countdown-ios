//
//  PhotoWidgetTimeline.swift
//  OshiCon
//

import Foundation

/// 推しの写真ウィジェットのタイムラインに置くエントリの時刻と、その時刻に Plus が使えるか。ウィジェットから切り離してテストする。
///
/// - 今と、0:00（日付が変わったら数え直す）にエントリを置く
/// - Plus の期限（`PlusWidgetStatus.Resolution.expirationDate`）がエントリの範囲の中にあれば、期限の時刻にもエントリを置き、
///   期限からは Plus でない表示にする。期限の時刻に作り直し、StoreKit で確かめ直す（更新されていれば Plus の表示に戻る）
nonisolated enum PhotoWidgetTimeline {
    /// エントリ 1 つ。
    struct Moment: Equatable, Sendable {
        let date: Date
        let isPlusUnlocked: Bool
    }

    /// エントリと、作り直す時刻。
    struct Plan: Equatable, Sendable {
        let moments: [Moment]
        /// 作り直す時刻。nil なら最後のエントリの後（`.atEnd`）。
        let reloadDate: Date?
    }

    /// `now` からのエントリを決める。`plus` は `now` の時点で決めた Plus の状態。
    static func plan(now: Date, plus: PlusWidgetStatus.Resolution, midnightCount: Int, calendar: Calendar) -> Plan {
        let midnights = WidgetTimeline.nextMidnights(after: now, count: midnightCount, calendar: calendar)
        var dates = [now] + midnights
        var reloadDate: Date?
        if plus.isUnlocked, let expirationDate = plus.expirationDate, expirationDate > now,
           let lastDate = dates.last, expirationDate <= lastDate {
            reloadDate = expirationDate
            if !dates.contains(expirationDate) {
                dates.append(expirationDate)
                dates.sort()
            }
        }
        let moments = dates.map { date in
            Moment(date: date, isPlusUnlocked: isUnlocked(at: date, plus: plus))
        }
        return Plan(moments: moments, reloadDate: reloadDate)
    }

    /// `date` に Plus が使えるか。期限の時刻からは使えない（`PlusWidgetStatus.decision` と同じく期限の時刻は含まない）。
    private static func isUnlocked(at date: Date, plus: PlusWidgetStatus.Resolution) -> Bool {
        guard plus.isUnlocked else {
            return false
        }
        guard let expirationDate = plus.expirationDate else {
            return true
        }
        return date < expirationDate
    }
}
