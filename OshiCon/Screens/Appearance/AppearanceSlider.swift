//
//  AppearanceSlider.swift
//  OshiCon
//

import SwiftUI

/// 着せ替えの画面のスライダー（背景の写真の暗幕の濃さ・ぼかしの強さ、飾りの濃さ・量）。設定のトレーの行に置く。
/// 値は 5% ずつに丸め、今の値を百分率で出す（読み上げの値も百分率）。
///
/// - 幅に収まるときは 1 行（名前・スライダー・値）にして、見本を見ながら動かせるようトレーの行を低くする
/// - 収まらないとき（長い訳・細いトレー）は 2 行（名前と値、その下に両端の言葉を添えたスライダー）
/// - アクセシビリティの大きな文字では、両端の言葉を並べると収まらないので、スライダーの下に置く
///
/// `Slider` の `step` は目盛りの点を 19 個並べて騒がしいので使わず、受け取った値を丸める。
struct AppearanceSlider: View {
    let title: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>
    let minimumLabel: LocalizedStringKey
    let maximumLabel: LocalizedStringKey
    /// UI テストで探す identifier。スライダーそのものに付ける。
    let identifier: String

    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 1 行に並べるときの、スライダーの幅の下限（pt）。これより狭くなるなら 2 行にする。
    private static let compactSliderMinWidth: CGFloat = 150
    /// 値（`100%`）の幅（pt）。値が変わっても並びが動かないよう、いちばん長い値に合わせる。
    private static let valueWidth: CGFloat = 52

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            stacked
        } else {
            ViewThatFits(in: .horizontal) {
                compact
                expanded
            }
        }
    }

    private var valueText: String {
        AppearancePreview.percentText(value)
    }

    /// 5% ずつに丸めた値。
    private var stepped: Binding<Double> {
        Binding {
            value
        } set: { newValue in
            value = Self.roundedToStep(newValue)
        }
    }

    /// 1 行（名前・スライダー・値）。
    private var compact: some View {
        HStack(spacing: 10) {
            Text(title)
                .lineLimit(1)
                .fixedSize()
            slider
                .frame(minWidth: Self.compactSliderMinWidth)
            valueLabel
                .frame(width: Self.valueWidth, alignment: .trailing)
        }
        .frame(minHeight: 36)
    }

    /// 2 行（名前と値、その下に両端の言葉を添えたスライダー）。
    private var expanded: some View {
        VStack(alignment: .leading, spacing: 6) {
            heading
            Slider(value: stepped, in: range) {
                Text(title)
            } minimumValueLabel: {
                endLabel(minimumLabel)
            } maximumValueLabel: {
                endLabel(maximumLabel)
            }
            .accessibilityValue(Text(verbatim: valueText))
            .accessibilityIdentifier(identifier)
        }
    }

    /// アクセシビリティの大きな文字のときの 3 行（名前と値、スライダー、両端の言葉）。
    private var stacked: some View {
        VStack(alignment: .leading, spacing: 8) {
            heading
            slider
            HStack {
                endLabel(minimumLabel)
                Spacer(minLength: 8)
                endLabel(maximumLabel)
            }
            .accessibilityHidden(true)
        }
    }

    private var heading: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
            Spacer(minLength: 8)
            valueLabel
        }
    }

    private var slider: some View {
        Slider(value: stepped, in: range) {
            Text(title)
        }
        .accessibilityValue(Text(verbatim: valueText))
        .accessibilityIdentifier(identifier)
    }

    private var valueLabel: some View {
        Text(verbatim: valueText)
            .monospacedDigit()
            .lineLimit(1)
            .foregroundStyle(theme.palette.onSurfaceVariant.color)
            .accessibilityHidden(true)
    }

    private func endLabel(_ label: LocalizedStringKey) -> some View {
        Text(label)
            .font(theme.typography.text(.footnote))
            .foregroundStyle(theme.palette.onSurfaceVariant.color)
    }

    /// スライダーの値を 5% ずつに丸める（`0.3499…` を `0.35` にし、百分率の表示と保存する値をそろえる）。
    private static func roundedToStep(_ value: Double) -> Double {
        (value * 20).rounded() / 20
    }
}

#Preview("スライダー") {
    @Previewable @State var value = 0.4
    VStack(alignment: .leading, spacing: 16) {
        AppearanceSlider(
            title: "飾りの濃さ",
            value: $value,
            range: 0...1,
            minimumLabel: "薄い",
            maximumLabel: "濃い",
            identifier: "preview.slider"
        )
        AppearanceSlider(
            title: "飾りの濃さ",
            value: $value,
            range: 0...1,
            minimumLabel: "薄い",
            maximumLabel: "濃い",
            identifier: "preview.slider.narrow"
        )
        .frame(width: 220)
        AppearanceSlider(
            title: "飾りの濃さ",
            value: $value,
            range: 0...1,
            minimumLabel: "薄い",
            maximumLabel: "濃い",
            identifier: "preview.slider.large"
        )
        .dynamicTypeSize(.accessibility3)
    }
    .padding()
}
