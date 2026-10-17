//
//  PlaceholderWidget.swift
//  OshiConWidget
//

import SwiftUI
import WidgetKit

/// Widget Extension のビルドを通すための仮のウィジェット。タスク 16 のカウントダウンウィジェットで置き換える。
struct PlaceholderWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "jp.shilokuma.OshiCon.Placeholder", provider: PlaceholderProvider()) { _ in
            Text("推し活カウントダウン")
                .font(AppFont.text(.headline, weight: .bold))
                .foregroundStyle(AppPalette.onSurface.color)
                .containerBackground(AppPalette.surface.color, for: .widget)
        }
        .configurationDisplayName("推し活カウントダウン")
        .supportedFamilies([.systemSmall])
    }
}

nonisolated struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        completion(Timeline(entries: [SimpleEntry(date: .now)], policy: .never))
    }
}

nonisolated struct SimpleEntry: TimelineEntry {
    let date: Date
}
