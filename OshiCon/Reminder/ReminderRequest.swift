//
//  ReminderRequest.swift
//  OshiCon
//

import Foundation
import UserNotifications

extension ReminderSettings {
    /// UserDefaults（設定画面の `@AppStorage`）から読む。書いていない項目は既定の値。
    nonisolated init(defaults: UserDefaults) {
        let minutes = defaults.object(forKey: AppStorageKey.reminderMinutes) as? Int
        let timeOfDay = minutes.flatMap(TimeOfDay.init(minutesSinceMidnight:)) ?? Self.defaultTimeOfDay
        self.init(
            isEnabled: defaults.object(forKey: AppStorageKey.remindersEnabled) as? Bool ?? true,
            timings: Set(ReminderTiming.allCases.filter { defaults.object(forKey: AppStorageKey.reminderTiming($0)) as? Bool ?? true }),
            timeOfDay: timeOfDay
        )
    }
}

extension TimeOfDay {
    /// 0:00 からの分から作る。0〜1439 の外なら nil。
    nonisolated init?(minutesSinceMidnight minutes: Int) {
        guard (0..<1_440).contains(minutes) else {
            return nil
        }
        self.init(hour: minutes / 60, minute: minutes % 60)
    }
}

/// 予約する通知の識別子・文面・出す日時を、`UNNotificationRequest` にする。
nonisolated enum ReminderRequest {
    /// このアプリが予約した予定の通知の識別子の頭（`PlannedReminder.identifier`）。予約し直すときに、ほかの通知と分ける。
    static let identifierPrefix = "reminder."
    /// 押したときに開く画面のリンク（`WidgetLink` の URL）を入れるキー。
    static let linkKey = "link"

    static func make(_ reminder: PlannedReminder, content text: ReminderContent) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = text.title
        content.subtitle = text.subtitle
        content.body = text.body
        content.sound = .default
        // 同じ予定の通知を通知センターでまとめる
        content.threadIdentifier = reminder.eventID.uuidString
        content.userInfo = [linkKey: WidgetLink.eventDetail(reminder.eventID).url.absoluteString]
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents(of: reminder), repeats: false)
        return UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
    }

    /// 出す日付と時刻。タイムゾーンを入れないので、端末のタイムゾーンを変えても、その土地の同じ日付・時刻に出す。
    /// 暦は西暦にする（端末の暦が仏暦・和暦などでも、年を西暦として読ませるため）。
    static func dateComponents(of reminder: PlannedReminder) -> DateComponents {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: reminder.fireDay.year,
            month: reminder.fireDay.month,
            day: reminder.fireDay.day,
            hour: reminder.fireTime.hour,
            minute: reminder.fireTime.minute
        )
    }

    /// 通知の中身に入れたリンク。知らない通知なら nil。
    static func link(from userInfo: [AnyHashable: Any]) -> WidgetLink? {
        guard let string = userInfo[linkKey] as? String, let url = URL(string: string) else {
            return nil
        }
        return WidgetLink(url: url)
    }
}
