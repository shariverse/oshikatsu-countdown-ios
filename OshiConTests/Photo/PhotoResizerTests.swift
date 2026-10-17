//
//  PhotoResizerTests.swift
//  OshiConTests
//

import Foundation
import ImageIO
@testable import OshiCon
import Testing
import UniformTypeIdentifiers

struct PhotoResizerTests {
    @Test("長辺 1440px を超える写真は、縦横比を保って長辺 1440px の JPEG にする")
    func shrinksLargePhoto() throws {
        let jpeg = try #require(PhotoResizer.jpegData(from: PhotoFixtures.imageData(width: 3_000, height: 2_000)))
        let properties = try #require(PhotoFixtures.properties(of: jpeg))
        #expect(properties.width == 1_440)
        #expect(properties.height == 960)
        let source = try #require(CGImageSourceCreateWithData(jpeg as CFData, nil))
        #expect(CGImageSourceGetType(source) as String? == UTType.jpeg.identifier)
    }

    @Test("縦長の写真も長辺で縮める")
    func shrinksPortraitPhoto() throws {
        let jpeg = try #require(PhotoResizer.jpegData(from: PhotoFixtures.imageData(width: 1_500, height: 3_000)))
        let properties = try #require(PhotoFixtures.properties(of: jpeg))
        #expect(properties.width == 720)
        #expect(properties.height == 1_440)
    }

    @Test("長辺 1440px 以下の写真は拡大しない")
    func keepsSmallPhoto() throws {
        let jpeg = try #require(PhotoResizer.jpegData(from: PhotoFixtures.imageData(width: 800, height: 600)))
        let properties = try #require(PhotoFixtures.properties(of: jpeg))
        #expect(properties.width == 800)
        #expect(properties.height == 600)
    }

    @Test("写真の向き（EXIF）を画素に反映し、Orientation は残さない")
    func appliesOrientation() throws {
        // Orientation 6 は右に 90° 回して表示する写真。横長の画素が縦長に見える
        let data = PhotoFixtures.imageData(width: 2_000, height: 1_000, type: .jpeg, orientation: 6)
        let jpeg = try #require(PhotoResizer.jpegData(from: data))
        let properties = try #require(PhotoFixtures.properties(of: jpeg))
        #expect(properties.width == 720)
        #expect(properties.height == 1_440)
        let orientation = properties.metadata[kCGImagePropertyOrientation] as? Int
        #expect(orientation == nil || orientation == 1)
    }

    @Test("位置情報は残さない")
    func dropsLocation() throws {
        let data = PhotoFixtures.imageData(width: 1_000, height: 1_000, type: .jpeg, gps: true)
        #expect(PhotoFixtures.properties(of: data)?.metadata[kCGImagePropertyGPSDictionary] != nil)
        let jpeg = try #require(PhotoResizer.jpegData(from: data))
        #expect(PhotoFixtures.properties(of: jpeg)?.metadata[kCGImagePropertyGPSDictionary] == nil)
    }

    @Test("画像でないデータは読めない")
    func rejectsNonImage() {
        #expect(PhotoResizer.jpegData(from: Data("not an image".utf8)) == nil)
        #expect(PhotoResizer.jpegData(from: Data()) == nil)
    }
}
