//
//  RootView.swift
//  OshiCon
//

import SwiftUI

/// 初回の導線を終えるまでは導線を、終えたらタブを出す。
struct RootView: View {
    @AppStorage(AppStorageKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false

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
