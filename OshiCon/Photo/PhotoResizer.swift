//
//  PhotoResizer.swift
//  OshiCon
//

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
