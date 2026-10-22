//
//  ThemePreviewCanvas.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// テーマの Preview に描く画面。
enum ThemePreviewScreen {
    /// ホーム（先頭のピン留めのライブと、これからの予定）。
    case home
    /// 先頭の予定の詳細。
    case eventDetail
    /// 予定の追加。
    case eventEditor
    /// ウィジェット 2 種（カウントダウン・推しカウント）を、ウィジェットの大きさの枠で。
    case widgets
}

/// テーマの Preview。日本語の見本の推しと予定をメモリ上のストアに入れ、テーマと外観を当てて画面を描く。
/// テーマの日本語の書体は、アプリの言語が日本語のときだけ使われる（Xcode の Scheme の Run の Options の App Language を日本語にする）。
struct ThemePreviewCanvas: View {
    let theme: AppTheme
    let screen: ThemePreviewScreen
    let colorScheme: ColorScheme

    @State private var store = ThemePreviewStore()
    /// 画面遷移の状態を描き直しのあとも保つため、`@State` で持つ。
    @State private var router = AppRouter()

    init(_ theme: AppTheme, _ screen: ThemePreviewScreen, _ colorScheme: ColorScheme) {
        PreviewFonts.registerIfNeeded()
        self.theme = theme
        self.screen = screen
        self.colorScheme = colorScheme
    }

    var body: some View {
        Group {
            if let container = store.container {
                content.modelContainer(container)
            } else {
                Text(verbatim: "見本のストアを作れませんでした")
            }
        }
        .environment(router)
        .environment(\.appTheme, theme)
        .preferredColorScheme(colorScheme)
    }

    @ViewBuilder private var content: some View {
        switch screen {
        case .home:
            NavigationStack {
                HomeScreen()
            }
        case .eventDetail:
            NavigationStack {
                if let eventID = store.featuredEventID {
                    EventDetailScreen(eventID: eventID)
                }
            }
        case .eventEditor:
            EventEditorScreen(event: nil)
        case .widgets:
            VStack(spacing: 16) {
                WidgetPreview.countdown(.sample, theme: theme)
                WidgetPreview.upcoming(.sample, theme: theme)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ThemeScreenBackground().ignoresSafeArea())
        }
    }
}

/// テーマの Preview の見本のストア。日本語の見本の推しと予定（`SampleData`）をメモリ上のストアに入れる。
private struct ThemePreviewStore {
    let container: ModelContainer?
    /// ホームの先頭に出る、ピン留めした予定。
    let featuredEventID: OshiEvent.ID?

    init(now: Date = .now) {
        let sample = SampleData.make(today: CalendarDay(now, calendar: .autoupdatingCurrent), now: now, language: .japanese)
        let container = try? OshiConStore.makeContainer(.inMemory)
        if let container {
            SampleData.insert(sample, into: container.mainContext, now: now)
        }
        self.container = container
        featuredEventID = sample.events.first(where: \.isPinned)?.id
    }
}
