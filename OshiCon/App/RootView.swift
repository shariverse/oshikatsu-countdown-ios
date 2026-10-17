//
//  RootView.swift
//  OshiCon
//

import SwiftUI

/// 初回の導線を終えるまでは導線を、終えたらタブを出す。
struct RootView: View {
    @AppStorage(AppStorageKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @Environment(AppRouter.self) private var router

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainNavigationView()
            } else {
                OnboardingFlowView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .font(AppFont.text(.body))
        .tint(AppPalette.brand.color)
        .environment(\.locale, .app)
        .onOpenURL(perform: open)
    }

    /// ウィジェットから開いたリンク。予定の詳細はホームのタブに積む。初回の導線の途中なら開かない。
    private func open(_ url: URL) {
        guard hasCompletedOnboarding, let link = WidgetLink(url: url) else {
            return
        }
        switch link {
        case let .eventDetail(id):
            router.openInHome(.eventDetail(id))
        case .home:
            router.selectedTab = .home
        case .addEvent:
            // 予定の追加は推しカウントウィジェット（タスク 17）で開く
            router.selectedTab = .home
        }
    }
}

/// ストアを開けなかったときの画面。
struct StoreUnavailableView: View {
    var body: some View {
        ContentUnavailableView {
            Label("データを開けませんでした", systemImage: "exclamationmark.triangle")
        } description: {
            Text("アプリを終了して、もう一度開いてください。端末の空き容量が少ないときは、空きを増やしてからお試しください。")
        }
        .font(AppFont.text(.body))
    }
}

#Preview("ストアを開けない") {
    StoreUnavailableView()
}
