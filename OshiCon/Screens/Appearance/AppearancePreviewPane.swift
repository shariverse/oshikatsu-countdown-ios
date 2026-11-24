//
//  AppearancePreviewPane.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// 着せ替えの画面で、設定（Form）の外に置くホームの見本。上に固定する帯か、左の列（`AppearancePreviewLayout`）。
///
/// 選んだ写真と設定を、Plus によらずその場で見本（`AppearanceHomePreview`）に映す（試着）。
/// 設定を変えている間もスクロールで流れないよう、Form には入れない。
/// 「見本」と説明の文は、上に固定するときは見本の右、左の列では見本の下に置く。
/// 読み上げでは見本を 1 つの要素（名前「ホームの見本」と、映しているものの値）にし、説明の文はそのヒントにする（文は読み上げから外す）。
struct AppearancePreviewPane: View {
    let layout: AppearancePreviewLayout
    /// 登録した推し（推しの並び）。見本の推しと飾りに使う。
    let oshis: [Oshi]

    @Environment(AppearanceStore.self) private var store
    @Environment(\.appTheme) private var theme
    @Query private var storedEvents: [StoredEvent]

    var body: some View {
        let isSide = layout.arrangement == .sideBySide
        // 回転などで並べ方が変わっても見本を作り直さない（読んだ写真を捨てない）よう、同じ View のまま並べ方だけを替える
        let stack = isSide
            ? AnyLayout(VStackLayout(alignment: .center, spacing: AppearancePreviewLayout.sideSpacing))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 16))
        stack {
            preview
            caption
                .frame(
                    maxWidth: .infinity,
                    maxHeight: layout.captionHeight,
                    alignment: isSide ? .topLeading : .leading
                )
        }
        .padding(.horizontal, AppearancePreviewLayout.horizontalPadding)
        .padding(.vertical, AppearancePreviewLayout.verticalPadding)
        .frame(width: isSide ? layout.sideColumnWidth : nil, height: isSide ? nil : layout.pinnedHeight)
        .frame(maxWidth: isSide ? nil : .infinity, maxHeight: isSide ? .infinity : nil, alignment: .top)
    }

    private var preview: some View {
        let now = Date()
        // 端末のタイムゾーンを変えたときも、その日付で数える
        let today = CalendarDay(now, calendar: .autoupdatingCurrent)
        let content = AppearancePreview.content(
            events: storedEvents.compactMap(OshiConStore.event(from:)),
            oshis: oshis,
            today: today,
            now: now
        )
        return AppearanceHomePreview(
            rendering: AppearancePreview.rendering(settings: store.settings),
            content: content,
            decorationOshis: oshis,
            photos: store.photos,
            width: layout.previewSize.width
        )
        .accessibilityHint(Text("選んだ写真と設定を、その場でホームの見本に映します"))
    }

    /// 「見本」と説明の文。決めた高さに収まらない大きな文字は縮めて収め、下の設定を押し下げない。
    private var caption: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("見本")
                .font(theme.typography.text(.subheadline, weight: .bold))
                .foregroundStyle(theme.palette.onSurface.color)
            Text("選んだ写真と設定を、その場でホームの見本に映します")
                .font(theme.typography.text(.footnote))
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
        }
        .minimumScaleFactor(0.5)
        // 見本の名前とヒントで同じことを読むので、読み上げから外す
        .accessibilityHidden(true)
    }
}

/// Preview で使う、空から始める着せ替えの設定（端末の設定と写真の置き場所に触れない）。
private enum AppearancePreviewPanePreview {
    static func store() -> AppearanceStore {
        AppearanceStore.volatile(
            suiteName: "jp.shilokuma.OshiCon.PreviewAppearance",
            directory: FileManager.default.temporaryDirectory.appending(path: "PreviewAppearancePhotos", directoryHint: .isDirectory)
        )
    }
}

#Preview("上に固定") {
    AppearancePreviewPane(
        layout: AppearancePreviewLayout(containerSize: CGSize(width: 390, height: 670), isAccessibilitySize: false),
        oshis: []
    )
    .environment(AppearancePreviewPanePreview.store())
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}

#Preview("左の列") {
    AppearancePreviewPane(
        layout: AppearancePreviewLayout(containerSize: CGSize(width: 1_000, height: 900), isAccessibilitySize: false),
        oshis: []
    )
    .environment(AppearancePreviewPanePreview.store())
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
