//
//  AppRouter.swift
//  OshiCon
//

import Observation
import SwiftUI

/// アプリのタブ。
enum AppTab: String, CaseIterable, Identifiable {
    case home
    case oshi
    case settings

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .home:
            "ホーム"
        case .oshi:
            "推し"
        case .settings:
            "設定"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .oshi:
            "heart"
        case .settings:
            "gearshape"
        }
    }
}

/// ホームのタブに積む画面。
enum HomeRoute: Hashable {
    /// 予定の詳細。
    case eventDetail(OshiEvent.ID)
}

/// 選んでいるタブと、ホームのタブに積んだ画面。ウィジェットから開くときにまとめて切り替える。
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var homePath: [HomeRoute] = []

    /// ホームのタブに切り替え、最初の画面まで戻してから `route` を積む。
    func openInHome(_ route: HomeRoute) {
        selectedTab = .home
        homePath = [route]
    }

    /// ウィジェットから開いたリンク。予定の詳細はホームのタブに積む。初回の導線の途中なら開かない（何もしない）。
    func open(_ link: WidgetLink, hasCompletedOnboarding: Bool) {
        guard hasCompletedOnboarding else {
            return
        }
        switch link {
        case let .eventDetail(id):
            openInHome(.eventDetail(id))
        case .home, .addEvent:
            // 予定の追加のシートは推しカウントウィジェット（タスク 17）で開く
            selectedTab = .home
        }
    }
}
