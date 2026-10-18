//
//  SelectEventIntent.swift
//  OshiConWidget
//

import AppIntents
import Foundation

/// カウントダウンウィジェットに出す予定を選ぶ設定（ウィジェットを長押しして「ウィジェットを編集」から選ぶ）。
struct SelectEventIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "表示する予定を選ぶ"
    static let description = IntentDescription("カウントダウンする予定を選びます。")

    @Parameter(title: "予定")
    var event: EventEntity?

    init() {}

    init(event: EventEntity?) {
        self.event = event
    }
}

/// 設定で選ぶ予定。
nonisolated struct EventEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "予定"
    static let defaultQuery = EventEntityQuery()

    let id: OshiEvent.ID
    let title: String
    /// 選ぶ画面の補足（`10月18日(日) · ミナト`）。
    let detail: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(detail)")
    }

    /// 選んだあとに削除された（またはストアを読めず見つからない）予定。id を残して「予定が見つかりません」を出すために使う。
    init(missingID: OshiEvent.ID) {
        id = missingID
        title = "見つからない予定"
        detail = ""
    }

    init(event: OshiEvent, oshis: [Oshi], today: CalendarDay) {
        id = event.id
        title = event.title
        let occurrence = event.occurrence(from: today)
        let oshiName = event.oshiID.flatMap { id in oshis.first { $0.id == id }?.name } ?? "推しなし"
        detail = "\(EventText.monthDayWeekday(occurrence)) · \(oshiName)"
    }
}

/// 選ぶ画面に出す予定（当日とこれからの予定を近い順）と、選んだ予定の読み直し。
nonisolated struct EventEntityQuery: EntityQuery {
    func entities(for identifiers: [EventEntity.ID]) async throws -> [EventEntity] {
        let data = await WidgetStore.load()
        let today = CalendarDay(.now, calendar: .autoupdatingCurrent)
        // 選んだあとに終わった予定も読み直せるよう、終わった予定も含めて探す。
        // 見つからない予定も id を残して返す（落とすと選んでいない扱いになり、「予定が見つかりません」を出せない）
        return identifiers.map { id in
            guard let event = data?.events.first(where: { $0.id == id }) else {
                return EventEntity(missingID: id)
            }
            return EventEntity(event: event, oshis: data?.oshis ?? [], today: today)
        }
    }

    func suggestedEntities() async throws -> [EventEntity] {
        guard let data = await WidgetStore.load() else {
            return []
        }
        let today = CalendarDay(.now, calendar: .autoupdatingCurrent)
        return CountdownWidgetContent.selectableEvents(data.events, today: today)
            .map { EventEntity(event: $0, oshis: data.oshis, today: today) }
    }
}
