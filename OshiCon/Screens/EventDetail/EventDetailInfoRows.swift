//
//  EventDetailInfoRows.swift
//  OshiCon
//

import SwiftUI

/// 日時・会場・くり返しの行を 1 つにまとめた札。行はアイコン・項目名・値を横に並べ、項目名の幅をそろえる。
/// アクセシビリティの大きな文字では、項目名の下に値を置く（横に並べると値の幅が足りなくなるため）。
/// どちらの並びでも、1 行を「項目名、値」の 1 つの要素として読む。
struct EventDetailInfoRows: View {
    let rows: [EventDetailContent.InfoRow]

    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let rowSpacing: CGFloat = 11

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: theme.shape.section)
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                stacked
            } else {
                grid
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, Self.rowSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.palette.surfaceContainer.color, in: shape)
        .overlay {
            shape.strokeBorder(theme.palette.surfaceContainerHigh.color, lineWidth: 1)
        }
    }

    /// アイコン・項目名・値の 3 列。項目名の列は、いちばん長い項目名の幅になる。
    private var grid: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: Self.rowSpacing) {
            ForEach(rows) { row in
                if row.id != rows.first?.id {
                    separator
                }
                GridRow {
                    icon(for: row)
                    title(of: row)
                        .accessibilityHidden(true)
                    value(of: row)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(row.accessibilityLabel)
                }
            }
        }
    }

    /// アイコンの右に、項目名と値を縦に積む。
    private var stacked: some View {
        VStack(alignment: .leading, spacing: Self.rowSpacing) {
            ForEach(rows) { row in
                if row.id != rows.first?.id {
                    separator
                }
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    icon(for: row)
                    VStack(alignment: .leading, spacing: 2) {
                        title(of: row)
                        value(of: row)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.accessibilityLabel)
            }
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(theme.palette.surfaceContainerHigh.color)
            .frame(height: 1)
            // 区切りの幅で列の幅を決めない
            .gridCellUnsizedAxes(.horizontal)
            .accessibilityHidden(true)
    }

    private func icon(for row: EventDetailContent.InfoRow) -> some View {
        Image(systemName: Self.systemImage(for: row.kind))
            .font(.subheadline)
            .foregroundStyle(theme.palette.onSurfaceVariant.color)
            .accessibilityHidden(true)
    }

    private func title(of row: EventDetailContent.InfoRow) -> some View {
        Text(row.title)
            .font(theme.typography.text(.caption))
            .foregroundStyle(theme.palette.onSurfaceVariant.color)
    }

    private func value(of row: EventDetailContent.InfoRow) -> some View {
        Text(row.value)
            .font(theme.typography.text(.subheadline))
            .foregroundStyle(theme.palette.onSurface.color)
    }

    private static func systemImage(for kind: EventDetailContent.InfoKind) -> String {
        switch kind {
        case .dateTime:
            "clock"
        case .venue:
            "mappin.and.ellipse"
        case .repeating:
            "repeat"
        }
    }
}
