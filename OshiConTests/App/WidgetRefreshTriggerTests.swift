//
//  WidgetRefreshTriggerTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import SwiftData
import Testing
import UIKit

struct WidgetRefreshTriggerTests {
    @Test("ウィジェットは保存・時刻の大きな変化・タイムゾーンの変更で描き直す")
    func triggers() {
        #expect(WidgetRefreshTrigger.allCases.map(\.notificationName) == [
            ModelContext.didSave,
            UIApplication.significantTimeChangeNotification,
            .NSSystemTimeZoneDidChange
        ])
    }
}
