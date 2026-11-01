//
//  HomeScreen.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// ホーム。推しで絞り込み、先頭の予定のカードと、これからの予定・終わった予定を出す。
/// 1 分ごと（分の変わり目）に今日を確かめ、日付が変わったら数え直す。
struct HomeScreen: View {
    /// ウィジェットの ＋ から予定の追加のシートを開くまで待つ時間。ほかのシートが閉じる動きが終わるのを待つ。
    private static let sheetPresentationDelay = Duration.milliseconds(450)

    @Query private var storedEvents: [StoredEvent]
    @Query(sort: [SortDescriptor(\StoredOshi.createdAt), SortDescriptor(\StoredOshi.name)])
    private var storedOshis: [StoredOshi]
    @AppStorage(AppStorageKey.showsPastEvents) private var showsPastEvents = false
    @State private var selectedOshiID: Oshi.ID?
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appTheme) private var theme
    @State private var isAddingEvent = false
    /// 予定の追加のシートが実際に出ている（開こうとしても出せなかったときと分ける）。
    @State private var isAddEventSheetVisible = false

    var body: some View {
        TimelineView(.everyMinute) { context in
            content(makeContent(now: context.date))
        }
        .background(ThemeScreenBackground().ignoresSafeArea())
        // 画面の名前（VoiceOver・iPad の戻り先）として残し、バーには出さない（Discussion #148 の Q1・Q3）。
        // 大きいタイトルの帯も無くし、先頭のカードを上に詰める
        .navigationTitle("推し活カウントダウン")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(removing: Self.hiddenToolbarTitle)
        .toolbar {
            if #unavailable(iOS 18.0) {
                // iOS 17 は `toolbar(removing: .title)` が無いので、見えない要素でタイトルの文字を置き換える
                ToolbarItem(placement: .principal) {
                    Color.clear
                        .frame(width: 1, height: 1)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("予定を追加", systemImage: "plus", action: presentAddEvent)
                    .accessibilityIdentifier("home.addEvent")
            }
        }
        // ウィジェットのリンクで画面を切り替えるときは、予定の追加のシートを閉じる（予定の追加のリンクのときは開いたまま）
        .onChange(of: router.sheetDismissal) { _, dismissal in
            if !dismissal.keepsAddEvent {
                isAddingEvent = false
            }
        }
        // ウィジェットの ＋ の要求を受け取る。ホームを新しく作ったとき（iPad でほかの項目から移ったとき）も受け取る
        .onChange(of: router.pendingAddEvent, initial: true) {
            guard router.pendingAddEvent else {
                return
            }
            router.pendingAddEvent = false
            guard !isAddEventSheetVisible else {
                return
            }
            Task {
                // ほかの画面のシートが閉じきるのを待ってから開く（閉じている途中に出すと出せない）
                try? await Task.sleep(for: Self.sheetPresentationDelay)
                presentAddEvent()
            }
        }
        .sheet(isPresented: $isAddingEvent) {
            // 推しで絞り込んでいるときは、その推しを選んでおく
            EventEditorScreen(event: nil, preselectedOshiID: selectedOshiID)
                .onAppear {
                    isAddEventSheetVisible = true
                }
                .onDisappear {
                    isAddEventSheetVisible = false
                }
        }
    }

    /// バーから外すタイトル。iOS 17 には無いので外さない（代わりに `.principal` の見えない要素で置き換える）。
    private static var hiddenToolbarTitle: ToolbarDefaultItemKind? {
        if #available(iOS 18.0, *) {
            return .title
        }
        return nil
    }

    /// 予定の追加のシートを開く。ほかのシートと重なって開けずに残っていたら、一度戻してから開き直す。
    private func presentAddEvent() {
        guard !isAddEventSheetVisible else {
            return
        }
        guard isAddingEvent else {
            isAddingEvent = true
            return
        }
        isAddingEvent = false
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            isAddingEvent = true
        }
    }

    private func makeContent(now: Date) -> HomeContent {
        // 端末のタイムゾーンを変えたときも、次の分の変わり目からその日付で数える
        let calendar = Calendar.autoupdatingCurrent
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
                Button("予定を追加", action: presentAddEvent)
                .buttonStyle(.borderedProminent)
                .font(theme.typography.text(.headline, weight: .bold))
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !content.oshis.isEmpty {
                        OshiFilterBar(oshis: content.oshis, selection: $selectedOshiID)
                    }
                    if content.emptyState == .noEventsForOshi {
                        Text("この推しの予定はまだありません")
                            .foregroundStyle(theme.palette.onSurfaceVariant.color)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        sections(content)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                // 予定が増える・消える・絞り込みやピン留めで入れ替わるときに、カードと行を短く出入りさせる
                .animation(AppMotion.animation(for: cardMotion), value: content)
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
            // 読み上げはリンク（ボタン）そのものに付け、中の文字を別々に読ませない
            .accessibilityLabel(featured.featuredAccessibilityLabel)
            // UI テスト（App Store 用スクリーンショット）は言語によらずこの ID で探す
            .accessibilityIdentifier("home.featuredEvent")
            // 先頭の予定が別の予定に替わったら、入れ替わりとして出入りさせる
            .id(featured.id)
            .transition(AppMotion.transition(for: cardMotion))
        }
        HomeSection(title: "これからの予定") {
            if content.upcoming.isEmpty {
                Text("これからの予定はありません")
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
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
            .accessibilityLabel(item.accessibilityLabel)
            .transition(AppMotion.transition(for: cardMotion))
        }
    }

    private var cardMotion: AppMotion.Style {
        AppMotion.style(for: .homeCards, reduceMotion: reduceMotion)
    }
}

/// ホームの見出しつきのまとまり。中身はカードの地に並べる。
struct HomeSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: () -> Content

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(theme.typography.text(.headline, weight: .bold))
                .foregroundStyle(theme.palette.onSurface.color)
                .accessibilityAddTraits(.isHeader)
                .themeHeadingOrnament()
            VStack(spacing: 0) {
                content()
            }
            .background(theme.palette.surface.color, in: RoundedRectangle(cornerRadius: theme.shape.section))
            .themeCardBorder(RoundedRectangle(cornerRadius: theme.shape.section))
        }
    }
}

#Preview {
    NavigationStack {
        HomeScreen()
    }
    .environment(AppRouter())
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
