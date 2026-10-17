//
//  RGBColor.swift
//  OshiCon
//

import SwiftUI
import UIKit

/// sRGB の色。配色の値を持ち、混ぜる・コントラストを求める計算をテストできるようにする。
nonisolated struct RGBColor: Hashable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    /// `0xRRGGBB` から作る。
    init(hex: UInt32) {
        red = Double((hex >> 16) & 0xFF) / 255
        green = Double((hex >> 8) & 0xFF) / 255
        blue = Double(hex & 0xFF) / 255
    }

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    static let white = Self(hex: 0xFFFFFF)
    static let black = Self(hex: 0x000000)

    /// `other` に `fraction`（0〜1）だけ寄せた色。
    func mixed(with other: Self, fraction: Double) -> Self {
        Self(
            red: red + (other.red - red) * fraction,
            green: green + (other.green - green) * fraction,
            blue: blue + (other.blue - blue) * fraction
        )
    }

    /// WCAG の相対輝度。
    var relativeLuminance: Double {
        func linear(_ value: Double) -> Double {
            value <= 0.040_45 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// WCAG のコントラスト比（1〜21）。
    func contrastRatio(with other: Self) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
    }

    var color: Color {
        Color(uiColor: uiColor)
    }
}

/// ライトとダークで値が変わる色。
nonisolated struct AdaptiveColor: Hashable, Sendable {
    let light: RGBColor
    let dark: RGBColor

    init(light: RGBColor, dark: RGBColor) {
        self.light = light
        self.dark = dark
    }

    init(light: UInt32, dark: UInt32) {
        self.init(light: RGBColor(hex: light), dark: RGBColor(hex: dark))
    }

    func resolved(isDark: Bool) -> RGBColor {
        isDark ? dark : light
    }

    /// 端末の外観に合わせて変わる色。
    var color: Color {
        let light = light.uiColor
        let dark = dark.uiColor
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
