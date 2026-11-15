//
//  ReminderScheduler.swift
//  OshiCon
//

import Observation
import os
import SwiftData
import SwiftUI
import UserNotifications

/// 予定の通知の予約と許可。押された通知のリンクも受け取る（`UNUserNotificationCenter` の delegate）。
///
/// 予約は計画（`ReminderPlan`）のとおりに置き換える。近い順に 64 件までしか予約できないので、
/// 推し・予定の保存・削除、日付・時刻・タイムゾーンの変更、アプリが前面に来たとき（出た通知のぶん空いた枠を埋める）、設定を変えたときに予約し直す。
/// UI テスト・スクリーンショット（メモリ上のストア）では、予約も許可も求めない（許可のダイアログでテストが止まり、Simulator に見本の通知が残るため）。
@Observable
final class ReminderScheduler: NSObject {
    private static let logger = Logger(subsystem: "jp.shilokuma.OshiCon", category: "ReminderScheduler")

    /// 通知の許可の状態。設定画面の案内に使う。
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    /// 押された通知が開く画面。受け取った画面が nil に戻す。
    var openedLink: WidgetLink?

    @ObservationIgnored private let container: ModelContainer
    @ObservationIgnored private let isActive: Bool
    @ObservationIgnored private var rescheduling: Task<Void, Never>?

    init(container: ModelContainer, isActive: Bool = !LaunchOptions.usesInMemoryStore) {
        self.container = container
        self.isActive = isActive
        super.init()
        if isActive {
            // 押して起動したときの通知を受け取れるよう、起動の途中で delegate にする
            UNUserNotificationCenter.current().delegate = self
        }
    }

    /// 計画を作り直し、予約を置き換える。続けて呼ばれたら、前の置き換えを取りやめ、それが止まってから置き換える
    /// （前の置き換えが予約を足している途中に次の置き換えが今の予約を読むと、消した予定の予約が残るため）。
    func reschedule() {
        guard isActive else {
            return
        }
        let store = OshiConStore(context: container.mainContext)
        let events: [OshiEvent]
        let oshiNames: [Oshi.ID: String]
        do {
            events = try store.events()
            oshiNames = Dictionary(uniqueKeysWithValues: try store.oshis().map { ($0.id, $0.name) })
        } catch {
            Self.logger.error("予定を読めず、通知を予約し直せなかった: \(error.localizedDescription, privacy: .public)")
            return
        }
        let settings = ReminderSettings(defaults: .standard)
        let previous = rescheduling
        previous?.cancel()
        rescheduling = Task {
            await previous?.value
            await replaceRequests(events: events, oshiNames: oshiNames, settings: settings)
        }
    }

    /// まだ許可を聞いていなければ聞く（予定を保存した直後と、設定で通知を ON にしたとき）。通知が OFF なら聞かない。
    func requestAuthorizationIfNeeded() {
        guard isActive, ReminderSettings(defaults: .standard).isEnabled else {
            return
        }
        Task {
            let center = UNUserNotificationCenter.current()
            guard await center.notificationSettings().authorizationStatus == .notDetermined else {
                return
            }
            do {
                _ = try await center.requestAuthorization(options: [.alert, .sound])
            } catch {
                Self.logger.error("通知の許可を求められなかった: \(error.localizedDescription, privacy: .public)")
            }
            await refreshAuthorizationStatus()
            reschedule()
        }
    }

    /// 許可の状態を読み直す（設定画面を開いたとき・iOS の設定から戻ったとき）。
    func refreshAuthorizationStatus() async {
        guard isActive else {
            return
        }
        authorizationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private func replaceRequests(events: [OshiEvent], oshiNames: [Oshi.ID: String], settings: ReminderSettings) async {
        let center = UNUserNotificationCenter.current()
        authorizationStatus = await center.notificationSettings().authorizationStatus
        let pending = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(ReminderRequest.identifierPrefix) }
        guard !Task.isCancelled else {
            return
        }
        // 許可されていなければ何も出せないので、残っている予約を消す
        let isAllowed = [.authorized, .provisional, .ephemeral].contains(authorizationStatus)
        let plan = isAllowed
            ? ReminderPlan(events: events, settings: settings, now: .now, calendar: .autoupdatingCurrent).reminders
            : []
        let eventsByID = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })
        let requests = plan.compactMap { reminder -> UNNotificationRequest? in
            guard let event = eventsByID[reminder.eventID] else {
                return nil
            }
            let content = ReminderContent(reminder: reminder, event: event, oshiName: event.oshiID.flatMap { oshiNames[$0] })
            return ReminderRequest.make(reminder, content: content)
        }
        let planned = Set(requests.map(\.identifier))
        center.removePendingNotificationRequests(withIdentifiers: pending.filter { !planned.contains($0) })
        // 同じ識別子で足すと、文面と日時が置き換わる。取りやめたら、残りは次の置き換えに任せる
        for request in requests where !Task.isCancelled {
            do {
                try await center.add(request)
            } catch {
                Self.logger.error("通知を予約できなかった: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

/// delegate のメソッドは MainActor で動かす。iOS は完了ハンドラ付きのメソッドとして呼び、Swift が作る橋渡しが、
/// async のメソッドが終わったスレッドで iOS の完了ハンドラを呼ぶ。`nonisolated` にするとメインではないスレッドで呼ばれ、
/// 完了ハンドラの中の UIKit の処理（画面のスナップショットの更新）が assertion で落ちる（#186）。
extension ReminderScheduler: @MainActor UNUserNotificationCenterDelegate {
    /// アプリを開いている間に出た通知も、バナーで出す。
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    /// 押された通知の画面を開く（開くのは `RootView`。初回の導線の途中なら開かない）。
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let link = ReminderRequest.link(from: response.notification.request.content.userInfo) else {
            return
        }
        openedLink = link
    }
}

/// 予定の通知を予約し直す。推し・予定の保存・削除、端末の時刻・タイムゾーンの変更（ウィジェットを描き直すきっかけと同じ）と、
/// アプリが前面に来たときに予約し直す。
struct ReminderRefresher: ViewModifier {
    /// ストアを開けなかったときは nil（何もしない）。
    let scheduler: ReminderScheduler?

    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .environment(scheduler)
            .onReceive(WidgetRefreshTrigger.publisher) { _ in
                scheduler?.reschedule()
            }
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .active {
                    scheduler?.reschedule()
                }
            }
    }
}

extension View {
    /// 保存・削除と、端末の時刻・タイムゾーンの変更、アプリが前面に来たときに、予定の通知を予約し直す。
    /// `scheduler` は Environment にも入れる（設定画面と予定の入力画面が使う）。
    func refreshesReminders(_ scheduler: ReminderScheduler?) -> some View {
        modifier(ReminderRefresher(scheduler: scheduler))
    }
}
