//
//  CalendarDay.swift
//  OshiCon
//

import Foundation

/// 暦の日付（年・月・日）。時刻とタイムゾーンを持たない。
///
/// 予定の日付は、書いた日付のまま持つ（遠征先で時差があっても、書いた日付のまま数える）。
/// 日数の差は暦の日数で数えるため、夏時間で 1 日が 23 時間や 25 時間になっても 1 日と数える。
nonisolated struct CalendarDay: Hashable, Comparable, Codable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    /// 月の末日より後の日は、その月の末日にそろえる（2/29 を平年にすると 2/28）。
    init(year: Int, month: Int, day: Int) {
        precondition((1...12).contains(month), "month は 1〜12 で指定する: \(month)")
        precondition(day >= 1, "day は 1 以上で指定する: \(day)")
        self.year = year
        self.month = month
        self.day = min(day, Self.numberOfDays(year: year, month: month))
    }

    /// `date` が `calendar` のタイムゾーンで何日かを求める。
    init(_ date: Date, calendar: Calendar) {
        let gregorian = Self.gregorian(matching: calendar)
        self.init(
            year: gregorian.component(.year, from: date),
            month: gregorian.component(.month, from: date),
            day: gregorian.component(.day, from: date)
        )
    }

    /// 保存した値を読むときも、月・日を確かめて末日にそろえる（壊れた値で落ちないよう、範囲外は読み込みの失敗にする）。
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let year = try container.decode(Int.self, forKey: .year)
        let month = try container.decode(Int.self, forKey: .month)
        let day = try container.decode(Int.self, forKey: .day)
        guard (1...12).contains(month), day >= 1 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "日付が範囲外: \(year)-\(month)-\(day)")
            )
        }
        self.init(year: year, month: month, day: day)
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// 同じ月日の別の年。2/29 は平年には 2/28 になる。
    func withYear(_ year: Int) -> Self {
        Self(year: year, month: month, day: day)
    }

    /// `days` 日後（負なら前）の日付。
    func adding(days: Int) -> Self {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = .gmt
        guard let date = gregorian.date(byAdding: .day, value: days, to: date(at: nil, calendar: gregorian)) else {
            preconditionFailure("日付を足せなかった: \(self) + \(days)")
        }
        return Self(date, calendar: gregorian)
    }

    /// `other` までの暦の日数。`other` が前の日なら負。
    func days(until other: Self) -> Int {
        other.dayNumber - dayNumber
    }

    /// この日の `time`（無ければ 0:00）の時刻を、`calendar` のタイムゾーンで求める。
    func date(at time: TimeOfDay?, calendar: Calendar) -> Date {
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: time?.hour ?? 0,
            minute: time?.minute ?? 0
        )
        guard let date = Self.gregorian(matching: calendar).date(from: components) else {
            preconditionFailure("西暦の日付から時刻を作れなかった: \(self)")
        }
        return date
    }

    /// 規則の計算に使う西暦の暦。端末の暦が和暦などでも年がずれないよう、タイムゾーンだけを引き継ぐ。
    static func gregorian(matching calendar: Calendar) -> Calendar {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        return gregorian
    }

    static func numberOfDays(year: Int, month: Int) -> Int {
        switch month {
        case 2:
            isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11:
            30
        default:
            31
        }
    }

    static func isLeapYear(_ year: Int) -> Bool {
        year.isMultiple(of: 4) && (!year.isMultiple(of: 100) || year.isMultiple(of: 400))
    }

    /// 1970/1/1 からの日数（先発グレゴリオ暦）。日数の差を暦の上で求めるために使う。
    private var dayNumber: Int {
        let shiftedYear = month <= 2 ? year - 1 : year
        let era = (shiftedYear >= 0 ? shiftedYear : shiftedYear - 399) / 400
        let yearOfEra = shiftedYear - era * 400
        let shiftedMonth = (month + 9) % 12
        let dayOfYear = (153 * shiftedMonth + 2) / 5 + day - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146_097 + dayOfEra - 719_468
    }
}

/// 開始の時刻（時・分）。予定の日付と同じく、書いた時刻のまま持つ。
nonisolated struct TimeOfDay: Hashable, Comparable, Codable, Sendable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) {
        precondition((0...23).contains(hour), "hour は 0〜23 で指定する: \(hour)")
        precondition((0...59).contains(minute), "minute は 0〜59 で指定する: \(minute)")
        self.hour = hour
        self.minute = minute
    }

    /// 保存した値を読むときも範囲を確かめる（壊れた値で落ちないよう、範囲外は読み込みの失敗にする）。
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hour = try container.decode(Int.self, forKey: .hour)
        let minute = try container.decode(Int.self, forKey: .minute)
        guard (0...23).contains(hour), (0...59).contains(minute) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "時刻が範囲外: \(hour):\(minute)")
            )
        }
        self.init(hour: hour, minute: minute)
    }

    /// 0:00 からの分。
    var minutesSinceMidnight: Int {
        hour * 60 + minute
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.minutesSinceMidnight < rhs.minutesSinceMidnight
    }
}
