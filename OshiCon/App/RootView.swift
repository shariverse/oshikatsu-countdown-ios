//
//  RootView.swift
//  OshiCon
//

import SwiftUI

/// 初回の導線を終えるまでは導線を、終えたらタブを出す。
struct RootView: View {
    @AppStorage(AppStorageKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @Environment(AppRouter.self) private var router
    @Environment(\.appTheme) private var theme
    /// 保存・ピン留めの触覚。保存した画面は直後に閉じたり導線の次の歩に進んだりするので、ずっと残るここで鳴らす。
    @State private var haptic = HapticTrigger()

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
        .font(theme.typography.text(.body))
        .tint(theme.palette.brand.color)
        .environment(\.locale, .app)
        .environment(\.haptic, HapticAction { haptic.fire($0) })
        .hapticFeedback(haptic)
        .onOpenURL(perform: open)
    }

    /// ウィジェットから開いたリンク。知らないリンクは無視する。
    private func open(_ url: URL) {
        guard let link = WidgetLink(url: url) else {
            return
        }
        router.open(link, hasCompletedOnboarding: hasCompletedOnboarding)
    }
}

/// ストアを開けなかったときの画面。
struct StoreUnavailableView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        ContentUnavailableView {
            Label("データを開けませんでした", systemImage: "exclamationmark.triangle")
        } description: {
            Text("アプリを終了して、もう一度開いてください。端末の空き容量が少ないときは、空きを増やしてからお試しください。")
        }
        .font(theme.typography.text(.body))
    }
}

#Preview("ストアを開けない") {
    StoreUnavailableView()
}
