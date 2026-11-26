//
//  AppearanceStore.swift
//  OshiCon
//

import Foundation
import Observation

/// 推し活カウントダウン Plus の着せ替えの設定（`AppearanceSettings`）と、背景の写真のファイルを持つ。
///
/// - 設定はアプリだけの UserDefaults に、背景の写真は `photos`（推しの写真と同じ置き場所）に置く
/// - 背景の写真を差し替える・外すときは、前のファイルを消す
/// - Plus が使えるかにかかわらず保存する（Plus でない人も試着で選んだ写真を残し、買ったらそのまま使う）。描くものは `rendering(isPlusUnlocked:)`
///
/// UI テスト・スクリーンショット（メモリ上のストア）では端末の設定を書き換えないよう、別の UserDefaults と一時ディレクトリを使い、
/// 起動するたびに空にする（`forLaunch()`）。
@Observable
final class AppearanceStore {
    /// メモリ上のストアのときに使う UserDefaults の名前。
    static let inMemorySuiteName = "jp.shilokuma.OshiCon.InMemoryAppearance"

    /// メモリ上のストアのときに、背景の写真を置く一時ディレクトリ。
    static var inMemoryPhotosDirectory: URL {
        FileManager.default.temporaryDirectory.appending(path: "InMemoryAppearancePhotos", directoryHint: .isDirectory)
    }

    private(set) var settings: AppearanceSettings

    /// 背景の写真の置き場所。背景の写真を読むときもここから読む。
    @ObservationIgnored let photos: OshiPhotoLibrary
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, photos: OshiPhotoLibrary = .shared) {
        self.defaults = defaults
        self.photos = photos
        settings = AppearanceSettings(defaults: defaults)
    }

    /// 起動するときの着せ替えの設定。メモリ上のストアのときは、端末の設定と写真の置き場所に触れず、空から始める。
    static func forLaunch(usesInMemoryStore: Bool = LaunchOptions.usesInMemoryStore) -> AppearanceStore {
        guard usesInMemoryStore else {
            return AppearanceStore()
        }
        return volatile(suiteName: inMemorySuiteName, directory: inMemoryPhotosDirectory)
    }

    /// `suiteName` の UserDefaults と `directory` を空にしてから使う。
    static func volatile(suiteName: String, directory: URL) -> AppearanceStore {
        let defaults = UserDefaults(suiteName: suiteName) ?? UserDefaults()
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: directory)
        return AppearanceStore(defaults: defaults, photos: OshiPhotoLibrary(directory: directory))
    }

    /// Plus が使えるかと設定から、実際に描くもの。
    func rendering(isPlusUnlocked: Bool) -> AppearanceRendering {
        AppearanceRendering(settings: settings, isPlusUnlocked: isPlusUnlocked)
    }

    /// 背景の写真を地に敷くか。
    var isBackgroundEnabled: Bool {
        get { settings.isBackgroundEnabled }
        set { update { $0.isBackgroundEnabled = newValue } }
    }

    /// 地の飾りを推しの丸い写真にするか。
    var isDecorationEnabled: Bool {
        get { settings.isDecorationEnabled }
        set { update { $0.isDecorationEnabled = newValue } }
    }

    /// 飾りの濃さ（丸い写真の不透明度）。範囲の外の値は範囲に収める。
    var decorationOpacity: Double {
        get { settings.decorationStyle.opacity }
        set { update { $0.decorationStyle.opacity = newValue } }
    }

    /// 飾りの量（0 は少なめ、1 は埋め尽くす）。範囲の外の値は範囲に収める。
    var decorationAmount: Double {
        get { settings.decorationStyle.amount }
        set { update { $0.decorationStyle.amount = newValue } }
    }

    /// 推し `oshiID` を飾りに出すかを切り替える。あわせて、もういない推し（`existingOshiIDs` に無い推し）の分を設定から外す。
    func setDecorationIncludes(_ oshiID: UUID, _ isIncluded: Bool, existingOshiIDs: Set<UUID>) {
        update { settings in
            var excluded = settings.decorationStyle.excludedOshiIDs.intersection(existingOshiIDs)
            if isIncluded {
                excluded.remove(oshiID)
            } else {
                excluded.insert(oshiID)
            }
            settings.decorationStyle.excludedOshiIDs = excluded
        }
    }

    /// 背景の写真に掛ける暗幕の濃さ（スライダーの位置）。範囲の外の値は範囲に収める。
    var backgroundScrim: Double {
        get { settings.backgroundStyle.scrim }
        set { update { $0.backgroundStyle.scrim = newValue } }
    }

    /// 背景の写真に掛けるぼかしの強さ（スライダーの位置）。範囲の外の値は範囲に収める。
    var backgroundBlur: Double {
        get { settings.backgroundStyle.blur }
        set { update { $0.backgroundStyle.blur = newValue } }
    }

    /// 背景の写真を、調整した範囲 `crop`（縦長の枠。`PhotoCrop.backgroundAspectRatio`）で切り抜いて取り込み、差し替える。
    /// 差し替えたら前の写真を消す。読めない写真なら何も変えずに false。
    @discardableResult
    func replaceBackgroundPhoto(_ data: Data, crop: PhotoCrop) async throws -> Bool {
        guard let fileName = try await photos.importPhoto(data, crop: crop, maxPixelLength: PhotoResizer.maxBackgroundPixelLength) else {
            return false
        }
        // 取り込みの間に別の写真に差し替わっていても、そのとき持っている写真を消す（使わないファイルを残さない）
        let previous = settings.backgroundPhotoFileName
        update { $0.backgroundPhotoFileName = fileName }
        if let previous, previous != fileName {
            photos.delete(fileName: previous)
        }
        return true
    }

    /// 背景の写真を外し、ファイルを消す。ほかの設定はそのまま。
    func removeBackgroundPhoto() {
        guard let previous = settings.backgroundPhotoFileName else {
            return
        }
        update { $0.backgroundPhotoFileName = nil }
        photos.delete(fileName: previous)
    }

    private func update(_ change: (inout AppearanceSettings) -> Void) {
        var changed = settings
        change(&changed)
        guard changed != settings else {
            return
        }
        settings = changed
        changed.write(to: defaults)
    }
}
