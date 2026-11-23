//
//  AppearanceSlider.swift
//  OshiCon
//

import SwiftUI

/// 着せ替えの画面のスライダー（背景の写真の暗幕の濃さ・ぼかしの強さ、飾りの濃さ・量）。Form の行に置く。
/// 値は 5% ずつに丸め、今の値を百分率で出す（読み上げの値も百分率）。
///
/// `Slider` の `step` は目盛りの点を 19 個並べて騒がしいので使わず、受け取った値を丸める。
/// アクセシビリティの大きな文字では、両端の言葉を並べると収まらないので、スライダーの下に置く。
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

    var body: some View {
        let valueText = AppearancePreview.percentText(value)
        let stepped = Binding<Double>(
            get: { value },
            set: { value = Self.roundedToStep($0) }
        )
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                Spacer(minLength: 8)
                Text(verbatim: valueText)
                    .monospacedDigit()
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
                    .accessibilityHidden(true)
            }
            if dynamicTypeSize.isAccessibilitySize {
                Slider(value: stepped, in: range) {
                    Text(title)
                }
                .accessibilityValue(Text(verbatim: valueText))
                .accessibilityIdentifier(identifier)
                HStack {
                    Text(minimumLabel)
                    Spacer(minLength: 8)
                    Text(maximumLabel)
                }
                .font(theme.typography.text(.footnote))
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
                .accessibilityHidden(true)
            } else {
                Slider(value: stepped, in: range) {
                    Text(title)
                } minimumValueLabel: {
                    Text(minimumLabel)
                        .font(theme.typography.text(.footnote))
                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                } maximumValueLabel: {
                    Text(maximumLabel)
                        .font(theme.typography.text(.footnote))
                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                }
                .accessibilityValue(Text(verbatim: valueText))
                .accessibilityIdentifier(identifier)
            }
        }
        .padding(.vertical, 2)
    }

    /// スライダーの値を 5% ずつに丸める（`0.3499…` を `0.35` にし、百分率の表示と保存する値をそろえる）。
    private static func roundedToStep(_ value: Double) -> Double {
        (value * 20).rounded() / 20
    }
}

#Preview("スライダー") {
    @Previewable @State var value = 0.4
    Form {
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
            identifier: "preview.slider.large"
        )
        .dynamicTypeSize(.accessibility3)
    }
}
