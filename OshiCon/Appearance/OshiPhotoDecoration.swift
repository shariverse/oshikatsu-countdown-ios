//
//  OshiPhotoDecoration.swift
//  OshiCon
//

import CoreGraphics
import Foundation

/// 着せ替えの飾り（Plus）の濃さ・量・出す推し。着せ替えの設定（`AppearanceSettings`）に置き、着せ替えの画面のスライダーと推しごとのスイッチで変える。
nonisolated struct OshiPhotoDecorationStyle: Equatable, Sendable {
    /// 濃さ（丸い写真の不透明度）の範囲。
    static let opacityRange: ClosedRange<Double> = 0.1...1
    /// 濃さの既定。地の上の文字はどの濃さでも板の上に描くので（`AppearanceTextPlate`）、推しが分かる濃さにする。
    static let defaultOpacity = 0.4
    /// 量の範囲。0 は少なめ、1 は丸どうしが接して地を埋め尽くす（`OshiPhotoDecorationLayout`）。
    static let amountRange: ClosedRange<Double> = 0...1
    /// 量の既定。初めの版の散らし方（地のおよそ 9% を覆う）より少し多くする。
    static let defaultAmount = 0.25

    static let `default` = Self()

    /// 丸い写真の不透明度。範囲の外の値は範囲に収める。
    var opacity: Double {
        didSet {
            opacity = Self.clamped(opacity, to: Self.opacityRange, fallback: Self.defaultOpacity)
        }
    }

    /// 丸い写真の量。範囲の外の値は範囲に収める。
    var amount: Double {
        didSet {
            amount = Self.clamped(amount, to: Self.amountRange, fallback: Self.defaultAmount)
        }
    }

    /// 飾りに出さない推しの id。既定は空（すべての推しを出す。新しく登録した推しも出す）。
    var excludedOshiIDs: Set<UUID>

    init(opacity: Double = defaultOpacity, amount: Double = defaultAmount, excludedOshiIDs: Set<UUID> = []) {
        self.opacity = Self.clamped(opacity, to: Self.opacityRange, fallback: Self.defaultOpacity)
        self.amount = Self.clamped(amount, to: Self.amountRange, fallback: Self.defaultAmount)
        self.excludedOshiIDs = excludedOshiIDs
    }

    /// 推し `oshi` を飾りに出すか。
    func includes(_ oshi: Oshi) -> Bool {
        !excludedOshiIDs.contains(oshi.id)
    }

    private static func clamped(_ value: Double, to range: ClosedRange<Double>, fallback: Double) -> Double {
        value.isNaN ? fallback : min(max(value, range.lowerBound), range.upperBound)
    }
}

/// 着せ替えの飾り（Plus）: 地に、選んだ推しの丸い写真を互い違いの並び（`OshiPhotoDecorationLayout`）で並べる規則。
///
/// - 飾りに出す推し（`OshiPhotoDecorationStyle.excludedOshiIDs` に無い推し）のうち、写真のある推しを、渡した順（推しの並び）に使う
/// - 出す推しに写真のある推しが 1 人もいなければ、テーマの模様（出荷するテーマはハートと十字）のまま
/// - 丸い写真は濃さ（`opacity`）の不透明度で描く。濃くすると地の上の文字が読めなくなるので、飾りを描くときは文字の後ろに板を敷く（`AppearanceRendering.drawsPhotosOnGround`）
nonisolated struct OshiPhotoDecoration: Equatable, Sendable {
    /// 丸い写真を並べる推しの写真のファイル名（渡した順。重なりを除く）。
    let photoFileNames: [String]
    /// 丸い写真の不透明度。
    let opacity: Double
    /// 丸い写真の量（`OshiPhotoDecorationLayout`）。
    let amount: Double

    /// 推し `oshis`（並べたい順）と、濃さ・量・出す推し `style` から決める。写真が無い・置き場所の外を指す推しは使わない。
    init(oshis: [Oshi], style: OshiPhotoDecorationStyle = .default) {
        var seen = Set<String>()
        photoFileNames = oshis
            .filter(style.includes)
            .compactMap { oshi in oshi.photoFileName.flatMap { OshiPhotoLibrary.isValidFileName($0) ? $0 : nil } }
            .filter { seen.insert($0).inserted }
        opacity = style.opacity
        amount = style.amount
    }

    /// 丸い写真を並べるか。写真のある推しがいなければ、テーマの模様のまま。
    var hasPhotos: Bool {
        !photoFileNames.isEmpty
    }

    /// 写真を読む一辺（画素）。いちばん大きい丸の直径を画面の倍率 `displayScale` で画素にする。
    static func decodePixelLength(displayScale: CGFloat) -> Int {
        Int(max((OshiPhotoDecorationLayout.maxDiameter * max(displayScale, 1)).rounded(.up), 1))
    }

    /// 大きさ `imageSize` の写真で丸の枠 `circle` を覆う、写真を描く枠（縦横比を保ち、中央に置く。はみ出した分は丸で切る）。
    static func imageRect(imageSize: CGSize, filling circle: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return circle
        }
        let scale = max(circle.width / imageSize.width, circle.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(x: circle.midX - width / 2, y: circle.midY - height / 2, width: width, height: height)
    }

    /// 写真 `image` の中央で丸を覆い、丸の外を透明にした、一辺 `pixelLength` の正方形の画像。
    /// 量を増やすと丸が数百になるので、描くたびに丸で切らずに済むよう、読むときに 1 回だけ作る。作れなければ nil。
    static func circularImage(from image: CGImage, pixelLength: Int) -> CGImage? {
        guard pixelLength > 0, image.width > 0, image.height > 0 else {
            return nil
        }
        let colorSpace = image.colorSpace.flatMap { $0.model == .rgb ? $0 : nil } ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: pixelLength,
            height: pixelLength,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        let circle = CGRect(x: 0, y: 0, width: pixelLength, height: pixelLength)
        context.interpolationQuality = .high
        context.addEllipse(in: circle)
        context.clip()
        context.draw(image, in: imageRect(imageSize: CGSize(width: image.width, height: image.height), filling: circle))
        return context.makeImage()
    }
}

/// 飾りの丸い写真の並べ方。行ごとに半分ずらした互い違いの並び（六角形の詰め方）で、量（0〜1）に合わせて丸の大きさと間隔を変える。
///
/// - 量 0: 直径 32pt・間隔 128pt（地のおよそ 6% を覆う）。量の既定 0.25 で、直径 40pt・間隔 112pt（およそ 12%）
/// - 量 1: 直径 64pt・間隔 64pt。丸どうしが接して、地を埋め尽くす（およそ 91%）
/// - 一定の大きさで並べるので、iPad の広い画面では丸が増え、大きさは変わらない
nonisolated enum OshiPhotoDecorationLayout {
    /// 量 0 の丸の直径（pt）。
    static let minDiameter: CGFloat = 32
    /// 量 1 の丸の直径（pt）。量 1 では、となりの丸との間隔も同じ（丸どうしが接する）。
    static let maxDiameter: CGFloat = 64
    /// 量 0 の、同じ行のとなりの丸との中心の間隔（pt）。
    static let maxSpacing: CGFloat = 128

    /// 地に置く丸 1 つ。`row`・`column` は並びの中の位置（どちらも 0 から。0 行目は地の上の外に半分はみ出す）、`rect` は地の座標の丸の枠。
    nonisolated struct Circle: Equatable, Sendable {
        let row: Int
        let column: Int
        let rect: CGRect
    }

    /// 量 `amount` の丸の直径（pt）。
    static func diameter(amount: Double) -> CGFloat {
        minDiameter + (maxDiameter - minDiameter) * clamped(amount)
    }

    /// 量 `amount` の、同じ行のとなりの丸との中心の間隔（pt）。行の間隔はこの √3/2 倍（となりの行の丸とも同じ間隔になる）。
    static func spacing(amount: Double) -> CGFloat {
        maxSpacing - (maxSpacing - maxDiameter) * clamped(amount)
    }

    /// 大きさ `size` の地に置く丸。地に少しでもかかる丸を、上の行から左から順に返す。
    static func circles(in size: CGSize, amount: Double) -> [Circle] {
        guard size.width > 0, size.height > 0 else {
            return []
        }
        let diameter = diameter(amount: amount)
        let spacing = spacing(amount: amount)
        let rowSpacing = spacing * sqrt(3) / 2
        var circles: [Circle] = []
        var row = 0
        // 0 行目は中心を地の上の外（行の間隔の半分）に置き、量 1 でも上の端まで埋める
        while CGFloat(row) * rowSpacing - rowSpacing / 2 - diameter / 2 < size.height {
            let centerY = CGFloat(row) * rowSpacing - rowSpacing / 2
            // 奇数の行は間隔の半分だけ右にずらす。0 列目は中心を地の左の外に置き、量 1 でも左の端まで埋める
            let shift = row.isMultiple(of: 2) ? 0 : spacing / 2
            var column = 0
            while CGFloat(column) * spacing - spacing / 2 + shift - diameter / 2 < size.width {
                let centerX = CGFloat(column) * spacing - spacing / 2 + shift
                let rect = CGRect(x: centerX - diameter / 2, y: centerY - diameter / 2, width: diameter, height: diameter)
                if rect.maxX > 0, rect.maxY > 0 {
                    circles.append(Circle(row: row, column: column, rect: rect))
                }
                column += 1
            }
            row += 1
        }
        return circles
    }

    /// `row` 行 `column` 列の丸に置く推しの写真の番号（`count` 人を順にくり返す）。
    ///
    /// 斜めにずらして割り当て、推しが 3 人以上なら、となり合う丸（同じ行の左右と、上下の行の 2 つずつ）がどれも別の推しになる。
    /// 2 人なら同じ行の左右だけが別の推し、1 人ならすべて同じ推し。
    static func photoIndex(row: Int, column: Int, count: Int) -> Int {
        guard count > 0 else {
            return 0
        }
        // 互い違いの並びを斜めの座標にすると、となりの丸との差が ±1・±2 になる
        let value = column - row / 2 - row
        return (value % count + count) % count
    }

    private static func clamped(_ amount: Double) -> CGFloat {
        CGFloat(amount.isNaN ? 0 : min(max(amount, 0), 1))
    }
}
