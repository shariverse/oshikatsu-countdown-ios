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

    /// 推しの写真を選ぶボタンで、写真ライブラリ（`PhotosPicker`）の代わりにテスト用に生成した画像を選ぶ（UI テスト）。
    /// `PhotosPicker` は別プロセスの画面で UI テストから操作できないため。メモリ上のストアのときだけ効く。
    static let testPhotoArgument = "-useTestPhoto"

    static var usesTestPhoto: Bool {
        usesInMemoryStore && ProcessInfo.processInfo.arguments.contains(testPhotoArgument)
    }

    /// アプリが裏に回ったら、いちばん新しく登録した予定の通知を 2 秒後に出す（UI テストで、通知を押したときの動きを確かめる）。
    /// メモリ上のストアでは予定の通知を予約しないため。メモリ上のストアのときだけ効く。
    static let testReminderArgument = "-scheduleTestReminder"

    static var schedulesTestReminder: Bool {
        usesInMemoryStore && ProcessInfo.processInfo.arguments.contains(testReminderArgument)
    }

    /// 推し活カウントダウン Plus を使える状態で起動する（UI テスト・スクリーンショット）。
    /// メモリ上のストアでは StoreKit に問い合わせず、Plus は使えない状態に固定する（`PlusStore`）。この引数でそれを使える状態に替える。
    /// メモリ上のストアのときだけ効く。
    static let plusUnlockedArgument = "-plusUnlocked"

    /// 推し活カウントダウン Plus を使えない状態で起動する（UI テスト・スクリーンショット）。メモリ上のストアの既定と同じだが、
    /// テストの意図を書くために渡す。`-plusUnlocked` と一緒に渡したときは、こちらを優先する。
    static let plusLockedArgument = "-plusLocked"

    static var unlocksPlus: Bool {
        unlocksPlus(arguments: ProcessInfo.processInfo.arguments)
    }

    /// 起動引数から、メモリ上のストアで Plus を使える状態にするかを決める。
    static func unlocksPlus(arguments: [String]) -> Bool {
        arguments.contains(inMemoryStoreArgument)
            && arguments.contains(plusUnlockedArgument)
            && !arguments.contains(plusLockedArgument)
    }

    /// App Store 版として動かす（課金画面の入口を出さない。App Store 用スクリーンショットと UI テスト）。
    /// DEBUG のビルドでは入口を出すので、配るアプリと同じ画面にするときに渡す（`AppDistributionDetector.live`）。メモリ上のストアのときだけ効く。
    static let appStoreDistributionArgument = "-simulateAppStoreDistribution"

    static var simulatesAppStoreDistribution: Bool {
        usesInMemoryStore && ProcessInfo.processInfo.arguments.contains(appStoreDistributionArgument)
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
    /// 予定を通知する（既定は ON）。
    static let remindersEnabled = "remindersEnabled"
    /// 日付で決まる通知（N 日前・前日・当日）を出す時刻。0:00 からの分（既定は 9:00）。
    static let reminderMinutes = "reminderMinutes"
    /// 着せ替え: 背景の写真を地に敷く（既定は ON。`AppearanceSettings`）。
    static let appearanceBackgroundEnabled = "appearanceBackgroundEnabled"
    /// 着せ替え: 地の飾りを推しの丸い写真に替える（既定は OFF）。
    static let appearanceDecorationEnabled = "appearanceDecorationEnabled"
    /// 着せ替え: 背景の写真に掛ける暗幕とぼかしの強さ（`AppearanceIntensity` の rawValue。既定は medium）。
    static let appearanceIntensity = "appearanceIntensity"
    /// 着せ替え: 背景の写真のファイル名（`OshiPhotoLibrary` の中。選んでいなければ無い）。
    static let appearanceBackgroundPhoto = "appearanceBackgroundPhoto"
    /// 着せ替え: 飾りの濃さ（丸い写真の不透明度。`OshiPhotoDecorationStyle.opacityRange`。既定は 0.4）。
    static let appearanceDecorationOpacity = "appearanceDecorationOpacity"
    /// 着せ替え: 飾りの量（0〜1。`OshiPhotoDecorationLayout`。既定は 0.25）。
    static let appearanceDecorationAmount = "appearanceDecorationAmount"
    /// 着せ替え: 飾りに出さない推しの id（UUID の文字列の配列。既定は空で、すべての推しを出す）。
    static let appearanceDecorationExcludedOshis = "appearanceDecorationExcludedOshis"

    /// そのタイミングの通知を出す（既定は ON）。
    static func reminderTiming(_ timing: ReminderTiming) -> String {
        "reminderTiming.\(timing.rawValue)"
    }

    /// UI テストが初期値を渡せるキー。どれも Bool（`LaunchOptions.applyDefaultEnvironment()`）
    static let all = [hasCompletedOnboarding, showsPastEvents, remindersEnabled]
}
