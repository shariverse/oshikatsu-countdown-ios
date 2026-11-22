//
//  RootView.swift
//  OshiCon
//

import SwiftUI

/// 初回の導線を終えるまでは導線を、終えたらタブを出す。ウィジェットのリンクと押された通知の画面を開く。課金画面のシートを受け持つ。
struct RootView: View {
    @AppStorage(AppStorageKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @Environment(AppRouter.self) private var router
    @Environment(ReminderScheduler.self) private var reminders: ReminderScheduler?
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
        // どの画面からでも課金画面を開けるようにする（シートにも下の書体・色・言語が入る）
        .presentsPlusPaywall()
        .font(theme.typography.text(.body))
        .tint(theme.palette.brand.color)
        .environment(\.locale, .app)
        .environment(\.haptic, HapticAction { haptic.fire($0) })
        .hapticFeedback(haptic)
        .onOpenURL(perform: open)
        // 押された通知の画面を開く（押して起動したときは最初から入っている）
        .onChange(of: reminders?.openedLink, initial: true) { _, link in
            guard let link else {
                return
            }
            reminders?.openedLink = nil
            router.open(link, hasCompletedOnboarding: hasCompletedOnboarding)
        }
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
