//
//  SampleData.swift
//  OshiCon
//

import Foundation
import SwiftData

/// App Store 用スクリーンショットの見本の推しと予定。起動引数 `-seedSampleData` を付け、メモリ上のストアで起動したときだけ入れる。
/// 実在の人物・作品名・ロゴは使わない。日付は今日から数えて決めるので、いつ撮っても同じ残り日数になる。
/// スクリーンショットは言語ごとに撮るので、名前と予定名は言語ごとに用意する。
nonisolated enum SampleData {
    struct Content: Sendable {
        let oshis: [Oshi]
        let events: [OshiEvent]
    }

    /// 見本を用意している言語。`en` を既定にする。
    enum Language: String, CaseIterable, Sendable {
        case english = "en"
        case japanese = "ja"
        case simplifiedChinese = "zh-Hans"
        case traditionalChinese = "zh-Hant"
        case korean = "ko"
        case french = "fr"
        case german = "de"
        case spanish = "es"
        case brazilianPortuguese = "pt-BR"
        case italian = "it"
        case thai = "th"
        case indonesian = "id"

        /// `locale` の言語コードで選ぶ。中国語は字体（無ければ地域）で簡体・繁体を分け、用意していない言語は英語にする。
        init(_ locale: Locale) {
            let language = locale.language
            let code = language.languageCode?.identifier
            switch code {
            case "zh":
                let traditionalRegions: Set = ["TW", "HK", "MO"]
                if let script = language.script {
                    self = script == .hanTraditional ? .traditionalChinese : .simplifiedChinese
                } else if let region = language.region?.identifier, traditionalRegions.contains(region) {
                    self = .traditionalChinese
                } else {
                    self = .simplifiedChinese
                }
            case "pt":
                self = .brazilianPortuguese
            default:
                self = code.flatMap(Self.init(rawValue:)) ?? .english
            }
        }
    }

    /// `today` から見た見本。`now` は登録した時刻（進み具合の起点）に使う。名前と予定名は `locale` の言語で選ぶ。
    static func make(today: CalendarDay, now: Date, locale: Locale) -> Content {
        make(today: today, now: now, language: Language(locale))
    }

    static func make(today: CalendarDay, now: Date, language: Language) -> Content {
        let text = Strings.byLanguage[language] ?? .english
        let cast = Cast(text)
        let registeredAt = now.addingTimeInterval(-36 * 86_400)
        return Content(oshis: cast.all, events: events(of: cast, text: text, today: today, registeredAt: registeredAt))
    }

    // swiftlint:disable:next function_body_length
    private static func events(of cast: Cast, text: Strings, today: CalendarDay, registeredAt: Date) -> [OshiEvent] {
        [
            OshiEvent(
                oshiID: cast.group.id,
                kind: .live,
                title: text.domeLive,
                day: today.adding(days: 12),
                startTime: TimeOfDay(hour: 17, minute: 0),
                venue: text.domeVenue,
                isPinned: true,
                createdAt: registeredAt
            ),
            OshiEvent(
                oshiID: cast.voiceActor.id,
                kind: .birthday,
                title: text.birthday,
                // 誕生日らしく過去の年にする。平年だと 2/29 が 2/28 に丸められるので、うるう年の 2000 年にする
                day: today.adding(days: 3).withYear(2000),
                repeatsYearly: true,
                createdAt: registeredAt
            ),
            OshiEvent(
                oshiID: cast.streamer.id,
                kind: .stream,
                title: text.anniversaryStream,
                day: today,
                startTime: TimeOfDay(hour: 21, minute: 0),
                createdAt: registeredAt
            ),
            OshiEvent(
                oshiID: nil,
                kind: .other,
                title: text.hotel,
                day: today.adding(days: 6),
                createdAt: registeredAt
            ),
            OshiEvent(
                oshiID: cast.character.id,
                kind: .other,
                title: text.goodsDeadline,
                day: today.adding(days: 9),
                startTime: TimeOfDay(hour: 23, minute: 59),
                createdAt: registeredAt
            ),
            OshiEvent(
                oshiID: cast.stageActor.id,
                kind: .live,
                title: text.stageFinale,
                day: today.adding(days: 18),
                startTime: TimeOfDay(hour: 13, minute: 0),
                createdAt: registeredAt
            ),
            OshiEvent(
                oshiID: cast.character.id,
                kind: .release,
                title: text.moviePremiere,
                day: today.adding(days: 25),
                createdAt: registeredAt
            ),
            OshiEvent(
                oshiID: cast.singer.id,
                kind: .live,
                title: text.fanMeeting,
                day: today.adding(days: 32),
                startTime: TimeOfDay(hour: 18, minute: 0),
                createdAt: registeredAt
            )
        ]
    }
}

private extension SampleData {
    /// 言語ごとの推しの名前と予定名。作品名・会場以外の固有名は、その言語の人に自然な架空の名前にする。
    /// 画面で切れないよう、タイトルは短めにする（上限は `InputField`）。
    nonisolated struct Strings: Sendable {
        /// 声優（誕生日を祝う推し）
        let voiceActor: String
        /// アニメのキャラクター（劇場版とグッズの推し）
        let character: String
        /// 舞台俳優（2.5 次元舞台の推し）
        let stageActor: String
        /// 配信者
        let streamer: String
        /// 歌手（ファンミーティングの推し）
        let singer: String
        let domeLive: String
        let domeVenue: String
        let birthday: String
        let anniversaryStream: String
        let hotel: String
        let goodsDeadline: String
        let stageFinale: String
        let moviePremiere: String
        let fanMeeting: String
    }

    /// 見本の推し。登録した順（推しの一覧の並び）に `all` に並べる。
    nonisolated struct Cast: Sendable {
        // アイドルグループは英字の名前なので、どの言語でも同じにする（スクリーンショットの UI テストもこの名前で推しの行を探す）
        let group = Oshi(name: "LUMINA", color: .pink)
        let voiceActor: Oshi
        let character: Oshi
        let stageActor: Oshi
        let streamer: Oshi
        let singer: Oshi

        init(_ text: Strings) {
            voiceActor = Oshi(name: text.voiceActor, color: .navy)
            character = Oshi(name: text.character, color: .red)
            stageActor = Oshi(name: text.stageActor, color: .purple)
            streamer = Oshi(name: text.streamer, color: .orange)
            singer = Oshi(name: text.singer, color: .mint)
        }

        var all: [Oshi] {
            [group, voiceActor, character, stageActor, streamer, singer]
        }
    }
}

nonisolated private extension SampleData.Strings {
    static let english = Self(
        voiceActor: "Minato",
        character: "Leo",
        stageActor: "Ethan",
        streamer: "Ivy",
        singer: "Jade",
        domeLive: "Dome Tour: Tokyo Night",
        domeVenue: "Tokyo Dome",
        birthday: "Minato's Birthday",
        anniversaryStream: "3rd Anniversary Stream",
        hotel: "Book a hotel for the trip",
        goodsDeadline: "Acrylic stand preorders close",
        stageFinale: "Moonblade Stage: Final Show",
        moviePremiere: "Starsea Arcadia: The Movie",
        fanMeeting: "Fan Meeting"
    )

    static let japanese = Self(
        voiceActor: "ミナト",
        character: "レオ",
        stageActor: "レン",
        streamer: "ひなた",
        singer: "ソラ",
        domeLive: "ドームツアー 東京公演",
        domeVenue: "東京ドーム",
        birthday: "ミナトの誕生日",
        anniversaryStream: "活動 3 周年の記念配信",
        hotel: "遠征の宿を予約",
        goodsDeadline: "ランダムアクスタの予約締切",
        stageFinale: "舞台『蒼月の剣』大千秋楽",
        moviePremiere: "劇場版『星海のアルカディア』公開",
        fanMeeting: "ファンミーティング"
    )

    static let simplifiedChinese = Self(
        voiceActor: "沈墨",
        character: "雷欧",
        stageActor: "陆川",
        streamer: "小葵",
        singer: "苏晴",
        domeLive: "巨蛋巡演 东京站",
        domeVenue: "东京巨蛋",
        birthday: "沈墨的生日",
        anniversaryStream: "出道三周年纪念直播",
        hotel: "预订远征酒店",
        goodsDeadline: "盲盒亚克力立牌预订截止",
        stageFinale: "舞台剧《苍月之剑》千秋乐",
        moviePremiere: "剧场版《星海阿卡迪亚》上映",
        fanMeeting: "粉丝见面会"
    )

    static let traditionalChinese = Self(
        voiceActor: "沈墨",
        character: "雷歐",
        stageActor: "陸川",
        streamer: "小葵",
        singer: "蘇晴",
        domeLive: "巨蛋巡演 東京場",
        domeVenue: "東京巨蛋",
        birthday: "沈墨的生日",
        anniversaryStream: "出道三週年紀念直播",
        hotel: "預訂遠征住宿",
        goodsDeadline: "盲盒壓克力立牌預購截止",
        stageFinale: "舞台劇《蒼月之劍》千秋樂",
        moviePremiere: "劇場版《星海阿卡迪亞》上映",
        fanMeeting: "粉絲見面會"
    )

    static let korean = Self(
        voiceActor: "도윤",
        character: "레오",
        stageActor: "서진",
        streamer: "하늘",
        singer: "유나",
        domeLive: "돔 투어 도쿄 공연",
        domeVenue: "도쿄돔",
        birthday: "도윤 생일",
        anniversaryStream: "데뷔 3주년 기념 방송",
        hotel: "원정 숙소 예약",
        goodsDeadline: "랜덤 아크릴 스탠드 예약 마감",
        stageFinale: "뮤지컬 〈푸른 달의 검〉 막공",
        moviePremiere: "극장판 〈별바다의 아르카디아〉 개봉",
        fanMeeting: "팬미팅"
    )

    static let french = Self(
        voiceActor: "Minato",
        character: "Léo",
        stageActor: "Lucas",
        streamer: "Chloé",
        singer: "Inès",
        domeLive: "Tournée des dômes : Tokyo",
        domeVenue: "Tokyo Dome",
        birthday: "Anniversaire de Minato",
        anniversaryStream: "Live spécial 3 ans",
        hotel: "Réserver l'hôtel du voyage",
        goodsDeadline: "Acryliques : fin des préco",
        stageFinale: "Lame de lune : dernière",
        moviePremiere: "Sortie du film Arcadia",
        fanMeeting: "Rencontre avec les fans"
    )

    static let german = Self(
        voiceActor: "Minato",
        character: "Leo",
        stageActor: "Jonas",
        streamer: "Mia",
        singer: "Lena",
        domeLive: "Dome-Tour: Tokio",
        domeVenue: "Tokyo Dome",
        birthday: "Minatos Geburtstag",
        anniversaryStream: "Stream zum 3. Jubiläum",
        hotel: "Hotel für die Reise buchen",
        goodsDeadline: "Vorbestellschluss Acrylfiguren",
        stageFinale: "Mondklinge: Dernière",
        moviePremiere: "Kinostart: Sternenmeer Arcadia",
        fanMeeting: "Fan-Meeting"
    )

    static let spanish = Self(
        voiceActor: "Minato",
        character: "Leo",
        stageActor: "Mateo",
        streamer: "Lucía",
        singer: "Sofía",
        domeLive: "Gira de domos: Tokio",
        domeVenue: "Tokyo Dome",
        birthday: "Cumpleaños de Minato",
        anniversaryStream: "Directo del 3.er aniversario",
        hotel: "Reservar hotel para el viaje",
        goodsDeadline: "Fin de reservas de acrílicos",
        stageFinale: "Hoja Lunar: última función",
        moviePremiere: "Estreno de la película Arcadia",
        fanMeeting: "Encuentro con fans"
    )

    static let brazilianPortuguese = Self(
        voiceActor: "Minato",
        character: "Leo",
        stageActor: "Gabriel",
        streamer: "Luana",
        singer: "Bia",
        domeLive: "Turnê de domos: Tóquio",
        domeVenue: "Tokyo Dome",
        birthday: "Aniversário do Minato",
        anniversaryStream: "Live de 3 anos de canal",
        hotel: "Reservar hotel da viagem",
        goodsDeadline: "Fim da pré-venda de acrílicos",
        stageFinale: "Lâmina Lunar: última sessão",
        moviePremiere: "Estreia do filme Arcádia",
        fanMeeting: "Encontro com fãs"
    )

    static let italian = Self(
        voiceActor: "Minato",
        character: "Leo",
        stageActor: "Matteo",
        streamer: "Giulia",
        singer: "Sofia",
        domeLive: "Tour nei dome: Tokyo",
        domeVenue: "Tokyo Dome",
        birthday: "Compleanno di Minato",
        anniversaryStream: "Live per i 3 anni di canale",
        hotel: "Hotel per la trasferta",
        goodsDeadline: "Chiusura preordini acrilici",
        stageFinale: "Lama di Luna: ultima replica",
        moviePremiere: "Esce il film Arcadia Stellare",
        fanMeeting: "Incontro con i fan"
    )

    static let thai = Self(
        voiceActor: "มินาโตะ",
        character: "ลีโอ",
        stageActor: "ภูมิ",
        streamer: "ไข่มุก",
        singer: "แพรว",
        domeLive: "โดมทัวร์ รอบโตเกียว",
        domeVenue: "โตเกียวโดม",
        birthday: "วันเกิดมินาโตะ",
        anniversaryStream: "ไลฟ์ฉลองครบรอบ 3 ปี",
        hotel: "จองที่พักไปตามเชียร์",
        goodsDeadline: "ปิดพรีสแตนดี้อะคริลิกสุ่ม",
        stageFinale: "ละครเวทีดาบจันทรา รอบสุดท้าย",
        moviePremiere: "อาร์คาเดีย เดอะมูฟวี่ เข้าฉาย",
        fanMeeting: "แฟนมีตติ้ง"
    )

    static let indonesian = Self(
        voiceActor: "Minato",
        character: "Leo",
        stageActor: "Dimas",
        streamer: "Nayla",
        singer: "Kirana",
        domeLive: "Tur Dome: Tokyo",
        domeVenue: "Tokyo Dome",
        birthday: "Ulang tahun Minato",
        anniversaryStream: "Live spesial 3 tahun",
        hotel: "Pesan hotel untuk perjalanan",
        goodsDeadline: "Batas PO akrilik acak",
        stageFinale: "Pedang Bulan: hari terakhir",
        moviePremiere: "Film Arkadia tayang perdana",
        fanMeeting: "Fan meeting"
    )

    /// 言語ごとの見本。無い言語は英語にする（`SampleDataTests` で全言語があることを確かめる）。
    static let byLanguage: [SampleData.Language: Self] = [
        .english: english,
        .japanese: japanese,
        .simplifiedChinese: simplifiedChinese,
        .traditionalChinese: traditionalChinese,
        .korean: korean,
        .french: french,
        .german: german,
        .spanish: spanish,
        .brazilianPortuguese: brazilianPortuguese,
        .italian: italian,
        .thai: thai,
        .indonesian: indonesian
    ]
}

extension SampleData {
    /// 見本の推しと予定をストアに入れる（起動引数 `-seedSampleData` と Preview で使う）。保存に失敗したものは飛ばす。
    @MainActor
    static func insert(_ content: Content, into context: ModelContext, now: Date) {
        let store = OshiConStore(context: context)
        for (index, oshi) in content.oshis.enumerated() {
            // 登録した順に並ぶよう、1 秒ずつずらす
            try? store.save(oshi, now: now.addingTimeInterval(Double(index - content.oshis.count)))
        }
        for event in content.events {
            try? store.save(event)
        }
    }
}
