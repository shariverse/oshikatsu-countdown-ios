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
                        // UI テスト（App Store 用スクリーンショット）は言語によらずこの ID で探す（OS によってはセルに届かないので、並びの位置でも探す）
                        .accessibilityIdentifier("sidebar.\(tab.rawValue)")
                }
                .navigationTitle("推し活カウントダウン")
                .navigationBarTitleDisplayMode(.inline)
            } detail: {
                // 右の列の NavigationStack は 1 つにして、タブの最初の画面と経路だけを替える。
                // タブごとに別の NavigationStack を入れ替えると、ホームの経路（詳細を積んだまま）に結び付いた列で SwiftUI が落ちる（#331）
                NavigationStack(path: detailPath) {
                    TabRootScreen(tab: router.selectedTab)
                        .homeDestinations()
                }
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
    /// ほかのタブに移るときは、ホームに積んだ画面（予定の詳細）を最初に戻す。右の列は選び直すと最初の画面に戻るので、それに合わせる
    private var sidebarSelection: Binding<AppTab?> {
        Binding {
            router.selectedTab
        } set: { tab in
            guard let tab, tab != router.selectedTab else {
                return
            }
            router.homePath = []
            router.selectedTab = tab
        }
    }

    /// 右の列の経路。ホームではホームに積んだ画面、推し・設定では空
    /// （iPhone のタブバーでホームに詳細を積んだまま、iPad の幅の広い表示に切り替わったときも、推し・設定の上に詳細を出さない）。
    private var detailPath: Binding<[HomeRoute]> {
        Binding {
            router.selectedTab == .home ? router.homePath : []
        } set: { path in
            if router.selectedTab == .home {
                router.homePath = path
            }
        }
    }
}

/// タブごとの画面の積み重ね（iPhone のタブバー）。
struct TabRootView: View {
    let tab: AppTab
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        switch tab {
        case .home:
            NavigationStack(path: $router.homePath) {
                TabRootScreen(tab: .home)
                    .homeDestinations()
            }
        case .oshi, .settings:
            NavigationStack {
                TabRootScreen(tab: tab)
            }
        }
    }
}

/// タブの最初の画面。
struct TabRootScreen: View {
    let tab: AppTab

    var body: some View {
        switch tab {
        case .home:
            HomeScreen()
        case .oshi:
            OshiListScreen()
        case .settings:
            SettingsScreen()
        }
    }
}

extension View {
    /// 詳細・入力の画面を開いている間はタブバーを隠す（SPEC の 2.2）。
    func hidesTabBar() -> some View {
        toolbar(.hidden, for: .tabBar)
    }

    /// ホームに積む画面（予定の詳細）。
    func homeDestinations() -> some View {
        navigationDestination(for: HomeRoute.self) { route in
            switch route {
            case let .eventDetail(id):
                EventDetailScreen(eventID: id)
                    .hidesTabBar()
            }
        }
    }
}

#Preview {
    MainNavigationView()
        .environment(AppRouter())
        .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
