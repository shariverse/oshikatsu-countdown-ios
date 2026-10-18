//
//  PhotoFixtures.swift
//  OshiConTests
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// 写真のテストで使う画像のデータ。
nonisolated enum PhotoFixtures {
    /// 単色の画像を `type`（PNG・JPEG など）で書き出したデータ。`orientation` は EXIF の Orientation（1〜8）。
    static func imageData(width: Int, height: Int, type: UTType = .png, orientation: Int? = nil, gps: Bool = false) -> Data {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            preconditionFailure("画像を作れない")
        }
        context.setFillColor(CGColor(red: 0.8, green: 0.2, blue: 0.4, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else {
            preconditionFailure("画像を作れない")
        }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, type.identifier as CFString, 1, nil) else {
            preconditionFailure("書き出せない")
        }
        var properties: [CFString: Any] = [:]
        if let orientation {
            properties[kCGImagePropertyOrientation] = orientation
        }
        if gps {
            properties[kCGImagePropertyGPSDictionary] = [kCGImagePropertyGPSLatitude: 35.68, kCGImagePropertyGPSLongitude: 139.76]
        }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        return output as Data
    }

    /// 画像の幅と高さ（px）と、メタデータ。
    struct ImageProperties {
        let width: Int
        let height: Int
        let metadata: [CFString: Any]
    }

    /// データの画像の幅と高さ（px）と、メタデータ。
    static func properties(of data: Data) -> ImageProperties? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = metadata[kCGImagePropertyPixelWidth] as? Int,
              let height = metadata[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        return ImageProperties(width: width, height: height, metadata: metadata)
    }

    /// 写真のテストごとの一時ディレクトリ。
    static func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "OshiConTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }
}
