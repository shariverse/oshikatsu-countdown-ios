//
//  AppPalette.swift
//  OshiCon
//

import Foundation

/// アプリの配色。地・文字・線は Android 版と同じ値で、アクセント（brand）は推し色のピンクと同じ。
/// SwiftUI では `AppPalette.background.color` のように引く。推しの色は `OshiColor` から引く。
nonisolated enum AppPalette {
    /// 画面の地。
    static let background = AdaptiveColor(light: 0xFCF8FA, dark: 0x141218)
    /// カード・シート。
    static let surface = AdaptiveColor(light: 0xFFFFFF, dark: 0x211F26)
    /// 入力欄・推しカウントの地（デザインの薄い灰色 `#F3EDF1`）。
    static let surfaceContainer = AdaptiveColor(light: 0xF3EDF1, dark: 0x1D1B20)
    /// 進み具合のバーの溝・区切り。
    static let surfaceContainerHigh = AdaptiveColor(light: 0xE2DCE3, dark: 0x36343B)
    /// 本文。
    static let onSurface = AdaptiveColor(light: 0x1D1B20, dark: 0xE6E0E9)
    /// 補助テキスト。
    static let onSurfaceVariant = AdaptiveColor(light: 0x49454F, dark: 0xCAC4D0)
    /// 区切り線。
    static let outlineVariant = AdaptiveColor(light: 0xCAC4D0, dark: 0x49454F)
    /// アプリのアクセント（推しが決まっていないところ）。
    static let brand = AdaptiveColor(light: 0xC8326A, dark: 0xFFB1C8)
    /// brand の塗りに乗る文字。
    static let onBrand = AdaptiveColor(light: 0xFFFFFF, dark: 0x5E1133)
    /// 選択中の印などの薄いアクセント。
    static let brandContainer = AdaptiveColor(light: 0xF4D6E1, dark: 0x7E2A4A)
    /// brandContainer に乗る文字。
    static let onBrandContainer = AdaptiveColor(light: 0x1D1B20, dark: 0xFFD9E2)
    /// 削除の文字。
    static let destructive = AdaptiveColor(light: 0xB3261E, dark: 0xF2B8B5)
}
