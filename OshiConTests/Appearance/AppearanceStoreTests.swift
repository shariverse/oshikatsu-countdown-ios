//
//  AppearanceStoreTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

@MainActor
struct AppearanceStoreTests {
    private let defaults: UserDefaults
    private let photos: OshiPhotoLibrary
    private let store: AppearanceStore

    init() throws {
        defaults = try AppearanceFixtures.makeDefaults()
        photos = OshiPhotoLibrary(directory: PhotoFixtures.temporaryDirectory())
        store = AppearanceStore(defaults: defaults, photos: photos)
    }

    private var photo: Data {
        PhotoFixtures.imageData(width: 2_000, height: 1_500)
    }

    private var crop: PhotoCrop {
        PhotoCrop(imageSize: CGSize(width: 2_000, height: 1_500), aspectRatio: PhotoCrop.backgroundAspectRatio)
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

    @Test("ON/OFF を変えると UserDefaults に書き、作り直しても読める")
    func togglesArePersisted() {
        #expect(store.settings == AppearanceSettings())
        store.isBackgroundEnabled = false
        store.isDecorationEnabled = true
        #expect(store.settings == AppearanceSettings(isBackgroundEnabled: false, isDecorationEnabled: true))
        #expect(AppearanceStore(defaults: defaults, photos: photos).settings == store.settings)
    }

    @Test("暗幕の濃さとぼかしの強さを変えると範囲に収めて書き、作り直しても読める")
    func backgroundScrimAndBlurArePersisted() {
        store.backgroundScrim = 0.75
        store.backgroundBlur = 1
        #expect(store.settings.backgroundStyle == AppearanceBackgroundStyle(scrim: 0.75, blur: 1))
        #expect(AppearanceStore(defaults: defaults, photos: photos).settings == store.settings)
        store.backgroundScrim = 3
        store.backgroundBlur = -2
        #expect(store.backgroundScrim == 1)
        #expect(store.backgroundBlur == 0)
        #expect(AppearanceStore(defaults: defaults, photos: photos).settings == store.settings)
    }

    @Test("前の版の強さを保存していれば、ストアはその位置で始め、何かを変えたら新しいキーに書く")
    func legacyIntensityIsMigrated() {
        defaults.set("weak", forKey: AppStorageKey.appearanceIntensity)
        let migrated = AppearanceStore(defaults: defaults, photos: photos)
        #expect(migrated.settings.backgroundStyle == AppearanceBackgroundStyle(scrim: 0.25, blur: 0))
        migrated.isDecorationEnabled = true
        #expect(defaults.object(forKey: AppStorageKey.appearanceIntensity) == nil)
        #expect(AppearanceStore(defaults: defaults, photos: photos).settings == migrated.settings)
    }

    @Test("飾りの濃さと量を変えると範囲に収めて書き、作り直しても読める")
    func decorationOpacityAndAmountArePersisted() {
        store.decorationOpacity = 0.75
        store.decorationAmount = 1
        #expect(store.settings.decorationStyle == OshiPhotoDecorationStyle(opacity: 0.75, amount: 1))
        store.decorationOpacity = 3
        store.decorationAmount = -2
        #expect(store.decorationOpacity == 1)
        #expect(store.decorationAmount == 0)
        #expect(AppearanceStore(defaults: defaults, photos: photos).settings == store.settings)
    }

    @Test("飾りに出す推しを切り替えると書き、もういない推しの分は外す")
    func decorationOshis() {
        let first = UUID()
        let second = UUID()
        let deleted = UUID()
        store.setDecorationIncludes(deleted, false, existingOshiIDs: [first, second, deleted])
        store.setDecorationIncludes(first, false, existingOshiIDs: [first, second, deleted])
        #expect(store.settings.decorationStyle.excludedOshiIDs == [first, deleted])

        // 推しが消えた後に切り替えると、消えた推しの分は残さない
        store.setDecorationIncludes(second, false, existingOshiIDs: [first, second])
        #expect(store.settings.decorationStyle.excludedOshiIDs == [first, second])
        store.setDecorationIncludes(first, true, existingOshiIDs: [first, second])
        #expect(store.settings.decorationStyle.excludedOshiIDs == [second])
        #expect(AppearanceStore(defaults: defaults, photos: photos).settings == store.settings)
    }

    @Test("背景の写真を選ぶと、縦長の範囲で切り抜いて写真の置き場所に取り込み、ファイル名を書く")
    func replaceBackgroundPhoto() async throws {
        let replaced = try await store.replaceBackgroundPhoto(photo, crop: crop)
        #expect(replaced)
        let fileName = try #require(store.settings.backgroundPhotoFileName)
        #expect(exists(fileName))
        #expect(AppearanceStore(defaults: defaults, photos: photos).settings.backgroundPhotoFileName == fileName)
        let properties = try #require(PhotoFixtures.properties(of: Data(contentsOf: photos.url(for: fileName))))
        // 1500px の高さを覆う縦長の範囲（9:19.5）。高さは上限（2560px）より小さいので縮めない
        #expect(properties.height == 1_500)
        #expect(abs(properties.width - 692) <= 1)
    }

    @Test("背景の写真を差し替えると、前の写真を消す")
    func replaceDeletesPrevious() async throws {
        try await store.replaceBackgroundPhoto(photo, crop: crop)
        let first = try #require(store.settings.backgroundPhotoFileName)
        try await store.replaceBackgroundPhoto(photo, crop: crop)
        let second = try #require(store.settings.backgroundPhotoFileName)
        #expect(first != second)
        #expect(!exists(first))
        #expect(exists(second))
        #expect(try photoFiles() == [second])
    }

    @Test("読めない写真を選んだら、何も変えず、前の写真を残す")
    func brokenPhotoKeepsCurrent() async throws {
        try await store.replaceBackgroundPhoto(photo, crop: crop)
        let first = try #require(store.settings.backgroundPhotoFileName)
        let replaced = try await store.replaceBackgroundPhoto(Data("broken".utf8), crop: crop)
        #expect(!replaced)
        #expect(store.settings.backgroundPhotoFileName == first)
        #expect(try photoFiles() == [first])
    }

    @Test("背景の写真を外すと、ファイルを消し、ほかの設定は残す")
    func removeBackgroundPhoto() async throws {
        store.isDecorationEnabled = true
        store.backgroundBlur = 0
        try await store.replaceBackgroundPhoto(photo, crop: crop)
        let fileName = try #require(store.settings.backgroundPhotoFileName)
        store.removeBackgroundPhoto()
        let style = AppearanceBackgroundStyle(blur: 0)
        #expect(store.settings == AppearanceSettings(isBackgroundEnabled: true, isDecorationEnabled: true, backgroundStyle: style))
        #expect(!exists(fileName))
        #expect(defaults.object(forKey: AppStorageKey.appearanceBackgroundPhoto) == nil)
        // 写真が無いときに外しても何もしない
        store.removeBackgroundPhoto()
        #expect(store.settings.backgroundPhotoFileName == nil)
    }

    @Test("Plus でないときは標準の見た目にするが、設定と写真は消さない。使えるようになったらそのまま使う")
    func lockedKeepsSettingsAndPhoto() async throws {
        store.isDecorationEnabled = true
        try await store.replaceBackgroundPhoto(photo, crop: crop)
        let fileName = try #require(store.settings.backgroundPhotoFileName)
        #expect(store.rendering(isPlusUnlocked: false) == .standard)
        #expect(exists(fileName))
        #expect(store.settings.backgroundPhotoFileName == fileName)
        let unlocked = store.rendering(isPlusUnlocked: true)
        #expect(unlocked.backgroundPhoto == AppearanceRendering.BackgroundPhoto(fileName: fileName, style: .default))
        #expect(unlocked.showsOshiPhotoDecoration)
    }

    @Test("メモリ上のストアのときは、別の UserDefaults と一時ディレクトリを空にして使う")
    func volatileStore() async throws {
        let suiteName = "AppearanceStoreTests.\(UUID().uuidString)"
        let directory = PhotoFixtures.temporaryDirectory()
        let first = AppearanceStore.volatile(suiteName: suiteName, directory: directory)
        #expect(first.photos.directory == directory)
        first.isDecorationEnabled = true
        try await first.replaceBackgroundPhoto(photo, crop: crop)
        let fileName = try #require(first.settings.backgroundPhotoFileName)
        #expect(first.photos.directory != OshiPhotoLibrary.shared.directory)

        // 次に起動したときは空から始める
        let second = AppearanceStore.volatile(suiteName: suiteName, directory: directory)
        #expect(second.settings == AppearanceSettings())
        #expect(!FileManager.default.fileExists(atPath: directory.appending(path: fileName).path(percentEncoded: false)))
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    @Test("メモリ上のストアでないときは、端末の UserDefaults と App Group の写真の置き場所を使う")
    func liveStore() {
        #expect(AppearanceStore.forLaunch(usesInMemoryStore: false).photos.directory == OshiPhotoLibrary.shared.directory)
        #expect(AppearanceStore.forLaunch(usesInMemoryStore: true).photos.directory == AppearanceStore.inMemoryPhotosDirectory)
    }
}
