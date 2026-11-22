//
//  AppTheme+ThemeColor.swift
//  OshiCon
//

import Foundation

// MARK: - テーマカラー（1 位の推しの推し色）

extension AppTheme {
    /// 出荷するテーマのピンクの基準。地雷系・ゴシックのピンク（地・装飾・アクセント）は推し色のピンクに合わせてあり、
    /// 1 位の推しの推し色で染めるときは、この色との差の分だけ置き換える（`RGBColor.retinted(from:to:)`）。
    nonisolated static let themeColorReference = OshiColor.pink

    /// 出荷するアプリとウィジェットのテーマを、推しの一覧のいちばん上の推し（1 位の推し）の推し色で染めたもの。
    /// 推しがいなければ（`themeColor` が nil）、染めない（`shipping` のピンクのまま）。
    nonisolated static func shipping(themeColor: OshiColor?) -> Self {
        guard let themeColor else {
            return .shipping
        }
        return shipping.tinted(with: themeColor)
    }

    /// テーマのピンクを `color` に置き換えたテーマ。地・本文・線・アクセント・装飾の色を染め、
    /// 削除の文字（destructive）・推し色の文字の調整の割合・角の丸み・書体・装飾の形は変えない。
    /// `color` が基準のピンクなら、配色は元のまま。
    nonisolated func tinted(with color: OshiColor) -> Self {
        let tint = { (value: AdaptiveColor) in
            value.retinted(from: Self.themeColorReference.rgb, to: color.rgb)
        }
        return Self(
            id: "\(id).\(color.rawValue)",
            displayName: displayName,
            palette: palette.tinted(tint),
            oshiText: oshiText,
            shape: shape,
            typography: typography,
            decoration: decoration.tinted(tint)
        )
    }
}

extension AppTheme.Palette {
    /// 削除の文字（destructive）を除く色を `tint` で染めた配色。
    nonisolated func tinted(_ tint: (AdaptiveColor) -> AdaptiveColor) -> Self {
        Self(
            background: tint(background),
            surface: tint(surface),
            surfaceContainer: tint(surfaceContainer),
            surfaceContainerHigh: tint(surfaceContainerHigh),
            onSurface: tint(onSurface),
            onSurfaceVariant: tint(onSurfaceVariant),
            outlineVariant: tint(outlineVariant),
            brand: tint(brand),
            onBrand: tint(onBrand),
            brandContainer: tint(brandContainer),
            onBrandContainer: tint(onBrandContainer),
            destructive: destructive
        )
    }
}

extension AppTheme.Decoration {
    /// 装飾の色を `tint` で染めた装飾。形は変えない。
    nonisolated func tinted(_ tint: (AdaptiveColor) -> AdaptiveColor) -> Self {
        let screenBackground: AppTheme.ScreenBackground = switch self.screenBackground {
        case .none:
            .none
        case let .crossesAndHearts(ornament):
            .crossesAndHearts(ornament: tint(ornament))
        }
        let cardBorder: AppTheme.CardBorder = switch self.cardBorder {
        case .none:
            .none
        case let .doubleLine(color):
            .doubleLine(color: tint(color))
        }
        let headingOrnament: AppTheme.HeadingOrnament = switch self.headingOrnament {
        case .none:
            .none
        case let .symbol(name, color):
            .symbol(name: name, color: tint(color))
        }
        return Self(
            screenBackground: screenBackground,
            cardBorder: cardBorder,
            headingOrnament: headingOrnament,
            photoPlaceholder: photoPlaceholder
        )
    }
}
