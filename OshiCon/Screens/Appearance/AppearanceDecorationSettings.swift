//
//  AppearanceDecorationSettings.swift
//  OshiCon
//

import SwiftUI

/// 着せ替えの画面（`AppearanceSettingsScreen`）の「飾り」のタブの中身。設定のトレー（`AppearanceEditorTray`）に置く。
///
/// - 飾りの ON/OFF と、濃さ・量のスライダー（`OshiPhotoDecorationStyle`）。飾りが OFF のときも値は見せ、押せなくする
/// - 飾りに出す推し（推しごとの切り替え。丸い写真と名前を横に並べる）。推しがいなければ出さない
struct AppearanceDecorationSettings: View {
    /// 登録した推し（推しの並び）。
    let oshis: [Oshi]

    @Environment(AppearanceStore.self) private var store
    @Environment(\.appTheme) private var theme

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 14) {
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
                oshiPicker
            }
            // 飾りが OFF でも値は残し、見せておく（ON にしたときの見た目が分かるように）
            .disabled(!store.isDecorationEnabled)
        }
    }

    /// 飾りに出す推し。登録した推しを推しの並びで横に並べ、推しごとに切り替える。推しがいなければ出さない。
    /// 写真の無い推しも選んでおける（写真を登録すると飾りに出る）。
    @ViewBuilder private var oshiPicker: some View {
        if !oshis.isEmpty {
            let existingIDs = Set(oshis.map(\.id))
            VStack(alignment: .leading, spacing: 8) {
                Text("飾りに出す推し")
                    .accessibilityAddTraits(.isHeader)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Array(oshis.enumerated()), id: \.element.id) { index, oshi in
                            AppearanceDecorationOshiChip(
                                oshi: oshi,
                                isOn: Binding(
                                    get: { store.settings.decorationStyle.includes(oshi) },
                                    set: { store.setDecorationIncludes(oshi.id, $0, existingOshiIDs: existingIDs) }
                                ),
                                identifier: "appearance.decorationOshi.\(index)"
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                Text("選んだ推しのうち、写真を登録した推しを順にくり返して並べます")
                    .font(theme.typography.text(.footnote))
                    .foregroundStyle(theme.palette.onSurfaceVariant.color)
            }
        }
    }
}

/// 飾りに出す推しの切り替えの 1 人分。丸い写真（無ければ頭文字）の下に名前を置き、押すと出す・出さないを切り替える。
///
/// 出す推しは推し色の印を付け、出さない推しは薄くする。写真の無い推しには「写真がありません」を添える。
/// 読み上げと UI テストには、名前の付いたスイッチとして見せる。
private struct AppearanceDecorationOshiChip: View {
    let oshi: Oshi
    @Binding var isOn: Bool
    let identifier: String

    @Environment(\.appTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    /// 名前の幅（pt）。長い名前は 1 行に切り詰める。文字の大きさの設定に合わせて広げる。
    @ScaledMetric(relativeTo: .caption) private var labelWidth: CGFloat = 72

    private static let avatarSize: CGFloat = 44

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            VStack(spacing: 4) {
                OshiPhotoAvatar(oshi: oshi, size: Self.avatarSize)
                    .overlay(alignment: .bottomTrailing) {
                        if isOn {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(theme.palette.onBrand.color, theme.palette.brand.color)
                                .offset(x: 3, y: 3)
                        }
                    }
                    .opacity(isOn ? 1 : 0.4)
                Text(verbatim: oshi.name)
                    .font(theme.typography.text(.caption, weight: isOn ? .bold : .regular))
                    .foregroundStyle(theme.palette.onSurface.color)
                    .lineLimit(1)
                if oshi.photoFileName == nil {
                    Text("写真がありません")
                        .font(theme.typography.text(.caption2))
                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: labelWidth)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityRepresentation {
            Toggle(isOn: $isOn) {
                Text(verbatim: oshi.name)
                if oshi.photoFileName == nil {
                    Text("写真がありません")
                }
            }
            .accessibilityIdentifier(identifier)
        }
    }
}

#Preview("飾り") {
    AppearanceDecorationSettings(oshis: [
        Oshi(name: "ミナト", color: .navy),
        Oshi(name: "LUMINA", color: .pink)
    ])
    .padding()
    .environment(AppearanceStore.volatile(
        suiteName: "jp.shilokuma.OshiCon.PreviewAppearance",
        directory: FileManager.default.temporaryDirectory.appending(path: "PreviewAppearancePhotos", directoryHint: .isDirectory)
    ))
}
