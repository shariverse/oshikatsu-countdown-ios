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
        // ウィジェットから開いたリンク。課金画面のリンクで課金画面を開けるよう、`presentsPlusPaywall()` の内側で受ける
        .modifier(WidgetLinkReceiver())
        // どの画面からでも課金画面を開けるようにする（シートにも下の書体・色・言語が入る）
        .presentsPlusPaywall()
        .font(theme.typography.text(.body))
        .tint(theme.palette.brand.color)
        .environment(\.locale, .app)
        .environment(\.haptic, HapticAction { haptic.fire($0) })
        .hapticFeedback(haptic)
        // 押された通知の画面を開く（押して起動したときは最初から入っている）
        .onChange(of: reminders?.openedLink, initial: true) { _, link in
            guard let link else {
                return
            }
            reminders?.openedLink = nil
            router.open(link, hasCompletedOnboarding: hasCompletedOnboarding)
        }
    }
}

/// ウィジェットから開いたリンクを受ける。知らないリンクは無視する。
/// 課金画面のリンク（Plus でない人が推しの写真ウィジェットを押した）は、課金画面の入口を出す配り方（`PlusEntryPolicy`）なら
/// 課金画面を開き、出さない配り方なら今のカウントダウンのウィジェットと同じく予定の詳細に移る。初回の導線の途中なら何も開かない。
private struct WidgetLinkReceiver: ViewModifier {
    /// 課金画面を開くまで待つ時間。ほかの画面のシートが閉じる動きが終わるのを待つ（閉じている途中に出すと出せない）。
    private static let sheetPresentationDelay = Duration.milliseconds(450)

    @AppStorage(AppStorageKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @Environment(AppRouter.self) private var router
    @Environment(\.openPlusPaywall) private var openPlusPaywall
    @Environment(\.appDistributionDetector) private var distributionDetector

    func body(content: Content) -> some View {
        content
            .onOpenURL(perform: open)
    }

    private func open(_ url: URL) {
        guard let link = WidgetLink(url: url) else {
            return
        }
        guard case .plusPaywall = link else {
            router.open(link, hasCompletedOnboarding: hasCompletedOnboarding)
            return
        }
        let hasCompletedOnboarding = hasCompletedOnboarding
        Task {
            let showsPlusPaywall = PlusEntryPolicy.showsEntry(in: await distributionDetector())
            guard router.open(link, hasCompletedOnboarding: hasCompletedOnboarding, showsPlusPaywall: showsPlusPaywall) else {
                return
            }
            try? await Task.sleep(for: Self.sheetPresentationDelay)
            openPlusPaywall()
        }
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
