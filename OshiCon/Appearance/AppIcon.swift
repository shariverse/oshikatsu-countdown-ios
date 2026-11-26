//
//  AppIcon.swift
//  OshiCon
//

/// 着せ替え（Plus）のアプリアイコンの色。推し色の 12 色から選び、図柄（白いハート）はそのまま地の色だけを替える。
///
/// - ピンクは主アイコン（`OshiCon/AppIcon.icon`）。ほかの 11 色は代替アイコン（`OshiCon/AlternateAppIcons/AppIcon-<色>.icon`）で、
///   名前は `Configs/Project.xcconfig` の `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` に並べる（Xcode が Info.plist の `CFBundleAlternateIcons` を書く）
/// - ホーム画面に出すアイコンは、Plus が使えれば選んだ色、使えなければ標準（ピンク）。選んだ色は Plus でなくても残す（また Plus になったら戻す）
nonisolated enum AppIconRule {
    /// 色 `color` のアイコンの名前（`UIApplication.setAlternateIconName(_:)` に渡す）。ピンクは主アイコンなので nil。
    ///
    /// 名前はシステムが覚えるので、一度出したら変えない。
    static func alternateIconName(for color: OshiColor) -> String? {
        color.appIconName
    }

    /// アイコンの名前（`UIApplication.alternateIconName`）の色。nil は主アイコン（ピンク）。知らない名前なら nil。
    static func color(forAlternateIconName name: String?) -> OshiColor? {
        OshiColor.allCases.first { alternateIconName(for: $0) == name }
    }

    /// ホーム画面に出すアイコンの名前。Plus が使えれば選んだ色 `selected`、使えなければ主アイコン（nil）。
    static func iconName(selected: OshiColor, isPlusUnlocked: Bool) -> String? {
        isPlusUnlocked ? alternateIconName(for: selected) : nil
    }

    /// ホーム画面のアイコンを替えるか。今のアイコン `current` が出したいアイコン `desired` と違うときだけ替える。
    ///
    /// 替えるたびにシステムが利用者に知らせるので、同じアイコンには替え直さない。
    /// 端末が代替アイコンを使えない（`supportsAlternateIcons` が false）ときは替えない。
    static func request(desired: String?, current: String?, supportsAlternateIcons: Bool) -> AppIconRequest {
        guard supportsAlternateIcons, desired != current else {
            return .keep
        }
        return .change(to: desired)
    }
}

/// ホーム画面のアイコンをどうするか（`AppIconRule.request(desired:current:supportsAlternateIcons:)`）。
nonisolated enum AppIconRequest: Equatable, Sendable {
    /// 替えない。
    case keep
    /// `name` のアイコンに替える（nil は主アイコン）。
    case change(to: String?)
}

/// アプリアイコンの色。ライトの外観は推し色の地に白いハート、ダークの外観は暗い地に淡い推し色のハート（今のアイコンと同じ考え方）。
///
/// Icon Composer のファイル（`AppIcon.icon`・`AlternateAppIcons/*.icon`）と同じ値で、着せ替えの画面の見本を描く。
/// 値を変えたら `scripts/make-alternate-app-icons.py` の表も直してファイルを作り直す（`AppIconTests` が食い違いを見つける）。
/// ダークの色は、OKLCH で地を明るさ 0.19・彩度は推し色の 0.18 倍（0.035 まで）、ハートを明るさ 0.84・彩度は推し色の 0.8 倍（0.095 まで）にし、
/// 色相は推し色のままにしたもの（ピンクは今のアイコンの値のまま）。
nonisolated enum AppIconPalette {
    /// アイコンの地の色。
    static func ground(of color: OshiColor, isDark: Bool) -> RGBColor {
        isDark ? color.appIconDark.ground : color.rgb
    }

    /// ハートの色。ライトは白。
    static func heart(of color: OshiColor, isDark: Bool) -> RGBColor {
        isDark ? color.appIconDark.heart : .white
    }
}

private extension OshiColor {
    /// 代替アイコンの名前（`AppIconRule.alternateIconName(for:)`）。
    nonisolated var appIconName: String? {
        switch self {
        case .pink:
            nil
        case .red:
            "AppIcon-Red"
        case .orange:
            "AppIcon-Orange"
        case .yellow:
            "AppIcon-Yellow"
        case .green:
            "AppIcon-Green"
        case .mint:
            "AppIcon-Mint"
        case .blue:
            "AppIcon-Blue"
        case .navy:
            "AppIcon-Navy"
        case .purple:
            "AppIcon-Purple"
        case .lavender:
            "AppIcon-Lavender"
        case .brown:
            "AppIcon-Brown"
        case .black:
            "AppIcon-Black"
        }
    }

    /// ダークの外観のアイコンの地とハートの色（`AppIconPalette`）。
    nonisolated var appIconDark: (ground: RGBColor, heart: RGBColor) {
        switch self {
        case .pink:
            (RGBColor(hex: 0x200D15), RGBColor(hex: 0xFFB1C8))
        case .red:
            (RGBColor(hex: 0x210D0B), RGBColor(hex: 0xFFB5AA))
        case .orange:
            (RGBColor(hex: 0x1D1109), RGBColor(hex: 0xFDBA91))
        case .yellow:
            (RGBColor(hex: 0x171309), RGBColor(hex: 0xE1C986))
        case .green:
            (RGBColor(hex: 0x0C1711), RGBColor(hex: 0x99DCB6))
        case .mint:
            (RGBColor(hex: 0x0B1617), RGBColor(hex: 0x92D8E1))
        case .blue:
            (RGBColor(hex: 0x0B1422), RGBColor(hex: 0xACCCFF))
        case .navy:
            (RGBColor(hex: 0x0F1322), RGBColor(hex: 0xB8C8FF))
        case .purple:
            (RGBColor(hex: 0x151022), RGBColor(hex: 0xCEBFFF))
        case .lavender:
            (RGBColor(hex: 0x1B0E1D), RGBColor(hex: 0xE9B6EF))
        case .brown:
            (RGBColor(hex: 0x161311), RGBColor(hex: 0xD6C8B9))
        case .black:
            (RGBColor(hex: 0x141315), RGBColor(hex: 0xCBC9D3))
        }
    }
}
