//
//  OshiListScreen.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// 推しの一覧。並び順に、アバター・名前・予定の件数を並べる。押すと編集、「推しを登録」で登録のシートを開く。
/// 「並べ替え」で並べ替えの状態にし、行をドラッグして順番を入れ替える（いちばん上が 1 位の推し）。読み上げでは、行の操作の「上に移動」「下に移動」でも入れ替えられる。
struct OshiListScreen: View {
    @Query(sort: OshiConStore.oshiOrder)
    private var storedOshis: [StoredOshi]
    @Query private var storedEvents: [StoredEvent]
    @State private var editorTarget: EditorTarget?
    @State private var editMode = EditMode.inactive
    @State private var failureMessage: String?
    @Environment(AppRouter.self) private var router
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    /// 開いているシート。
    private enum EditorTarget: Identifiable {
        case register
        case edit(Oshi)

        var id: String {
            switch self {
            case .register:
                "register"
            case let .edit(oshi):
                oshi.id.uuidString
            }
        }

        var oshi: Oshi? {
            switch self {
            case .register:
                nil
            case let .edit(oshi):
                oshi
            }
        }
    }

    var body: some View {
        Group {
            if storedOshis.isEmpty {
                emptyView
            } else {
                list
            }
        }
        .background(theme.palette.background.color.ignoresSafeArea())
        .navigationTitle("推し")
        .toolbar {
            // 2 人以上いるときだけ並べ替えられる
            if storedOshis.count > 1 || editMode.isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    // 三項演算子の文字列は String になって訳されないので、キーとして渡す
                    Button(editMode.isEditing ? LocalizedStringKey("完了") : LocalizedStringKey("並べ替え")) {
                        withAnimation {
                            editMode = editMode.isEditing ? .inactive : .active
                        }
                    }
                    .fontWeight(editMode.isEditing ? .bold : .regular)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("推しを登録", systemImage: "plus") {
                    editorTarget = .register
                }
                .disabled(editMode.isEditing)
            }
        }
        .environment(\.editMode, $editMode)
        // ウィジェットのリンクで画面を切り替えるときは、登録・編集のシートを閉じる
        .onChange(of: router.sheetDismissal) {
            editorTarget = nil
        }
        .sheet(item: $editorTarget) { target in
            OshiEditorScreen(oshi: target.oshi)
        }
        .alert(
            failureMessage ?? "",
            isPresented: Binding { failureMessage != nil } set: { if !$0 { failureMessage = nil } }
        ) {
            Button("閉じる", role: .cancel) {}
        }
    }

    private var list: some View {
        // 件数は関係の配列ではなく予定の一覧から数える（予定の付け替えの直後でも保存した中身どおりにする）
        let eventCounts = Dictionary(grouping: storedEvents.compactMap { $0.oshi?.id }, by: \.self).mapValues(\.count)
        return List {
            ForEach(Array(storedOshis.enumerated()), id: \.element.id) { index, stored in
                let oshi = OshiConStore.oshi(from: stored)
                Button {
                    // 並べ替えの間は、行を押しても編集を開かない
                    if !editMode.isEditing {
                        editorTarget = .edit(oshi)
                    }
                } label: {
                    OshiRow(oshi: oshi, eventCount: eventCounts[oshi.id, default: 0], isReordering: editMode.isEditing)
                }
                .themeRowBackground()
                .accessibilityIdentifier("oshiList.row")
                .accessibilityActions {
                    if index > 0 {
                        Button("上に移動") {
                            move(from: IndexSet(integer: index), to: index - 1)
                        }
                    }
                    if index < storedOshis.count - 1 {
                        Button("下に移動") {
                            move(from: IndexSet(integer: index), to: index + 2)
                        }
                    }
                }
            }
            .onMove(perform: move)
        }
        .scrollContentBackground(.hidden)
    }

    /// 推しを並べ替えて保存する。`destination` は `onMove` と同じく、動かす前の並びでの位置。
    private func move(from source: IndexSet, to destination: Int) {
        var ids = storedOshis.map(\.id)
        ids.move(fromOffsets: source, toOffset: destination)
        do {
            try OshiConStore(context: modelContext).reorderOshis(ids)
        } catch {
            // ストアが変更を取り消すので、並びは元に戻る
            failureMessage = String(localized: "保存できませんでした")
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("推しを登録しよう", systemImage: "heart")
        } description: {
            Text("名前と推し色を登録すると、予定やカウントダウンが推し色になります。")
        } actions: {
            Button("推しを登録") {
                editorTarget = .register
            }
            .buttonStyle(.borderedProminent)
            .font(theme.typography.text(.headline, weight: .bold))
        }
    }
}

/// 推しの一覧の行。並べ替えの間は、編集を開く印（＞）と案内を出さない。
private struct OshiRow: View {
    let oshi: Oshi
    let eventCount: Int
    let isReordering: Bool

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            OshiPhotoAvatar(oshi: oshi, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(oshi.name)
                    .font(theme.typography.text(.body, weight: .bold))
                    .foregroundStyle(theme.palette.onSurface.color)
                Text("予定 \(eventCount) 件")
                    .font(theme.typography.text(.subheadline))
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
            }
            Spacer(minLength: 0)
            if !isReordering {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(isReordering ? Text(verbatim: "") : Text("編集する"))
    }
}

#Preview {
    NavigationStack {
        OshiListScreen()
    }
    .environment(AppRouter())
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
