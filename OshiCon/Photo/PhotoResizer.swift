//
//  PhotoResizer.swift
//  OshiCon
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// 選んだ写真を、取り込む JPEG に縮める。
nonisolated enum PhotoResizer {
    /// 取り込む写真の長辺の上限（px）。
    static let maxPixelLength = 1_440
    /// JPEG の画質。
    static let compressionQuality = 0.85

    /// 写真のデータ（HEIC・JPEG・PNG など）を、長辺 `maxPixelLength` 以下の JPEG にする。読めなければ nil。
    ///
    /// 写真の向き（EXIF の Orientation）は画素に反映し、位置情報などのメタデータは残さない。小さい写真は拡大しない。
    static func jpegData(from data: Data, maxPixelLength: Int = maxPixelLength) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let image = thumbnail(of: source, maxPixelLength: maxPixelLength) else {
            return nil
        }
        return jpegData(from: image)
    }

    /// 写真のデータを、調整した範囲（`crop`）で正方形に切り抜き、一辺 `maxPixelLength` 以下の JPEG にする。読めなければ nil。
    /// 切り抜き方は `croppedImage(from:crop:maxPixelLength:)`。
    static func croppedJPEGData(from data: Data, crop: PhotoCrop, maxPixelLength: Int = maxPixelLength) -> Data? {
        croppedImage(from: data, crop: crop, maxPixelLength: maxPixelLength).flatMap(jpegData(from:))
    }

    /// 写真のデータを、調整した範囲（`crop`）で正方形に切り抜いた、一辺 `maxPixelLength` 以下の画像。読めなければ nil。
    ///
    /// `crop` は向きを反映した後の画像の座標で決めたもの。`crop.imageSize` が写真と違う大きさ（表示用に縮めた画像など）でも、
    /// 縦横比が同じなら同じ割合の範囲を切り抜く（縦横比が違えば、向きの取り違えとみなして nil）。
    /// 枠の隅が空かないよう、範囲は `PhotoCrop.clamped()` で補正してから使う。
    /// 一辺は切り抜く範囲の画素の一辺と `maxPixelLength` の小さいほう（小さい写真は拡大しない）。
    /// 切り抜く範囲が `maxPixelLength` より広ければ、写真を全部はデコードせず、切り抜いた結果に足りる大きさに縮めて読んでから切り抜く
    /// （`decodePixelLength`）。それより狭く切り抜く（強く拡大した）ときは、粗くしないよう写真を元の大きさで読む。
    static func croppedImage(from data: Data, crop: PhotoCrop, maxPixelLength: Int = maxPixelLength) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let orientedSize = orientedPixelSize(of: source) else {
            return nil
        }
        // crop の座標から、向きを反映した写真の画素への倍率
        let cropToPhoto = orientedSize.width / crop.imageSize.width
        let heightRatio = orientedSize.height / crop.imageSize.height
        guard abs(cropToPhoto / heightRatio - 1) < 0.02 else {
            return nil
        }
        let region = crop.clamped().region
        let sideInPhoto = region.side * cropToPhoto
        let center = CGPoint(x: region.center.x * cropToPhoto, y: region.center.y * cropToPhoto)
        guard sideInPhoto.isFinite, sideInPhoto > 0, center.x.isFinite, center.y.isFinite else {
            return nil
        }
        let outputSide = max(Int(min(sideInPhoto, CGFloat(maxPixelLength)).rounded()), 1)
        let decodeLength = decodePixelLength(orientedSize: orientedSize, cropSide: sideInPhoto, outputSide: outputSide)
        guard let image = thumbnail(of: source, maxPixelLength: decodeLength),
              let context = squareContext(side: outputSide, colorSpace: image.colorSpace) else {
            return nil
        }
        context.interpolationQuality = .high
        // 写真の画素の座標（y が上向きに直したもの）で描く。縮めて読んだ画像は写真の大きさの矩形に引き伸ばして置くので、
        // 縦と横で丸めの誤差が違っても範囲がずれない
        // CGContext は y が上向き。y が下向きの座標で「画像を +rotation 回して枠に写す」ことは、y が上向きでは −rotation 回すことになる
        let scale = CGFloat(outputSide) / sideInPhoto
        context.translateBy(x: CGFloat(outputSide) / 2, y: CGFloat(outputSide) / 2)
        context.scaleBy(x: scale, y: scale)
        context.rotate(by: -CGFloat(region.rotation.radians))
        context.translateBy(x: -center.x, y: -(orientedSize.height - center.y))
        context.draw(image, in: CGRect(origin: .zero, size: orientedSize))
        return context.makeImage()
    }

    /// 切り抜きのために読む画像の長辺（画素）。切り抜く範囲（一辺 `cropSide`）が `outputSide` 画素に足りるだけの大きさで、元より大きくはしない。
    static func decodePixelLength(orientedSize: CGSize, cropSide: CGFloat, outputSide: Int) -> Int {
        let decodeScale = min(CGFloat(outputSide) / cropSide, 1)
        return Int((max(orientedSize.width, orientedSize.height) * decodeScale).rounded(.up))
    }

    /// 一辺 `side` の正方形の描き先。色空間は写真のもの（RGB なら。広色域の写真の色を保つ）、使えなければ sRGB。
    private static func squareContext(side: Int, colorSpace: CGColorSpace?) -> CGContext? {
        let srgb = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let spaces = [colorSpace, srgb].compactMap { $0 }.filter { $0.model == .rgb }
        for space in spaces {
            if let context = CGContext(
                data: nil,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: space,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) {
                return context
            }
        }
        return nil
    }

    /// 画像を、画質 `compressionQuality` の JPEG に書き出す（メタデータは付けない）。
    private static func jpegData(from image: CGImage) -> Data? {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImageDestinationLossyCompressionQuality: compressionQuality] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return output as Data
    }

    /// 向き（EXIF の Orientation）を反映した後の画像の大きさ（画素）。読めなければ nil。
    static func orientedPixelSize(of source: CGImageSource) -> CGSize? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else {
            return nil
        }
        // Orientation 5〜8 は 90° 回して表示する写真で、縦と横が入れ替わる
        let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
        return (5...8).contains(orientation)
            ? CGSize(width: height, height: width)
            : CGSize(width: width, height: height)
    }

    /// 写真のデータの、向きを反映した後の大きさ（画素）。読めなければ nil。
    static func orientedPixelSize(of data: Data) -> CGSize? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }
        return orientedPixelSize(of: source)
    }

    /// 長辺 `maxPixelLength` 以下に縮めた画像。向きを反映する。
    static func thumbnail(of source: CGImageSource, maxPixelLength: Int) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelLength,
            kCGImageSourceShouldCacheImmediately: true
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    /// 選んだばかりの写真のデータを、表示用に縮めて読む。読めなければ nil。
    static func image(data: Data, maxPixelLength: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }
        return thumbnail(of: source, maxPixelLength: maxPixelLength)
    }

    /// 表示用に縮めて読む（アバター・詳細の上の写真）。読めなければ nil。
    static func image(contentsOf url: URL, maxPixelLength: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }
        return thumbnail(of: source, maxPixelLength: maxPixelLength)
    }
}
