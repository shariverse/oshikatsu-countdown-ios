//
//  HomeScreen.swift
//  OshiCon
//

import SwiftUI

/// ホーム。中身はタスク 10 で作る。
struct HomeScreen: View {
    var body: some View {
        AppPalette.background.color
            .ignoresSafeArea()
            .navigationTitle("推し活カウントダウン")
    }
}

/// 予定の詳細の仮の画面。タスク 11 で置き換える。
struct EventDetailPlaceholder: View {
    let eventID: OshiEvent.ID

    var body: some View {
        AppPalette.background.color
            .ignoresSafeArea()
            .navigationTitle("予定")
            .navigationBarTitleDisplayMode(.inline)
    }
}
