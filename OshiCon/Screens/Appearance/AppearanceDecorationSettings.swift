//
//  AppearanceDecorationSettings.swift
//  OshiCon
//

import SwiftUI

/// 着せ替えの画面（`AppearanceSettingsScreen`）の飾りのまとまり。Form の中に置く。
///
/// - 飾りの ON/OFF と、濃さ・量のスライダー（`OshiPhotoDecorationStyle`）。飾りが OFF のときも値は見せ、押せなくする
/// - 飾りに出す推し（推しごとのスイッチ）。推しがいなければ出さない
struct AppearanceDecorationSettings: View {
    /// 登録した推し（推しの並び）。
    let oshis: [Oshi]

    @Environment(AppearanceStore.self) private var store
    @Environment(\.appTheme) private var theme

    var body: some View {
        decorationSection
        oshisSection
    }

    private var decorationSection: some View {
        @Bindable var store = store
        return Section("飾り") {
            Toggle(isOn: $store.isDecorationEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("飾りを推しの写真にする")
                    Text("地のハートと十字の代わりに、推しの丸い写真を並べます")
                        .font(theme.typography.text(.footnote))
                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                }
            }
            .accessibilityIdentifier("appearance.decorationToggle")
            Group {
                AppearanceSlider(
                    title: "飾りの濃さ",
                    value: $store.decorationOpacity,
                    range: OshiPhotoDecorationStyle.opacityRange,
                    minimumLabel: "薄い",
                    maximumLabel: "濃い",
                    identifier: "appearance.decorationOpacity"
                )
                AppearanceSlider(
                    title: "飾りの量",
                    value: $store.decorationAmount,
                    range: OshiPhotoDecorationStyle.amountRange,
                    minimumLabel: "少なめ",
                    maximumLabel: "埋め尽くす",
                    identifier: "appearance.decorationAmount"
                )
            }
            // 飾りが OFF でも値は残し、見せておく（ON にしたときの見た目が分かるように）
            .disabled(!store.isDecorationEnabled)
        }
        .themeRowBackground()
    }

    /// 飾りに出す推し。登録した推しを推しの並びで出し、推しごとに切り替える。推しがいなければ出さない。
    /// 写真の無い推しも選んでおける（写真を登録すると飾りに出る）。
    @ViewBuilder private var oshisSection: some View {
        if !oshis.isEmpty {
            let existingIDs = Set(oshis.map(\.id))
            Section {
                ForEach(Array(oshis.enumerated()), id: \.element.id) { index, oshi in
                    Toggle(isOn: Binding(
                        get: { store.settings.decorationStyle.includes(oshi) },
                        set: { store.setDecorationIncludes(oshi.id, $0, existingOshiIDs: existingIDs) }
                    )) {
                        HStack(spacing: 12) {
                            OshiPhotoAvatar(oshi: oshi, size: 32)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: oshi.name)
                                if oshi.photoFileName == nil {
                                    Text("写真がありません")
                                        .font(theme.typography.text(.footnote))
                                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                                }
                            }
                        }
                    }
                    .accessibilityIdentifier("appearance.decorationOshi.\(index)")
                }
            } header: {
                Text("飾りに出す推し")
            } footer: {
                Text("選んだ推しのうち、写真を登録した推しを順にくり返して並べます")
            }
            .disabled(!store.isDecorationEnabled)
            .themeRowBackground()
        }
    }
}

#Preview("飾り") {
    Form {
        AppearanceDecorationSettings(oshis: [
            Oshi(name: "ミナト", color: .navy),
            Oshi(name: "LUMINA", color: .pink)
        ])
    }
    .environment(AppearanceStore.volatile(
        suiteName: "jp.shilokuma.OshiCon.PreviewAppearance",
        directory: FileManager.default.temporaryDirectory.appending(path: "PreviewAppearancePhotos", directoryHint: .isDirectory)
    ))
}
