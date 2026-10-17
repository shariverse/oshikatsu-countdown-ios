//
//  SettingsScreen.swift
//  OshiCon
//

import SwiftUI

/// 設定。終わった予定の表示、データの保存先の説明、バージョンとオープンソースライセンス。
struct SettingsScreen: View {
    @AppStorage(AppStorageKey.showsPastEvents) private var showsPastEvents = false

    var body: some View {
        Form {
            Section("表示") {
                Toggle(isOn: $showsPastEvents) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("終わった予定も表示する")
                        Text("ホームの下に、過ぎた予定を新しい順に出します")
                            .font(AppFont.text(.footnote))
                            .foregroundStyle(AppPalette.onSurfaceVariant.color)
                    }
                }
            }
            Section("データ") {
                VStack(alignment: .leading, spacing: 4) {
                    Label("この端末の中だけに保存", systemImage: "iphone")
                    Text(
                        "推し・写真・予定は端末の外に送りません。アプリを削除すると消えます。"
                            + "端末のバックアップ（iCloud・パソコン）には含まれます。"
                    )
                    .font(AppFont.text(.footnote))
                    .foregroundStyle(AppPalette.onSurfaceVariant.color)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
            }
            Section("このアプリについて") {
                LabeledContent("バージョン", value: AppVersion.displayText())
                NavigationLink {
                    OpenSourceLicenseListScreen()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("オープンソースライセンス")
                        Text("このアプリで使っているライブラリとライセンス")
                            .font(AppFont.text(.footnote))
                            .foregroundStyle(AppPalette.onSurfaceVariant.color)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppPalette.background.color)
        .navigationTitle("設定")
    }
}

/// オープンソースライセンスの一覧。行を押すとライセンスの本文を出す。
struct OpenSourceLicenseListScreen: View {
    var body: some View {
        List(OpenSourceLicense.all) { license in
            NavigationLink {
                OpenSourceLicenseScreen(license: license)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(license.name)
                        .font(AppFont.text(.body, weight: .bold))
                    Text("\(license.author) · バージョン \(license.version)")
                        .font(AppFont.text(.footnote))
                        .foregroundStyle(AppPalette.onSurfaceVariant.color)
                    Text(license.licenseName)
                        .font(AppFont.text(.footnote))
                        .foregroundStyle(AppPalette.onSurfaceVariant.color)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppPalette.background.color)
        .navigationTitle("オープンソースライセンス")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// ライセンスの本文。
struct OpenSourceLicenseScreen: View {
    let license: OpenSourceLicense

    var body: some View {
        ScrollView {
            Text(license.licenseText() ?? "ライセンスの本文を読み込めませんでした")
                // ライセンスの本文は英語なので、本文の書体（日本語）ではなくシステムの書体で出す
                .font(.footnote.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(AppPalette.background.color)
        .navigationTitle(license.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
    }
}
