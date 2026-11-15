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

    /// 4 つの象限を色分けした画像の色。見たときの左上・右上・左下・右下。
    enum Quadrant: CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight

        /// 象限の色（0〜255 の赤・緑・青）。JPEG にしても見分けられるよう、はっきり離した色にする。
        var rgb: [Int] {
            switch self {
            case .topLeft: [230, 30, 30]
            case .topRight: [30, 200, 30]
            case .bottomLeft: [30, 30, 230]
            case .bottomRight: [240, 220, 20]
            }
        }
    }

    /// 4 つの象限を色分けした画像を `type` で書き出したデータ。色は画素の並び（保存した向き）で塗る。
    /// `orientation` を付けると、見たときの向きは EXIF の Orientation で変わる。
    static func quadrantImageData(
        width: Int,
        height: Int,
        type: UTType = .png,
        orientation: Int? = nil,
        gps: Bool = false,
        colorSpace: CGColorSpace? = nil
    ) -> Data {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            preconditionFailure("画像を作れない")
        }
        let halfWidth = CGFloat(width) / 2
        let halfHeight = CGFloat(height) / 2
        // CGContext は y が上向きなので、上の象限は y が大きいほう
        let rects: [Quadrant: CGRect] = [
            .topLeft: CGRect(x: 0, y: halfHeight, width: halfWidth, height: halfHeight),
            .topRight: CGRect(x: halfWidth, y: halfHeight, width: halfWidth, height: halfHeight),
            .bottomLeft: CGRect(x: 0, y: 0, width: halfWidth, height: halfHeight),
            .bottomRight: CGRect(x: halfWidth, y: 0, width: halfWidth, height: halfHeight)
        ]
        for (quadrant, rect) in rects {
            let rgb = quadrant.rgb
            context.setFillColor(CGColor(red: CGFloat(rgb[0]) / 255, green: CGFloat(rgb[1]) / 255, blue: CGFloat(rgb[2]) / 255, alpha: 1))
            context.fill(rect)
        }
        guard let image = context.makeImage() else {
            preconditionFailure("画像を作れない")
        }
        return encode(image, type: type, orientation: orientation, gps: gps)
    }

    /// 画像を書き出す。
    private static func encode(_ image: CGImage, type: UTType, orientation: Int?, gps: Bool) -> Data {
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

    /// 画像のデータを読み、画素（x, y は左上が原点）の RGB（0〜255）を返す。読めなければ nil。
    static func pixels(of data: Data) -> Pixels? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) else {
                return false
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        return drawn ? Pixels(width: image.width, height: image.height, bytes: bytes) : nil
    }

    /// 読んだ画像の画素。
    struct Pixels {
        let width: Int
        let height: Int
        let bytes: [UInt8]

        /// (x, y) の画素の色が、象限の色に近いか（JPEG の誤差を許す）。
        func matches(x: Int, y: Int, _ quadrant: Quadrant, tolerance: Int = 48) -> Bool {
            let index = (y * width + x) * 4
            let rgb = quadrant.rgb
            return (0..<3).allSatisfy { abs(Int(bytes[index + $0]) - rgb[$0]) <= tolerance }
        }
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
