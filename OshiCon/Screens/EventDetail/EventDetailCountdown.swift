//
//  EventDetailCountdown.swift
//  OshiCon
//

import SwiftUI

/// 詳細の残りの見せ方。何を出すかは `EventDetailContent.countdownDisplay` が決める。
///
/// - 開始の前: 「あと N 日」（数字は推し色で大きく）と、時間・分・秒のタイル
/// - 当日の開始の前: 日数の代わりに「今日！」ときらめきの印、開始までのタイル
/// - 開始を過ぎた当日: 「今日は当日！」ときらめきの印、「楽しんできてね」
/// - 終わった予定: 「終わった予定」「N 日前」
///
/// 数えているときは、見出し・日数・タイルをまとめて 1 つの要素として読む（秒は読まないので、毎秒読み上げ直さない）。
struct EventDetailCountdown: View {
    let detail: EventDetailContent

    @Environment(\.appTheme) private var theme
    /// 「今日！」の文字の大きさ。ダイナミックタイプに合わせて変わる。
    @ScaledMetric(relativeTo: .largeTitle) private var todayTextSize: CGFloat = 52

    var body: some View {
        switch detail.countdownDisplay {
        case .counting:
            counting {
                daysHeadline
            }
        case .countingOnTheDay:
            counting {
                onTheDayHeadline
            }
        case .today:
            VStack(alignment: .leading, spacing: 4) {
                todayMark(Text("今日は当日！"))
                Text("楽しんできてね")
                    .font(theme.typography.text(.body))
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
            }
            .accessibilityElement(children: .combine)
        case .ended:
            VStack(alignment: .leading, spacing: 4) {
                Text("終わった予定")
                    .font(theme.typography.text(.subheadline, weight: .bold))
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
                Text(detail.daysAgoText)
                    .font(theme.typography.text(.title, weight: .bold))
                    .foregroundStyle(theme.palette.onSurface.color)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// 数えているときの並び。大きな見出しの下に、時間・分・秒のタイル。
    private func counting(@ViewBuilder headline: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            headline()
            EventDetailClockTiles(tiles: detail.clockTiles, color: detail.color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(detail.countdownAccessibilityLabel)
    }

    private var oshiText: Color {
        detail.color.text(in: theme).color
    }

    // MARK: 「あと N 日」

    /// 見出し（`開演まで`）と「あと N 日」を 1 行に並べる。入りきらないとき（長い言語・大きな文字）は 2 段にする。
    private var daysHeadline: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                untilLabel
                daysCount
            }
            VStack(alignment: .leading, spacing: 0) {
                untilLabel
                daysCount
            }
        }
    }

    private var untilLabel: some View {
        Text(detail.untilLabel)
            .font(theme.typography.text(.footnote, weight: .bold))
            .foregroundStyle(theme.palette.onSurfaceVariant.color)
    }

    private var daysCount: some View {
        let days = detail.remainingDaysParts
        return HStack(alignment: .firstTextBaseline, spacing: 6) {
            if !days.prefix.isEmpty {
                Text(days.prefix)
            }
            Text(days.number)
                .font(theme.typography.countdownHero)
                .foregroundStyle(oshiText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .countdownNumberTransition(detail.countdown.remainingParts.days)
            if !days.suffix.isEmpty {
                Text(days.suffix)
            }
        }
        .font(theme.typography.text(.callout, weight: .bold))
        .foregroundStyle(theme.palette.onSurface.color)
    }

    // MARK: 当日

    /// 見出しのリボン（`開演まで`）と「今日！」を 1 行に並べる。入りきらないときは 2 段にする。
    private var onTheDayHeadline: some View {
        let today = todayMark(Text(EventText.today(locale: detail.locale)))
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                EventDetailRibbon(text: detail.untilLabel)
                today
            }
            VStack(alignment: .leading, spacing: 8) {
                EventDetailRibbon(text: detail.untilLabel)
                today
            }
        }
    }

    /// 当日の大きな文字（推し色）に、きらめきの印を添える。
    private func todayMark(_ text: Text) -> some View {
        HStack(alignment: .center, spacing: 8) {
            text
                .font(todayFont)
                .foregroundStyle(oshiText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            EventDetailSparkles(color: oshiText, accent: theme.palette.brand.color, size: todayTextSize * 0.55)
        }
    }

    /// 「今日！」の書体。本文と同じく、日本語はテーマの書体、ほかの言語はシステムの書体。
    private var todayFont: Font {
        if AppFont.usesBundledTextFace(locale: detail.locale) {
            .custom(theme.typography.textFaces.name(for: .bold), fixedSize: todayTextSize)
        } else {
            .system(size: todayTextSize, weight: .bold)
        }
    }
}

/// 残りの時間・分・秒のタイル。3 つを同じ幅で横に並べ、1 秒ごとに進む秒のタイルは推し色の枠と数字にする。
/// アクセシビリティの大きな文字では、縦に積んで数字と単位を横に並べる（3 つを横に並べると数字が縮むため）。
struct EventDetailClockTiles: View {
    let tiles: [EventDetailContent.ClockTile]
    let color: OshiColor

    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isStacked = dynamicTypeSize.isAccessibilitySize
        let layout = isStacked ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 10))
        layout {
            ForEach(tiles) { tile in
                tileView(tile, isStacked: isStacked)
            }
        }
    }

    private func tileView(_ tile: EventDetailContent.ClockTile, isStacked: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.shape.section)
        // タイルの地は入力欄と同じ地（surfaceContainer）。その上の推し色の文字は、専用の色で 4.5:1 を保つ
        let oshiText = color.textOnSurfaceContainer(in: theme).color
        let content = isStacked
            ? AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
            : AnyLayout(VStackLayout(spacing: 2))
        return content {
            Text(tile.number)
                .font(theme.typography.countdownClock)
                .foregroundStyle(tile.isLive ? oshiText : theme.palette.onSurface.color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(tile.label)
                .font(theme.typography.text(.caption))
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: isStacked ? nil : 72)
        .background(theme.palette.surfaceContainer.color, in: shape)
        .overlay {
            if tile.isLive {
                shape.strokeBorder(oshiText, lineWidth: 1.5)
            } else {
                shape.strokeBorder(theme.palette.surfaceContainerHigh.color, lineWidth: 1)
            }
        }
    }
}

/// 当日の見出しのリボン。アクセントの地に、右端を三角に切り込む。
private struct EventDetailRibbon: View {
    let text: String

    @Environment(\.appTheme) private var theme

    var body: some View {
        Text(text)
            .font(theme.typography.text(.footnote, weight: .bold))
            .foregroundStyle(theme.palette.onBrand.color)
            .lineLimit(1)
            .padding(.leading, 12)
            .padding(.trailing, 12 + EventDetailRibbonShape.notch)
            .padding(.vertical, 7)
            .background(theme.palette.brand.color, in: EventDetailRibbonShape())
    }
}

/// 右端を三角に切り込んだリボンの形。形は描く側のスレッドで作られるので、メインアクターに縛らない。
nonisolated private struct EventDetailRibbonShape: Shape {
    /// 切り込みの深さ。
    static let notch: CGFloat = 9

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - Self.notch, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// 当日のきらめきの印。大きい印の右上に、小さい印を添える。飾りなので読み上げない。
private struct EventDetailSparkles: View {
    let color: Color
    let accent: Color
    /// 大きい印の大きさ。
    let size: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            Image(systemName: "sparkle")
                .font(.system(size: size))
                .foregroundStyle(color)
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.55))
                .foregroundStyle(accent)
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
