//
//  OshiEditorScreen.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// 推しの登録・編集のシート。写真・名前・推し色を入れて保存する。編集のときだけ削除を置く。
/// 保存・削除の途中は閉じられないようにし、失敗したら知らせて入力を残す（もう一度押せる）。
/// `onboarding` を渡すと、初回の導線の 1 歩目として出す（シートとして閉じず、保存したら `onSaved` を呼ぶ）。
struct OshiEditorScreen: View {
    /// 編集する推し。新しく登録するときは nil。
    let oshi: Oshi?
    var onboarding: OnboardingStep?
    /// 保存したあと、シートを閉じる前に呼ぶ。
    var onSaved: (Oshi) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @State private var form: OshiForm
    /// 新しく登録するときの id。保存に失敗してやり直しても同じ推しとして保存する。
    @State private var newOshiID = UUID()
    @State private var photoChange = PhotoChange.keep
    @State private var isLoadingPhoto = false
    @State private var isBusy = false
    @State private var failureMessage: String?
    /// 保存が成功したときの触覚。
    @Environment(\.haptic) private var haptic
    @State private var deleteRequest: DeleteRequest?

    /// 削除の確認に出す中身。
    private struct DeleteRequest {
        let oshi: Oshi
        let eventCount: Int
    }

    init(oshi: Oshi?, onboarding: OnboardingStep? = nil, onSaved: @escaping (Oshi) -> Void = { _ in }) {
        self.oshi = oshi
        self.onboarding = onboarding
        self.onSaved = onSaved
        _form = State(initialValue: OshiForm(oshi: oshi))
    }

    var body: some View {
        NavigationStack {
            Form {
                if let onboarding {
                    OnboardingHeading(step: onboarding)
                }
                photoSection
                nameSection
                Section {
                    OshiColorPicker(selection: $form.color)
                        .padding(.vertical, 4)
                } header: {
                    Text("推し色（メンバーカラー）")
                } footer: {
                    Text("写真と推し色はこの端末の中だけに保存されます")
                }
                .themeRowBackground()
                if oshi != nil {
                    Section {
                        Button("推しを削除", role: .destructive, action: requestDelete)
                            .frame(maxWidth: .infinity)
                    }
                    .themeRowBackground()
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.palette.background.color)
            .disabled(isBusy)
            .navigationTitle(onboarding?.title ?? (oshi == nil ? String(localized: "推しを登録") : String(localized: "推しを編集")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .safeAreaInset(edge: .bottom) {
                if let onboarding {
                    OnboardingPrimaryButton(
                        title: onboarding.primaryActionTitle,
                        isEnabled: form.canSave && !isLoadingPhoto && !isBusy,
                        action: startSaving
                    )
                }
            }
        }
        .font(theme.typography.text(.body))
        .tint(theme.palette.brand.color)
        .interactiveDismissDisabled(isBusy)
        .alert(
            failureMessage ?? "",
            isPresented: Binding { failureMessage != nil } set: { if !$0 { failureMessage = nil } }
        ) {
            Button("閉じる", role: .cancel) {}
        }
        .alert(
            deleteRequest.map { OshiForm.deleteTitle(name: $0.oshi.name) } ?? "",
            isPresented: Binding { deleteRequest != nil } set: { if !$0 { deleteRequest = nil } },
            presenting: deleteRequest
        ) { request in
            Button("削除", role: .destructive) {
                delete(request.oshi)
            }
            Button("キャンセル", role: .cancel) {}
        } message: { request in
            Text(OshiForm.deleteMessage(eventCount: request.eventCount))
        }
    }

    private var photoSection: some View {
        Section {
            OshiPhotoPicker(
                currentPhotoFileName: oshi?.photoFileName,
                photoChange: $photoChange,
                isLoading: $isLoadingPhoto
            ) {
                OshiAvatar(name: form.name, color: form.color, size: 96)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
    }

    private var nameSection: some View {
        Section {
            TextField("推しの名前", text: $form.name)
                .submitLabel(.done)
        } header: {
            Text("推しの名前")
        } footer: {
            InputLengthFooter(field: .oshiName, text: form.name)
        }
        .themeRowBackground()
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        if let onboarding {
            ToolbarItem(placement: .topBarTrailing) {
                Button("あとで", action: onboarding.onSkip)
                    .disabled(isBusy)
            }
        } else {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
                .disabled(isBusy)
            }
            ToolbarItem(placement: .confirmationAction) {
                if isBusy {
                    ProgressView()
                } else {
                    Button("保存", action: startSaving)
                        .fontWeight(.bold)
                        .disabled(!form.canSave || isLoadingPhoto)
                }
            }
        }
    }

    private func startSaving() {
        // Task が走り出す前に立て、続けて押しても 1 回だけ保存する
        isBusy = true
        Task {
            await save()
        }
    }

    private func save() async {
        defer {
            isBusy = false
        }
        let editing = OshiEditing(store: OshiConStore(context: modelContext))
        do {
            guard let saved = try await editing.save(
                current: oshi,
                name: form.name,
                color: form.color,
                photoChange: photoChange,
                now: .now,
                newOshiID: newOshiID
            ) else {
                return
            }
            haptic(.saved)
            onSaved(saved)
            if onboarding == nil {
                dismiss()
            }
        } catch {
            failureMessage = String(localized: "保存できませんでした")
        }
    }

    private func requestDelete() {
        guard let oshi else {
            return
        }
        do {
            let eventCount = try OshiConStore(context: modelContext).eventCount(oshiID: oshi.id)
            deleteRequest = DeleteRequest(oshi: oshi, eventCount: eventCount)
        } catch {
            // 一緒に消える件数を出せないまま消させない
            failureMessage = String(localized: "削除できませんでした")
        }
    }

    private func delete(_ oshi: Oshi) {
        isBusy = true
        defer {
            isBusy = false
        }
        do {
            try OshiEditing(store: OshiConStore(context: modelContext)).delete(oshiID: oshi.id)
            dismiss()
        } catch {
            failureMessage = String(localized: "削除できませんでした")
        }
    }
}

#Preview("登録") {
    OshiEditorScreen(oshi: nil)
        .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}

#Preview("初回の導線") {
    OshiEditorScreen(oshi: nil, onboarding: .oshi {})
        .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}

#Preview("編集") {
    OshiEditorScreen(oshi: Oshi(name: "ミナト", color: .navy))
        .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
