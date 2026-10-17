//
//  OshiEditorScreen.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// 推しの登録・編集のシート。写真・名前・推し色を入れて保存する。編集のときだけ削除を置く。
/// 保存・削除の途中は閉じられないようにし、失敗したら知らせて入力を残す（もう一度押せる）。
struct OshiEditorScreen: View {
    /// 編集する推し。新しく登録するときは nil。
    let oshi: Oshi?
    /// 保存したあと、シートを閉じる前に呼ぶ。
    var onSaved: (Oshi) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var form: OshiForm
    @State private var photoChange = PhotoChange.keep
    @State private var isLoadingPhoto = false
    @State private var isBusy = false
    @State private var failureMessage: String?
    @State private var deleteRequest: DeleteRequest?

    /// 削除の確認に出す中身。
    private struct DeleteRequest {
        let oshi: Oshi
        let eventCount: Int
    }

    init(oshi: Oshi?, onSaved: @escaping (Oshi) -> Void = { _ in }) {
        self.oshi = oshi
        self.onSaved = onSaved
        _form = State(initialValue: OshiForm(oshi: oshi))
    }

    var body: some View {
        NavigationStack {
            Form {
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
                if oshi != nil {
                    Section {
                        Button("推しを削除", role: .destructive, action: requestDelete)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppPalette.background.color)
            .disabled(isBusy)
            .navigationTitle(oshi == nil ? "推しを登録" : "推しを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
        }
        .font(AppFont.text(.body))
        .tint(AppPalette.brand.color)
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
            HStack {
                if form.isNameTooLong {
                    Text("\(form.nameMaxLength) 文字までです")
                }
                Spacer()
                Text("\(form.nameLength) / \(form.nameMaxLength)")
                    .monospacedDigit()
                    .accessibilityLabel("\(form.nameMaxLength) 文字中 \(form.nameLength) 文字")
            }
            .foregroundStyle(form.isNameTooLong ? AppPalette.destructive.color : AppPalette.onSurfaceVariant.color)
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
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
                Button("保存") {
                    Task {
                        await save()
                    }
                }
                .fontWeight(.bold)
                .disabled(!form.canSave || isLoadingPhoto)
            }
        }
    }

    private func save() async {
        isBusy = true
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
                now: .now
            ) else {
                return
            }
            onSaved(saved)
            dismiss()
        } catch {
            failureMessage = "保存できませんでした"
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
            failureMessage = "削除できませんでした"
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
            failureMessage = "削除できませんでした"
        }
    }
}

#Preview("登録") {
    OshiEditorScreen(oshi: nil)
        .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}

#Preview("編集") {
    OshiEditorScreen(oshi: Oshi(name: "ミナト", color: .navy))
        .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
