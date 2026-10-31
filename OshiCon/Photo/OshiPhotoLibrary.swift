//
//  OshiPhotoLibrary.swift
//  OshiCon
//

import CoreGraphics
import Foundation

/// 取り込んだ推しの写真の置き場所（App Group のコンテナの Photos）。端末の外には出さない。
nonisolated struct OshiPhotoLibrary: Sendable {
    /// アプリの写真の置き場所（App Group のコンテナの Photos）。
    static let shared = Self()

    /// 写真のファイルを置くディレクトリ。
    let directory: URL

    init(directory: URL = AppGroupContainer.dataDirectory.appending(path: "Photos", directoryHint: .isDirectory)) {
        self.directory = directory
    }

    /// 写真のデータを長辺 1440px 以下の JPEG に縮めて取り込み、ファイル名を返す。読めなければ nil。
    /// `crop` があれば、その範囲で一辺 1440px 以下の正方形に切り抜く。縮めるのは重いので、メインアクターの外で行う。
    @concurrent
    func importPhoto(_ data: Data, crop: PhotoCrop? = nil) async throws -> String? {
        let jpeg = if let crop {
            PhotoResizer.croppedJPEGData(from: data, crop: crop)
        } else {
            PhotoResizer.jpegData(from: data)
        }
        guard let jpeg else {
            return nil
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileName = "\(UUID().uuidString).jpg"
        try jpeg.write(to: url(for: fileName), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return fileName
    }

    /// 取り込んだ写真を消す。取り込み先の外を指すファイル名は消さない。無ければ何もしない。
    func delete(fileName: String) {
        guard Self.isValidFileName(fileName) else {
            return
        }
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    /// 写真のファイルの場所。
    func url(for fileName: String) -> URL {
        directory.appending(path: fileName, directoryHint: .notDirectory)
    }

    /// 表示用に縮めて読む。読めなければ nil。
    @concurrent
    func loadImage(fileName: String, maxPixelLength: Int) async -> CGImage? {
        guard Self.isValidFileName(fileName) else {
            return nil
        }
        return PhotoResizer.image(contentsOf: url(for: fileName), maxPixelLength: maxPixelLength)
    }

    /// 選んだばかりの写真のデータを、表示用に縮めて読む。読めなければ nil。
    @concurrent
    func previewImage(data: Data, maxPixelLength: Int) async -> CGImage? {
        PhotoResizer.image(data: data, maxPixelLength: maxPixelLength)
    }

    /// 写真のデータを、調整画面で描くために縮めて読む。範囲の計算に使う元の大きさ（向きを反映した後）も返す。読めなければ nil。
    ///
    /// 短い辺が `shortSidePixels` 以上になる大きさで読み（横長・縦長の写真も、拡大なしの枠で引き伸ばさないため）、長辺は `maxLongSidePixels` までにする。
    /// 元の写真より大きくはしない。
    @concurrent
    func cropSource(data: Data, shortSidePixels: Int, maxLongSidePixels: Int) async -> PhotoCropSource? {
        guard let size = PhotoResizer.orientedPixelSize(of: data) else {
            return nil
        }
        let length = PhotoCropSource.decodeLength(pixelSize: size, shortSidePixels: shortSidePixels, maxLongSidePixels: maxLongSidePixels)
        guard let image = PhotoResizer.image(data: data, maxPixelLength: length) else {
            return nil
        }
        return PhotoCropSource(image: image, pixelSize: size)
    }

    /// 取り込んだ写真のファイルのデータ（調整し直すときに使う）。取り込み先の外を指すファイル名や、読めなければ nil。
    @concurrent
    func photoData(fileName: String) async -> Data? {
        guard Self.isValidFileName(fileName) else {
            return nil
        }
        return try? Data(contentsOf: url(for: fileName))
    }

    /// 選んだばかりの写真を、調整した範囲で切り抜いたプレビュー（一辺 `maxPixelLength` 以下）。読めなければ nil。
    @concurrent
    func croppedPreviewImage(data: Data, crop: PhotoCrop, maxPixelLength: Int) async -> CGImage? {
        PhotoResizer.croppedImage(from: data, crop: crop, maxPixelLength: maxPixelLength)
    }

    /// 取り込みで付けるファイル名（`<UUID>.jpg`）か。ディレクトリの外を指す名前を弾く。
    static func isValidFileName(_ fileName: String) -> Bool {
        guard fileName.hasSuffix(".jpg") else {
            return false
        }
        return UUID(uuidString: String(fileName.dropLast(4))) != nil
    }
}

/// 調整画面に渡す写真。表示用に縮めた画像と、元の写真の大きさ（向きを反映した後の画素）。
nonisolated struct PhotoCropSource: Sendable {
    let image: CGImage
    let pixelSize: CGSize

    /// 写真全体が枠を覆う最小の大きさで、中央・回転なしの範囲（元の写真の画素の座標）。
    var initialCrop: PhotoCrop {
        PhotoCrop(imageSize: pixelSize)
    }

    /// 調整画面で描くために読む長辺（画素）。短い辺が `shortSidePixels` 以上になる長辺を、`maxLongSidePixels` と元の長辺で抑える。
    static func decodeLength(pixelSize: CGSize, shortSidePixels: Int, maxLongSidePixels: Int) -> Int {
        let shortSide = max(min(pixelSize.width, pixelSize.height), 1)
        let longSide = max(pixelSize.width, pixelSize.height)
        let needed = (CGFloat(shortSidePixels) * longSide / shortSide).rounded(.up)
        return Int(min(needed, CGFloat(maxLongSidePixels), longSide))
    }
}
