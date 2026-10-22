//
//  AppTheme.swift
//  OshiCon
//

import SwiftUI

/// アプリのテーマ。地の配色・角の丸み・書体・装飾をまとめて持つ。アプリとウィジェットの両方で使う。
/// 推し色（`OshiColor`）の役割は置き換えない。テーマが変えるのは、推し色の文字を地に合わせて調整する割合だけ。
/// 出荷するアプリは Discussion #80 の 5 案から採用したテーマ（`shipping`。「地雷系・ゴシック」）だけを使う。
/// 採用しなかった案（採用前のデザインを含む）は片付け、アイデアは shilokuma-inc/design-knowledge に残した（`docs/design/themes.md`）。
nonisolated struct AppTheme: Hashable, Sendable, Identifiable {
    /// 英字の安定した値（テストの表示で使う）。
    let id: String
    /// 表示名。Preview とドキュメントだけで使う（出荷する画面には出さないので訳さない）。
    let displayName: String
    let palette: Palette
    let oshiText: OshiTextAdjustment
    let shape: CornerRadii
    let typography: Typography
    let decoration: Decoration

    /// 出荷するアプリとウィジェットのテーマ。Discussion #80 の 5 案から「地雷系・ゴシック」を採用し、採用前のデザインを置き換えた。
    static var shipping: Self {
        .jiraiGothic
    }
}

// MARK: - 配色

extension AppTheme {
    /// 地・文字・線とアプリのアクセントの配色。推し色を置き換える役割は持たない。
    nonisolated struct Palette: Hashable, Sendable {
        /// 画面の地。
        let background: AdaptiveColor
        /// カード・シート。
        let surface: AdaptiveColor
        /// 入力欄の地。
        let surfaceContainer: AdaptiveColor
        /// 進み具合のバーの溝・区切り。
        let surfaceContainerHigh: AdaptiveColor
        /// 本文。
        let onSurface: AdaptiveColor
        /// 補助テキスト。
        let onSurfaceVariant: AdaptiveColor
        /// 区切り線。
        let outlineVariant: AdaptiveColor
        /// アプリのアクセント（推しが決まっていないところ）。
        let brand: AdaptiveColor
        /// brand の塗りに乗る文字。
        let onBrand: AdaptiveColor
        /// 選択中の印などの薄いアクセント。
        let brandContainer: AdaptiveColor
        /// brandContainer に乗る文字。
        let onBrandContainer: AdaptiveColor
        /// 削除の文字。
        let destructive: AdaptiveColor
    }

    /// 推し色を地の上の文字や薄い地に使うときの調整の割合。テーマの地で 4.5:1 を保てるよう、テーマごとに持つ。
    nonisolated struct OshiTextAdjustment: Hashable, Sendable {
        /// ライトの地で推し色を文字に使うとき、黒に寄せる割合。地が色付きで、推し色のままでは 4.5:1 を保てない色があるときに持つ（0 なら推し色のまま）。
        let lightTextDarkenFraction: Double
        /// ダークの地で推し色を文字に使うとき、白に寄せる割合。
        let darkTextLightenFraction: Double
        /// ライトの surfaceContainer の上で推し色を文字に使うとき、黒に寄せる割合。
        let surfaceContainerTextDarkenFraction: Double
        /// 推し色を薄く敷いた地（ライト）で、カードの地に推し色を混ぜる割合。
        let containerLightFraction: Double
        /// 推し色を薄く敷いた地（ダーク）で、カードの地に推し色を混ぜる割合。
        let containerDarkFraction: Double
    }
}

// MARK: - 形

extension AppTheme {
    /// 角の丸み（役割の名前で持つ）。
    nonisolated struct CornerRadii: Hashable, Sendable {
        /// ホームの先頭のカード。
        let heroCard: CGFloat
        /// 見出しつきのまとまり（ホームのこれからの予定など）。
        let section: CGFloat
        /// 予定の詳細のカード（上の 2 つの角）。
        let detailCard: CGFloat
        /// 予定の種類などの小さな札。
        let tag: CGFloat
    }
}

// MARK: - 書体

extension AppTheme {
    /// 日本語の本文の書体の PostScript 名。足りない太さは近い太さのフェイスに寄せる（合成の太字にしない）。
    nonisolated struct TextFaces: Hashable, Sendable {
        let regular: String
        let medium: String
        let bold: String

        /// 太さを regular・medium・bold に丸めたフェイス。
        func name(for weight: Font.Weight) -> String {
            switch AppFont.face(for: weight) {
            case .regular:
                regular
            case .medium:
                medium
            case .bold:
                bold
            }
        }
    }

    /// 書体。日本語の本文はテーマの書体、ほかの言語の本文はどのテーマでもシステムの書体（`AppFont.usesBundledTextFace(locale:)`）。
    /// 数字は Outfit を太さを変えて使う。
    nonisolated struct Typography: Hashable, Sendable {
        let textFaces: TextFaces
        /// 数字の書体の family 名（可変フォント）。
        let numeralFamily: String
        /// 数字の既定の太さ。
        let numeralWeight: Font.Weight

        // MARK: 数字。桁の幅をそろえ、秒が進んでも横に揺れない

        /// 詳細の残り日数。
        var countdownHero: Font {
            numeral(size: 88, relativeTo: .largeTitle)
        }

        /// ホームの先頭の残り日数。
        var countdownLarge: Font {
            numeral(size: 68, relativeTo: .largeTitle)
        }

        /// 詳細の時・分・秒。
        var countdownClock: Font {
            numeral(size: 32, relativeTo: .title)
        }

        /// 一覧の行の残り日数。
        var countdownSmall: Font {
            numeral(size: 24, relativeTo: .title2)
        }

        /// 先頭のカードの日付（`10.18 SUN`）。
        var dateBadge: Font {
            numeral(size: 18, relativeTo: .headline)
        }

        /// 数字。`size` はダイナミックタイプが標準のときの大きさ。`weight` を省くとテーマの既定の太さ。
        func numeral(size: CGFloat, weight: Font.Weight? = nil, relativeTo style: Font.TextStyle) -> Font {
            .custom(numeralFamily, size: size, relativeTo: style)
                .weight(weight ?? numeralWeight)
                .monospacedDigit()
        }

        /// 本文。日本語ではテーマの書体（太さは 3 つに丸める）、ほかの言語はシステムの書体。
        func text(_ style: Font.TextStyle, weight: Font.Weight = .regular, locale: Locale = .app) -> Font {
            guard AppFont.usesBundledTextFace(locale: locale) else {
                return .system(style, weight: weight)
            }
            return .custom(textFaces.name(for: weight), size: AppFont.defaultSize(of: style), relativeTo: style)
        }
    }
}

// MARK: - 装飾

extension AppTheme {
    /// 差し込み口ごとの装飾。値の型だけで持ち（`Hashable` / `Sendable` を保つ）、描くのは `Shared/Design/` の View。
    /// 装飾は読み上げ・押せる範囲・並びを変えず（`accessibilityHidden(true)`・`allowsHitTesting(false)`）、文字の上に重ねない。
    /// 画像の素材は使わず、SwiftUI の図形・`Canvas`・SF Symbols で描く。
    nonisolated struct Decoration: Hashable, Sendable {
        /// 画面の地の模様。
        let screenBackground: ScreenBackground
        /// カード（先頭のカード・見出しつきのまとまり）の縁取り。
        let cardBorder: CardBorder
        /// 見出しの飾り。
        let headingOrnament: HeadingOrnament
        /// 写真が無いときに写真の場所を埋める模様。
        let photoPlaceholder: PhotoPlaceholder
    }

    nonisolated enum ScreenBackground: Hashable, Sendable {
        case none
        /// 地の色に、十字とハートを小さく散らす（`ornament` を `markOpacity` で薄めて描く）。
        case crossesAndHearts(ornament: AdaptiveColor)

        /// 十字とハートの不透明度。
        static let markOpacity = 0.35

        /// 画面の地の色（模様を除く）。`background` はテーマの画面の地の色。
        func grounds(background: AdaptiveColor) -> [AdaptiveColor] {
            [background]
        }

        /// 画面の地の上の文字（見出しなど）が乗りうる色。地の色に、模様の色を重ねたところも含める。
        /// 推し色の文字は画面の地の上に置かない（行・札・カードの地の上に置く）ので、模様を重ねたところは本文の色だけで確かめる。
        func textGrounds(background: AdaptiveColor) -> [AdaptiveColor] {
            let grounds = grounds(background: background)
            switch self {
            case .none:
                return grounds
            case let .crossesAndHearts(ornament):
                return grounds + grounds.map { ground in
                    AdaptiveColor(
                        light: ground.light.mixed(with: ornament.light, fraction: Self.markOpacity),
                        dark: ground.dark.mixed(with: ornament.dark, fraction: Self.markOpacity)
                    )
                }
            }
        }
    }

    nonisolated enum CardBorder: Hashable, Sendable {
        case none
        /// カードの内側に沿う 2 本の線（外は太く、内は細く薄く）。
        case doubleLine(color: AdaptiveColor)
    }

    nonisolated enum HeadingOrnament: Hashable, Sendable {
        case none
        /// 見出しの前に置く SF Symbols（`name` はシンボルの名前）。
        case symbol(name: String, color: AdaptiveColor)
    }

    nonisolated enum PhotoPlaceholder: Hashable, Sendable {
        /// 推し色を黒に寄せた地に、白い十字とハートを散らす（`CrossPatternBackground`）。
        case crosses
    }
}

// MARK: - 配り方

extension EnvironmentValues {
    /// 画面とウィジェットが使うテーマ。出荷するアプリは `AppTheme.shipping` のまま（Preview だけがテーマを入れる）。
    @Entry var appTheme: AppTheme = .shipping
}
