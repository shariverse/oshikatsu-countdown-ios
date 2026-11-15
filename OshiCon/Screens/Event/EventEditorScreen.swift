//
//  EventEditorScreen.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// 予定の追加・編集のシート。推し・種類・タイトル・日付・開始時刻・会場・毎年くり返すを入れて保存する。
/// 保存に失敗したら知らせて入力を残す（もう一度押せる）。予定の削除は詳細の画面で行う。
/// `onboarding` を渡すと、初回の導線の 2 歩目として出す（シートとして閉じず、保存したら `onSaved` を呼ぶ）。
struct EventEditorScreen: View {
    /// 編集する予定。新しく追加するときは nil。
    let event: OshiEvent?
    /// 追加で選んでおく推し（初回の導線で、登録したばかりの推し）。nil なら先頭の推し。
    var preselectedOshiID: Oshi.ID?
    var onboarding: OnboardingStep?
    /// 保存したあと、シートを閉じる前に呼ぶ。
    var onSaved: (OshiEvent) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar
    @Environment(\.appTheme) private var theme
    @Query(sort: [SortDescriptor(\StoredOshi.createdAt), SortDescriptor(\StoredOshi.name)])
    private var storedOshis: [StoredOshi]
    /// 入力。開いたときの推しの一覧と今日から作る。
    @State private var form: EventForm?
    /// 新しく追加するときの id。保存に失敗してやり直しても同じ予定として保存する。
    @State private var newEventID = UUID()
    @State private var failureMessage: String?
    /// 保存が成功したときの触覚。
    @Environment(\.haptic) private var haptic

    var body: some View {
        NavigationStack {
            Group {
                if let form = Binding($form) {
                    EventFormFields(form: form, oshis: storedOshis.map(OshiConStore.oshi(from:)), onboarding: onboarding)
                }
            }
            .navigationTitle(onboarding?.title ?? (event == nil ? String(localized: "予定を追加") : String(localized: "予定を編集")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .safeAreaInset(edge: .bottom) {
                if let onboarding {
                    OnboardingPrimaryButton(title: onboarding.primaryActionTitle, isEnabled: form?.canSave ?? false, action: save)
                }
            }
        }
        .font(theme.typography.text(.body))
        .tint(theme.palette.brand.color)
        .task {
            guard form == nil else {
                return
            }
            form = EventForm(
                event: event,
                oshis: storedOshis.map(OshiConStore.oshi(from:)),
                today: CalendarDay(.now, calendar: calendar),
                preselectedOshiID: preselectedOshiID
            )
        }
        .alert(
            failureMessage ?? "",
            isPresented: Binding { failureMessage != nil } set: { if !$0 { failureMessage = nil } }
        ) {
            Button("閉じる", role: .cancel) {}
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        if let onboarding {
            ToolbarItem(placement: .topBarTrailing) {
                Button("あとで", action: onboarding.onSkip)
            }
        } else {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存", action: save)
                    .fontWeight(.bold)
                    .disabled(!(form?.canSave ?? false))
            }
        }
    }

    /// 保存は同期で終わるので、保存の途中にシートを閉じられることはない。
    private func save() {
        guard let saved = form?.makeEvent(existing: event, newEventID: newEventID, now: .now) else {
            return
        }
        do {
            try OshiConStore(context: modelContext).save(saved)
            haptic(.saved)
            onSaved(saved)
            if onboarding == nil {
                dismiss()
            }
        } catch {
            failureMessage = String(localized: "保存できませんでした")
        }
    }
}

/// 予定の入力欄。
private struct EventFormFields: View {
    @Binding var form: EventForm
    let oshis: [Oshi]
    let onboarding: OnboardingStep?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Environment(\.calendar) private var calendar
    @Environment(\.appTheme) private var theme

    var body: some View {
        Form {
            if let onboarding {
                OnboardingHeading(step: onboarding)
            }
            Section {
                Picker("推し", selection: $form.oshiID) {
                    Text("推しなし")
                        .tag(Oshi.ID?.none)
                    ForEach(oshis) { oshi in
                        Text(oshi.name)
                            .tag(Oshi.ID?.some(oshi.id))
                    }
                }
            }
            .themeRowBackground()
            Section("種類") {
                if dynamicTypeSize.isAccessibilitySize {
                    // 大きな文字では 5 つのセグメントに収まらないので、メニューで選ぶ
                    kindPicker
                        .pickerStyle(.menu)
                } else {
                    kindPicker
                        .pickerStyle(.segmented)
                        .labelsHidden()
                }
            }
            .themeRowBackground()
            Section {
                TextField("例：5th LIVE 東京公演", text: $form.title)
                    .accessibilityLabel("タイトル")
                    .accessibilityIdentifier("eventEditor.title")
            } header: {
                Text("タイトル")
            } footer: {
                InputLengthFooter(field: .eventTitle, text: form.title)
            }
            .themeRowBackground()
            Section {
                DatePicker("日付", selection: day, displayedComponents: .date)
                startTimeRow
            }
            .themeRowBackground()
            Section {
                TextField("会場・場所（任意）", text: $form.venue)
                    .accessibilityLabel("会場・場所（任意）")
            } header: {
                Text("会場・場所（任意）")
            } footer: {
                InputLengthFooter(field: .eventVenue, text: form.venue)
            }
            .themeRowBackground()
            Section {
                Toggle(isOn: $form.repeatsYearly) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("毎年くり返す")
                        Text("誕生日や記念日は、過ぎたら翌年の同じ日を数えます")
                            .font(theme.typography.text(.footnote))
                            .foregroundStyle(theme.palette.onSurfaceVariant.color)
                    }
                }
            }
            .themeRowBackground()
        }
        .scrollContentBackground(.hidden)
        .background(theme.palette.background.color)
    }

    /// 開始時刻。決まっていなければ「未定」で、押すと 18:00 から選べるようにする。消すボタンで時刻なしに戻す。
    @ViewBuilder private var startTimeRow: some View {
        if form.startTime != nil {
            HStack {
                DatePicker("開始時刻（任意）", selection: startTime, displayedComponents: .hourAndMinute)
                    .environment(\.locale, .app24Hour)
                Button {
                    form.startTime = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("開始時刻を消す")
            }
        } else {
            LabeledContent("開始時刻（任意）") {
                Button("未定") {
                    form.startTime = EventForm.defaultStartTime
                }
                .buttonStyle(.borderless)
                .accessibilityHint("押すと開始時刻を決められます")
            }
        }
    }

    private var kindPicker: some View {
        Picker("種類", selection: kind) {
            ForEach(EventKind.allCases, id: \.self) { kind in
                Text(kind.label)
                    .tag(kind)
            }
        }
    }

    private var kind: Binding<EventKind> {
        Binding {
            form.kind
        } set: { kind in
            form.selectKind(kind)
        }
    }

    private var day: Binding<Date> {
        Binding {
            form.day.date(at: nil, calendar: calendar)
        } set: { date in
            form.day = CalendarDay(date, calendar: calendar)
        }
    }

    private var startTime: Binding<Date> {
        Binding {
            form.day.date(at: form.startTime ?? EventForm.defaultStartTime, calendar: calendar)
        } set: { date in
            let gregorian = CalendarDay.gregorian(matching: calendar)
            form.startTime = TimeOfDay(hour: gregorian.component(.hour, from: date), minute: gregorian.component(.minute, from: date))
        }
    }
}

#Preview("追加") {
    EventEditorScreen(event: nil)
        .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
