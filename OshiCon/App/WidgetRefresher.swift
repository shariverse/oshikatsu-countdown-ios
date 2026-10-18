//
//  WidgetRefresher.swift
//  OshiCon
//

import SwiftData
import SwiftUI
import UIKit
import WidgetKit

/// ホーム画面ウィジェットを描き直す。アプリで推し・予定を保存・削除したとき（SwiftData の保存）と、
/// 端末の時刻・タイムゾーンが変わったときに描き直す（ウィジェットの 0:00 のエントリは作った時点のタイムゾーンで決まるため）。
struct WidgetRefresher: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in
                reload()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                reload()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
                reload()
            }
    }

    private func reload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension View {
    /// 保存・削除と、端末の時刻・タイムゾーンの変更で、ホーム画面ウィジェットを描き直す。
    func refreshesWidgets() -> some View {
        modifier(WidgetRefresher())
    }
}
