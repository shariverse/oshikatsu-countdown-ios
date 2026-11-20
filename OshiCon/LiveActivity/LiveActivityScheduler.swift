//
//  LiveActivityScheduler.swift
//  OshiCon
//

import ActivityKit
import os
import SwiftData
import SwiftUI

/// 当日の開演までのライブアクティビティを、計画（`LiveActivityPlan`）のとおりに始める・予約する・終える。
///
/// - 時間帯に入っている予定は、すぐに始める（iOS 17・18 で始められるのは、アプリが前面にいるこのときだけ）
/// - iOS 26 以降は、これから時間帯が始まる予定を、始まる時刻に予約する（アプリを開いていなくても始まる）
/// - 計画に無くなったもの（削除した・時刻を変えた・時間帯を過ぎた予定）と、中身が変わったもの（タイトル・推しなど）は終える
///
/// 推し・予定の保存・削除、日付・時刻・タイムゾーンの変更、アプリが前面に来たときに置き直す。
/// UI テスト・スクリーンショット（メモリ上のストア）では何もしない。
final class LiveActivityScheduler {
    private static let logger = Logger(subsystem: "jp.shilokuma.OshiCon", category: "LiveActivityScheduler")

    private let container: ModelContainer
    private let isActive: Bool

    init(container: ModelContainer, isActive: Bool = !LaunchOptions.usesInMemoryStore) {
        self.container = container
        self.isActive = isActive
    }

    /// 計画を作り直し、出しているもの・予約したものを置き直す。
    func refresh() {
        guard isActive else {
            return
        }
        let store = OshiConStore(context: container.mainContext)
        let events: [OshiEvent]
        let oshis: [Oshi.ID: Oshi]
        do {
            events = try store.events()
            oshis = Dictionary(uniqueKeysWithValues: try store.oshis().map { ($0.id, $0) })
        } catch {
            Self.logger.error("予定を読めず、ライブアクティビティを置き直せなかった: \(error.localizedDescription, privacy: .public)")
            return
        }
        let now = Date.now
        let plan = LiveActivityPlan(events: events, now: now, calendar: .autoupdatingCurrent)
        let eventsByID = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })
        let attributes = { (window: LiveActivityWindow) -> EventActivityAttributes? in
            eventsByID[window.eventID].map { event in
                EventActivityAttributes(window: window, event: event, oshi: event.oshiID.flatMap { oshis[$0] })
            }
        }
        let current = plan.current.compactMap(attributes)
        let scheduled = plan.scheduled.compactMap(attributes)
        // ライブアクティビティを許可していなくても、終えることはできるので、置き直しは続ける
        let canStart = ActivityAuthorizationInfo().areActivitiesEnabled

        var existing = Set<EventActivityAttributes>()
        var unwanted = Set<String>()
        for activity in Activity<EventActivityAttributes>.activities where Self.isRunning(activity) {
            let wanted = current.contains(activity.attributes) || (Self.canSchedule && scheduled.contains(activity.attributes))
            if wanted {
                existing.insert(activity.attributes)
            } else {
                unwanted.insert(activity.id)
            }
        }
        if !unwanted.isEmpty {
            Task {
                await Self.end(activityIDs: unwanted)
            }
        }
        guard canStart else {
            return
        }
        for attributes in current where !existing.contains(attributes) {
            start(attributes)
        }
        if Self.canSchedule {
            for attributes in scheduled where !existing.contains(attributes) {
                schedule(attributes)
            }
        }
    }

    /// 始まる時刻に予約できる OS か（iOS 26 以降）。
    private static var canSchedule: Bool {
        if #available(iOS 26.0, *) {
            true
        } else {
            false
        }
    }

    /// 出している・予約しているもの（終えたものは、消えるまで一覧に残る）。
    private static func isRunning(_ activity: Activity<EventActivityAttributes>) -> Bool {
        switch activity.activityState {
        case .ended, .dismissed:
            false
        default:
            true
        }
    }

    /// `activityIDs` のライブアクティビティをすぐに終える（予約したものは取り消す）。
    /// `Activity` は Sendable ではないので、id だけを受け取り、ここで一覧から引き直す。
    nonisolated private static func end(activityIDs: Set<String>) async {
        for activity in Activity<EventActivityAttributes>.activities where activityIDs.contains(activity.id) {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// 開演を過ぎたら古くなる中身。古くなったら「今日は当日！」に切り替える。
    private static func content(for attributes: EventActivityAttributes) -> ActivityContent<EventActivityAttributes.ContentState> {
        ActivityContent(state: EventActivityAttributes.ContentState(), staleDate: attributes.startDate)
    }

    private func start(_ attributes: EventActivityAttributes) {
        do {
            _ = try Activity.request(attributes: attributes, content: Self.content(for: attributes), pushType: nil)
        } catch {
            Self.logger.error("ライブアクティビティを始められなかった: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func schedule(_ attributes: EventActivityAttributes) {
        guard #available(iOS 26.0, *) else {
            return
        }
        // 始まるときに出す知らせ。予定の名前と開始の時刻（`開演 17:00`）
        let alert = AlertConfiguration(
            title: LocalizedStringResource("\(attributes.title)"),
            body: LocalizedStringResource("\(attributes.startText)"),
            sound: .default
        )
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: Self.content(for: attributes),
                pushType: nil,
                style: .standard,
                alertConfiguration: alert,
                start: attributes.countdownBegin
            )
        } catch {
            Self.logger.error("ライブアクティビティを予約できなかった: \(error.localizedDescription, privacy: .public)")
        }
    }
}

/// ライブアクティビティを置き直す。推し・予定の保存・削除、端末の時刻・タイムゾーンの変更（ウィジェットを描き直すきっかけと同じ）と、
/// アプリが前面に来たとき（iOS 17・18 で時間帯に入った予定を始めるのは、このとき）に置き直す。
struct LiveActivityRefresher: ViewModifier {
    /// ストアを開けなかったときは nil（何もしない）。
    let scheduler: LiveActivityScheduler?

    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onReceive(WidgetRefreshTrigger.publisher) { _ in
                scheduler?.refresh()
            }
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .active {
                    scheduler?.refresh()
                }
            }
    }
}

extension View {
    /// 保存・削除と、端末の時刻・タイムゾーンの変更、アプリが前面に来たときに、当日のライブアクティビティを置き直す。
    func refreshesLiveActivities(_ scheduler: LiveActivityScheduler?) -> some View {
        modifier(LiveActivityRefresher(scheduler: scheduler))
    }
}
