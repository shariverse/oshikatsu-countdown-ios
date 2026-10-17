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
        let location: OshiConStore.Location = LaunchOptions.usesInMemoryStore ? .inMemory : .appGroup
        container = Result { try OshiConStore.makeContainer(location) }
    }

    var body: some Scene {
        WindowGroup {
            switch container {
            case let .success(container):
                RootView()
                    .environment(router)
                    .modelContainer(container)
            case .failure:
                StoreUnavailableView()
            }
        }
    }
}
