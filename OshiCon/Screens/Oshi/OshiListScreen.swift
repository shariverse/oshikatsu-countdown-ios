//
//  OshiListScreen.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// 推しの一覧。登録した順に、アバター・名前・予定の件数を並べる。押すと編集、「推しを登録」で登録のシートを開く。
struct OshiListScreen: View {
    @Query(sort: [SortDescriptor(\StoredOshi.createdAt), SortDescriptor(\StoredOshi.name)])
    private var storedOshis: [StoredOshi]
    @Query private var storedEvents: [StoredEvent]
    @State private var editorTarget: EditorTarget?
    @Environment(AppRouter.self) private var router

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
        .background(AppPalette.background.color.ignoresSafeArea())
        .navigationTitle("推し")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("推しを登録", systemImage: "plus") {
                    editorTarget = .register
                }
            }
        }
        // ウィジェットのリンクで画面を切り替えるときは、登録・編集のシートを閉じる
        .onChange(of: router.sheetDismissal) {
            editorTarget = nil
        }
        .sheet(item: $editorTarget) { target in
            OshiEditorScreen(oshi: target.oshi)
        }
    }

    private var list: some View {
        // 件数は関係の配列ではなく予定の一覧から数える（予定の付け替えの直後でも保存した中身どおりにする）
        let eventCounts = Dictionary(grouping: storedEvents.compactMap { $0.oshi?.id }, by: \.self).mapValues(\.count)
        return List(storedOshis) { stored in
            let oshi = OshiConStore.oshi(from: stored)
            Button {
                editorTarget = .edit(oshi)
            } label: {
                OshiRow(oshi: oshi, eventCount: eventCounts[oshi.id, default: 0])
            }
            .listRowBackground(AppPalette.surface.color)
            .accessibilityIdentifier("oshiList.row")
        }
        .scrollContentBackground(.hidden)
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
            .font(AppFont.text(.headline, weight: .bold))
        }
    }
}

/// 推しの一覧の行。
private struct OshiRow: View {
    let oshi: Oshi
    let eventCount: Int

    var body: some View {
        HStack(spacing: 12) {
            OshiPhotoAvatar(oshi: oshi, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(oshi.name)
                    .font(AppFont.text(.body, weight: .bold))
                    .foregroundStyle(AppPalette.onSurface.color)
                Text("予定 \(eventCount) 件")
                    .font(AppFont.text(.subheadline))
                    .foregroundStyle(AppPalette.onSurfaceVariant.color)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppPalette.onSurfaceVariant.color)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("編集する")
    }
}

#Preview {
    NavigationStack {
        OshiListScreen()
    }
    .environment(AppRouter())
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
