//
//  AppearanceBackgroundSettings.swift
//  OshiCon
//

import PhotosUI
import SwiftUI

/// 着せ替えの画面（`AppearanceSettingsScreen`）の「背景」のタブの中身。設定のトレー（`AppearanceEditorTray`）に置く。
///
/// - 背景の ON/OFF、写真を選ぶ・変える・外す（`PhotosPicker` → 縦長の枠の調整画面 `PhotoCropScreen`）、暗幕の濃さとぼかしの強さ（スライダー）
/// - 写真は「共通」と推しごとに選べる。推しがいれば、共通と推しの枠（選んだ写真の小さな見本と名前）を横に並べ、選んだ枠の写真を選ぶ・変える・外す。
///   暗幕とぼかしは全体で 1 つ。選んだ枠は見本にも映す（推しを選ぶと、見本のホームをその推しで絞り込む）
/// - 写真を選び直したら背景を ON にする。背景が OFF のときもスライダーの値は見せ、押せなくする
/// - Plus でない人も写真と設定を保存できる（`AppearanceStore`）
///
/// UI テストでは、起動引数 `-useTestPhoto`（`LaunchOptions.usesTestPhoto`）で `PhotosPicker` の代わりに生成した画像を選ぶボタンにする。
struct AppearanceBackgroundSettings: View {
    /// 登録した推し（推しの並び）。推しがいなければ、共通の写真だけを選ぶ（枠を並べない）。
    let oshis: [Oshi]
    /// 写真を選ぶ推し（共通なら nil）。
    @Binding var target: Oshi.ID?

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

    /// 選んでいる枠（共通か推し）に写真があるか。
    private var hasPhoto: Bool {
        store.settings.backgroundPhotoFileName(for: target) != nil
    }

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $store.isBackgroundEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("背景に写真を敷く")
                    if !oshis.isEmpty {
                        Text("推しごとに選べます")
                            .font(theme.typography.text(.footnote))
                            .foregroundStyle(theme.palette.onSurfaceVariant.color)
                    }
                }
            }
            .accessibilityIdentifier("appearance.backgroundToggle")
            if !oshis.isEmpty {
                targetPicker
            }
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
            if !oshis.isEmpty {
                Group {
                    if target == nil {
                        Text("共通の写真は、推しで絞り込んでいないホームと、写真を選んでいない推しの画面に敷きます")
                    } else {
                        Text("この推しで絞り込んだホームと、この推しの予定の詳細・シェアのカードに敷きます。選んでいなければ、共通の写真を敷きます")
                    }
                }
                .font(theme.typography.text(.footnote))
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
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
            // 読んでいる間は枠を替えられないので、選んだときの枠に取り込む
            let oshiID = target
            await load(data: try? await selectedItem.loadTransferable(type: Data.self), for: oshiID)
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
                        await apply(pending.data, crop: crop, for: pending.oshiID)
                    }
                }
            )
        }
    }

    // MARK: - 写真を選ぶ枠（共通・推しごと）

    /// 共通と推しの枠を横に並べる。押した枠の写真を選ぶ・変える・外す。写真を読んでいる・取り込んでいる間は替えられない。
    private var targetPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 8) {
                AppearanceBackgroundTargetChip(
                    title: Text("共通"),
                    fileName: store.settings.backgroundPhotoFileName,
                    photos: store.photos,
                    isSelected: target == nil,
                    identifier: "appearance.backgroundTarget.common"
                ) {
                    select(nil)
                }
                ForEach(Array(oshis.enumerated()), id: \.element.id) { index, oshi in
                    AppearanceBackgroundTargetChip(
                        title: Text(verbatim: oshi.name),
                        fileName: store.settings.oshiBackgroundPhotoFileNames[oshi.id],
                        photos: store.photos,
                        isSelected: target == oshi.id,
                        identifier: "appearance.backgroundTarget.\(index)"
                    ) {
                        select(oshi.id)
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .disabled(isLoading)
    }

    private func select(_ oshiID: Oshi.ID?) {
        failure = nil
        target = oshiID
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
                    let oshiID = target
                    Task {
                        await load(data: PhotoCropPreviewImage.pngData(), for: oshiID)
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
                store.removeBackgroundPhoto(for: target)
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
    /// `oshiID` は取り込む枠（共通なら nil）。
    private func load(data: Data?, for oshiID: Oshi.ID?) async {
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
        cropping = PendingBackgroundCrop(data: data, source: source, oshiID: oshiID)
    }

    /// 調整画面の「完了」。縦長に切り抜いて取り込み、枠 `oshiID`（共通なら nil）の背景の写真を差し替える（前の写真は消える）。
    /// 選び直した写真がすぐ見本に映るよう、背景を OFF にしていたら ON にする。
    private func apply(_ data: Data, crop: PhotoCrop, for oshiID: Oshi.ID?) async {
        // 取り込んでいる間にタブを替えても（この View が外れても）設定を書けるよう、先にストアを引いておく
        let store = store
        failure = nil
        defer {
            isLoading = false
        }
        do {
            guard try await store.replaceBackgroundPhoto(data, crop: crop, for: oshiID) else {
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
    /// 取り込む枠（共通なら nil）。
    let oshiID: Oshi.ID?
}

/// 「背景」の写真を選ぶ枠の 1 つ（共通か推し）。選んだ写真の小さな見本（無ければ ＋）の下に名前を置き、押すとその枠を選ぶ。
///
/// 選んでいる枠はアクセントの色の線と太字にする。読み上げでは名前と、写真があるか（`背景の写真あり`・`背景の写真なし`）を伝える。
private struct AppearanceBackgroundTargetChip: View {
    let title: Text
    /// 選んだ写真のファイル名。無ければ nil。
    let fileName: String?
    /// 背景の写真の置き場所（`AppearanceStore.photos`）。
    let photos: OshiPhotoLibrary
    let isSelected: Bool
    let identifier: String
    let action: () -> Void

    @Environment(\.appTheme) private var theme
    @Environment(\.displayScale) private var displayScale
    @Environment(\.isEnabled) private var isEnabled
    /// 枠の幅（pt）。文字の大きさの設定に合わせて広げる。長い名前は 1 行に切り詰める。
    @ScaledMetric(relativeTo: .caption) private var width: CGFloat = 64
    /// 写真の小さな見本の高さ（pt）。
    @ScaledMetric(relativeTo: .caption) private var boxHeight: CGFloat = 48
    @State private var thumbnail: CGImage?

    private static let cornerRadius: CGFloat = 12

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                box
                title
                    .font(theme.typography.text(.caption, weight: isSelected ? .bold : .regular))
                    .foregroundStyle((isSelected ? theme.palette.brand : theme.palette.onSurfaceVariant).color)
                    .lineLimit(1)
            }
            .frame(width: width)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(fileName == nil ? Text("背景の写真なし") : Text("背景の写真あり"))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier(identifier)
        // 写真を差し替えたら読み直す。縦長の写真を枠の幅で覆う大きさに縮めて読む
        .task(id: fileName) {
            guard let fileName else {
                thumbnail = nil
                return
            }
            let pixels = Int((width / PhotoCrop.backgroundAspectRatio * displayScale).rounded(.up))
            let image = await photos.loadImage(fileName: fileName, maxPixelLength: max(pixels, 1))
            guard !Task.isCancelled else {
                return
            }
            thumbnail = image
        }
    }

    private var box: some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius)
        return shape
            .fill(theme.palette.surfaceContainer.color)
            .overlay {
                if fileName != nil, let thumbnail {
                    Image(decorative: thumbnail, scale: 1)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                }
            }
            .frame(width: width, height: boxHeight)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    (isSelected ? theme.palette.brand : theme.palette.outlineVariant).color,
                    lineWidth: isSelected ? 2 : 1
                )
            }
    }
}

#Preview("背景") {
    @Previewable @State var target: Oshi.ID?
    AppearanceBackgroundSettings(oshis: [Oshi(name: "ミナト", color: .navy), Oshi(name: "LUMINA", color: .pink)], target: $target)
        .padding()
        .environment(AppearanceStore.volatile(
            suiteName: "jp.shilokuma.OshiCon.PreviewAppearance",
            directory: FileManager.default.temporaryDirectory.appending(path: "PreviewAppearancePhotos", directoryHint: .isDirectory)
        ))
}
