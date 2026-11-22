//
//  WidgetPhotoLoader.swift
//  OshiCon
//

import CoreGraphics
import Foundation
import ImageIO

/// 推しの写真ウィジェットで、App Group の推しの写真をウィジェットの大きさに縮めて読む。
/// ウィジェットは使えるメモリが少なく、大きすぎる画像は描けないので、取り込んだ写真（一辺 1440px まで）をそのまま読まない。
nonisolated struct WidgetPhotoLoader: Sendable {
    /// 読む画像の一辺の上限（px）。ウィジェットの小・中の写真（一辺 170pt ほど）を 3 倍の画面で描くのに足り、StandBy で拡大されても粗くなりにくい大きさ。
    static let maxPixelLength = 720

    /// 写真のファイルを置くディレクトリ。
    let directory: URL

    init(directory: URL = AppGroupContainer.photosDirectory) {
        self.directory = directory
    }

    /// 写真を描く枠（一辺 `pointLength` pt）を、画面の倍率 `scale` で描くのに要る一辺（px）。
    /// 上限は `maxPixelLength`。大きさが分からない（0 や無限）ときは上限にする。
    static func pixelLength(pointLength: CGFloat, scale: CGFloat) -> Int {
        let length = (pointLength * scale).rounded(.up)
        guard length.isFinite, length >= 1 else {
            return maxPixelLength
        }
        return Int(min(length, CGFloat(maxPixelLength)))
    }

    /// 写真を、長辺 `pixelLength`（`maxPixelLength` まで）以下に縮めて読む。小さい写真は拡大しない。
    /// 取り込みで付けた名前でないファイル名・無いファイル・読めないファイルは nil（写真が無いときの模様で描く）。
    func loadImage(fileName: String, pixelLength: Int) -> CGImage? {
        guard AppGroupContainer.isPhotoFileName(fileName) else {
            return nil
        }
        let url = directory.appending(path: fileName, directoryHint: .notDirectory)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: min(max(pixelLength, 1), Self.maxPixelLength),
            kCGImageSourceShouldCacheImmediately: true
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
