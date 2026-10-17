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
    /// ウィジェットのリンクで画面を切り替えるときに、各画面へ自分のシートを閉じさせる合図。値が変わったら閉じる。
    /// ほかのシートが開いたままだと、ホームで予定の追加のシートを出せない（2 枚目のシートは出せない）ため。
    private(set) var sheetDismissal = 0
    /// 予定の追加のシートを開く要求。ホームが受け取ったら false に戻し、ほかのシートが閉じてから開く。
    var pendingAddEvent = false

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
            // 開いているシート（予定の追加の入力中を含む）は閉じる。ウィジェットから別の予定を開くのは利用者の操作なので、確かめない
            pendingAddEvent = false
            sheetDismissal += 1
            openInHome(.eventDetail(id))
        case .addEvent:
            // ホームの最初の画面に戻し、ほかのシートを閉じてから予定の追加のシートを開く
            selectedTab = .home
            homePath = []
            pendingAddEvent = true
            sheetDismissal += 1
        case .home:
            selectedTab = .home
        }
    }
}
