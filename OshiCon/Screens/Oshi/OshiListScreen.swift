//
//  OshiListScreen.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// 推しの一覧。並び順に、1 位の推しを大きいカード（チェキの写真・「1 位」のリボン・次の予定と残り日数・予定の件数）で、
/// 2 位からの推しを行（缶バッジのアバター・名前・次の予定と日付・残り日数）で並べる。押すと編集、「推しを登録」で登録のシートを開く。
/// 1 分ごと（分の変わり目）に今日を確かめ、日付が変わったら次の予定と残り日数を数え直す。
///
/// 「並べ替え」で並べ替えの状態にし、行をドラッグして順番を入れ替える（いちばん上が 1 位の推し）。並べ替えの間は、読み上げの行の操作「上に移動」「下に移動」でも入れ替えられる。
/// 並べ替えの間は、ふつうの一覧と見分けられるよう、カードをやめて同じ形の行のリストにし、一覧の上に案内・各行に順位を出し、「この順番で確定」を塗りのボタンにする。
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
            } else if editMode.isEditing {
                reorderList
                    .transition(.opacity)
            } else {
                TimelineView(.everyMinute) { context in
                    cards(makeContent(now: context.date))
                }
                .transition(.opacity)
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

    private func makeContent(now: Date) -> OshiListContent {
        // 件数と次の予定は、関係の配列ではなく予定の一覧から数える（予定の付け替えの直後でも保存した中身どおりにする）。
        // 端末のタイムゾーンを変えたときも、次の分の変わり目からその日付で数える
        OshiListContent(
            oshis: storedOshis.map(OshiConStore.oshi(from:)),
            events: storedEvents.compactMap(OshiConStore.event(from:)),
            now: now,
            calendar: .autoupdatingCurrent
        )
    }

    /// ふつうの一覧。1 位の推しのカードと、2 位からの推しの行のまとまり。
    private func cards(_ content: OshiListContent) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                if let top = content.top {
                    editButton(for: top.oshi, label: top.topAccessibilityLabel) {
                        OshiTopCard(row: top)
                    }
                }
                if !content.others.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(content.others.enumerated()), id: \.element.id) { index, row in
                            if index > 0 {
                                Divider()
                                    .padding(.leading, 72)
                            }
                            editButton(for: row.oshi, label: row.accessibilityLabel) {
                                OshiNextEventRow(row: row)
                            }
                        }
                    }
                    .background(theme.palette.surface.color, in: RoundedRectangle(cornerRadius: theme.shape.section))
                    .themeCardBorder(RoundedRectangle(cornerRadius: theme.shape.section))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            // 広い画面でも読みやすい幅に収める
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
    }

    /// 押すと編集を開くカード・行。読み上げはボタンそのものに付け、中の文字を別々に読ませない。
    private func editButton(for oshi: Oshi, label: String, @ViewBuilder content: () -> some View) -> some View {
        Button {
            editorTarget = .edit(oshi)
        } label: {
            content()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint(Text("編集する"))
        .accessibilityIdentifier("oshiList.row")
    }

    /// 並べ替えの状態の一覧。行をドラッグして順番を入れ替える。
    private var reorderList: some View {
        // 件数は関係の配列ではなく予定の一覧から数える（予定の付け替えの直後でも保存した中身どおりにする）
        let eventCounts = Dictionary(grouping: storedEvents.compactMap { $0.oshi?.id }, by: \.self).mapValues(\.count)
        return List {
            Section {
                OshiReorderGuide()
                    .listRowBackground(theme.palette.brandContainer.color)
                    .accessibilityIdentifier("oshiList.reorderGuide")
            }
            Section {
                ForEach(Array(storedOshis.enumerated()), id: \.element.id) { index, stored in
                    // 並べ替えの間は、行を押しても編集を開かない
                    Button {} label: {
                        OshiReorderRow(
                            oshi: OshiConStore.oshi(from: stored),
                            eventCount: eventCounts[stored.id, default: 0],
                            rank: index + 1
                        )
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

/// 並べ替えの間の行。左に順位、缶バッジのアバター・名前・予定の件数を出す。編集を開く印（＞）と案内は出さない。
private struct OshiReorderRow: View {
    /// アバターの一辺。
    private static let avatarSize: CGFloat = 48

    let oshi: Oshi
    let eventCount: Int
    /// 順位（1 から）。
    let rank: Int

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            OshiRankBadge(rank: rank)
            OshiPhotoAvatar(oshi: oshi, size: Self.avatarSize)
                .canBadgeStyle(color: oshi.color, size: Self.avatarSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(oshi.name)
                    .font(theme.typography.text(.body, weight: .bold))
                    .foregroundStyle(theme.palette.onSurface.color)
                Text("予定 \(eventCount) 件")
                    .font(theme.typography.text(.subheadline))
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
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
    // 推しの編集の画面が引く着せ替えの設定（端末の設定に触れない）
    .environment(AppearanceStore.volatile(
        suiteName: "jp.shilokuma.OshiCon.PreviewAppearance",
        directory: FileManager.default.temporaryDirectory.appending(path: "PreviewAppearancePhotos", directoryHint: .isDirectory)
    ))
}
