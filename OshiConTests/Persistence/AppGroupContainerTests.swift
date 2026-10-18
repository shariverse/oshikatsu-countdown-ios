//
//  AppGroupContainerTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct AppGroupContainerTests {
    @Test("App Group の ID は xcconfig の APP_GROUP_IDENTIFIER が Info.plist に入る")
    func identifier() {
        #expect(AppGroupContainer.identifier == "group.jp.shilokuma.OshiCon")
    }

    @Test("ストアはデータのディレクトリに置く")
    func storeURL() {
        #expect(AppGroupContainer.storeURL.lastPathComponent == "OshiCon.store")
        let directory = AppGroupContainer.storeURL.deletingLastPathComponent()
        #expect(directory.standardizedFileURL == AppGroupContainer.dataDirectory.standardizedFileURL)
    }
}
