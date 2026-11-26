//
//  AppearanceEditorTray.swift
//  OshiCon
//

import SwiftUI

/// 着せ替えの画面の設定のタブ。
///
/// タブを足すとき（「カード」「アイコン」など）は、ここに case を足し、`AppearanceEditorTray` の `content(of:)` にそのタブの中身を足す。
enum AppearanceEditorTab: String, CaseIterable, Identifiable {
    /// 背景の写真（ON/OFF・写真を選ぶ／変える・外す・暗幕・ぼかし）。
    case background
    /// 飾り（ON/OFF・濃さ・量・出す推し）。
    case decoration
    /// ホーム画面のアプリアイコンの色（推し色の 12 色）。開いている間は、上の見本をアイコンの見本にする（`AppearanceIconPreview`）。
    case icon

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .background:
            "背景"
        case .decoration:
            "飾り"
        case .icon:
            "アイコン"
        }
    }

    /// タブの記号（SF Symbols）。
    var systemImage: String {
        switch self {
        case .background:
            "photo"
        case .decoration:
            "sparkles"
        case .icon:
            "heart.square"
        }
    }
}

/// 着せ替えの画面の設定のトレー。見本の下（上の角を丸める）か、見本の右（`AppearancePreviewLayout`）に置く。
///
/// 上にタブ（「背景」「飾り」「アイコン」）を並べ、その下に選んだタブの設定をスクロールで出す。いちばん下に Plus の案内を添える。
/// 見本はトレーの外にあるので、どの設定を変えているときも見える。選んでいるタブは画面が持つ（タブによって見本を替えるため）。
struct AppearanceEditorTray: View {
    /// 登録した推し（推しの並び）。
    let oshis: [Oshi]
    let arrangement: AppearancePreviewLayout.Arrangement
    /// 「背景」で写真を選ぶ推し（共通なら nil）。見本もこの推しに合わせる。
    @Binding var backgroundOshiID: Oshi.ID?
    /// 選んでいるタブ。
    @Binding var tab: AppearanceEditorTab

    @Environment(\.appTheme) private var theme
    @Environment(\.isPlusUnlocked) private var isPlusUnlocked
    @Environment(\.displayScale) private var displayScale

    /// 見本の下に置くときの、上の角の丸み（pt）。
    private static let cornerRadius: CGFloat = 24
    /// 広い画面でも読みやすい、設定の幅の上限（pt）。
    private static let maximumContentWidth: CGFloat = 640

    var body: some View {
        VStack(spacing: 0) {
            tabs
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)
                .frame(maxWidth: Self.maximumContentWidth)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    content(of: tab)
                    plusNote
                }
                .font(theme.typography.text(.subheadline))
                .foregroundStyle(theme.palette.onSurface.color)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .frame(maxWidth: Self.maximumContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            // タブを替えたら、いちばん上から出す
            .id(tab)
            // UI テストは、見本の外（トレーの設定の上）で指を動かして送る
            .accessibilityIdentifier("appearance.form")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            ground
        }
    }

    /// 選んだタブの設定。
    @ViewBuilder
    private func content(of tab: AppearanceEditorTab) -> some View {
        switch tab {
        case .background:
            AppearanceBackgroundSettings(oshis: oshis, target: $backgroundOshiID)
        case .decoration:
            AppearanceDecorationSettings(oshis: oshis)
        case .icon:
            AppearanceIconSettings()
        }
    }

    // MARK: - タブ

    private var tabs: some View {
        HStack(spacing: 6) {
            ForEach(AppearanceEditorTab.allCases) { item in
                tabButton(item)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func tabButton(_ item: AppearanceEditorTab) -> some View {
        let isSelected = tab == item
        return Button {
            tab = item
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 18))
                    .frame(height: 22)
                Text(item.title)
                    .font(theme.typography.text(.caption, weight: isSelected ? .bold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle((isSelected ? theme.palette.onBrandContainer : theme.palette.onSurfaceVariant).color)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.palette.brandContainer.color)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("appearance.tab.\(item.rawValue)")
        .accessibilityShowsLargeContentViewer {
            Label(item.title, systemImage: item.systemImage)
        }
        // タブの文字は大きくしすぎず、長押しで大きく表示する（中身の設定は文字の大きさに合わせる）
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    // MARK: - Plus の案内

    /// いちばん下に添える Plus の案内。Plus でない人には試着できること、Plus の人には効いていることを伝える。
    /// アプリアイコンは、ホームと予定の詳細ではなくホーム画面に効くので、「アイコン」のタブでは文を替える。
    @ViewBuilder private var plusNote: some View {
        VStack(alignment: .leading, spacing: 2) {
            if isPlusUnlocked {
                if tab == .icon {
                    Text("選んだ色が、ホーム画面のアイコンになります")
                } else {
                    Text("ホームと予定の詳細に、着せ替えが効いています")
                }
            } else {
                Text("着せ替えは Plus で使えます")
                    .font(theme.typography.text(.footnote, weight: .bold))
                    .foregroundStyle(theme.palette.onSurface.color)
                if tab == .icon {
                    Text("Plus でなくても、色を選んで見本で試せます。Plus にすると、ホーム画面のアイコンが替わります")
                } else {
                    Text("Plus でなくても、写真を選んで試着し、保存しておけます。Plus にすると、ホームと予定の詳細に映ります")
                }
            }
        }
        .font(theme.typography.text(.footnote))
        .foregroundStyle(theme.palette.onSurfaceVariant.color)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: - 地

    /// トレーの地。カードの地の色で、見本との境目に細い線を引く。見本の下に置くときは上の角を丸め、下の安全領域の外まで敷く。
    @ViewBuilder private var ground: some View {
        switch arrangement {
        case .pinnedTop:
            let shape = UnevenRoundedRectangle(topLeadingRadius: Self.cornerRadius, topTrailingRadius: Self.cornerRadius)
            shape
                .fill(theme.palette.surface.color)
                .overlay {
                    shape.strokeBorder(theme.palette.outlineVariant.color)
                }
                .shadow(color: .black.opacity(0.18), radius: 12, y: -4)
                // 左右と下の線は画面の外に出す
                .padding(.horizontal, -1)
                .padding(.bottom, -1)
                .ignoresSafeArea(edges: .bottom)
        case .sideBySide:
            theme.palette.surface.color
                .overlay(alignment: .leading) {
                    theme.palette.outlineVariant.color
                        .frame(width: 1 / displayScale)
                }
                .ignoresSafeArea(edges: [.bottom, .trailing])
        }
    }
}

#Preview("トレー（Plus でない）") {
    @Previewable @State var tab = AppearanceEditorTab.background
    AppearanceEditorTray(
        oshis: [Oshi(name: "ミナト", color: .navy), Oshi(name: "LUMINA", color: .pink)],
        arrangement: .pinnedTop,
        backgroundOshiID: .constant(nil),
        tab: $tab
    )
    .frame(height: 320)
    .frame(maxHeight: .infinity, alignment: .bottom)
    .environment(AppearanceStore.volatile(
        suiteName: "jp.shilokuma.OshiCon.PreviewAppearance",
        directory: FileManager.default.temporaryDirectory.appending(path: "PreviewAppearancePhotos", directoryHint: .isDirectory)
    ))
}
