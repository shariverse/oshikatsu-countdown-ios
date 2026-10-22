//
//  ThemeComparisonBoard.swift
//  OshiCon
//

import SwiftUI

/// テーマ案を横に並べて比べる見本（採用の判断に使った。出荷するテーマは地雷系・ゴシックの `AppTheme.shipping`）。
/// テーマごとに 1 列で、案の名前・ホームの先頭のカードとこれからの予定・ウィジェット 2 種を描く。
/// 見本のデータは日本語の見本の推しと予定（`SampleData`）で、SwiftData を使わずに `HomeContent` から描く
/// （`ImageRenderer` でも描けるように、`ScrollView`・`NavigationStack` は使わない）。
struct ThemeComparisonBoard: View {
    /// 1 列の幅（推しカウントウィジェットの枠が収まる幅）。
    static let columnWidth: CGFloat = 380
    /// これからの予定に出す行の数。
    static let upcomingRows = 3

    let themes: [AppTheme]
    let content: HomeContent

    init(themes: [AppTheme] = AppTheme.all, now: Date = .now) {
        PreviewFonts.registerIfNeeded()
        let calendar = Calendar.autoupdatingCurrent
        let today = CalendarDay(now, calendar: calendar)
        let sample = SampleData.make(today: today, now: now, language: .japanese)
        self.themes = themes
        content = HomeContent(events: sample.events, oshis: sample.oshis, selectedOshiID: nil, showsPastEvents: false, today: today)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            ForEach(themes) { theme in
                ThemeComparisonColumn(theme: theme, content: content)
                    .frame(width: Self.columnWidth)
            }
        }
        .padding(24)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

/// 比べる見本の 1 列。テーマを当てて、ホームの抜粋とウィジェット 2 種を描く。
private struct ThemeComparisonColumn: View {
    let theme: AppTheme
    let content: HomeContent

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 案の名前は見本の見出しなので、テーマの書体ではなくシステムの書体で書く
            Text(verbatim: theme.displayName)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            home
            VStack(alignment: .leading, spacing: 12) {
                WidgetPreview.countdown(.sample, theme: theme)
                WidgetPreview.upcoming(.sample, theme: theme)
            }
        }
        .environment(\.appTheme, theme)
    }

    /// ホームの先頭のカードとこれからの予定（ホームの画面と同じ部品）。
    private var home: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let featured = content.featured {
                FeaturedEventCard(item: featured)
            }
            HomeSection(title: "これからの予定") {
                let items = Array(content.upcoming.prefix(ThemeComparisonBoard.upcomingRows))
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 68)
                    }
                    HomeEventRow(item: item)
                }
            }
        }
        .padding(16)
        .background(ThemeScreenBackground())
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview("テーマ案を並べる・ライト", traits: .sizeThatFitsLayout) {
    ThemeComparisonBoard()
        .preferredColorScheme(.light)
}

#Preview("テーマ案を並べる・ダーク", traits: .sizeThatFitsLayout) {
    ThemeComparisonBoard()
        .preferredColorScheme(.dark)
}
