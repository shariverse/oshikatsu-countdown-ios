//
//  PhotoResizerCropTests.swift
//  OshiConTests
//

import CoreGraphics
import Foundation
import ImageIO
@testable import OshiCon
import SwiftUI
import Testing

/// 調整した範囲で正方形に切り抜く取り込み（`PhotoResizer.croppedJPEGData`）。
struct PhotoResizerCropTests {
    private typealias Quadrant = PhotoFixtures.Quadrant

    /// 切り抜いて読み直した画像。
    private static func crop(_ data: Data, _ crop: PhotoCrop) throws -> PhotoFixtures.Pixels {
        let jpeg = try #require(PhotoResizer.croppedJPEGData(from: data, crop: crop))
        return try #require(PhotoFixtures.pixels(of: jpeg))
    }

    /// 400×300 の、4 つの象限を色分けした画像。
    private static let landscape = PhotoFixtures.quadrantImageData(width: 400, height: 300)

    @Test("初期の範囲は、短い辺いっぱいの中央の正方形")
    func initialCropIsCenterSquare() throws {
        let pixels = try Self.crop(Self.landscape, PhotoCrop(imageSize: CGSize(width: 400, height: 300)))
        #expect(pixels.width == 300)
        #expect(pixels.height == 300)
        #expect(pixels.matches(x: 30, y: 30, .topLeft))
        #expect(pixels.matches(x: 270, y: 30, .topRight))
        #expect(pixels.matches(x: 30, y: 270, .bottomLeft))
        #expect(pixels.matches(x: 270, y: 270, .bottomRight))
    }

    @Test("拡大・移動した範囲を切り抜く（左上寄りを 2 倍）")
    func zoomedAndMovedCrop() throws {
        // 1600×1200 の画像で一辺 600px、画像の x 300〜900・y 300〜900。色の境目（x 800・y 600）は切り抜いた画像の x 500・y 300
        let data = PhotoFixtures.quadrantImageData(width: 1_600, height: 1_200)
        let crop = PhotoCrop(imageSize: CGSize(width: 1_600, height: 1_200), zoom: 2, rotation: .zero, center: CGPoint(x: 600, y: 600))
        let pixels = try Self.crop(data, crop)
        #expect(pixels.width == 600)
        #expect(pixels.matches(x: 80, y: 80, .topLeft))
        #expect(pixels.matches(x: 560, y: 80, .topRight))
        #expect(pixels.matches(x: 80, y: 560, .bottomLeft))
        #expect(pixels.matches(x: 560, y: 560, .bottomRight))
        // 境目の手前は左上の色
        #expect(pixels.matches(x: 480, y: 280, .topLeft))
    }

    @Test("右に 90° 回すと、左上には元の画像の左下が写る（画面の回し方と同じ向き）")
    func rotatedClockwise() throws {
        let crop = PhotoCrop(imageSize: CGSize(width: 400, height: 300), zoom: 1, rotation: .degrees(90), center: CGPoint(x: 200, y: 150))
        let pixels = try Self.crop(Self.landscape, crop)
        #expect(pixels.width == 300)
        #expect(pixels.matches(x: 30, y: 30, .bottomLeft))
        #expect(pixels.matches(x: 270, y: 30, .topLeft))
        #expect(pixels.matches(x: 270, y: 270, .topRight))
        #expect(pixels.matches(x: 30, y: 270, .bottomRight))
    }

    @Test("45° 回しても、隅は空かない（拡大率は補正される）")
    func rotated45DegreesCoversCorners() throws {
        let crop = PhotoCrop(imageSize: CGSize(width: 400, height: 300), zoom: 1, rotation: .degrees(45), center: CGPoint(x: 200, y: 150))
        let pixels = try Self.crop(Self.landscape, crop)
        // 補正した拡大率は √2 で、一辺は 300 ÷ √2 ≒ 212px
        #expect(pixels.width == 212)
        let last = pixels.width - 1
        let middle = pixels.width / 2
        // 上の真ん中は画像の左上、右の真ん中は右上（右に回したので）
        #expect(pixels.matches(x: middle, y: 8, .topLeft))
        #expect(pixels.matches(x: last - 8, y: middle, .topRight))
        #expect(pixels.matches(x: middle, y: last - 8, .bottomRight))
        #expect(pixels.matches(x: 8, y: middle, .bottomLeft))
        for (x, y) in [(0, 0), (last, 0), (0, last), (last, last)] {
            #expect(!pixels.isDark(x: x, y: y), "(\(x), \(y)) が空いている")
        }
    }

    @Test("負の角度は左回り")
    func rotatedCounterclockwise() throws {
        let crop = PhotoCrop(imageSize: CGSize(width: 400, height: 300), zoom: 1, rotation: .degrees(-90), center: CGPoint(x: 200, y: 150))
        let pixels = try Self.crop(Self.landscape, crop)
        #expect(pixels.matches(x: 30, y: 30, .topRight))
        #expect(pixels.matches(x: 270, y: 30, .bottomRight))
        #expect(pixels.matches(x: 270, y: 270, .bottomLeft))
        #expect(pixels.matches(x: 30, y: 270, .topLeft))
    }

    @Test("写真の向き（EXIF）を反映した画像の上で切り抜き、Orientation は残さない")
    func appliesOrientationBeforeCropping() throws {
        // 画素は 400×300 の横長。Orientation 6（右に 90° 回して表示）で、見たときは 300×400 の縦長
        let data = PhotoFixtures.quadrantImageData(width: 400, height: 300, type: .jpeg, orientation: 6)
        #expect(PhotoResizer.orientedPixelSize(of: data) == CGSize(width: 300, height: 400))
        let jpeg = try #require(PhotoResizer.croppedJPEGData(from: data, crop: PhotoCrop(imageSize: CGSize(width: 300, height: 400))))
        let pixels = try #require(PhotoFixtures.pixels(of: jpeg))
        #expect(pixels.width == 300)
        #expect(pixels.height == 300)
        // 見たときの左上は、画素の並びでは左下
        #expect(pixels.matches(x: 30, y: 30, .bottomLeft))
        #expect(pixels.matches(x: 270, y: 30, .topLeft))
        #expect(pixels.matches(x: 270, y: 270, .topRight))
        #expect(pixels.matches(x: 30, y: 270, .bottomRight))
        let orientation = PhotoFixtures.properties(of: jpeg)?.metadata[kCGImagePropertyOrientation] as? Int
        #expect(orientation == nil || orientation == 1)
    }

    @Test("位置情報は残さない")
    func dropsLocation() throws {
        let data = PhotoFixtures.quadrantImageData(width: 400, height: 300, type: .jpeg, gps: true)
        let jpeg = try #require(PhotoResizer.croppedJPEGData(from: data, crop: PhotoCrop(imageSize: CGSize(width: 400, height: 300))))
        #expect(PhotoFixtures.properties(of: jpeg)?.metadata[kCGImagePropertyGPSDictionary] == nil)
    }

    @Test("一辺は 1440px まで")
    func capsAt1440Pixels() throws {
        let data = PhotoFixtures.quadrantImageData(width: 4_000, height: 3_000)
        let jpeg = try #require(PhotoResizer.croppedJPEGData(from: data, crop: PhotoCrop(imageSize: CGSize(width: 4_000, height: 3_000))))
        let properties = try #require(PhotoFixtures.properties(of: jpeg))
        #expect(properties.width == 1_440)
        #expect(properties.height == 1_440)
        let pixels = try #require(PhotoFixtures.pixels(of: jpeg))
        #expect(pixels.matches(x: 100, y: 100, .topLeft))
        #expect(pixels.matches(x: 1_340, y: 1_340, .bottomRight))
    }

    @Test("切り抜く範囲が 1440px より小さければ拡大しない")
    func keepsSmallCropSize() throws {
        let data = PhotoFixtures.quadrantImageData(width: 800, height: 600)
        let crop = PhotoCrop(imageSize: CGSize(width: 800, height: 600), zoom: 1.5, rotation: .zero, center: CGPoint(x: 400, y: 300))
        let properties = try #require(PhotoFixtures.properties(of: PhotoResizer.croppedJPEGData(from: data, crop: crop) ?? Data()))
        #expect(properties.width == 400)
        #expect(properties.height == 400)
    }

    @Test("範囲を表示用に縮めた画像の座標で決めても、元の写真の同じ割合の範囲を切り抜く")
    func cropInPreviewCoordinates() throws {
        // 800×600 の写真を 400×300 の座標で、左に寄せた範囲（元の写真では x 0〜600 の一辺 600px）
        let data = PhotoFixtures.quadrantImageData(width: 800, height: 600)
        let crop = PhotoCrop(imageSize: CGSize(width: 400, height: 300), zoom: 1, rotation: .zero, center: CGPoint(x: 150, y: 150))
        let pixels = try Self.crop(data, crop)
        #expect(pixels.width == 600)
        // 色の境目は元の写真の x 400
        #expect(pixels.matches(x: 380, y: 20, .topLeft))
        #expect(pixels.matches(x: 420, y: 20, .topRight))
        #expect(pixels.matches(x: 20, y: 580, .bottomLeft))
    }

    @Test("枠から外れた範囲は、補正してから切り抜く（隅が空かない）")
    func clampsBeforeCropping() throws {
        let crop = PhotoCrop(imageSize: CGSize(width: 400, height: 300), zoom: 0.5, rotation: .zero, center: CGPoint(x: -1_000, y: 150))
        let pixels = try Self.crop(Self.landscape, crop)
        // 拡大率は 1、中心は x 150 に戻り、画像の x 0〜300 を切り抜く
        #expect(pixels.width == 300)
        #expect(pixels.matches(x: 2, y: 2, .topLeft))
        #expect(pixels.matches(x: 270, y: 30, .topRight))
        #expect(pixels.matches(x: 2, y: 297, .bottomLeft))
    }

    @Test("拡大・回転した大きな写真も、一辺 1440px までにする")
    func capsRotatedCropOfLargePhoto() throws {
        let data = PhotoFixtures.quadrantImageData(width: 4_000, height: 3_000)
        let crop = PhotoCrop(
            imageSize: CGSize(width: 4_000, height: 3_000),
            zoom: 1.5,
            rotation: .degrees(30),
            center: CGPoint(x: 2_000, y: 1_500)
        )
        let pixels = try Self.crop(data, crop)
        #expect(pixels.width == 1_440)
        #expect(pixels.height == 1_440)
        for (x, y) in [(0, 0), (1_439, 0), (0, 1_439), (1_439, 1_439)] {
            #expect(!pixels.isDark(x: x, y: y), "(\(x), \(y)) が空いている")
        }
    }

    @Test("切り抜く範囲が 1440px より広ければ、足りる大きさまで縮めて読む（広くなければ元の大きさで読む）")
    func decodesOnlyWhatIsNeeded() {
        let size = CGSize(width: 8_064, height: 6_048)
        // 写真全体（一辺 6048px）を 1440px に切り抜くなら、長辺 1920px で読めば足りる
        #expect(PhotoResizer.decodePixelLength(orientedSize: size, cropSide: 6_048, outputSide: 1_440) == 1_920)
        // 一辺 1000px の範囲は縮めずに読む
        #expect(PhotoResizer.decodePixelLength(orientedSize: size, cropSide: 1_000, outputSide: 1_000) == 8_064)
    }

    @Test("範囲の縦横比が写真と違えば（向きの取り違え）切り抜かない")
    func rejectsMismatchedAspectRatio() {
        // 写真は 400×300 の横長なのに、範囲は縦長の 300×400 の座標
        #expect(PhotoResizer.croppedImage(from: Self.landscape, crop: PhotoCrop(imageSize: CGSize(width: 300, height: 400))) == nil)
    }

    @Test("広い色域（Display P3）の写真は、その色空間のまま切り抜く")
    func keepsWideColorSpace() throws {
        let data = PhotoFixtures.quadrantImageData(width: 400, height: 300, colorSpace: CGColorSpace(name: CGColorSpace.displayP3))
        let image = try #require(PhotoResizer.croppedImage(from: data, crop: PhotoCrop(imageSize: CGSize(width: 400, height: 300))))
        #expect(image.colorSpace?.name == CGColorSpace.displayP3)
    }

    @Test("調整画面に渡す写真は、縮めた画像と、向きを反映した元の大きさ")
    func cropSourceKeepsOriginalSize() async throws {
        let photos = OshiPhotoLibrary(directory: PhotoFixtures.temporaryDirectory())
        let data = PhotoFixtures.quadrantImageData(width: 2_000, height: 1_000, type: .jpeg, orientation: 6)
        let source = try #require(await photos.cropSource(data: data, shortSidePixels: 250, maxLongSidePixels: 4_096))
        #expect(source.pixelSize == CGSize(width: 1_000, height: 2_000))
        #expect(source.image.width == 250)
        #expect(source.image.height == 500)
        #expect(source.initialCrop == PhotoCrop(imageSize: CGSize(width: 1_000, height: 2_000)))
        let preview = try #require(await photos.croppedPreviewImage(data: data, crop: source.initialCrop, maxPixelLength: 288))
        #expect(preview.width == 288)
        #expect(preview.height == 288)
    }

    @Test("調整画面で描く写真は、短い辺が足りる大きさで読み、長辺と元の大きさで抑える")
    func cropSourceDecodeLength() {
        func length(_ width: CGFloat, _ height: CGFloat) -> Int {
            PhotoCropSource.decodeLength(pixelSize: CGSize(width: width, height: height), shortSidePixels: 1_680, maxLongSidePixels: 4_096)
        }
        // 4:3 の写真で短い辺 1680px なら長辺 2240px
        #expect(length(4_032, 3_024) == 2_240)
        // 4:1 のパノラマは長辺の上限で止める
        #expect(length(16_000, 4_000) == 4_096)
        // 小さい写真は元の大きさ
        #expect(length(800, 600) == 800)
    }

    @Test("取り込んだ写真のデータを読める。取り込み先の外を指す名前は読まない")
    func readsImportedPhotoData() async throws {
        let directory = PhotoFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let photos = OshiPhotoLibrary(directory: directory)
        let fileName = try #require(try await photos.importPhoto(Self.landscape))
        let data = try #require(await photos.photoData(fileName: fileName))
        #expect(PhotoResizer.orientedPixelSize(of: data) == CGSize(width: 400, height: 300))
        #expect(await photos.photoData(fileName: "../secret.jpg") == nil)
        #expect(await photos.photoData(fileName: "\(UUID().uuidString).jpg") == nil)
    }

    @Test("画像でないデータは読めない")
    func rejectsNonImage() {
        #expect(PhotoResizer.croppedJPEGData(from: Data("broken".utf8), crop: PhotoCrop(imageSize: CGSize(width: 10, height: 10))) == nil)
    }

    @Test("範囲つきで取り込むと、正方形の JPEG を保存する")
    func importsCroppedPhoto() async throws {
        let directory = PhotoFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let photos = OshiPhotoLibrary(directory: directory)
        let crop = PhotoCrop(imageSize: CGSize(width: 400, height: 300))
        let fileName = try #require(try await photos.importPhoto(Self.landscape, crop: crop))
        let properties = try #require(PhotoFixtures.properties(of: Data(contentsOf: photos.url(for: fileName))))
        #expect(properties.width == 300)
        #expect(properties.height == 300)
    }
}

extension PhotoFixtures.Pixels {
    /// (x, y) の画素が黒に近い（切り抜いた範囲が画像の外にはみ出した）か。
    func isDark(x: Int, y: Int) -> Bool {
        let index = (y * width + x) * 4
        return max(bytes[index], bytes[index + 1], bytes[index + 2]) < 40
    }
}
