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
}
