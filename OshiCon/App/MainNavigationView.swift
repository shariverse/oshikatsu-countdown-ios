//
//  MainNavigationView.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// ホーム・推し・設定の切り替え。iPhone（横幅が狭いとき）はタブバー、iPad の広い画面はサイドバー。
struct MainNavigationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        if horizontalSizeClass == .regular {
            NavigationSplitView {
                List(AppTab.allCases, selection: sidebarSelection) { tab in
                    Label(tab.title, systemImage: tab.systemImage)
                        .accessibilityIdentifier("sidebar.\(tab.rawValue)")
                }
                .navigationTitle("推し活カウントダウン")
                .navigationBarTitleDisplayMode(.inline)
            } detail: {
                TabRootView(tab: router.selectedTab)
            }
        } else {
            TabView(selection: $router.selectedTab) {
                ForEach(AppTab.allCases) { tab in
                    TabRootView(tab: tab)
                        .tabItem {
                            Label(tab.title, systemImage: tab.systemImage)
                        }
                        .tag(tab)
                }
            }
        }
    }

    /// サイドバーの選択。選択を外す操作では今のタブのままにする。
    private var sidebarSelection: Binding<AppTab?> {
        Binding {
            router.selectedTab
        } set: { tab in
            if let tab {
                router.selectedTab = tab
            }
        }
    }
}

/// タブごとの画面の積み重ね。
struct TabRootView: View {
    let tab: AppTab
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        switch tab {
        case .home:
            NavigationStack(path: $router.homePath) {
                HomeScreen()
                    .navigationDestination(for: HomeRoute.self) { route in
                        switch route {
                        case let .eventDetail(id):
                            EventDetailScreen(eventID: id)
                                .hidesTabBar()
                        }
                    }
            }
        case .oshi:
            NavigationStack {
                OshiListScreen()
            }
        case .settings:
            NavigationStack {
                SettingsScreen()
            }
        }
    }
}

extension View {
    /// 詳細・入力の画面を開いている間はタブバーを隠す（SPEC の 2.2）。
    func hidesTabBar() -> some View {
        toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    MainNavigationView()
        .environment(AppRouter())
        .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
