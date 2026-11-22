//
//  WidgetPhotoLoaderTests.swift
//  OshiConTests
//

import CoreGraphics
import Foundation
@testable import OshiCon
import Testing

struct WidgetPhotoLoaderTests {
    private let directory = PhotoFixtures.temporaryDirectory()

    private var loader: WidgetPhotoLoader {
        WidgetPhotoLoader(directory: directory)
    }

    /// `data` を取り込みと同じ名前（`<UUID>.jpg`）で置き、ファイル名を返す。
    private func place(_ data: Data) throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileName = "\(UUID().uuidString).jpg"
        try data.write(to: directory.appending(path: fileName, directoryHint: .notDirectory))
        return fileName
    }

    @Test("写真をウィジェットの大きさに縮めて読む")
    func loadsResized() throws {
        let fileName = try place(PhotoFixtures.imageData(width: 1_440, height: 1_440, type: .jpeg))
        let image = try #require(loader.loadImage(fileName: fileName, pixelLength: 510))
        #expect(image.width == 510)
        #expect(image.height == 510)
    }

    @Test("大きい枠を頼んでも、一辺は上限（720px）まで")
    func capsAtMaximum() throws {
        let fileName = try place(PhotoFixtures.imageData(width: 1_440, height: 1_440, type: .jpeg))
        let image = try #require(loader.loadImage(fileName: fileName, pixelLength: 4_000))
        #expect(WidgetPhotoLoader.maxPixelLength == 720)
        #expect(max(image.width, image.height) == WidgetPhotoLoader.maxPixelLength)
    }

    @Test("小さい写真は拡大しない。0 以下を頼んでも読める")
    func keepsSmallPhoto() throws {
        let fileName = try place(PhotoFixtures.imageData(width: 300, height: 300, type: .jpeg))
        let image = try #require(loader.loadImage(fileName: fileName, pixelLength: 510))
        #expect(image.width == 300)
        #expect(image.height == 300)
        #expect(loader.loadImage(fileName: fileName, pixelLength: 0) != nil)
    }

    @Test("写真の向き（EXIF）を反映して読む")
    func appliesOrientation() throws {
        // Orientation 6 は 90° 回して表示するので、縦と横が入れ替わる
        let fileName = try place(PhotoFixtures.imageData(width: 400, height: 200, type: .jpeg, orientation: 6))
        let image = try #require(loader.loadImage(fileName: fileName, pixelLength: 100))
        #expect(image.width == 50)
        #expect(image.height == 100)
    }

    @Test("無い写真・読めないファイルは読まない")
    func missingOrBroken() throws {
        #expect(loader.loadImage(fileName: "\(UUID().uuidString).jpg", pixelLength: 510) == nil)
        let broken = try place(Data("broken".utf8))
        #expect(loader.loadImage(fileName: broken, pixelLength: 510) == nil)
    }

    @Test(
        "取り込みで付けた名前でないファイル名は読まない（ディレクトリの外を読まない）",
        arguments: ["../OshiCon.store", "photo.jpg", "\(UUID().uuidString).png", "/\(UUID().uuidString).jpg", ""]
    )
    func rejectsUnexpectedFileName(fileName: String) {
        #expect(!AppGroupContainer.isPhotoFileName(fileName))
        #expect(loader.loadImage(fileName: fileName, pixelLength: 510) == nil)
    }

    @Test(
        "枠の一辺と画面の倍率から読む一辺を求め、上限で抑える。大きさが分からなければ上限",
        arguments: [
            (170, 3, 510),
            (169.5, 2, 339),
            (158, 3, 474),
            (400, 3, 720),
            (0, 3, 720),
            (170, 0, 720),
            (.infinity, 3, 720),
            (.nan, 3, 720)
        ] as [(CGFloat, CGFloat, Int)]
    )
    func pixelLength(pointLength: CGFloat, scale: CGFloat, expected: Int) {
        #expect(WidgetPhotoLoader.pixelLength(pointLength: pointLength, scale: scale) == expected)
    }

    @Test("写真は App Group のデータの Photos から読み、アプリが取り込む場所と同じ")
    func photosDirectory() {
        #expect(WidgetPhotoLoader().directory == AppGroupContainer.dataDirectory.appending(path: "Photos", directoryHint: .isDirectory))
        #expect(WidgetPhotoLoader().directory == OshiPhotoLibrary.shared.directory)
    }
}
