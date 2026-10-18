//
//  LaunchOptions.swift
//  OshiCon
//

import Foundation

/// 起動引数で切り替える動き（UI テスト用）。
///
/// 初回の導線を飛ばすときは `-hasCompletedOnboarding YES` を渡す。導線を通すときなど、アプリの中で書き換わる設定は
/// 環境変数で初期値を渡す（`applyDefaultEnvironment()`）。
nonisolated enum LaunchOptions {
    /// メモリ上のストアで起動する（UI テストで、端末に残ったデータに左右されないようにする）。
    static let inMemoryStoreArgument = "-useInMemoryStore"

    static var usesInMemoryStore: Bool {
        ProcessInfo.processInfo.arguments.contains(inMemoryStoreArgument)
    }

    /// 見本の推しと予定を入れる（App Store 用スクリーンショット）。端末のデータを書き換えないよう、メモリ上のストアのときだけ効く。
    static let sampleDataArgument = "-seedSampleData"

    static var seedsSampleData: Bool {
        usesInMemoryStore && ProcessInfo.processInfo.arguments.contains(sampleDataArgument)
    }

    /// UI テストが環境変数で渡した設定の初期値の、名前の頭（`OSHICON_DEFAULT_hasCompletedOnboarding=NO` など）
    static let defaultEnvironmentPrefix = "OSHICON_DEFAULT_"

    /// UI テストが環境変数で渡した設定の初期値を UserDefaults に書く。メモリ上のストアのときだけ効く。
    ///
    /// 起動引数（`-hasCompletedOnboarding NO`）で渡すと引数のドメインが UserDefaults への書き込みより優先され、
    /// 導線を終えても NO のまま読まれてタブに切り替わらないため、書き換わる設定は環境変数で渡す。
    static func applyDefaultEnvironment(
        _ environment: [String: String] = ProcessInfo.processInfo.environment,
        to defaults: UserDefaults = .standard
    ) {
        guard usesInMemoryStore else {
            return
        }
        for key in AppStorageKey.all {
            if let value = environment[defaultEnvironmentPrefix + key] {
                defaults.set(value == "YES", forKey: key)
            }
        }
    }
}

/// `@AppStorage` に使うキー。値は UserDefaults（`PrivacyInfo.xcprivacy` の CA92.1）に置く。
nonisolated enum AppStorageKey {
    /// 初回の導線を終えた（「あとで」を含む）。保存されるまで、タブの代わりに導線を出す。
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    /// 終わった予定もホームに表示する（既定は OFF）。
    static let showsPastEvents = "showsPastEvents"

    /// UI テストが初期値を渡せるキー。どれも Bool（`LaunchOptions.applyDefaultEnvironment()`）
    static let all = [hasCompletedOnboarding, showsPastEvents]
}
