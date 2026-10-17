//
//  OshiPhotoLibraryTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct OshiPhotoLibraryTests {
    private let photos = OshiPhotoLibrary(directory: PhotoFixtures.temporaryDirectory())

    @Test("取り込んだ写真を読み、消せる")
    func importLoadDelete() async throws {
        let fileName = try #require(try await photos.importPhoto(PhotoFixtures.imageData(width: 400, height: 300)))
        #expect(OshiPhotoLibrary.isValidFileName(fileName))
        let image = try #require(await photos.loadImage(fileName: fileName, maxPixelLength: 100))
        #expect(max(image.width, image.height) == 100)

        photos.delete(fileName: fileName)
        #expect(!FileManager.default.fileExists(atPath: photos.url(for: fileName).path(percentEncoded: false)))
        #expect(await photos.loadImage(fileName: fileName, maxPixelLength: 100) == nil)
    }

    @Test("読めないデータは取り込まない")
    func importRejectsNonImage() async throws {
        #expect(try await photos.importPhoto(Data("broken".utf8)) == nil)
    }

    @Test(
        "取り込みで付けた名前でないファイル名は扱わない（ディレクトリの外を消さない）",
        arguments: ["../OshiCon.store", "photo.jpg", "\(UUID().uuidString).png", "/\(UUID().uuidString).jpg", ""]
    )
    func rejectsUnexpectedFileName(fileName: String) {
        #expect(!OshiPhotoLibrary.isValidFileName(fileName))
    }

    @Test("無い写真を消しても何もしない")
    func deleteMissing() {
        let fileName = "\(UUID().uuidString).jpg"
        photos.delete(fileName: fileName)
        #expect(!FileManager.default.fileExists(atPath: photos.url(for: fileName).path(percentEncoded: false)))
    }
}
