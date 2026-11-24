//
//  SampleDataScreenshotTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import SwiftUI
import Testing

/// App Store 用スクリーンショットで見本の撮り方を替える規則（`SampleData+Screenshots`）と、その起動引数（`LaunchOptions`）。
struct SampleDataScreenshotTests {
    private let today = DomainFixtures.day(2026, 10, 18)
    private let now = DomainFixtures.date(2026, 10, 18, 9, 41)

    @Test("当日の配信の開始は、38 分後を 5 分単位に切り上げた時刻。日付をまたがないよう 23:55 まで、過ぎていれば 23:59", arguments: [
        (9, 41, TimeOfDay(hour: 10, minute: 20)),
        (20, 22, TimeOfDay(hour: 21, minute: 0)),
        (20, 17, TimeOfDay(hour: 20, minute: 55)),
        (23, 10, TimeOfDay(hour: 23, minute: 50)),
        (23, 30, TimeOfDay(hour: 23, minute: 55)),
        (23, 56, TimeOfDay(hour: 23, minute: 59))
    ])
    func streamStartTime(hour: Int, minute: Int, expected: TimeOfDay) {
        let now = DomainFixtures.date(2026, 10, 18, hour, minute)
        #expect(SampleData.streamStartTime(now: now, calendar: DomainFixtures.tokyo) == expected)
    }

    @Test("開始を近くにするのは当日の配信だけで、ほかの予定の時刻は変えない")
    func startingStreamSoon() {
        let sample = SampleData.make(today: today, now: now, language: .japanese)
        let changed = sample.startingStreamSoon(now: now, calendar: DomainFixtures.tokyo)
        for (before, after) in zip(sample.events, changed.events) {
            if before.kind == .stream {
                #expect(after.startTime == TimeOfDay(hour: 10, minute: 20))
                #expect(after.day == today)
            } else {
                #expect(after == before)
            }
        }
        #expect(changed.events.contains { $0.kind == .stream })
        #expect(changed.oshis == sample.oshis)
    }

    @Test("1 位にする推しだけを先頭に移し、ほかの推しの並びと予定は変えない")
    func movingToTop() {
        let sample = SampleData.make(today: today, now: now, language: .japanese)
        let moved = sample.movingToTop(.singer)
        #expect(moved.oshis.map(\.name) == ["ソラ", "LUMINA", "ミナト", "レオ", "レン", "ひなた"])
        #expect(moved.events == sample.events)
        #expect(sample.movingToTop(.group).oshis == sample.oshis)
    }

    @Test("1 位にする推しの起動引数は、見本を入れるときだけ、役どころの生の値を読む")
    func sampleTopOshiArgument() {
        #expect(LaunchOptions.sampleTopOshi(arguments: ["-sampleTopOshi", "voice-actor"], seedsSampleData: true) == .voiceActor)
        #expect(LaunchOptions.sampleTopOshi(arguments: ["-sampleTopOshi", "voice-actor"], seedsSampleData: false) == nil)
        #expect(LaunchOptions.sampleTopOshi(arguments: ["-sampleTopOshi", "unknown"], seedsSampleData: true) == nil)
        #expect(LaunchOptions.sampleTopOshi(arguments: ["-sampleTopOshi"], seedsSampleData: true) == nil)
    }

    @Test("外観を固定する起動引数は、メモリ上のストアのときだけ効く")
    func forcedColorScheme() {
        #expect(LaunchOptions.forcedColorScheme(arguments: ["-useInMemoryStore", "-colorScheme", "light"]) == .light)
        #expect(LaunchOptions.forcedColorScheme(arguments: ["-useInMemoryStore", "-colorScheme", "dark"]) == .dark)
        #expect(LaunchOptions.forcedColorScheme(arguments: ["-colorScheme", "light"]) == nil)
        #expect(LaunchOptions.forcedColorScheme(arguments: ["-useInMemoryStore", "-colorScheme", "sepia"]) == nil)
        #expect(LaunchOptions.forcedColorScheme(arguments: ["-useInMemoryStore"]) == nil)
    }
}
