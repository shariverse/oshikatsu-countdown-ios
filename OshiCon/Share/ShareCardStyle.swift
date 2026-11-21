//
//  ShareCardStyle.swift
//  OshiCon
//

import SwiftUI

/// シェアのカードの見た目の差し替え口。カード（`ShareCardView`）は地・飾り・書体・角の丸みをここから引く。
/// 既定は出荷するテーマ（`shipping`）。Plus の着せ替えは、同じ口で `background` を推しの写真に替える。
/// 推し色の役割（カードの塗り・写真が無いときの模様の色）は置き換えない。
nonisolated struct ShareCardStyle: Hashable, Sendable {
    /// カードの地（写真と予定のまわり）。
    nonisolated enum Background: Hashable, Sendable {
        /// テーマの画面の地（出荷するテーマは十字とハート）。
        case theme
        /// 取り込んだ画像（Plus の着せ替えで推しの写真にする）。`fileName` は `OshiPhotoLibrary` のファイル名。
        /// 読めないときはテーマの地にする。
        case photo(fileName: String)
    }

    /// 地・装飾・書体・角の丸みを引くテーマ。
    let theme: AppTheme
    var background: Background = .theme
    /// 書き出す画像の外観。端末の外観によらず同じ画像にする（出荷するテーマはダークが主役）。
    var colorScheme: ColorScheme = .dark

    /// 出荷するテーマのカード。
    static var shipping: Self {
        Self(theme: .shipping)
    }

    /// 地に写真を敷いたとき、透かしを読めるよう写真に重ねる黒の不透明度。
    static let photoBackgroundScrimOpacity = 0.45

    /// 本文の書体。日本語はテーマの書体（太さは 3 つに丸める）、ほかの言語はシステムの書体。
    /// 画像の大きさをそろえるため、ダイナミックタイプで変わらない固定の大きさにする。
    func text(size: CGFloat, weight: Font.Weight = .regular, locale: Locale) -> Font {
        guard AppFont.usesBundledTextFace(locale: locale) else {
            return .system(size: size, weight: weight)
        }
        return .custom(theme.typography.textFaces.name(for: weight), fixedSize: size)
    }

    /// 数字の書体（どの言語でも Outfit）。ダイナミックタイプで変わらない固定の大きさ。
    func numeral(size: CGFloat) -> Font {
        .custom(theme.typography.numeralFamily, fixedSize: size)
            .weight(theme.typography.numeralWeight)
            .monospacedDigit()
    }
}

/// カードに描く画像（推しの写真と、着せ替えの地）。描く前に読み込み終えておく（`ImageRenderer` は読み込みを待たない）。
nonisolated struct ShareCardImages: Sendable {
    /// 推しの写真。写真を載せない・無い・読めないときは nil（テーマの模様にする）。
    var photo: CGImage?
    /// 着せ替えの地の画像。テーマの地・読めないときは nil。
    var background: CGImage?

    /// `content` の写真と `style` の地の画像を、書き出す大きさで読む。
    static func load(
        content: ShareCardContent,
        style: ShareCardStyle,
        photos: OshiPhotoLibrary = .shared,
        maxPixelLength: Int = ShareCardSize.pixelLength
    ) async -> Self {
        var images = Self()
        if let fileName = content.photoFileName {
            images.photo = await photos.loadImage(fileName: fileName, maxPixelLength: maxPixelLength)
        }
        if case let .photo(fileName) = style.background {
            images.background = await photos.loadImage(fileName: fileName, maxPixelLength: maxPixelLength)
        }
        return images
    }
}

/// シェアのカードの大きさ。正方形（1:1）だけ。
nonisolated enum ShareCardSize {
    /// 一辺の大きさ（pt）。
    static let points: CGFloat = 360
    /// 書き出すときの倍率。
    static let scale: CGFloat = 3
    /// 書き出す画像の一辺（px）。
    static var pixelLength: Int {
        Int(points * scale)
    }
}
