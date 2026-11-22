//
//  PhotoResizerRectangleCropTests.swift
//  OshiConTests
//

import CoreGraphics
import Foundation
import ImageIO
@testable import OshiCon
import SwiftUI
import Testing

/// 縦長の枠（背景の写真）で長方形に切り抜く取り込み（`PhotoResizer.croppedJPEGData`）。
struct PhotoResizerRectangleCropTests {
    private static let background = PhotoCrop.backgroundAspectRatio

    /// 切り抜いて読み直した画像。
    private static func crop(
        _ data: Data,
        _ crop: PhotoCrop,
        maxPixelLength: Int = PhotoResizer.maxPixelLength
    ) throws -> PhotoFixtures.Pixels {
        let jpeg = try #require(PhotoResizer.croppedJPEGData(from: data, crop: crop, maxPixelLength: maxPixelLength))
        return try #require(PhotoFixtures.pixels(of: jpeg))
    }

    // MARK: - 大きさ

    @Test("切り抜いた画像の大きさ: 長い辺は範囲と上限の小さいほう、短い辺は縦横比に合わせる")
    func outputPixelSize() {
        func size(_ width: CGFloat, _ height: CGFloat, max maxPixelLength: Int) -> [Int] {
            let output = PhotoResizer.outputPixelSize(cropSize: CGSize(width: width, height: height), maxPixelLength: maxPixelLength)
            return [output.width, output.height]
        }
        #expect(size(6_048, 6_048, max: 1_440) == [1_440, 1_440])
        #expect(size(3_000 * Self.background, 3_000, max: 2_560) == [1_182, 2_560])
        #expect(size(3_000, 3_000 * Self.background, max: 2_560) == [2_560, 1_182])
        // 小さい範囲は拡大しない
        #expect(size(100, 100 / Self.background, max: 2_560) == [100, 217])
        // 細すぎても 1px は残す
        #expect(size(0.2, 3_000, max: 1_440) == [1, 1_440])
    }

    @Test("背景の写真の長い辺の上限は 2560px")
    func backgroundPixelLength() {
        #expect(PhotoResizer.maxBackgroundPixelLength == 2_560)
        #expect(PhotoResizer.maxBackgroundPixelLength > PhotoResizer.maxPixelLength)
    }

    @Test("大きな写真は、背景の上限で長い辺 2560px の縦長に切り抜く")
    func capsBackgroundAt2560Pixels() throws {
        let data = PhotoFixtures.quadrantImageData(width: 4_000, height: 3_000)
        let crop = PhotoCrop(imageSize: CGSize(width: 4_000, height: 3_000), aspectRatio: Self.background)
        let jpeg = try #require(PhotoResizer.croppedJPEGData(from: data, crop: crop, maxPixelLength: PhotoResizer.maxBackgroundPixelLength))
        let properties = try #require(PhotoFixtures.properties(of: jpeg))
        #expect(properties.width == 1_182)
        #expect(properties.height == 2_560)
    }

    @Test("上限を渡さなければ、長い辺は 1440px まで")
    func defaultCapIs1440Pixels() throws {
        let data = PhotoFixtures.quadrantImageData(width: 4_000, height: 3_000)
        let crop = PhotoCrop(imageSize: CGSize(width: 4_000, height: 3_000), aspectRatio: Self.background)
        let properties = try #require(PhotoFixtures.properties(of: PhotoResizer.croppedJPEGData(from: data, crop: crop) ?? Data()))
        #expect(properties.height == 1_440)
        #expect(properties.width == 665)
    }

    // MARK: - 切り抜く範囲

    @Test("初期の範囲は、写真の高さいっぱいの中央の縦長の長方形")
    func initialCropIsCenterPortrait() throws {
        // 1600×1200 の写真で、幅 1200 × 9/19.5 ≒ 554px、x 523〜1077。色の境目（x 800）は切り抜いた画像の x 277
        let data = PhotoFixtures.quadrantImageData(width: 1_600, height: 1_200)
        let pixels = try Self.crop(data, PhotoCrop(imageSize: CGSize(width: 1_600, height: 1_200), aspectRatio: Self.background))
        #expect(pixels.width == 554)
        #expect(pixels.height == 1_200)
        #expect(pixels.matches(x: 20, y: 20, .topLeft))
        #expect(pixels.matches(x: 534, y: 20, .topRight))
        #expect(pixels.matches(x: 20, y: 1_180, .bottomLeft))
        #expect(pixels.matches(x: 534, y: 1_180, .bottomRight))
        #expect(pixels.matches(x: 260, y: 20, .topLeft))
        #expect(pixels.matches(x: 295, y: 20, .topRight))
    }

    @Test("移動した範囲を切り抜く（左の端に寄せると左の色だけ）")
    func movedCrop() throws {
        let data = PhotoFixtures.quadrantImageData(width: 1_600, height: 1_200)
        let crop = PhotoCrop(
            imageSize: CGSize(width: 1_600, height: 1_200),
            aspectRatio: Self.background,
            zoom: 1,
            rotation: .zero,
            center: CGPoint(x: -1_000, y: 600)
        )
        let pixels = try Self.crop(data, crop)
        #expect(pixels.width == 554)
        for x in [2, 277, 551] {
            #expect(pixels.matches(x: x, y: 20, .topLeft), "x \(x)")
            #expect(pixels.matches(x: x, y: 1_180, .bottomLeft), "x \(x)")
        }
    }

    @Test("右に 90° 回すと、左上には元の画像の左下が写る（縦長のまま）")
    func rotatedClockwise() throws {
        let data = PhotoFixtures.quadrantImageData(width: 1_600, height: 1_200)
        let crop = PhotoCrop(
            imageSize: CGSize(width: 1_600, height: 1_200),
            aspectRatio: Self.background,
            zoom: 1,
            rotation: .degrees(90),
            center: CGPoint(x: 800, y: 600)
        )
        let pixels = try Self.crop(data, crop)
        #expect(pixels.width == 554)
        #expect(pixels.height == 1_200)
        #expect(pixels.matches(x: 20, y: 20, .bottomLeft))
        #expect(pixels.matches(x: 534, y: 20, .topLeft))
        #expect(pixels.matches(x: 534, y: 1_180, .topRight))
        #expect(pixels.matches(x: 20, y: 1_180, .bottomRight))
    }

    @Test("回して拡大した大きな写真も、隅は空かない", arguments: [12.0, 30, -45, 135])
    func rotatedCropCoversCorners(degrees: Double) throws {
        let data = PhotoFixtures.quadrantImageData(width: 4_000, height: 3_000)
        let crop = PhotoCrop(
            imageSize: CGSize(width: 4_000, height: 3_000),
            aspectRatio: Self.background,
            zoom: 1,
            rotation: .degrees(degrees),
            center: CGPoint(x: 3_900, y: 100)
        )
        let pixels = try Self.crop(data, crop, maxPixelLength: PhotoResizer.maxBackgroundPixelLength)
        #expect(pixels.height > pixels.width)
        let lastX = pixels.width - 1
        let lastY = pixels.height - 1
        for (x, y) in [(0, 0), (lastX, 0), (0, lastY), (lastX, lastY)] {
            #expect(!pixels.isDark(x: x, y: y), "(\(x), \(y)) が空いている")
        }
    }

    @Test("写真の向き（EXIF）を反映した画像の上で縦長に切り抜き、Orientation と位置情報は残さない")
    func appliesOrientationBeforeCropping() throws {
        // 画素は 400×300 の横長。Orientation 6（右に 90° 回して表示）で、見たときは 300×400 の縦長
        let data = PhotoFixtures.quadrantImageData(width: 400, height: 300, type: .jpeg, orientation: 6, gps: true)
        let crop = PhotoCrop(imageSize: CGSize(width: 300, height: 400), aspectRatio: Self.background)
        let jpeg = try #require(PhotoResizer.croppedJPEGData(from: data, crop: crop))
        let pixels = try #require(PhotoFixtures.pixels(of: jpeg))
        // 幅は 400 × 9/19.5 ≒ 185px
        #expect(pixels.width == 185)
        #expect(pixels.height == 400)
        // 見たときの左上は、画素の並びでは左下
        #expect(pixels.matches(x: 10, y: 10, .bottomLeft))
        #expect(pixels.matches(x: 175, y: 10, .topLeft))
        #expect(pixels.matches(x: 175, y: 390, .topRight))
        #expect(pixels.matches(x: 10, y: 390, .bottomRight))
        let metadata = try #require(PhotoFixtures.properties(of: jpeg)).metadata
        let orientation = metadata[kCGImagePropertyOrientation] as? Int
        #expect(orientation == nil || orientation == 1)
        #expect(metadata[kCGImagePropertyGPSDictionary] == nil)
    }

    @Test("広い色域（Display P3）の写真は、縦長でもその色空間のまま切り抜く")
    func keepsWideColorSpace() throws {
        let data = PhotoFixtures.quadrantImageData(width: 400, height: 300, colorSpace: CGColorSpace(name: CGColorSpace.displayP3))
        let crop = PhotoCrop(imageSize: CGSize(width: 400, height: 300), aspectRatio: Self.background)
        let image = try #require(PhotoResizer.croppedImage(from: data, crop: crop))
        #expect(image.colorSpace?.name == CGColorSpace.displayP3)
        #expect(image.height > image.width)
    }

    @Test("範囲を表示用に縮めた画像の座標で決めても、元の写真の同じ割合の縦長の範囲を切り抜く")
    func cropInPreviewCoordinates() throws {
        let data = PhotoFixtures.quadrantImageData(width: 1_600, height: 1_200)
        let crop = PhotoCrop(imageSize: CGSize(width: 400, height: 300), aspectRatio: Self.background)
        let pixels = try Self.crop(data, crop)
        #expect(pixels.width == 554)
        #expect(pixels.height == 1_200)
    }

    // MARK: - 取り込み

    @Test("縦長の範囲と背景の上限で取り込むと、縦長の JPEG を保存する")
    func importsBackgroundPhoto() async throws {
        let directory = PhotoFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let photos = OshiPhotoLibrary(directory: directory)
        let data = PhotoFixtures.quadrantImageData(width: 4_000, height: 3_000)
        let source = try #require(await photos.cropSource(data: data, shortSidePixels: 600, maxLongSidePixels: 4_096))
        let crop = source.initialCrop(aspectRatio: Self.background)
        #expect(crop.aspectRatio == Self.background)
        #expect(crop.imageSize == CGSize(width: 4_000, height: 3_000))
        let maxPixelLength = PhotoResizer.maxBackgroundPixelLength
        let fileName = try #require(try await photos.importPhoto(data, crop: crop, maxPixelLength: maxPixelLength))
        let properties = try #require(PhotoFixtures.properties(of: Data(contentsOf: photos.url(for: fileName))))
        #expect(properties.width == 1_182)
        #expect(properties.height == 2_560)
    }

    @Test("推しの写真の取り込みは、上限を渡さなければ今までどおり一辺 1440px の正方形")
    func importsOshiPhotoAsBefore() async throws {
        let directory = PhotoFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let photos = OshiPhotoLibrary(directory: directory)
        let data = PhotoFixtures.quadrantImageData(width: 4_000, height: 3_000)
        let fileName = try #require(try await photos.importPhoto(data, crop: PhotoCrop(imageSize: CGSize(width: 4_000, height: 3_000))))
        let properties = try #require(PhotoFixtures.properties(of: Data(contentsOf: photos.url(for: fileName))))
        #expect(properties.width == 1_440)
        #expect(properties.height == 1_440)
    }
}
