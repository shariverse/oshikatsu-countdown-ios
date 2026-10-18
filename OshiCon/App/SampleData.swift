//
//  SampleData.swift
//  OshiCon
//

import Foundation

/// App Store 用スクリーンショットの見本の推しと予定。起動引数 `-seedSampleData` を付け、メモリ上のストアで起動したときだけ入れる。
/// 実在の人物・作品名・ロゴは使わない。日付は今日から数えて決めるので、いつ撮っても同じ残り日数になる。
nonisolated enum SampleData {
    struct Content: Sendable {
        let oshis: [Oshi]
        let events: [OshiEvent]
    }

    /// `today` から見た見本。`now` は登録した時刻（進み具合の起点）に使う。
    static func make(today: CalendarDay, now: Date) -> Content {
        let lumina = Oshi(name: "LUMINA", color: .pink)
        let minato = Oshi(name: "ミナト", color: .navy)
        let sora = Oshi(name: "ソラ", color: .mint)
        let hinata = Oshi(name: "ひなた", color: .orange)
        let registeredAt = now.addingTimeInterval(-36 * 86_400)
        let events = [
            OshiEvent(
                oshiID: lumina.id,
                kind: .live,
                title: "5th LIVE 東京公演",
                day: today.adding(days: 12),
                startTime: TimeOfDay(hour: 17, minute: 0),
                venue: "東京ドーム",
                isPinned: true,
                createdAt: registeredAt
            ),
            OshiEvent(
                oshiID: minato.id,
                kind: .birthday,
                title: "ミナトの誕生日",
                // 誕生日らしく過去の年にする。平年だと 2/29 が 2/28 に丸められるので、うるう年の 2000 年にする
                day: today.adding(days: 3).withYear(2000),
                repeatsYearly: true,
                createdAt: registeredAt
            ),
            OshiEvent(
                oshiID: sora.id,
                kind: .release,
                title: "2nd シングル発売",
                day: today.adding(days: 25),
                startTime: TimeOfDay(hour: 0, minute: 0),
                createdAt: registeredAt
            ),
            OshiEvent(
                oshiID: hinata.id,
                kind: .stream,
                title: "1 周年記念の生配信",
                day: today,
                startTime: TimeOfDay(hour: 21, minute: 0),
                createdAt: registeredAt
            ),
            OshiEvent(
                oshiID: nil,
                kind: .other,
                title: "遠征の宿を予約",
                day: today.adding(days: 6),
                createdAt: registeredAt
            )
        ]
        return Content(oshis: [lumina, minato, sora, hinata], events: events)
    }
}
