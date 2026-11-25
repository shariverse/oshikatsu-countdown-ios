//
//  TodayPill.swift
//  OshiCon
//

import SwiftUI

/// 「今日！」の札の配色。地は、推し色を地の上の文字に使うときの色（残り日数の数字と同じ色）、文字はカードの地の色。
/// 推し色の文字はカードの地の上で 4.5:1 以上なので（`PaletteContrastTests`）、その 2 色を入れ替えたこの札も 4.5:1 以上になる。
nonisolated enum TodayPillColors {
    /// 札の地。
    static func ground(_ color: OshiColor, in theme: AppTheme) -> AdaptiveColor {
        color.text(in: theme)
    }

    /// 札の文字ときらめきの印。
    static func text(in theme: AppTheme) -> AdaptiveColor {
        theme.palette.surface
    }
}

/// 当日の予定の「今日！」の札。推し色の地の札に、きらめきの印を添える（ホームの行・推しの一覧）。印は飾りで、読み上げない。
struct TodayPill: View {
    let color: OshiColor

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkle")
                .font(.footnote.weight(.bold))
                .imageScale(.small)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .accessibilityHidden(true)
            Text("今日！")
                .font(theme.typography.text(.footnote, weight: .bold))
                .lineLimit(1)
        }
        .foregroundStyle(TodayPillColors.text(in: theme).color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(TodayPillColors.ground(color, in: theme).color, in: Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach([OshiColor.pink, .orange, .yellow, .navy, .black], id: \.self) { color in
            TodayPill(color: color)
        }
    }
    .padding()
}
