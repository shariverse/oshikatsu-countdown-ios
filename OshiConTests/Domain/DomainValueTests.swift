//
//  DomainValueTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct DomainValueTests {
    @Test("誕生日を選ぶと毎年くり返す、ほかの種類はくり返さない")
    func repeatsYearlyWhenSelected() {
        #expect(EventKind.birthday.repeatsYearlyWhenSelected)
        #expect(EventKind.allCases.filter(\.repeatsYearlyWhenSelected) == [.birthday])
    }

    @Test("種類の文言と並び")
    func kindLabels() {
        #expect(EventKind.allCases.map { $0.label(locale: DomainFixtures.japanese) } == ["ライブ", "誕生日", "発売日", "配信", "その他"])
    }

    @Test("推し色は 12 色で、既定はピンク")
    func oshiColors() {
        #expect(OshiColor.allCases.count == 12)
        #expect(OshiColor.defaultColor == .pink)
    }

    @Test("保存した日付を読むと末日にそろえる")
    func decodeCalendarDayClampsToEndOfMonth() throws {
        let data = Data(#"{"year":2025,"month":2,"day":29}"#.utf8)
        #expect(try JSONDecoder().decode(CalendarDay.self, from: data) == DomainFixtures.day(2025, 2, 28))
    }

    @Test(
        "範囲外の日付は読み込みの失敗にする",
        arguments: [
            #"{"year":2026,"month":13,"day":1}"#,
            #"{"year":2026,"month":0,"day":1}"#,
            #"{"year":2026,"month":1,"day":0}"#
        ]
    )
    func decodeInvalidCalendarDayThrows(json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(CalendarDay.self, from: Data(json.utf8))
        }
    }

    @Test(
        "範囲外の時刻は読み込みの失敗にする",
        arguments: [#"{"hour":24,"minute":0}"#, #"{"hour":-1,"minute":0}"#, #"{"hour":12,"minute":60}"#]
    )
    func decodeInvalidTimeOfDayThrows(json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(TimeOfDay.self, from: Data(json.utf8))
        }
    }

    @Test("日付と時刻は保存して読み直しても同じ")
    func codableRoundTrip() throws {
        let day = DomainFixtures.day(2024, 2, 29)
        let time = TimeOfDay(hour: 23, minute: 59)
        #expect(try JSONDecoder().decode(CalendarDay.self, from: JSONEncoder().encode(day)) == day)
        #expect(try JSONDecoder().decode(TimeOfDay.self, from: JSONEncoder().encode(time)) == time)
    }
}
