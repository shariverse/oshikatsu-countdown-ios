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
    ///
    /// `crop` は向きを反映した後の画像の座標で決めたもの。`crop.imageSize` が写真と違う大きさ（表示用に縮めた画像など）でも、
    /// 縦横比が同じなら同じ割合の範囲を切り抜く。枠の隅が空かないよう、範囲は `PhotoCrop.clamped()` で補正してから使う。
    /// 一辺は切り抜く範囲の画素の一辺と `maxPixelLength` の小さいほう（小さい写真は拡大しない）。
    /// 大きな写真は全部をデコードせず、切り抜いた結果に足りる大きさに縮めて読んでから切り抜く。
    static func croppedJPEGData(from data: Data, crop: PhotoCrop, maxPixelLength: Int = maxPixelLength) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let orientedSize = orientedPixelSize(of: source) else {
            return nil
        }
        let region = crop.clamped().region
        // crop の座標から、向きを反映した写真の画素への倍率
        let cropToPhoto = orientedSize.width / crop.imageSize.width
        let sideInPhoto = region.side * cropToPhoto
        guard sideInPhoto.isFinite, sideInPhoto > 0, region.center.x.isFinite, region.center.y.isFinite else {
            return nil
        }
        let outputSide = max(Int(min(sideInPhoto, CGFloat(maxPixelLength)).rounded()), 1)
        // 切り抜く範囲が outputSide 画素に足りるだけの大きさで読む（元より大きくはしない）
        let decodeScale = min(CGFloat(outputSide) / sideInPhoto, 1)
        let longSide = max(orientedSize.width, orientedSize.height)
        let decodeLength = Int((longSide * decodeScale).rounded(.up))
        guard let image = thumbnail(of: source, maxPixelLength: decodeLength) else {
            return nil
        }
        let photoToImage = CGFloat(image.width) / orientedSize.width
        let side = sideInPhoto * photoToImage
        let center = CGPoint(x: region.center.x * cropToPhoto * photoToImage, y: region.center.y * cropToPhoto * photoToImage)
        guard let context = CGContext(
            data: nil,
            width: outputSide,
            height: outputSide,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }
        context.interpolationQuality = .high
        // CGContext は y が上向き。y が下向きの座標で「画像を +rotation 回して枠に写す」ことは、y が上向きでは −rotation 回すことになる
        let scale = CGFloat(outputSide) / side
        context.translateBy(x: CGFloat(outputSide) / 2, y: CGFloat(outputSide) / 2)
        context.scaleBy(x: scale, y: scale)
        context.rotate(by: -CGFloat(region.rotation.radians))
        context.translateBy(x: -center.x, y: -(CGFloat(image.height) - center.y))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let cropped = context.makeImage() else {
            return nil
        }
        return jpegData(from: cropped)
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
