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
    #if DEBUG
    /// テーマ案の見本（`-previewTheme`）。引数が無ければ nil（設定の「デバッグ」で選んだテーマ）。
    private let previewTheme: AppTheme?
    #endif

    init() {
        LaunchOptions.applyDefaultEnvironment()
        #if DEBUG
        let previewTheme = LaunchOptions.previewTheme()
        if previewTheme != nil {
            PreviewFonts.registerIfNeeded()
        }
        self.previewTheme = previewTheme
        #endif
        let location: OshiConStore.Location = LaunchOptions.usesInMemoryStore ? .inMemory : .appGroup
        container = Result { try OshiConStore.makeContainer(location) }
        if LaunchOptions.seedsSampleData, case let .success(container) = container {
            Self.seedSampleData(into: container)
        }
    }

    /// 見本の推しと予定を入れる（メモリ上のストアのときだけ呼ぶ）。名前と予定名は画面の言語（`-AppleLanguages` で変えられる）で選ぶ。
    /// 端末の言語ではなくアプリが選んだ言語（`Locale.app`）にし、文言と見本の言語をそろえる。
    private static func seedSampleData(into container: ModelContainer) {
        let now = Date.now
        let sample = SampleData.make(today: CalendarDay(now, calendar: .autoupdatingCurrent), now: now, locale: .app)
        SampleData.insert(sample, into: container.mainContext, now: now)
    }

    /// 起動引数で選んだテーマ（DEBUG のビルドだけ）。
    private var launchTheme: AppTheme? {
        #if DEBUG
        previewTheme
        #else
        nil
        #endif
    }

    var body: some Scene {
        WindowGroup {
            switch container {
            case let .success(container):
                RootView()
                    .environment(router)
                    .modelContainer(container)
                    .refreshesWidgets()
                    .debugTheme(override: launchTheme)
            case .failure:
                StoreUnavailableView()
            }
        }
    }
}
