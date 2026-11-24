//
//  PlusPaywallPresentation.swift
//  OshiCon
//

import SwiftUI

/// 課金画面を開く操作。`RootView` の `presentsPlusPaywall()` が受け持ち、画面は `@Environment(\.openPlusPaywall)` から呼ぶ。
///
/// 設定画面の Plus の行のほか、Plus の機能（推しの写真ウィジェット・着せ替え）の画面からも、どこからでも同じシートで開く。
struct PlusPaywallAction {
    private let open: () -> Void

    init(_ open: @escaping () -> Void) {
        self.open = open
    }

    func callAsFunction() {
        open()
    }
}

extension EnvironmentValues {
    /// 課金画面を開く操作。`presentsPlusPaywall()` の外（Preview など）では何もしない。
    @Entry var openPlusPaywall = PlusPaywallAction {}
}

/// 課金画面をシートで出す。ウィジェット・通知のリンクで画面を切り替えるときは閉じる（ほかの画面のシートと同じ）。
private struct PlusPaywallPresenter: ViewModifier {
    @State private var isPresented = false
    @Environment(AppRouter.self) private var router

    func body(content: Content) -> some View {
        content
            .environment(\.openPlusPaywall, PlusPaywallAction { isPresented = true })
            // 開いた予定の詳細が課金画面の下に隠れないよう閉じる。課金画面のリンクのときは、閉じてから開き直す（`WidgetLinkReceiver`）
            .onChange(of: router.sheetDismissal) {
                isPresented = false
            }
            .sheet(isPresented: $isPresented) {
                PlusPaywallSheet()
            }
    }
}

/// シートで出す課金画面。閉じるボタンを置く。
struct PlusPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PlusPaywallScreen()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") {
                            dismiss()
                        }
                        .accessibilityIdentifier("plusPaywall.close")
                    }
                }
        }
    }
}

extension View {
    /// `\.openPlusPaywall` で課金画面を開けるようにする。購入の取引をアプリに渡せるよう、`providesPlusStatus(_:)` の内側に付ける。
    func presentsPlusPaywall() -> some View {
        modifier(PlusPaywallPresenter())
    }
}

#Preview {
    PlusPaywallSheet()
        .providesPlusStatus(PlusStore(isActive: false, unlocksWhenInactive: false))
}
