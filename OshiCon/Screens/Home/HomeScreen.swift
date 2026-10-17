//
//  HomeScreen.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// ホーム。推しで絞り込み、先頭の予定のカードと、これからの予定・終わった予定を出す。
/// 1 分ごと（分の変わり目）に今日を確かめ、日付が変わったら数え直す。
struct HomeScreen: View {
    @Query private var storedEvents: [StoredEvent]
    @Query(sort: [SortDescriptor(\StoredOshi.createdAt), SortDescriptor(\StoredOshi.name)])
    private var storedOshis: [StoredOshi]
    @AppStorage(AppStorageKey.showsPastEvents) private var showsPastEvents = false
    @Environment(\.calendar) private var calendar
    @Environment(\.timeZone) private var timeZone
    @State private var selectedOshiID: Oshi.ID?
    @State private var isAddingEvent = false

    var body: some View {
        TimelineView(.everyMinute) { context in
            content(makeContent(now: context.date))
        }
        .background(AppPalette.background.color.ignoresSafeArea())
        .navigationTitle("推し活カウントダウン")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("予定を追加", systemImage: "plus") {
                    isAddingEvent = true
                }
            }
        }
        .sheet(isPresented: $isAddingEvent) {
            // 推しで絞り込んでいるときは、その推しを選んでおく
            EventEditorScreen(event: nil, preselectedOshiID: selectedOshiID)
        }
    }

    private func makeContent(now: Date) -> HomeContent {
        // 端末のタイムゾーンを変えたときも、その日付で数える
        var calendar = calendar
        calendar.timeZone = timeZone
        return HomeContent(
            events: storedEvents.compactMap(OshiConStore.event(from:)),
            oshis: storedOshis.map(OshiConStore.oshi(from:)),
            selectedOshiID: selectedOshiID,
            showsPastEvents: showsPastEvents,
            today: CalendarDay(now, calendar: calendar)
        )
    }

    @ViewBuilder private func content(_ content: HomeContent) -> some View {
        if content.emptyState == .noEvents {
            ContentUnavailableView {
                Label("まだ予定がありません", systemImage: "calendar.badge.plus")
            } description: {
                Text("ライブ・誕生日・発売日を登録すると、その日まであと何日かを数えます。")
            } actions: {
                Button("予定を追加") {
                    isAddingEvent = true
                }
                .buttonStyle(.borderedProminent)
                .font(AppFont.text(.headline, weight: .bold))
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !content.oshis.isEmpty {
                        OshiFilterBar(oshis: content.oshis, selection: $selectedOshiID)
                    }
                    if content.emptyState == .noEventsForOshi {
                        Text("この推しの予定はまだありません")
                            .foregroundStyle(AppPalette.onSurfaceVariant.color)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        sections(content)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                // 広い画面でも読みやすい幅に収める
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder private func sections(_ content: HomeContent) -> some View {
        if let featured = content.featured {
            NavigationLink(value: HomeRoute.eventDetail(featured.id)) {
                FeaturedEventCard(item: featured)
            }
            .buttonStyle(.plain)
        }
        HomeSection(title: "これからの予定") {
            if content.upcoming.isEmpty {
                Text("これからの予定はありません")
                    .foregroundStyle(AppPalette.onSurfaceVariant.color)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                rows(content.upcoming)
            }
        }
        if !content.past.isEmpty {
            HomeSection(title: "終わった予定") {
                rows(content.past)
            }
        }
    }

    private func rows(_ items: [HomeContent.Item]) -> some View {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
            if index > 0 {
                Divider()
                    .padding(.leading, 68)
            }
            NavigationLink(value: HomeRoute.eventDetail(item.id)) {
                HomeEventRow(item: item)
            }
            .buttonStyle(.plain)
        }
    }
}

/// ホームの見出しつきのまとまり。中身はカードの地に並べる。
private struct HomeSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.text(.headline, weight: .bold))
                .foregroundStyle(AppPalette.onSurface.color)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                content()
            }
            .background(AppPalette.surface.color, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

#Preview {
    NavigationStack {
        HomeScreen()
    }
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
