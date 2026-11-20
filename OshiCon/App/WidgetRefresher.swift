//
//  WidgetRefresher.swift
//  OshiCon
//

import Combine
import SwiftData
import SwiftUI
import UIKit
import WidgetKit

/// ホーム画面ウィジェットを描き直すきっかけ。予定の通知とライブアクティビティを置き直すきっかけも同じ。
nonisolated enum WidgetRefreshTrigger: CaseIterable, Sendable {
    /// 推し・予定の保存・削除（SwiftData の保存）。
    case save
    /// 端末の時刻の大きな変化（日付が変わった・時刻を変えた）。
    case significantTimeChange
    /// 端末のタイムゾーンの変更。
    case timeZoneChange

    /// きっかけを知らせる通知。
    var notificationName: Notification.Name {
        switch self {
        case .save:
            ModelContext.didSave
        case .significantTimeChange:
            UIApplication.significantTimeChangeNotification
        case .timeZoneChange:
            .NSSystemTimeZoneDidChange
        }
    }

    /// どのきっかけの通知も、メインで受け取る（通知を出すスレッドは決まっていないため）。
    static var publisher: AnyPublisher<Notification, Never> {
        Publishers.MergeMany(allCases.map { NotificationCenter.default.publisher(for: $0.notificationName) })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

/// ホーム画面ウィジェットを描き直す。アプリで推し・予定を保存・削除したとき、端末の時刻・タイムゾーンが変わったとき、
/// アプリが前面に来たときに描き直す（ウィジェットの 0:00 のエントリと「今日」は作った時点のタイムゾーンで決まり、
/// アプリが動いていない間に時刻・タイムゾーンを変えたときは通知が届かないため）。前面にいる間の描き直しは WidgetKit の回数の枠を使わない。
struct WidgetRefresher: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onReceive(WidgetRefreshTrigger.publisher) { _ in
                reload()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    reload()
                }
            }
    }

    private func reload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension View {
    /// 保存・削除と、端末の時刻・タイムゾーンの変更、アプリが前面に来たときに、ホーム画面ウィジェットを描き直す。
    func refreshesWidgets() -> some View {
        modifier(WidgetRefresher())
    }
}
