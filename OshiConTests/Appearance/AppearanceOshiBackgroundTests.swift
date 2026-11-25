//
//  AppearanceOshiBackgroundTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

/// 推しごとの背景の写真で使う値。
nonisolated private enum OshiBackgroundFixtures {
    /// 共通の背景の写真。
    static let common = AppearanceFixtures.photoFileName
    /// 推しの背景の写真。
    static let minato = "00000000-0000-0000-0000-0000000000A1.jpg"
    static let lumina = "00000000-0000-0000-0000-0000000000B2.jpg"
    static let minatoID = UUID()
    static let luminaID = UUID()
}

/// 推しごとの背景の写真の、設定の読み書き。
struct AppearanceOshiBackgroundSettingsTests {
    private typealias Fixture = OshiBackgroundFixtures

    @Test("書いたことが無ければ、推しごとの背景の写真は無い")
    func defaultsAreEmpty() throws {
        let settings = AppearanceSettings(defaults: try AppearanceFixtures.makeDefaults())
        #expect(settings.oshiBackgroundPhotoFileNames.isEmpty)
        #expect(settings.backgroundPhotoFileName(for: Fixture.minatoID) == nil)
    }

    @Test("推しごとの背景の写真を書いて読み直せる。1 つも無くなったらキーを消す")
    func writeAndRead() throws {
        let defaults = try AppearanceFixtures.makeDefaults()
        let settings = AppearanceSettings(
            backgroundPhotoFileName: Fixture.common,
            oshiBackgroundPhotoFileNames: [Fixture.minatoID: Fixture.minato, Fixture.luminaID: Fixture.lumina]
        )
        settings.write(to: defaults)
        #expect(AppearanceSettings(defaults: defaults) == settings)

        var removed = settings
        removed.setBackgroundPhotoFileName(nil, for: Fixture.minatoID)
        removed.setBackgroundPhotoFileName(nil, for: Fixture.luminaID)
        removed.write(to: defaults)
        #expect(defaults.object(forKey: AppStorageKey.appearanceOshiBackgroundPhotos) == nil)
        // 共通の写真は残る
        #expect(AppearanceSettings(defaults: defaults) == AppearanceSettings(backgroundPhotoFileName: Fixture.common))
    }

    @Test("推しの id が UUID でない・ファイル名が写真の置き場所の外を指す・文字でない項目は読まない。辞書でなければ無いものとする")
    func invalidEntriesAreIgnored() throws {
        let defaults = try AppearanceFixtures.makeDefaults()
        defaults.set(
            [
                Fixture.minatoID.uuidString: Fixture.minato,
                "not-a-uuid": Fixture.lumina,
                Fixture.luminaID.uuidString: "../secret.jpg",
                UUID().uuidString: 42
            ] as [String: Any],
            forKey: AppStorageKey.appearanceOshiBackgroundPhotos
        )
        #expect(AppearanceSettings(defaults: defaults).oshiBackgroundPhotoFileNames == [Fixture.minatoID: Fixture.minato])

        defaults.set("broken", forKey: AppStorageKey.appearanceOshiBackgroundPhotos)
        #expect(AppearanceSettings(defaults: defaults).oshiBackgroundPhotoFileNames.isEmpty)
    }

    @Test("推しの id を渡すとその推しの写真、nil なら共通の写真を読み書きする（推しの写真が無くても共通の写真には戻らない）")
    func fileNameForTarget() {
        var settings = AppearanceSettings(backgroundPhotoFileName: Fixture.common)
        #expect(settings.backgroundPhotoFileName(for: nil) == Fixture.common)
        #expect(settings.backgroundPhotoFileName(for: Fixture.minatoID) == nil)

        settings.setBackgroundPhotoFileName(Fixture.minato, for: Fixture.minatoID)
        #expect(settings.backgroundPhotoFileName(for: Fixture.minatoID) == Fixture.minato)
        #expect(settings.backgroundPhotoFileName == Fixture.common)

        settings.setBackgroundPhotoFileName(nil, for: nil)
        #expect(settings.backgroundPhotoFileName == nil)
        #expect(settings.oshiBackgroundPhotoFileNames == [Fixture.minatoID: Fixture.minato])
    }
}

/// 推しごとの背景の写真の、描き分けの規則（`AppearanceRendering`）。
struct AppearanceOshiBackgroundRenderingTests {
    private typealias Fixture = OshiBackgroundFixtures

    private let settings = AppearanceSettings(
        backgroundStyle: AppearanceBackgroundStyle(scrim: 0.25, blur: 0),
        backgroundPhotoFileName: Fixture.common,
        oshiBackgroundPhotoFileNames: [Fixture.minatoID: Fixture.minato]
    )

    @Test("その推しの写真があればそれを、暗幕とぼかしは全体の設定で敷く")
    func oshiBackgroundWins() {
        let rendering = AppearanceRendering(settings: settings, isPlusUnlocked: true, oshiID: Fixture.minatoID)
        let photo = AppearanceRendering.BackgroundPhoto(fileName: Fixture.minato, style: settings.backgroundStyle, oshiID: Fixture.minatoID)
        #expect(rendering.backgroundPhoto == photo)
        #expect(rendering.backgroundPhoto?.isOshiBackground == true)
    }

    @Test("推しを決めていない画面（すべて・推しなしの予定）と、写真の無い推しの画面には共通の写真を敷く", arguments: [nil, OshiBackgroundFixtures.luminaID])
    func fallsBackToCommon(oshiID: UUID?) {
        let rendering = AppearanceRendering(settings: settings, isPlusUnlocked: true, oshiID: oshiID)
        #expect(rendering.backgroundPhoto == AppearanceRendering.BackgroundPhoto(fileName: Fixture.common, style: settings.backgroundStyle))
        #expect(rendering.backgroundPhoto?.isOshiBackground == false)
    }

    @Test("共通の写真が無ければ、推しの写真のある推しの画面にだけ敷き、ほかは標準")
    func onlyOshiBackground() {
        var settings = settings
        settings.backgroundPhotoFileName = nil
        let rendering = { (oshiID: UUID?) in
            AppearanceRendering(settings: settings, isPlusUnlocked: true, oshiID: oshiID)
        }
        #expect(rendering(Fixture.minatoID).backgroundPhoto?.fileName == Fixture.minato)
        #expect(rendering(Fixture.luminaID).isStandard)
        #expect(rendering(nil).isStandard)
    }

    @Test("共通も推しごとも無ければ標準。背景を OFF にしていれば、推しの写真があっても敷かない（飾りは別に効く）")
    func noneOrDisabled() {
        #expect(AppearanceRendering(settings: AppearanceSettings(), isPlusUnlocked: true, oshiID: Fixture.minatoID).isStandard)

        var off = settings
        off.isBackgroundEnabled = false
        #expect(AppearanceRendering(settings: off, isPlusUnlocked: true, oshiID: Fixture.minatoID).isStandard)
        off.isDecorationEnabled = true
        let decorated = AppearanceRendering(settings: off, isPlusUnlocked: true, oshiID: Fixture.minatoID)
        #expect(decorated.backgroundPhoto == nil)
        #expect(decorated.showsOshiPhotoDecoration)
    }

    @Test("Plus が使えなければ、推しの写真があっても標準")
    func lockedIsStandard() {
        #expect(AppearanceRendering(settings: settings, isPlusUnlocked: false, oshiID: Fixture.minatoID) == .standard)
    }

    @Test("推しの写真のファイル名が写真の置き場所の外を指していれば、共通の写真にする")
    func invalidOshiFileNameFallsBack() {
        let settings = AppearanceSettings(
            backgroundPhotoFileName: Fixture.common,
            oshiBackgroundPhotoFileNames: [Fixture.minatoID: "../secret.jpg"]
        )
        let rendering = AppearanceRendering(settings: settings, isPlusUnlocked: true, oshiID: Fixture.minatoID)
        #expect(rendering.backgroundPhoto?.fileName == Fixture.common)
        #expect(rendering.backgroundPhoto?.isOshiBackground == false)
    }

    @Test("推しの写真を敷くときも、板と上の端の覆いを掛ける（文字の読みやすさの扱いは共通の写真と同じ）")
    func textPlateStillApplies() {
        let rendering = AppearanceRendering(settings: settings, isPlusUnlocked: true, oshiID: Fixture.minatoID)
        #expect(rendering.drawsPhotosOnGround)
    }

    @Test("シェアのカードの地は、その予定の推しの写真があればそれ、無ければ共通の写真")
    func shareCardUsesSameRule() {
        let oshi = ShareCardStyle.appearance(AppearanceRendering(settings: settings, isPlusUnlocked: true, oshiID: Fixture.minatoID))
        #expect(oshi.background == .photo(fileName: Fixture.minato))
        let other = ShareCardStyle.appearance(AppearanceRendering(settings: settings, isPlusUnlocked: true, oshiID: Fixture.luminaID))
        #expect(other.background == .photo(fileName: Fixture.common))
        let locked = AppearanceRendering(settings: settings, isPlusUnlocked: false, oshiID: Fixture.minatoID)
        #expect(ShareCardStyle.appearance(locked) == .shipping)
    }

    @Test("UI テストの口は、共通の写真を photo、推しの写真を oshiPhoto で表す")
    func uiTestMarker() {
        var decorated = settings
        decorated.isDecorationEnabled = true
        let oshi = AppearanceRendering(settings: decorated, isPlusUnlocked: true, oshiID: Fixture.minatoID)
        #expect(AppearanceUITestMarker.value(of: oshi) == "oshiPhoto,decoration")
        let common = AppearanceRendering(settings: settings, isPlusUnlocked: true, oshiID: Fixture.luminaID)
        #expect(AppearanceUITestMarker.value(of: common) == "photo")
    }
}

/// 推しの削除に失敗するストア。
private struct FailingDeletionStore: OshiStoring {
    struct Failure: Error {}

    func save(_ oshi: Oshi, now: Date) throws {}

    func deleteOshi(id: Oshi.ID) throws -> Oshi? {
        throw Failure()
    }
}

/// 推しごとの背景の写真の、ストア（取り込み・差し替え・外す・推しの削除）。
@MainActor
struct AppearanceOshiBackgroundStoreTests {
    private typealias Fixture = OshiBackgroundFixtures

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

    private func photoFiles() throws -> Set<String> {
        let path = photos.directory.path(percentEncoded: false)
        guard FileManager.default.fileExists(atPath: path) else {
            return []
        }
        return Set(try FileManager.default.contentsOfDirectory(atPath: path))
    }

    @Test("推しの写真を選ぶと、共通の写真と同じ置き場所・同じ縦長の範囲で取り込み、その推しに結び付けて書く")
    func replaceOshiBackground() async throws {
        #expect(try await store.replaceBackgroundPhoto(photo, crop: crop, for: Fixture.minatoID))
        let fileName = try #require(store.settings.oshiBackgroundPhotoFileNames[Fixture.minatoID])
        #expect(store.settings.backgroundPhotoFileName == nil)
        #expect(exists(fileName))
        #expect(AppearanceStore(defaults: defaults, photos: photos).settings == store.settings)
        let properties = try #require(PhotoFixtures.properties(of: Data(contentsOf: photos.url(for: fileName))))
        #expect(properties.height == 1_500)
        #expect(abs(properties.width - 692) <= 1)
        #expect(store.rendering(isPlusUnlocked: true, oshiID: Fixture.minatoID).backgroundPhoto?.fileName == fileName)
    }

    @Test("推しの写真を差し替える・外すと、その推しの前の写真だけを消し、共通の写真とほかの推しの写真は残す")
    func replaceAndRemoveKeepOthers() async throws {
        try await store.replaceBackgroundPhoto(photo, crop: crop)
        let common = try #require(store.settings.backgroundPhotoFileName)
        try await store.replaceBackgroundPhoto(photo, crop: crop, for: Fixture.luminaID)
        let lumina = try #require(store.settings.oshiBackgroundPhotoFileNames[Fixture.luminaID])
        try await store.replaceBackgroundPhoto(photo, crop: crop, for: Fixture.minatoID)
        let first = try #require(store.settings.oshiBackgroundPhotoFileNames[Fixture.minatoID])

        try await store.replaceBackgroundPhoto(photo, crop: crop, for: Fixture.minatoID)
        let second = try #require(store.settings.oshiBackgroundPhotoFileNames[Fixture.minatoID])
        #expect(first != second)
        #expect(try photoFiles() == [common, lumina, second])

        store.removeBackgroundPhoto(for: Fixture.minatoID)
        #expect(store.settings.oshiBackgroundPhotoFileNames == [Fixture.luminaID: lumina])
        #expect(store.settings.backgroundPhotoFileName == common)
        #expect(try photoFiles() == [common, lumina])
        #expect(AppearanceStore(defaults: defaults, photos: photos).settings == store.settings)

        // 共通の写真を外しても、推しの写真は残る
        store.removeBackgroundPhoto()
        #expect(try photoFiles() == [lumina])
        // 写真が無い推しの写真を外しても何もしない
        store.removeBackgroundPhoto(for: Fixture.minatoID)
        #expect(store.settings.oshiBackgroundPhotoFileNames == [Fixture.luminaID: lumina])
    }

    @Test("読めない写真を推しに選んだら、何も変えず、前の写真を残す")
    func brokenPhotoKeepsCurrent() async throws {
        try await store.replaceBackgroundPhoto(photo, crop: crop, for: Fixture.minatoID)
        let current = try #require(store.settings.oshiBackgroundPhotoFileNames[Fixture.minatoID])
        let replaced = try await store.replaceBackgroundPhoto(Data("broken".utf8), crop: crop, for: Fixture.minatoID)
        #expect(!replaced)
        #expect(store.settings.oshiBackgroundPhotoFileNames == [Fixture.minatoID: current])
        #expect(try photoFiles() == [current])
    }

    @Test("Plus でないときは標準の見た目にするが、推しの写真と設定は消さない")
    func lockedKeepsOshiBackground() async throws {
        try await store.replaceBackgroundPhoto(photo, crop: crop, for: Fixture.minatoID)
        let fileName = try #require(store.settings.oshiBackgroundPhotoFileNames[Fixture.minatoID])
        #expect(store.rendering(isPlusUnlocked: false, oshiID: Fixture.minatoID) == .standard)
        #expect(exists(fileName))
        #expect(store.rendering(isPlusUnlocked: true, oshiID: Fixture.minatoID).backgroundPhoto?.isOshiBackground == true)
    }

    @Test("推しを削除すると、その推しの背景の写真と設定を消し、共通の写真とほかの推しの写真は残す")
    func deletingOshiRemovesItsBackground() async throws {
        let container = try OshiConStore.makeContainer(.inMemory)
        let oshiStore = OshiConStore(context: container.mainContext)
        let oshiPhotos = OshiPhotoLibrary(directory: PhotoFixtures.temporaryDirectory())
        let editing = OshiEditing(store: oshiStore, photos: oshiPhotos, appearance: store)
        let now = DomainFixtures.date(2026, 10, 18)
        let minato = try #require(try await editing.save(current: nil, name: "ミナト", color: .navy, photoChange: .keep, now: now))
        let lumina = try #require(try await editing.save(current: nil, name: "LUMINA", color: .pink, photoChange: .keep, now: now))

        try await store.replaceBackgroundPhoto(photo, crop: crop)
        let common = try #require(store.settings.backgroundPhotoFileName)
        try await store.replaceBackgroundPhoto(photo, crop: crop, for: minato.id)
        let minatoBackground = try #require(store.settings.oshiBackgroundPhotoFileNames[minato.id])
        try await store.replaceBackgroundPhoto(photo, crop: crop, for: lumina.id)
        let luminaBackground = try #require(store.settings.oshiBackgroundPhotoFileNames[lumina.id])

        try editing.delete(oshiID: minato.id)
        #expect(!exists(minatoBackground))
        #expect(store.settings.oshiBackgroundPhotoFileNames == [lumina.id: luminaBackground])
        #expect(store.settings.backgroundPhotoFileName == common)
        #expect(try photoFiles() == [common, luminaBackground])
        #expect(AppearanceStore(defaults: defaults, photos: photos).settings == store.settings)
    }

    @Test("推しの削除に失敗したら、その推しの背景の写真を消さない")
    func failedDeletionKeepsBackground() async throws {
        try await store.replaceBackgroundPhoto(photo, crop: crop, for: Fixture.minatoID)
        let fileName = try #require(store.settings.oshiBackgroundPhotoFileNames[Fixture.minatoID])
        let editing = OshiEditing(store: FailingDeletionStore(), photos: photos, appearance: store)
        #expect(throws: FailingDeletionStore.Failure.self) {
            try editing.delete(oshiID: Fixture.minatoID)
        }
        #expect(exists(fileName))
        #expect(store.settings.oshiBackgroundPhotoFileNames == [Fixture.minatoID: fileName])
    }

    @Test("メモリ上のストアは、次に起動したときに推しの写真も空から始める")
    func volatileStoreStartsEmpty() async throws {
        let suiteName = "AppearanceOshiBackgroundTests.\(UUID().uuidString)"
        let directory = PhotoFixtures.temporaryDirectory()
        let first = AppearanceStore.volatile(suiteName: suiteName, directory: directory)
        try await first.replaceBackgroundPhoto(photo, crop: crop, for: Fixture.minatoID)
        let fileName = try #require(first.settings.oshiBackgroundPhotoFileNames[Fixture.minatoID])

        let second = AppearanceStore.volatile(suiteName: suiteName, directory: directory)
        #expect(second.settings == AppearanceSettings())
        #expect(!FileManager.default.fileExists(atPath: directory.appending(path: fileName).path(percentEncoded: false)))
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }
}

/// 推しごとの背景の写真の、試着（着せ替えの画面の見本と全画面の試着）。
struct AppearanceOshiBackgroundPreviewTests {
    private typealias Fixture = OshiBackgroundFixtures

    private let today = DomainFixtures.day(2026, 10, 18)
    private let now = DomainFixtures.date(2026, 10, 18, 9, 41)
    private let minato = Oshi(id: OshiBackgroundFixtures.minatoID, name: "ミナト", color: .navy)
    private let lumina = Oshi(id: OshiBackgroundFixtures.luminaID, name: "LUMINA", color: .pink)
    private let settings = AppearanceSettings(
        backgroundPhotoFileName: OshiBackgroundFixtures.common,
        oshiBackgroundPhotoFileNames: [OshiBackgroundFixtures.minatoID: OshiBackgroundFixtures.minato]
    )

    private func event(_ title: String, of oshi: Oshi?, inDays days: Int, isPinned: Bool = false) -> OshiEvent {
        var event = DomainFixtures.event(title: title, day: today.adding(days: days), isPinned: isPinned)
        event.oshiID = oshi?.id
        return event
    }

    @Test("推しを選ぶと、ホームの見本をその推しで絞り込み、予定の詳細とシェアのカードにその推しの予定を出す")
    func selectedOshiFiltersPreview() {
        let events = [event("LUMINA LIVE", of: lumina, inDays: 2), event("ミナトの誕生日", of: minato, inDays: 5)]
        let content = AppearancePreview.content(
            events: events,
            oshis: [lumina, minato],
            selectedOshiID: minato.id,
            today: today,
            now: now,
            locale: DomainFixtures.japanese
        )
        #expect(content.selectedOshiID == minato.id)
        #expect(content.featured?.event.title == "ミナトの誕生日")
        #expect(AppearancePreview.featuredItem(of: content)?.oshi == minato)
    }

    @Test("選んだ推しに予定が無ければ、見本の先頭の予定をその推しの予定として出す")
    func selectedOshiWithoutEventsUsesSampleEvent() {
        let content = AppearancePreview.content(
            events: [event("LUMINA LIVE", of: lumina, inDays: 2)],
            oshis: [lumina, minato],
            selectedOshiID: minato.id,
            today: today,
            now: now,
            locale: DomainFixtures.japanese
        )
        #expect(content.selectedOshiID == minato.id)
        #expect(content.oshis == [lumina, minato])
        #expect(content.featured?.event.title == "ドームツアー 東京公演")
        #expect(content.featured?.oshi == minato)
        #expect(content.emptyState == nil)
    }

    @Test("推しを選んでいない（共通）・いない推しを選んでいるときは、今までどおり絞り込まない", arguments: [nil, UUID()])
    func commonDoesNotFilter(selectedOshiID: UUID?) {
        let events = [event("LUMINA LIVE", of: lumina, inDays: 2), event("ミナトの誕生日", of: minato, inDays: 5)]
        let content = AppearancePreview.content(
            events: events,
            oshis: [lumina, minato],
            selectedOshiID: selectedOshiID,
            today: today,
            now: now,
            locale: DomainFixtures.japanese
        )
        #expect(content.selectedOshiID == nil)
        #expect(content.featured?.event.title == "LUMINA LIVE")
    }

    @Test("見本の推しは、ホームでは絞り込んでいる推し、予定の詳細とシェアのカードでは出す予定の推し")
    func backgroundOshiPerKind() {
        let events = [event("LUMINA LIVE", of: lumina, inDays: 2), event("ミナトの誕生日", of: minato, inDays: 5)]
        let all = AppearancePreview.content(events: events, oshis: [lumina, minato], today: today, now: now)
        #expect(AppearancePreview.backgroundOshiID(of: .home, content: all) == nil)
        #expect(AppearancePreview.backgroundOshiID(of: .eventDetail, content: all) == lumina.id)
        #expect(AppearancePreview.backgroundOshiID(of: .share, content: all) == lumina.id)

        let filtered = AppearancePreview.content(events: events, oshis: [lumina, minato], selectedOshiID: minato.id, today: today, now: now)
        for kind in AppearancePreview.Kind.allCases {
            #expect(AppearancePreview.backgroundOshiID(of: kind, content: filtered) == minato.id)
        }

        // 推しなしの予定の詳細は推しを決めない
        let unassigned = AppearancePreview.content(events: [event("遠征の宿", of: nil, inDays: 1)], oshis: [lumina], today: today, now: now)
        #expect(AppearancePreview.backgroundOshiID(of: .eventDetail, content: unassigned) == nil)
    }

    @Test("見本も実際の画面と同じ規則で背景の写真を選ぶ（Plus によらず）")
    func previewUsesSameRule() {
        let events = [event("LUMINA LIVE", of: lumina, inDays: 2), event("ミナトの誕生日", of: minato, inDays: 5)]
        let all = AppearancePreview.content(events: events, oshis: [lumina, minato], today: today, now: now)
        let fileName = { (kind: AppearancePreview.Kind, content: HomeContent) in
            AppearancePreview.rendering(settings: settings, kind: kind, content: content).backgroundPhoto?.fileName
        }
        // すべてのホームと、LUMINA（写真なし）の予定は共通の写真
        #expect(fileName(.home, all) == Fixture.common)
        #expect(fileName(.eventDetail, all) == Fixture.common)

        let filtered = AppearancePreview.content(events: events, oshis: [lumina, minato], selectedOshiID: minato.id, today: today, now: now)
        for kind in AppearancePreview.Kind.allCases {
            #expect(fileName(kind, filtered) == Fixture.minato)
        }
        #expect(AppearancePreview.rendering(settings: settings, kind: .home, content: filtered, isComparing: true).isStandard)
    }

    @Test("見本の読み上げの値は、推しの写真を敷いているとき「推しの背景の写真あり」にする（シェアのカードも）")
    func accessibilityValue() {
        let oshi = AppearanceRendering(settings: settings, isPlusUnlocked: true, oshiID: minato.id)
        let common = AppearanceRendering(settings: settings, isPlusUnlocked: true, oshiID: nil)
        let japanese = DomainFixtures.japanese
        #expect(AppearancePreview.accessibilityValue(of: oshi, kind: .home, locale: japanese).hasPrefix("推しの背景の写真あり、暗幕の濃さ 50%"))
        #expect(AppearancePreview.accessibilityValue(of: oshi, kind: .share, locale: japanese) == "推しの背景の写真あり")
        #expect(AppearancePreview.accessibilityValue(of: common, kind: .share, locale: japanese) == "背景の写真あり")
        #expect(AppearancePreview.accessibilityValue(of: oshi, kind: .share, locale: DomainFixtures.english) == "Oshi background photo on")
    }

    @Test("全画面の試着の読み上げの値も、見本の中身の推しで決める。長押ししている間は「着せ替える前」")
    func tryOnAccessibilityValue() {
        let events = [event("ミナトの誕生日", of: minato, inDays: 5)]
        let filtered = AppearancePreview.content(events: events, oshis: [lumina, minato], selectedOshiID: minato.id, today: today, now: now)
        let japanese = DomainFixtures.japanese
        #expect(
            AppearancePreview.tryOnAccessibilityValue(of: settings, kind: .share, content: filtered, isComparing: false, locale: japanese)
                == "推しの背景の写真あり"
        )
        #expect(
            AppearancePreview.tryOnAccessibilityValue(of: settings, kind: .home, content: filtered, isComparing: true, locale: japanese)
                == "着せ替える前"
        )
    }
}

/// 推しごとの背景の写真を、見本の推しの写真で入れておく起動引数。
struct SampleOshiBackgroundOptionTests {
    @Test("-sampleOshiBackground の後の役どころを読む。見本を入れないとき・知らない役どころは nil")
    func sampleOshiBackground() {
        let role = { (arguments: [String], seeds: Bool) in
            LaunchOptions.sampleOshiBackground(arguments: arguments, seedsSampleData: seeds)
        }
        #expect(role(["-sampleOshiBackground", "voice-actor"], true) == .voiceActor)
        #expect(role(["-sampleOshiBackground", "voice-actor"], false) == nil)
        #expect(role(["-sampleOshiBackground", "unknown"], true) == nil)
        #expect(role(["-sampleOshiBackground"], true) == nil)
        #expect(role([], true) == nil)
    }
}
