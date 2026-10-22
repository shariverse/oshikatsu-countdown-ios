//
//  UpcomingWidgetView.swift
//  OshiCon
//

import SwiftUI
import WidgetKit

/// 推しカウントウィジェット（4×2）の中身。当日とこれからの予定を近い順に、推し色の丸・タイトル・残り日数で並べる。
/// 行を押すとアプリで予定の詳細、右上の ＋ で予定の追加、見出しでアプリを開く。
/// アプリの Preview からもウィジェットの大きさの枠で描けるよう、Widget Extension ではなくここに置く。
struct UpcomingWidgetView: View {
    let content: UpcomingWidgetContent

    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            switch content {
            case let .rows(rows) where rows.isEmpty:
                message("これからの予定はありません")
            case let .rows(rows):
                // 端末や文字の大きさで高さが違うので、収まる件数まで減らす（4 → 3 → 2 → 1 件）
                ViewThatFits(in: .vertical) {
                    ForEach((1...rows.count).reversed(), id: \.self) { count in
                        rowList(Array(rows.prefix(count)))
                    }
                }
                Spacer(minLength: 0)
            case .unavailable:
                message("データを読み込めませんでした")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(WidgetLink.home.url)
        .containerBackground(Self.containerColor(in: theme).color, for: .widget)
        .environment(\.locale, .app)
    }

    /// ウィジェットの地（入力欄の地）。
    static func containerColor(in theme: AppTheme) -> AdaptiveColor {
        theme.palette.surfaceContainer
    }

    /// 見出し（押すとアプリ）と、右上の ＋（押すと予定の追加）。
    private var header: some View {
        HStack {
            Link(destination: WidgetLink.home.url) {
                Text("推しカウント")
                    .font(theme.typography.text(.subheadline, weight: .bold))
                    .foregroundStyle(theme.palette.onSurface.color)
            }
            Spacer()
            Link(destination: WidgetLink.addEvent.url) {
                // 見た目は 32pt の丸、押せる範囲は 44pt にする
                addButtonLabel
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .padding(.trailing, -6)
            .padding(.vertical, -6)
            .accessibilityLabel("予定を追加")
        }
    }

    private func rowList(_ rows: [UpcomingWidgetContent.Row]) -> some View {
        VStack(spacing: 2) {
            ForEach(rows) { row in
                Link(destination: WidgetLink.eventDetail(row.id).url) {
                    UpcomingRowView(row: row)
                }
            }
        }
    }

    /// ＋ の丸。色付き・透明のウィジェット（色が 1 色になる描き方）では、塗りと記号が同じ色で見えなくなるので輪郭の丸にする。
    @ViewBuilder private var addButtonLabel: some View {
        let plus = Image(systemName: "plus")
            .font(.system(size: 15, weight: .bold))
            .frame(width: 32, height: 32)
        if renderingMode == .fullColor {
            plus
                .foregroundStyle(theme.palette.onBrand.color)
                .background(theme.palette.brand.color, in: Circle())
        } else {
            plus
                .overlay(Circle().strokeBorder(lineWidth: 2))
        }
    }

    private func message(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(theme.typography.text(.footnote))
            .foregroundStyle(theme.palette.onSurfaceVariant.color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 推しカウントの 1 行。推し色の丸・タイトル・残り日数（推し色。当日は「今日！」）。
private struct UpcomingRowView: View {
    let row: UpcomingWidgetContent.Row

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            OshiColorDot(color: row.color)
            Text(row.title)
                .font(theme.typography.text(.footnote, weight: .medium))
                .foregroundStyle(theme.palette.onSurface.color)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(row.daysText)
                .font(theme.typography.numeral(size: 15, relativeTo: .footnote))
                .foregroundStyle(row.color.textOnSurfaceContainer(in: theme).color)
                .lineLimit(1)
        }
        .frame(minHeight: 22)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
    }
}
