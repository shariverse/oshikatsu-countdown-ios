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

    init() {
        LaunchOptions.applyDefaultEnvironment()
        let location: OshiConStore.Location = LaunchOptions.usesInMemoryStore ? .inMemory : .appGroup
        container = Result { try OshiConStore.makeContainer(location) }
        if LaunchOptions.seedsSampleData, case let .success(container) = container {
            Self.seedSampleData(into: container)
        }
    }

    /// 見本の推しと予定を入れる（メモリ上のストアのときだけ呼ぶ）。名前と予定名は端末の言語（`-AppleLanguages` で変えられる）で選ぶ。
    private static func seedSampleData(into container: ModelContainer) {
        let now = Date.now
        let language = Locale(identifier: Locale.preferredLanguages.first ?? "en")
        let sample = SampleData.make(today: CalendarDay(now, calendar: .autoupdatingCurrent), now: now, locale: language)
        let store = OshiConStore(context: container.mainContext)
        for (index, oshi) in sample.oshis.enumerated() {
            // 登録した順に並ぶよう、1 秒ずつずらす
            try? store.save(oshi, now: now.addingTimeInterval(Double(index - sample.oshis.count)))
        }
        for event in sample.events {
            try? store.save(event)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch container {
            case let .success(container):
                RootView()
                    .environment(router)
                    .modelContainer(container)
                    .refreshesWidgets()
            case .failure:
                StoreUnavailableView()
            }
        }
    }
}
