//
//  OshiEditingTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import SwiftData
import Testing

struct OshiEditingTests {
    private let container: ModelContainer
    private let store: OshiConStore
    private let photos: OshiPhotoLibrary
    private let editing: OshiEditing
    private let now = DomainFixtures.date(2026, 10, 18)

    init() throws {
        container = try OshiConStore.makeContainer(inMemory: true)
        store = OshiConStore(context: ModelContext(container))
        photos = OshiPhotoLibrary(directory: PhotoFixtures.temporaryDirectory())
        editing = OshiEditing(store: store, photos: photos)
    }

    private var photo: Data {
        PhotoFixtures.imageData(width: 2_000, height: 1_500)
    }

    private func exists(_ fileName: String?) -> Bool {
        guard let fileName else {
            return false
        }
        return FileManager.default.fileExists(atPath: photos.url(for: fileName).path(percentEncoded: false))
    }

    private func photoFiles() throws -> [String] {
        let path = photos.directory.path(percentEncoded: false)
        guard FileManager.default.fileExists(atPath: path) else {
            return []
        }
        return try FileManager.default.contentsOfDirectory(atPath: path)
    }

    @Test("写真を選んで登録すると、縮めた写真を取り込んで推しに結び付ける")
    func registerWithPhoto() async throws {
        let oshi = try #require(try await editing.save(current: nil, name: " ミナト ", color: .navy, photoChange: .replace(photo), now: now))
        #expect(oshi.name == "ミナト")
        #expect(oshi.color == .navy)
        #expect(exists(oshi.photoFileName))
        #expect(try store.oshis() == [oshi])
        let data = try Data(contentsOf: photos.url(for: try #require(oshi.photoFileName)))
        #expect(PhotoFixtures.properties(of: data)?.width == 1_440)
    }

    @Test("写真を差し替えると、前の写真を消す")
    func replacePhoto() async throws {
        let first = try #require(try await editing.save(current: nil, name: "ミナト", color: .pink, photoChange: .replace(photo), now: now))
        let second = try #require(try await editing.save(current: first, name: "ミナト", color: .pink, photoChange: .replace(photo), now: now))
        #expect(second.id == first.id)
        #expect(second.photoFileName != first.photoFileName)
        #expect(!exists(first.photoFileName))
        #expect(exists(second.photoFileName))
        #expect(try photoFiles().count == 1)
    }

    @Test("写真を外すと、写真を消す")
    func removePhoto() async throws {
        let first = try #require(try await editing.save(current: nil, name: "ミナト", color: .pink, photoChange: .replace(photo), now: now))
        let second = try #require(try await editing.save(current: first, name: "ミナト", color: .pink, photoChange: .remove, now: now))
        #expect(second.photoFileName == nil)
        #expect(!exists(first.photoFileName))
        #expect(try store.oshis().first?.photoFileName == nil)
    }

    @Test("写真をそのままにすると、写真は変えない")
    func keepPhoto() async throws {
        let first = try #require(try await editing.save(current: nil, name: "ミナト", color: .pink, photoChange: .replace(photo), now: now))
        let second = try #require(try await editing.save(current: first, name: "ミナトくん", color: .blue, photoChange: .keep, now: now))
        #expect(second.photoFileName == first.photoFileName)
        #expect(second.name == "ミナトくん")
        #expect(exists(second.photoFileName))
    }

    @Test("読めない写真に差し替えたときは、今の写真のまま保存する")
    func importFailureKeepsCurrentPhoto() async throws {
        let first = try #require(try await editing.save(current: nil, name: "ミナト", color: .pink, photoChange: .replace(photo), now: now))
        let second = try #require(
            try await editing.save(current: first, name: "ミナト", color: .red, photoChange: .replace(Data("broken".utf8)), now: now)
        )
        #expect(second.photoFileName == first.photoFileName)
        #expect(second.color == .red)
        #expect(exists(first.photoFileName))
        #expect(try photoFiles().count == 1)
    }

    @Test("名前が空白だけなら保存しない。写真も取り込まない")
    func emptyNameIsNotSaved() async throws {
        let saved = try await editing.save(current: nil, name: " 　", color: .pink, photoChange: .replace(photo), now: now)
        #expect(saved == nil)
        #expect(try store.oshis().isEmpty)
        #expect(try photoFiles().isEmpty)
    }

    @Test("推しを削除すると、結び付いた予定と写真も消す")
    func deleteOshi() async throws {
        let oshi = try #require(try await editing.save(current: nil, name: "ミナト", color: .pink, photoChange: .replace(photo), now: now))
        try store.save(OshiEvent(oshiID: oshi.id, kind: .live, title: "ライブ", day: DomainFixtures.day(2026, 11, 1), createdAt: now))
        try editing.delete(oshiID: oshi.id)
        #expect(try store.oshis().isEmpty)
        #expect(try store.events().isEmpty)
        #expect(!exists(oshi.photoFileName))
    }
}
