//
//  OshiEditing.swift
//  OshiCon
//

import Foundation

/// 推しを保存するときの写真の扱い。
nonisolated enum PhotoChange: Sendable {
    /// 今の写真のまま。
    case keep
    /// 写真を外す。
    case remove
    /// 選んだ写真（PhotosPicker で読んだデータ）に差し替える。
    case replace(Data)
}

/// 推しを保存・削除する口。`OshiConStore` が満たす（テストでは失敗させる偽物に差し替える）。
protocol OshiStoring {
    func save(_ oshi: Oshi, now: Date) throws
    func deleteOshi(id: Oshi.ID) throws -> Oshi?
}

extension OshiConStore: OshiStoring {}

/// 推しの保存・削除と、写真の取り込み・削除をまとめて行う。
final class OshiEditing {
    let store: any OshiStoring
    let photos: OshiPhotoLibrary

    init(store: any OshiStoring, photos: OshiPhotoLibrary = .shared) {
        self.store = store
        self.photos = photos
    }

    /// 推しを保存する。写真を差し替えるときは新しい写真を取り込んでから保存し、使わなくなった写真を消す。
    /// 取り込みに失敗したときは今の写真のまま保存する。保存に失敗したときは取り込んだ写真を消して投げる。
    ///
    /// - Parameter current: 編集中の推し。新しく登録するときは nil。
    /// - Returns: 保存した推し。名前が空のときは保存せず nil。
    func save(current: Oshi?, name: String, color: OshiColor, photoChange: PhotoChange, now: Date) async throws -> Oshi? {
        let normalizedName = InputField.oshiName.normalized(name)
        guard !normalizedName.isEmpty else {
            return nil
        }
        let currentPhoto = current?.photoFileName
        var importedPhoto: String?
        if case let .replace(data) = photoChange {
            importedPhoto = try? await photos.importPhoto(data)
        }
        let photoFileName: String? = switch photoChange {
        case .keep:
            currentPhoto
        case .remove:
            nil
        case .replace:
            importedPhoto ?? currentPhoto
        }

        var oshi = current ?? Oshi(name: normalizedName, color: color)
        oshi.name = normalizedName
        oshi.color = color
        oshi.photoFileName = photoFileName
        do {
            try store.save(oshi, now: now)
        } catch {
            if let importedPhoto {
                photos.delete(fileName: importedPhoto)
            }
            throw error
        }
        if let currentPhoto, currentPhoto != photoFileName {
            photos.delete(fileName: currentPhoto)
        }
        return oshi
    }

    /// 推しを削除する。結び付いた予定と写真も消す。
    func delete(oshiID: Oshi.ID) throws {
        let deleted = try store.deleteOshi(id: oshiID)
        if let photoFileName = deleted?.photoFileName {
            photos.delete(fileName: photoFileName)
        }
    }
}
