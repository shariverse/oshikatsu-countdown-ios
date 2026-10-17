//
//  LaunchOptions.swift
//  OshiCon
//

import Foundation

/// 起動引数で切り替える動き（UI テスト用）。
///
/// 初回の導線を飛ばすときは `-hasCompletedOnboarding YES` を渡す（`@AppStorage` は起動引数の値を読む）。
nonisolated enum LaunchOptions {
    /// メモリ上のストアで起動する（UI テストで、端末に残ったデータに左右されないようにする）。
    static let inMemoryStoreArgument = "-useInMemoryStore"

    static var usesInMemoryStore: Bool {
        ProcessInfo.processInfo.arguments.contains(inMemoryStoreArgument)
    }
}

/// `@AppStorage` に使うキー。値は UserDefaults（`PrivacyInfo.xcprivacy` の CA92.1）に置く。
nonisolated enum AppStorageKey {
    /// 初回の導線を終えた（「あとで」を含む）。保存されるまで、タブの代わりに導線を出す。
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    /// 終わった予定もホームに表示する（既定は OFF）。
    static let showsPastEvents = "showsPastEvents"
}
