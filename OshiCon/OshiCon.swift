//
//  OshiCon.swift
//  OshiCon
//
//  Created by 村石 拓海 on 2024/05/12.
//

import SwiftData
import SwiftUI

@main
struct OshiCon: App {
    @State private var router = AppRouter()
    /// SwiftData のストア。開けなかったときはその旨の画面を出す。
    private let container: Result<ModelContainer, any Error>
    /// 予定の通知。押して起動したときの通知を受け取れるよう、起動の途中で作って delegate にする。ストアを開けなかったときは nil。
    private let reminders: ReminderScheduler?
    /// 当日の開演までのライブアクティビティ。ストアを開けなかったときは nil。
    private let liveActivities: LiveActivityScheduler?
    /// Plus の購入の状態。取引の変化（`Transaction.updates`）を取りこぼさないよう、起動の途中で作って監視を始める。
    private let plus: PlusStore
    /// Plus の着せ替えの設定と背景の写真。画面は `@Environment(AppearanceStore.self)` で引く。
    private let appearance: AppearanceStore

    init() {
        LaunchOptions.applyDefaultEnvironment()
        NavigationBarAppearance.applyTitleFonts()
        plus = PlusStore()
        appearance = AppearanceStore.forLaunch()
        let location: OshiConStore.Location = LaunchOptions.usesInMemoryStore ? .inMemory : .appGroup
        container = Result { try OshiConStore.makeContainer(location) }
        if LaunchOptions.seedsSampleData, case let .success(container) = container {
            Self.seedSampleData(into: container)
        }
        reminders = (try? container.get()).map { ReminderScheduler(container: $0) }
        liveActivities = (try? container.get()).map { LiveActivityScheduler(container: $0) }
    }

    /// 見本の推しと予定を入れる（メモリ上のストアのときだけ呼ぶ）。名前と予定名は画面の言語（`-AppleLanguages` で変えられる）で選ぶ。
    /// 端末の言語ではなくアプリが選んだ言語（`Locale.app`）にし、文言と見本の言語をそろえる。
    /// App Store 用スクリーンショットでは、UI テストから渡された写真を見本の推しに付ける（`LaunchOptions.sampleOshiPhotosDirectory`）。
    private static func seedSampleData(into container: ModelContainer) {
        let now = Date.now
        var sample = SampleData.make(today: CalendarDay(now, calendar: .autoupdatingCurrent), now: now, locale: .app)
        if let directory = LaunchOptions.sampleOshiPhotosDirectory {
            sample = SampleData.attachingPhotos(to: sample, from: directory, library: .shared)
        }
        SampleData.insert(sample, into: container.mainContext, now: now)
    }

    var body: some Scene {
        WindowGroup {
            switch container {
            case let .success(container):
                RootView()
                    .environment(router)
                    .modelContainer(container)
                    .refreshesWidgets()
                    .refreshesReminders(reminders)
                    .refreshesLiveActivities(liveActivities)
                    .providesPlusStatus(plus)
                    .environment(appearance)
            case .failure:
                StoreUnavailableView()
            }
        }
    }
}
