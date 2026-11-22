//
//  AppearanceSettingsScreen.swift
//  OshiCon
//

import PhotosUI
import SwiftData
import SwiftUI

/// 着せ替え（Plus）の設定。設定画面の「着せ替え」の行から開く。
///
/// - 背景の写真を選ぶ・変える・外す（`PhotosPicker` → 縦長の枠の調整画面 `PhotoCropScreen`）、背景と飾りの ON/OFF、暗幕とぼかしの強さ
/// - ホームの見本（`AppearanceHomePreview`）に、選んだ写真・ON/OFF・強さをその場で映す（Plus でなくても試着できる）
/// - Plus でない人も写真と設定を保存でき（`AppearanceStore`）、案内から課金画面（`\.openPlusPaywall`）を開ける。Plus の人には使えていることを示す
///
/// UI テストでは、起動引数 `-useTestPhoto`（`LaunchOptions.usesTestPhoto`）で `PhotosPicker` の代わりに生成した画像を選ぶボタンにする。
struct AppearanceSettingsScreen: View {
    @Environment(AppearanceStore.self) private var store
    @Environment(\.isPlusUnlocked) private var isPlusUnlocked
    @Environment(\.openPlusPaywall) private var openPlusPaywall
    @Environment(\.appTheme) private var theme
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var storedEvents: [StoredEvent]
    @Query(sort: [SortDescriptor(\StoredOshi.createdAt), SortDescriptor(\StoredOshi.name)])
    private var storedOshis: [StoredOshi]

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
        Form {
            plusSection
            previewSection
            backgroundSection
            decorationSection
        }
        .scrollContentBackground(.hidden)
        .background(theme.palette.background.color)
        .navigationTitle("着せ替え")
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Plus の案内

    @ViewBuilder private var plusSection: some View {
        Section {
            if isPlusUnlocked {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Plus をお使いいただけます")
                        Text("ホームと予定の詳細に、着せ替えが効いています")
                            .font(theme.typography.text(.footnote))
                            .foregroundStyle(theme.palette.onSurfaceVariant.color)
                    }
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(theme.palette.brand.color)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("appearance.plusActive")
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("着せ替えは Plus で使えます")
                        .font(theme.typography.text(.body, weight: .bold))
                    Text("Plus でなくても、写真を選んで試着し、保存しておけます。Plus にすると、ホームと予定の詳細に映ります")
                        .font(theme.typography.text(.footnote))
                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
                Button {
                    openPlusPaywall()
                } label: {
                    Label("Plus で使う", systemImage: "sparkles")
                        .font(theme.typography.text(.body, weight: .bold))
                        .foregroundStyle(theme.palette.brand.color)
                }
                .accessibilityIdentifier("appearance.openPaywall")
            }
        }
        .themeRowBackground()
    }

    // MARK: - 見本

    private var previewSection: some View {
        let now = Date()
        // 端末のタイムゾーンを変えたときも、その日付で数える
        let today = CalendarDay(now, calendar: .autoupdatingCurrent)
        let oshis = storedOshis.map(OshiConStore.oshi(from:))
        let content = AppearancePreview.content(
            events: storedEvents.compactMap(OshiConStore.event(from:)),
            oshis: oshis,
            today: today,
            now: now
        )
        return Section {
            AppearanceHomePreview(
                rendering: AppearancePreview.rendering(settings: store.settings),
                content: content,
                decorationOshis: oshis,
                photos: store.photos
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        } header: {
            Text("見本")
        } footer: {
            Text("選んだ写真と設定を、その場でホームの見本に映します")
        }
        .themeRowBackground()
    }

    // MARK: - 背景の写真

    private var backgroundSection: some View {
        @Bindable var store = store
        return Section {
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
            Toggle("背景に写真を敷く", isOn: $store.isBackgroundEnabled)
                .accessibilityIdentifier("appearance.backgroundToggle")
            intensityPicker(selection: $store.intensity)
        } header: {
            Text("背景の写真")
        } footer: {
            Text("ホームと予定の詳細の地に、暗幕とぼかしを掛けて敷きます。強いほど写真はぼけ、文字が読みやすくなります")
        }
        .themeRowBackground()
    }

    @ViewBuilder private var photoButtons: some View {
        Group {
            if LaunchOptions.usesTestPhoto {
                // UI テストでは、写真ライブラリの代わりに生成した画像を選ぶ
                Button {
                    isLoading = true
                    Task {
                        await load(data: PhotoCropPreviewImage.pngData())
                    }
                } label: {
                    photoButtonLabel
                }
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    photoButtonLabel
                }
            }
        }
        .accessibilityIdentifier("appearance.selectPhoto")
        .disabled(isLoading)
        if hasPhoto {
            Button(role: .destructive) {
                failure = nil
                store.removeBackgroundPhoto()
            } label: {
                Label("写真を外す", systemImage: "trash")
            }
            .accessibilityIdentifier("appearance.removePhoto")
            .disabled(isLoading)
        }
    }

    private var photoButtonLabel: some View {
        HStack(spacing: 8) {
            Label(hasPhoto ? "写真を変える" : "写真を選ぶ", systemImage: "photo.on.rectangle")
            Spacer(minLength: 8)
            if isLoading {
                ProgressView()
            }
        }
    }

    /// 暗幕とぼかしの強さ。アクセシビリティの大きな文字では、分割したボタンに収まらないのでメニューにする。
    @ViewBuilder private func intensityPicker(selection: Binding<AppearanceIntensity>) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker("暗幕とぼかしの強さ", selection: selection) {
                intensityOptions
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("appearance.intensity")
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("暗幕とぼかしの強さ")
                Picker("暗幕とぼかしの強さ", selection: selection) {
                    intensityOptions
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityIdentifier("appearance.intensity")
            }
            .padding(.vertical, 2)
        }
    }

    private var intensityOptions: some View {
        ForEach(AppearanceIntensity.allCases, id: \.self) { intensity in
            Text(intensity.title())
                .tag(intensity)
        }
    }

    // MARK: - 飾り

    private var decorationSection: some View {
        @Bindable var store = store
        return Section("飾り") {
            Toggle(isOn: $store.isDecorationEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("飾りを推しの写真にする")
                    Text("地のハートと十字を、写真を登録した推しの丸い写真に替えます")
                        .font(theme.typography.text(.footnote))
                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                }
            }
            .accessibilityIdentifier("appearance.decorationToggle")
        }
        .themeRowBackground()
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
        // 読んでいる間に画面を離れて `.task(id: selectedItem)` が取り消されたら出さない
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

/// 調整画面で調整中の背景の写真。写真ごとに id を変え、調整画面を作り直す。
private struct PendingBackgroundCrop: Identifiable {
    let id = UUID()
    let data: Data
    let source: PhotoCropSource
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
