//
//  Oshi.swift
//  OshiCon
//

import Foundation

/// 推し。予定はこの `id` で推しに結び付く。
nonisolated struct Oshi: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var color: OshiColor
    /// App Group のコンテナに取り込んだ写真のファイル名。写真が無ければ nil。
    var photoFileName: String?

    init(id: UUID = UUID(), name: String, color: OshiColor = .defaultColor, photoFileName: String? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.photoFileName = photoFileName
    }
}

/// 推し色（メンバーカラー）。実際の色の値は画面の側が持つ。並びは選ぶ画面に出す順。
nonisolated enum OshiColor: String, CaseIterable, Codable, Sendable {
    case pink
    case red
    case orange
    case yellow
    case green
    case mint
    case blue
    case navy
    case purple
    case lavender
    case brown
    case black

    static let defaultColor: Self = .pink
}
