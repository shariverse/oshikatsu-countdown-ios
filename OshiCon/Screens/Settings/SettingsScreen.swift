//
//  SettingsScreen.swift
//  OshiCon
//

import SwiftUI

/// 設定。Plus（入口を出すときだけ）、終わった予定の表示、通知、データの保存先の説明、バージョンとオープンソースライセンス。
struct SettingsScreen: View {
    @AppStorage(AppStorageKey.showsPastEvents) private var showsPastEvents = false
    @Environment(\.appTheme) private var theme
    @Environment(\.appDistributionDetector) private var distributionDetector
    /// Plus の行を出すか（`PlusEntryPolicy`）。見分け終わるまでは出さない。
    @State private var showsPlusEntry = false

    var body: some View {
        Form {
            if showsPlusEntry {
                PlusSettingsSection()
            }
            Section("表示") {
                Toggle(isOn: $showsPastEvents) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("終わった予定も表示する")
                        Text("ホームの下に、過ぎた予定を新しい順に出します")
                            .font(theme.typography.text(.footnote))
                            .foregroundStyle(theme.palette.onSurfaceVariant.color)
                    }
                }
            }
            .themeRowBackground()
            ReminderSettingsSection()
            Section("データ") {
                VStack(alignment: .leading, spacing: 4) {
                    // iPad では iPad の絵にする
                    Label("この端末の中だけに保存", systemImage: UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone")
                    Text("推し・写真・予定は端末の外に送りません。アプリを削除すると消えます。端末のバックアップ（iCloud・パソコン）には含まれます。")
                    .font(theme.typography.text(.footnote))
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
            }
            .themeRowBackground()
            Section("このアプリについて") {
                LabeledContent("バージョン", value: AppVersion.displayText())
                NavigationLink {
                    OpenSourceLicenseListScreen()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("オープンソースライセンス")
                        Text("このアプリで使っているライブラリとライセンス")
                            .font(theme.typography.text(.footnote))
                            .foregroundStyle(theme.palette.onSurfaceVariant.color)
                    }
                }
            }
            .themeRowBackground()
        }
        .scrollContentBackground(.hidden)
        .background(theme.palette.background.color)
        .navigationTitle("設定")
        .task {
            showsPlusEntry = PlusEntryPolicy.showsEntry(in: await distributionDetector())
        }
    }
}

/// Plus の行。押すと課金画面を開く（`\.openPlusPaywall`）。
private struct PlusSettingsSection: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.isPlusUnlocked) private var isPlusUnlocked
    @Environment(\.openPlusPaywall) private var openPlusPaywall

    var body: some View {
        Section {
            Button {
                openPlusPaywall()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(theme.palette.brand.color)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("推し活カウントダウン Plus")
                            .foregroundStyle(theme.palette.onSurface.color)
                        Group {
                            if isPlusUnlocked {
                                Text("Plus をお使いいただけます")
                            } else {
                                Text("推しの写真ウィジェットと、背景と飾りの着せ替え")
                            }
                        }
                        .font(theme.typography.text(.footnote))
                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .accessibilityIdentifier("settings.plus")
        }
        .themeRowBackground()
    }
}

/// オープンソースライセンスの一覧。行を押すとライセンスの本文を出す。
struct OpenSourceLicenseListScreen: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        List(OpenSourceLicense.all) { license in
            NavigationLink {
                OpenSourceLicenseScreen(license: license)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(license.name)
                        .font(theme.typography.text(.body, weight: .bold))
                    Text("\(license.author) · バージョン \(license.version)")
                        .font(theme.typography.text(.footnote))
                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                    Text(license.licenseName)
                        .font(theme.typography.text(.footnote))
                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
            }
            .themeRowBackground()
        }
        .scrollContentBackground(.hidden)
        .background(theme.palette.background.color)
        .navigationTitle("オープンソースライセンス")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// ライセンスの本文。
struct OpenSourceLicenseScreen: View {
    let license: OpenSourceLicense

    @Environment(\.appTheme) private var theme

    var body: some View {
        ScrollView {
            Text(license.licenseText() ?? String(localized: "ライセンスの本文を読み込めませんでした"))
                // ライセンスの本文は英語なので、本文の書体（日本語）ではなくシステムの書体で出す
                .font(.footnote.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(theme.palette.background.color)
        .navigationTitle(license.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
    }
}

#Preview("App Store 版（Plus の行なし）") {
    NavigationStack {
        SettingsScreen()
    }
    .environment(\.appDistributionDetector, .fixed(.appStore))
}
