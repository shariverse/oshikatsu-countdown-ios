//
//  AppearanceBackgroundSettings.swift
//  OshiCon
//

import PhotosUI
import SwiftUI

/// 着せ替えの画面（`AppearanceSettingsScreen`）の「背景」のタブの中身。設定のトレー（`AppearanceEditorTray`）に置く。
///
/// - 背景の ON/OFF、写真を選ぶ・変える・外す（`PhotosPicker` → 縦長の枠の調整画面 `PhotoCropScreen`）、暗幕の濃さとぼかしの強さ（スライダー）
/// - 写真を選び直したら背景を ON にする。背景が OFF のときもスライダーの値は見せ、押せなくする
/// - Plus でない人も写真と設定を保存できる（`AppearanceStore`）
///
/// UI テストでは、起動引数 `-useTestPhoto`（`LaunchOptions.usesTestPhoto`）で `PhotosPicker` の代わりに生成した画像を選ぶボタンにする。
struct AppearanceBackgroundSettings: View {
    @Environment(AppearanceStore.self) private var store
    @Environment(\.appTheme) private var theme
    @Environment(\.displayScale) private var displayScale

    @State private var selectedItem: PhotosPickerItem?
    /// 写真を読んでいる・取り込んでいる間は true（続けて選ばせない）。
    @State private var isLoading = false
    @State private var failure: Failure?
    /// 調整画面で調整中の写真。nil なら調整画面を出していない。
    @State private var cropping: PendingBackgroundCrop?

    /// 調整画面で描く写真の長辺の上限（画素）。パノラマなどで大きくなりすぎないようにする。
    private let cropDisplayMaxLongSide = 4_096

    private enum Failure {
        /// 選んだ写真を読めなかった。
        case load
        /// 取り込んだ写真を保存できなかった。
        case save
    }

    private var hasPhoto: Bool {
        store.settings.backgroundPhotoFileName != nil
    }

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 14) {
            Toggle("背景に写真を敷く", isOn: $store.isBackgroundEnabled)
                .accessibilityIdentifier("appearance.backgroundToggle")
            photoButtons
            if let failure {
                Group {
                    switch failure {
                    case .load:
                        Text("写真を読み込めませんでした")
                    case .save:
                        Text("保存できませんでした")
                    }
                }
                .font(theme.typography.text(.footnote))
                .foregroundStyle(theme.palette.destructive.color)
            }
            Group {
                AppearanceSlider(
                    title: "暗幕の濃さ",
                    value: $store.backgroundScrim,
                    range: AppearanceBackgroundStyle.scrimRange,
                    minimumLabel: "薄い",
                    maximumLabel: "濃い",
                    identifier: "appearance.backgroundScrim"
                )
                AppearanceSlider(
                    title: "ぼかしの強さ",
                    value: $store.backgroundBlur,
                    range: AppearanceBackgroundStyle.blurRange,
                    minimumLabel: "なし",
                    maximumLabel: "強い",
                    identifier: "appearance.backgroundBlur"
                )
            }
            // 背景が OFF でも値は残し、見せておく（ON にしたときの見た目が分かるように）
            .disabled(!store.isBackgroundEnabled)
            Text("ホームと予定の詳細の地に、暗幕とぼかしを掛けて敷きます。暗幕を薄く、ぼかしを弱くするほど、写真がはっきり見えます")
                .font(theme.typography.text(.footnote))
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
        }
        .task(id: selectedItem) {
            guard let selectedItem else {
                return
            }
            isLoading = true
            await load(data: try? await selectedItem.loadTransferable(type: Data.self))
            // 選んだ写真を戻し、読み込めなかった同じ写真をもう一度選んでも読み直せるようにする
            self.selectedItem = nil
        }
        .fullScreenCover(item: $cropping) { pending in
            PhotoCropScreen(
                image: pending.source.image,
                initialCrop: pending.source.initialCrop(aspectRatio: PhotoCrop.backgroundAspectRatio),
                shape: .roundedRectangle,
                onCancel: {
                    cropping = nil
                },
                onDone: { crop in
                    cropping = nil
                    // Task が動き出す前に立て、閉じるアニメーションの間に選び直させない
                    isLoading = true
                    Task {
                        await apply(pending.data, crop: crop)
                    }
                }
            )
        }
    }

    // MARK: - 写真を選ぶ・外す

    /// 「写真を選ぶ／写真を変える」と「写真を外す」。横に並べて収まらないとき（長い訳・大きな文字）は縦に並べる。
    private var photoButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                selectButton
                removeButton
            }
            VStack(alignment: .leading, spacing: 8) {
                selectButton
                removeButton
            }
        }
    }

    private var selectButton: some View {
        Group {
            if LaunchOptions.usesTestPhoto {
                // UI テストでは、写真ライブラリの代わりに生成した画像を選ぶ
                Button {
                    isLoading = true
                    Task {
                        await load(data: PhotoCropPreviewImage.pngData())
                    }
                } label: {
                    selectButtonLabel
                }
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    selectButtonLabel
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("appearance.selectPhoto")
        .disabled(isLoading)
    }

    private var selectButtonLabel: some View {
        HStack(spacing: 6) {
            if isLoading {
                ProgressView()
            } else {
                Image(systemName: "photo.on.rectangle")
            }
            Text(hasPhoto ? "写真を変える" : "写真を選ぶ")
                .lineLimit(1)
        }
        .font(theme.typography.text(.subheadline, weight: .bold))
        .foregroundStyle(theme.palette.brand.color)
        .modifier(AppearanceTrayButtonShape(borderColor: theme.palette.brand.color))
    }

    @ViewBuilder private var removeButton: some View {
        if hasPhoto {
            Button(role: .destructive) {
                failure = nil
                store.removeBackgroundPhoto()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("写真を外す")
                        .lineLimit(1)
                }
                .font(theme.typography.text(.subheadline))
                .foregroundStyle(theme.palette.destructive.color)
                .modifier(AppearanceTrayButtonShape(borderColor: theme.palette.outlineVariant.color))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("appearance.removePhoto")
            .disabled(isLoading)
        }
    }

    // MARK: - 写真の取り込み

    /// 写真のデータ（選んだ写真、または UI テストで生成した画像）を調整画面で描ける大きさに読み、縦長の枠の調整画面を出す。
    private func load(data: Data?) async {
        isLoading = true
        failure = nil
        defer {
            isLoading = false
        }
        guard let data else {
            failure = .load
            return
        }
        let source = await store.photos.cropSource(
            data: data,
            shortSidePixels: AppearancePreview.cropDisplayShortSidePixels(displayScale: displayScale),
            maxLongSidePixels: cropDisplayMaxLongSide
        )
        // 読んでいる間に画面を離れて（タブを替えて）`.task(id: selectedItem)` が取り消されたら出さない
        guard !Task.isCancelled else {
            return
        }
        guard let source else {
            failure = .load
            return
        }
        cropping = PendingBackgroundCrop(data: data, source: source)
    }

    /// 調整画面の「完了」。縦長に切り抜いて取り込み、背景の写真を差し替える（前の写真は消える）。
    /// 選び直した写真がすぐ見本に映るよう、背景を OFF にしていたら ON にする。
    private func apply(_ data: Data, crop: PhotoCrop) async {
        // 取り込んでいる間にタブを替えても（この View が外れても）設定を書けるよう、先にストアを引いておく
        let store = store
        failure = nil
        defer {
            isLoading = false
        }
        do {
            guard try await store.replaceBackgroundPhoto(data, crop: crop) else {
                failure = .load
                return
            }
            store.isBackgroundEnabled = true
        } catch {
            failure = .save
        }
    }
}

/// 設定のトレーのボタンの形（細い線のカプセル。押せる高さは 44pt）。
struct AppearanceTrayButtonShape: ViewModifier {
    let borderColor: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .overlay {
                Capsule()
                    .strokeBorder(borderColor)
            }
            .contentShape(Capsule())
    }
}

/// 調整画面で調整中の背景の写真。写真ごとに id を変え、調整画面を作り直す。
private struct PendingBackgroundCrop: Identifiable {
    let id = UUID()
    let data: Data
    let source: PhotoCropSource
}

#Preview("背景") {
    AppearanceBackgroundSettings()
        .padding()
        .environment(AppearanceStore.volatile(
            suiteName: "jp.shilokuma.OshiCon.PreviewAppearance",
            directory: FileManager.default.temporaryDirectory.appending(path: "PreviewAppearancePhotos", directoryHint: .isDirectory)
        ))
}
