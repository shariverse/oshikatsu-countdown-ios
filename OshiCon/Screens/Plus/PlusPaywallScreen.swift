//
//  PlusPaywallScreen.swift
//  OshiCon
//

import StoreKit
import SwiftUI

/// 推し活カウントダウン Plus の課金画面。
///
/// - 見出し（文と SF Symbols の一覧で Plus の機能）の下に、サブスクリプション（月額・年額。`SubscriptionStoreView`）を出す
/// - その下に買い切りを並べ、いちばん下に購入の復元・利用規約・プライバシーポリシーを置く。
///   復元とリンクはサブスクリプションと買い切りの両方に効くので、`SubscriptionStoreView` の中ではなく画面の下にまとめる
/// - 購入の結果は `PlusStore.process(_:)` に渡す。保留（Ask to Buy）と失敗はアラートで知らせ、取り消しは何も出さない
/// - 自動で更新されるサブスクリプションがある間は、買い切りのそばに「自分で解約が要る」注記を出し、
///   買い切りを買い終えたら同じ旨の案内からサブスクリプションの管理を開ける（`PlusLifetimeGuidance`）
///
/// `NavigationStack` は持たない（開く側が置く）。
struct PlusPaywallScreen: View {
    @Environment(PlusStore.self) private var plus: PlusStore?
    @Environment(\.isPlusUnlocked) private var isPlusUnlocked
    @Environment(\.appTheme) private var theme
    @State private var notice: PlusPaywallNotice?
    @State private var isRestoring = false
    /// サブスクリプション中に買い切りを買い終えたときの案内（`PlusLifetimeGuidance`）。
    @State private var showsLifetimeGuide = false
    @State private var isManagingSubscriptions = false

    var body: some View {
        VStack(spacing: 0) {
            SubscriptionStoreView(productIDs: PlusProduct.subscriptionIDs) {
                PlusPaywallHeader(isUnlocked: isPlusUnlocked)
            }
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.hidden, for: .restorePurchases, .policies)
            .containerBackground(for: .subscriptionStoreFullHeight) {
                ThemeScreenBackground()
            }
            PlusPaywallFooter(
                isRestoring: isRestoring,
                showsLifetimeCaution: plus?.hasRenewingSubscription ?? false
            ) {
                Task {
                    await restore()
                }
            }
        }
        .background(ThemeScreenBackground().ignoresSafeArea())
        .font(theme.typography.text(.body))
        .tint(theme.palette.brand.color)
        .navigationTitle("推し活カウントダウン Plus")
        .navigationBarTitleDisplayMode(.inline)
        .onInAppPurchaseCompletion { product, result in
            await handle(PlusPurchaseOutcome(result), productID: product.id)
        }
        .alert(
            notice?.title ?? "",
            isPresented: Binding { notice != nil } set: { if !$0 { notice = nil } },
            presenting: notice
        ) { _ in
            Button("閉じる", role: .cancel) {}
        } message: { notice in
            Text(notice.message)
        }
        // サブスクリプション中に買い切りを買ったときの案内。サブスクリプションは自動で止まらないので、管理を開けるようにする
        .alert("サブスクリプションの解約をお忘れなく", isPresented: $showsLifetimeGuide) {
            Button("サブスクリプションを管理") {
                isManagingSubscriptions = true
            }
            Button("閉じる", role: .cancel) {}
        } message: {
            Text("買い切りを購入しても、サブスクリプションは自動で止まりません。続けて請求されないよう、ご自身で解約してください。")
        }
        .manageSubscriptionsSheet(isPresented: $isManagingSubscriptions)
    }

    private func handle(_ outcome: PlusPurchaseOutcome, productID: String) async {
        switch outcome {
        case let .purchased(verification):
            await plus?.process(verification)
            var isVerified = false
            if case .verified = verification {
                isVerified = true
            }
            showsLifetimeGuide = PlusLifetimeGuidance.showsGuideAfterPurchase(
                productID: productID,
                isVerified: isVerified,
                hasRenewingSubscription: plus?.hasRenewingSubscription ?? false
            )
        case .pending:
            notice = .pending
        case .cancelled:
            break
        case .failed:
            notice = .purchaseFailed
        }
    }

    /// 購入の復元。App Store と取引を同期し（Apple ID のサインインを求めることがある）、判定し直す。
    private func restore() async {
        isRestoring = true
        defer {
            isRestoring = false
        }
        do {
            try await AppStore.sync()
            await plus?.refresh()
        } catch {
            if case .userCancelled = error as? StoreKitError {
                return
            }
            notice = .restoreFailed
        }
    }
}

/// 課金画面のアラート。
enum PlusPaywallNotice {
    /// 購入の承認を待っている（Ask to Buy など）。
    case pending
    case purchaseFailed
    case restoreFailed

    var title: LocalizedStringKey {
        switch self {
        case .pending:
            "購入の承認を待っています"
        case .purchaseFailed:
            "購入できませんでした"
        case .restoreFailed:
            "購入を復元できませんでした"
        }
    }

    var message: LocalizedStringKey {
        switch self {
        case .pending:
            "承認されると、Plus が使えるようになります。"
        case .purchaseFailed, .restoreFailed:
            "時間をおいて、もう一度お試しください。"
        }
    }
}

/// 見出し。Plus の機能を文と SF Symbols の一覧で示す（画像の素材は使わない）。
private struct PlusPaywallHeader: View {
    let isUnlocked: Bool

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            Text("推し活カウントダウン Plus")
                .font(theme.typography.text(.title2, weight: .bold))
                .foregroundStyle(theme.palette.onSurface.color)
                .multilineTextAlignment(.center)
                .themeHeadingOrnament()
                .accessibilityAddTraits(.isHeader)
            Text("推しの写真で、ホーム画面とアプリをもっと自分らしく。")
                .font(theme.typography.text(.subheadline))
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
                .multilineTextAlignment(.center)
            if isUnlocked {
                Label("Plus をお使いいただけます", systemImage: "checkmark.seal.fill")
                    .font(theme.typography.text(.subheadline, weight: .bold))
                    .foregroundStyle(theme.palette.onBrandContainer.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(theme.palette.brandContainer.color, in: Capsule())
                    .accessibilityIdentifier("plusPaywall.unlocked")
            }
            VStack(alignment: .leading, spacing: 16) {
                PlusFeatureRow(
                    systemImage: "photo.on.rectangle.angled",
                    title: "推しの写真ウィジェット",
                    detail: "ホーム画面に、推しの写真とカウントダウンを置けます"
                )
                PlusFeatureRow(
                    systemImage: "paintpalette",
                    title: "背景と飾りの着せ替え",
                    detail: "アプリの背景や飾りを、推しの写真で着せ替えられます"
                )
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.palette.surface.color, in: RoundedRectangle(cornerRadius: theme.shape.section))
            .themeCardBorder(RoundedRectangle(cornerRadius: theme.shape.section))
            Text("数える・ウィジェット・通知などの今ある機能は、これまでどおり無料で使えます")
                .font(theme.typography.text(.footnote))
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: PlusPaywallLayout.maxContentWidth)
        .frame(maxWidth: .infinity)
    }
}

/// Plus の機能 1 つ。
private struct PlusFeatureRow: View {
    let systemImage: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(theme.palette.brand.color)
                .frame(minWidth: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.typography.text(.body, weight: .bold))
                    .foregroundStyle(theme.palette.onSurface.color)
                Text(detail)
                    .font(theme.typography.text(.subheadline))
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// サブスクリプションの下。買い切りと、購入の復元・利用規約・プライバシーポリシー。
private struct PlusPaywallFooter: View {
    let isRestoring: Bool
    /// 自動で更新されるサブスクリプションがある間、買い切りのそばに解約が自分で要る旨を出す。
    let showsLifetimeCaution: Bool
    let restore: () -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("買い切り")
                .font(theme.typography.text(.headline, weight: .bold))
                .foregroundStyle(theme.palette.onSurface.color)
                .accessibilityAddTraits(.isHeader)
            ProductView(id: PlusProduct.lifetime.rawValue) {
                Image(systemName: "infinity")
                    .font(.title2)
                    .foregroundStyle(theme.palette.brand.color)
                    .accessibilityHidden(true)
            }
            .productViewStyle(.compact)
            .accessibilityIdentifier("plusPaywall.lifetime")
            Text("一度の購入で、今後足す Plus の機能もずっと使えます")
                .font(theme.typography.text(.footnote))
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
            if showsLifetimeCaution {
                Label {
                    Text("サブスクリプション中に買い切りを購入しても、サブスクリプションは自動で止まりません。購入後に、ご自身で解約してください。")
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(theme.palette.brand.color)
                        .accessibilityHidden(true)
                }
                .font(theme.typography.text(.footnote, weight: .bold))
                .foregroundStyle(theme.palette.onSurface.color)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("plusPaywall.lifetimeCaution")
            }
            Divider()
            // 大きな文字で横に並ばないときは縦に並べる
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 20) {
                    links
                }
                VStack(spacing: 10) {
                    links
                }
            }
            .font(theme.typography.text(.footnote))
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: PlusPaywallLayout.maxContentWidth)
        .frame(maxWidth: .infinity)
        // 画面の下に固定して置くので、とても大きな文字でもサブスクリプションの場所を潰しきらないよう上限を付ける
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .background(theme.palette.surface.color.ignoresSafeArea(edges: .bottom))
    }

    @ViewBuilder private var links: some View {
        Button("購入を復元", action: restore)
            .disabled(isRestoring)
            .accessibilityIdentifier("plusPaywall.restore")
        Link("利用規約", destination: PlusLegalLink.termsOfUse)
            .accessibilityIdentifier("plusPaywall.terms")
        Link("プライバシーポリシー", destination: PlusLegalLink.privacyPolicy)
            .accessibilityIdentifier("plusPaywall.privacyPolicy")
    }
}

private enum PlusPaywallLayout {
    /// iPad・横向きで、文と買い切りの行が横に伸びすぎない幅。
    static let maxContentWidth: CGFloat = 560
}

#Preview("使えない") {
    NavigationStack {
        PlusPaywallScreen()
    }
    .providesPlusStatus(PlusStore(isActive: false, unlocksWhenInactive: false))
}

#Preview("使える") {
    NavigationStack {
        PlusPaywallScreen()
    }
    .providesPlusStatus(PlusStore(isActive: false, unlocksWhenInactive: true))
}

#Preview("サブスクリプション中") {
    NavigationStack {
        PlusPaywallScreen()
    }
    .providesPlusStatus(PlusStore(isActive: false, unlocksWhenInactive: true, subscribesWhenInactive: true))
}
