//
//  AppearanceSettingsScreen.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// 着せ替え（Plus）の画面。設定画面の「着せ替え」の行から開く。
///
/// - 見本の舞台（`AppearancePreviewStage`）: ホーム・予定の詳細・シェアのカードの見本を大きく置き、選んだ写真・ON/OFF・暗幕とぼかし・飾りをその場で映す
///   （Plus でなくても試着できる）。見本の下の切り替えと横のスワイプで見本を替え、「全画面」で全画面の試着（`AppearanceTryOnScreen`）を開く
/// - 設定のトレー（`AppearanceEditorTray`）: 「背景」「飾り」「アイコン」のタブに分けた設定。「アイコン」のタブの間は、
///   見本の舞台の代わりにアプリアイコンの見本（`AppearanceIconPreview`）を置く
/// - 見本はスクロールする設定の外に置き、どの設定を変えているときも見えるようにする。幅の狭い画面では見本を上、トレーを下に置き、
///   幅の広い画面では見本を左、トレーを右に並べる（`AppearancePreviewLayout`）
/// - Plus でない人も写真と設定を保存でき（`AppearanceStore`）、バーの「Plus で使う」から課金画面（`\.openPlusPaywall`）を開ける。Plus の人には使えていることを示す
///
/// 見本とトレーに場所を空けるため、開いている間はタブバーを隠す。
struct AppearanceSettingsScreen: View {
    @Environment(\.isPlusUnlocked) private var isPlusUnlocked
    @Environment(\.openPlusPaywall) private var openPlusPaywall
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: OshiConStore.oshiOrder)
    private var storedOshis: [StoredOshi]

    /// 映している見本。全画面の試着と同じものを切り替える。
    @State private var previewKind = AppearancePreview.Kind.home
    /// 「背景」で写真を選ぶ推し（共通なら nil）。見本のホームをその推しで絞り込み、予定の詳細とシェアのカードにその推しの予定を出す。
    @State private var backgroundOshiID: Oshi.ID?
    /// 設定のトレーで選んでいるタブ。
    @State private var editorTab = AppearanceEditorTab.background
    /// 全画面の試着を出しているか。
    @State private var isTryingOn = false
    /// 全画面の試着の「Plus で使う」を押した。全画面が閉じきってから課金画面を開く（重ねて出せないため）。
    @State private var opensPaywallAfterTryOn = false

    var body: some View {
        let oshis = storedOshis.map(OshiConStore.oshi(from:))
        // 選んでいた推しが消えたら共通に戻す
        let backgroundOshiID = HomeContent.validSelection(backgroundOshiID, among: oshis.map(\.id))
        GeometryReader { proxy in
            let layout = AppearancePreviewLayout(containerSize: proxy.size, isAccessibilitySize: dynamicTypeSize.isAccessibilitySize)
            // 回転などで並べ方が変わっても、見本とトレーを作り直さない（スクロールの位置と読んだ写真を保つ）よう、並べ方だけを替える
            let stack = layout.arrangement == .sideBySide
                ? AnyLayout(HStackLayout(spacing: 0))
                : AnyLayout(VStackLayout(spacing: 0))
            stack {
                if editorTab == .icon {
                    // アプリアイコンはホーム・予定の詳細・シェアの見本に映らないので、アイコンの見本にする
                    AppearanceIconPreview(layout: layout)
                } else {
                    AppearancePreviewStage(layout: layout, oshis: oshis, backgroundOshiID: backgroundOshiID, kind: $previewKind) {
                        isTryingOn = true
                    }
                }
                AppearanceEditorTray(oshis: oshis, arrangement: layout.arrangement, backgroundOshiID: $backgroundOshiID, tab: $editorTab)
            }
        }
        .background {
            ThemeScreenBackground()
                .ignoresSafeArea()
        }
        .navigationTitle("着せ替え")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                plusItem
            }
            .hidingSharedBarBackground()
        }
        .fullScreenCover(isPresented: $isTryingOn) {
            // 全画面が閉じきってから課金画面を開く
            if opensPaywallAfterTryOn {
                opensPaywallAfterTryOn = false
                openPlusPaywall()
            }
        } content: {
            AppearanceTryOnScreen(oshis: oshis, backgroundOshiID: backgroundOshiID, kind: $previewKind) {
                opensPaywallAfterTryOn = true
                isTryingOn = false
            }
        }
        // 見本とトレーに場所を空けるため、開いている間はタブバーを隠す
        .hidesTabBar()
    }

    // MARK: - Plus の案内

    /// バーの右の Plus の案内。Plus でない人には課金画面を開く「Plus で使う」、Plus の人には使えていることの印。
    @ViewBuilder private var plusItem: some View {
        if isPlusUnlocked {
            Label {
                // 商品名なので訳さない
                Text(verbatim: "Plus")
            } icon: {
                Image(systemName: "checkmark.seal.fill")
            }
            .labelStyle(.titleAndIcon)
            .font(theme.typography.text(.footnote, weight: .bold))
            .foregroundStyle(theme.palette.brand.color)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Plus をお使いいただけます")
            .accessibilityIdentifier("appearance.plusActive")
        } else {
            Button {
                openPlusPaywall()
            } label: {
                Text("Plus で使う")
                    .font(theme.typography.text(.footnote, weight: .bold))
                    .lineLimit(1)
                    .foregroundStyle(theme.palette.onBrand.color)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 36)
                    .background(theme.palette.brand.color, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("appearance.openPaywall")
        }
    }
}

private extension ToolbarContent {
    /// iOS 26 のバーが項目の後ろに敷くガラスの地を外す（自分で地を描くボタンと、押せない印のため）。それより前の版には地が無い。
    @ToolbarContentBuilder
    func hidingSharedBarBackground() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}

/// Preview で使う、空から始める着せ替えの設定（端末の設定と写真の置き場所に触れない）。
private enum AppearanceSettingsPreview {
    static func store() -> AppearanceStore {
        AppearanceStore.volatile(
            suiteName: "jp.shilokuma.OshiCon.PreviewAppearance",
            directory: FileManager.default.temporaryDirectory.appending(path: "PreviewAppearancePhotos", directoryHint: .isDirectory)
        )
    }
}

#Preview("Plus でない") {
    NavigationStack {
        AppearanceSettingsScreen()
    }
    .environment(AppearanceSettingsPreview.store())
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}

#Preview("Plus（ダーク）") {
    NavigationStack {
        AppearanceSettingsScreen()
    }
    .environment(\.isPlusUnlocked, true)
    .environment(AppearanceSettingsPreview.store())
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
    .preferredColorScheme(.dark)
}

#Preview("大きな文字") {
    NavigationStack {
        AppearanceSettingsScreen()
    }
    .environment(AppearanceSettingsPreview.store())
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
    .dynamicTypeSize(.accessibility3)
}

#Preview("横向き", traits: .landscapeLeft) {
    NavigationStack {
        AppearanceSettingsScreen()
    }
    .environment(AppearanceSettingsPreview.store())
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
