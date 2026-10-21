//
//  OpenSourceLicense.swift
//  OshiCon
//

import Foundation

/// アプリに同梱しているオープンソースのソフトウェアと、そのライセンス。
/// 外部ライブラリは使っていないので、同梱している書体だけを載せる（SwiftLint はビルドにだけ使い、アプリには入らない）。
nonisolated struct OpenSourceLicense: Identifiable, Hashable, Sendable {
    let name: String
    let author: String
    let version: String
    let licenseName: String
    /// 同梱しているライセンスの本文のファイル名（拡張子 txt を除く）。
    let licenseFileName: String

    var id: String {
        name
    }

    /// 書体を足したら、ライセンスの本文と一緒にここへ足す。
    static let all: [Self] = [
        Self(
            name: "Outfit",
            author: "The Outfit Project Authors",
            version: "1.100",
            licenseName: "SIL Open Font License 1.1",
            licenseFileName: "Outfit-OFL"
        ),
        Self(
            name: "Zen Kaku Gothic New",
            author: "The Zen Kaku Gothic Project Authors",
            version: "1.002",
            licenseName: "SIL Open Font License 1.1",
            licenseFileName: "ZenKakuGothicNew-OFL"
        ),
        Self(
            name: "Kaisei Decol",
            author: "The Kaisei Project Authors",
            version: "5.003",
            licenseName: "SIL Open Font License 1.1",
            licenseFileName: "KaiseiDecol-OFL"
        )
    ]

    /// ライセンスの本文。見つからなければ nil。
    func licenseText(in bundle: Bundle = .main) -> String? {
        guard let url = bundle.url(forResource: licenseFileName, withExtension: "txt") else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}

/// 設定に出すアプリのバージョン。
nonisolated enum AppVersion {
    /// `CFBundleShortVersionString`（例: 1.0.0）。読めなければ空。
    static func displayText(infoDictionary: [String: Any]? = Bundle.main.infoDictionary) -> String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}
