//
//  LaunchOptions.swift
//  OshiCon
//

import Foundation

/// 起動引数で切り替える動き（UI テスト用）。
///
/// 初回の導線を飛ばすときは `-hasCompletedOnboarding YES` を渡す。起動引数の設定は初期値として UserDefaults に書き写す
/// （`applyUserDefaultsArguments()`）。
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

    /// 起動引数で渡した設定（`-hasCompletedOnboarding NO` など）を UserDefaults に書き写し、引数のドメインを外す。
    ///
    /// 引数のドメインは UserDefaults への書き込みより優先されるため、そのままだと導線を終えても
    /// `hasCompletedOnboarding` が NO のまま読まれ、タブに切り替わらない。UI テスト（メモリ上のストア）のときだけ行う。
    static func applyUserDefaultsArguments(to defaults: UserDefaults = .standard) {
        guard usesInMemoryStore else {
            return
        }
        let arguments = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
        // 引数の値は文字列（"NO"）なので、Bool に直して書く
        for key in AppStorageKey.all where arguments[key] != nil {
            defaults.set(defaults.bool(forKey: key), forKey: key)
        }
        defaults.removeVolatileDomain(forName: UserDefaults.argumentDomain)
    }
}

/// `@AppStorage` に使うキー。値は UserDefaults（`PrivacyInfo.xcprivacy` の CA92.1）に置く。
nonisolated enum AppStorageKey {
    /// 初回の導線を終えた（「あとで」を含む）。保存されるまで、タブの代わりに導線を出す。
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    /// 終わった予定もホームに表示する（既定は OFF）。
    static let showsPastEvents = "showsPastEvents"

    /// 起動引数で初期値を渡せるキー。どれも Bool（`LaunchOptions.applyUserDefaultsArguments()`）
    static let all = [hasCompletedOnboarding, showsPastEvents]
}
