//
//  ReminderSettingsSection.swift
//  OshiCon
//

import SwiftUI
import UserNotifications

/// 設定の「通知」。予定を通知するか・タイミングごとの切り替え・日付で決まる通知の時刻と、許可の案内。
/// 値は UserDefaults に置き（予定ごとには持たない）、変えたら予約し直す。
struct ReminderSettingsSection: View {
    @AppStorage(AppStorageKey.remindersEnabled) private var isEnabled = true
    @AppStorage(AppStorageKey.reminderMinutes) private var minutes = ReminderSettings.defaultTimeOfDay.minutesSinceMidnight
    @Environment(ReminderScheduler.self) private var reminders: ReminderScheduler?
    @Environment(\.appTheme) private var theme
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Section {
            Toggle("予定を通知する", isOn: $isEnabled)
                .accessibilityIdentifier("settings.reminders")
            if isEnabled {
                ForEach(ReminderTiming.allCases, id: \.self) { timing in
                    ReminderTimingToggle(timing: timing)
                }
                DatePicker("通知の時刻", selection: time, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("通知")
        } footer: {
            if isEnabled {
                footer
            }
        }
        .themeRowBackground()
        .onChange(of: isEnabled) { _, isEnabled in
            if isEnabled {
                reminders?.requestAuthorizationIfNeeded()
            }
            reminders?.reschedule()
        }
        .onChange(of: minutes) {
            reminders?.reschedule()
        }
        .task(id: scenePhase) {
            // iOS の設定で許可を変えて戻ってきたときも、案内を出し直す
            if scenePhase == .active {
                await reminders?.refreshAuthorizationStatus()
            }
        }
    }

    @ViewBuilder private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("30 日前・7 日前・前日・当日の通知は、この時刻に出します。開演 1 時間前の通知は、開始の時刻がある予定だけに出します。")
            switch reminders?.authorizationStatus {
            case .denied:
                Text("通知が許可されていません。iOS の設定で、このアプリの通知を許可してください。")
                Button("設定を開く", action: openNotificationSettings)
                    .font(theme.typography.text(.footnote, weight: .bold))
            case .notDetermined:
                Button("通知を許可する") {
                    reminders?.requestAuthorizationIfNeeded()
                }
                .font(theme.typography.text(.footnote, weight: .bold))
            default:
                EmptyView()
            }
        }
        .font(theme.typography.text(.footnote))
    }

    /// 時刻の選択。日付は使わないので、今日のその時刻として渡す。
    private var time: Binding<Date> {
        Binding {
            let timeOfDay = TimeOfDay(minutesSinceMidnight: minutes) ?? ReminderSettings.defaultTimeOfDay
            return Calendar.autoupdatingCurrent.date(
                bySettingHour: timeOfDay.hour,
                minute: timeOfDay.minute,
                second: 0,
                of: .now
            ) ?? .now
        } set: { date in
            let components = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: date)
            minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        }
    }

    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            return
        }
        openURL(url)
    }
}

/// 1 つのタイミングの切り替え。
private struct ReminderTimingToggle: View {
    let timing: ReminderTiming

    @AppStorage private var isOn: Bool
    @Environment(ReminderScheduler.self) private var reminders: ReminderScheduler?

    init(timing: ReminderTiming) {
        self.timing = timing
        _isOn = AppStorage(wrappedValue: true, AppStorageKey.reminderTiming(timing))
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(timing.settingLabel)
        }
        .accessibilityIdentifier("settings.reminderTiming.\(timing.rawValue)")
        .onChange(of: isOn) {
            reminders?.reschedule()
        }
    }
}

extension ReminderTiming {
    /// 設定の画面のタイミングの名前。
    var settingLabel: LocalizedStringKey {
        switch self {
        case .thirtyDaysBefore:
            "30 日前"
        case .sevenDaysBefore:
            "7 日前"
        case .dayBefore:
            "前日"
        case .onTheDay:
            "当日"
        case .hourBeforeStart:
            "開演 1 時間前"
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            ReminderSettingsSection()
        }
    }
}
