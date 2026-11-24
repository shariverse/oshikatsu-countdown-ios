//
//  OshiListScreen.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// 推しの一覧。並び順に、アバター・名前・予定の件数を並べる。押すと編集、「推しを登録」で登録のシートを開く。
/// 「並べ替え」で並べ替えの状態にし、行をドラッグして順番を入れ替える（いちばん上が 1 位の推し）。並べ替えの間は、読み上げの行の操作「上に移動」「下に移動」でも入れ替えられる。
/// 並べ替えの間は、ふつうの一覧と見分けられるよう、一覧の上に案内・各行に順位を出し、「この順番で確定」を塗りのボタンにする。
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
                    if editMode.isEditing {
                        // 「完了」だと何が終わるのか分かりづらいので「この順番で確定」にする。
                        // 並べ替えの状態を終えるボタンだと分かるよう、塗りのボタンにする
                        Button("この順番で確定", action: toggleReordering)
                            .buttonStyle(.borderedProminent)
                            .fontWeight(.bold)
                    } else {
                        Button("並べ替え", action: toggleReordering)
                    }
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
            if editMode.isEditing {
                Section {
                    OshiReorderGuide()
                        .listRowBackground(theme.palette.brandContainer.color)
                        .accessibilityIdentifier("oshiList.reorderGuide")
                }
            }
            Section {
                ForEach(Array(storedOshis.enumerated()), id: \.element.id) { index, stored in
                    let oshi = OshiConStore.oshi(from: stored)
                    Button {
                        // 並べ替えの間は、行を押しても編集を開かない
                        if !editMode.isEditing {
                            editorTarget = .edit(oshi)
                        }
                    } label: {
                        OshiRow(
                            oshi: oshi,
                            eventCount: eventCounts[oshi.id, default: 0],
                            rank: editMode.isEditing ? index + 1 : nil
                        )
                    }
                    .themeRowBackground()
                    .accessibilityIdentifier("oshiList.row")
                    // 入れ替えるのは並べ替えの間だけ（ドラッグも読み上げの操作も）。ふつうの一覧では行を押すと編集を開く
                    .moveDisabled(!editMode.isEditing)
                    .accessibilityActions {
                        if editMode.isEditing {
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
                }
                .onMove(perform: move)
            }
        }
        // 並べ替えの案内を、案内する一覧のすぐ上に置く
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
    }

    /// 並べ替えの状態にする・終える。
    private func toggleReordering() {
        withAnimation {
            editMode = editMode.isEditing ? .inactive : .active
        }
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

/// 推しの一覧の行。並べ替えの間（`rank` がある）は、左に順位を出し、編集を開く印（＞）と案内を出さない。
private struct OshiRow: View {
    let oshi: Oshi
    let eventCount: Int
    /// 並べ替えの間だけ渡す順位（1 から）。
    let rank: Int?

    @Environment(\.appTheme) private var theme

    private var isReordering: Bool {
        rank != nil
    }

    var body: some View {
        HStack(spacing: 12) {
            if let rank {
                OshiRankBadge(rank: rank)
                    .transition(.opacity)
            }
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

/// 並べ替えの間に行の左に出す順位。1 位はアクセント（1 位の推しの推し色で染めた色）で塗り、ほかは縁取りだけにする。
private struct OshiRankBadge: View {
    let rank: Int

    @Environment(\.appTheme) private var theme
    @ScaledMetric(relativeTo: .subheadline) private var diameter: CGFloat = 28

    var body: some View {
        let isFirst = rank == 1
        Text(rank, format: .number)
            .font(theme.typography.numeral(size: 15, relativeTo: .subheadline))
            .foregroundStyle((isFirst ? theme.palette.onBrand : theme.palette.onSurfaceVariant).color)
            .padding(.horizontal, 4)
            .frame(minWidth: diameter, minHeight: diameter)
            .background {
                if isFirst {
                    Capsule().fill(theme.palette.brand.color)
                } else {
                    Capsule().strokeBorder(theme.palette.outlineVariant.color, lineWidth: 1.5)
                }
            }
            .accessibilityLabel(Text("\(rank) 位"))
    }
}

/// 並べ替えの間だけ一覧の上に出す案内。ふつうの一覧と見分けられるよう、アクセントの薄い地（行の地は置く側が付ける）に置く。
private struct OshiReorderGuide: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "arrow.up.arrow.down")
                .font(.headline)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("並べ替え中")
                    .font(theme.typography.text(.headline, weight: .bold))
                // 2 文目（アプリの色）は iOS 版だけの決定なので、仕様と合わせて文言を分けている
                Text("右端をドラッグして、順番を入れ替えます。")
                    .font(theme.typography.text(.subheadline))
                Text("いちばん上（1 位）の推しの推し色が、アプリの色になります。")
                    .font(theme.typography.text(.subheadline))
            }
        }
        .foregroundStyle(theme.palette.onBrandContainer.color)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        OshiListScreen()
    }
    .environment(AppRouter())
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
