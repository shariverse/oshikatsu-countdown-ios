//
//  AppearanceIconSettings.swift
//  OshiCon
//

import SwiftUI

/// 着せ替えの画面（`AppearanceSettingsScreen`）の「アイコン」のタブの中身。設定のトレー（`AppearanceEditorTray`）に置く。
///
/// 推し色の 12 色のアイコンを 6 列の格子に並べ、押した色を選ぶ（`AppearanceStore.appIconColor`）。
/// Plus でなくても選べ、上の見本（`AppearanceIconPreview`）に映る。ホーム画面のアイコンを替えるのは Plus のときだけ（`AppIconSynchronizer`）。
struct AppearanceIconSettings: View {
    @Environment(AppearanceStore.self) private var store
    @Environment(AppIconSynchronizer.self) private var synchronizer: AppIconSynchronizer?
    @Environment(\.appTheme) private var theme

    /// 格子の列の数。
    private static let columnCount = 6
    /// アイコンの一辺の上限（pt）。広いトレー（iPad）でも大きくしすぎない。
    private static let maximumIconSide: CGFloat = 64

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(maximum: Self.maximumIconSide), spacing: 12), count: Self.columnCount),
                alignment: .leading,
                spacing: 14
            ) {
                ForEach(OshiColor.allCases, id: \.self) { color in
                    AppIconChoice(color: color, isSelected: store.appIconColor == color) {
                        store.appIconColor = color
                    }
                }
            }
            // 選んでいるアイコンの輪（外に 4.5pt はみ出す）を切らない
            .padding(.vertical, 4)
            Text("ホーム画面のアイコンを、推し色の 12 色から選べます。ライトとダークの外観のどちらにも合わせます")
                .font(theme.typography.text(.footnote))
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
        }
        .appIconUITestMarker(synchronizer?.currentColor)
    }
}

/// 「アイコン」のタブの 1 色分。押すとその色を選ぶ。選んでいる色はアクセントの輪で囲む。
private struct AppIconChoice: View {
    let color: OshiColor
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.appTheme) private var theme
    @Environment(\.locale) private var locale

    /// 輪とアイコンの間（pt）。
    private static let ringGap: CGFloat = 2
    /// 輪の太さ（pt）。
    private static let ringWidth: CGFloat = 2.5

    var body: some View {
        Button(action: action) {
            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height)
                AppIconImage(color: color, isDark: false, side: side)
                    .overlay {
                        if isSelected {
                            let outset = Self.ringGap + Self.ringWidth
                            RoundedRectangle(cornerRadius: side * AppIconImage.cornerRadiusFraction + outset, style: .continuous)
                                .strokeBorder(theme.palette.brand.color, lineWidth: Self.ringWidth)
                                .padding(-outset)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: color.label(locale: locale)))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("appearance.icon.\(color.rawValue)")
    }
}

/// 「アイコン」のタブを開いている間、ホーム・予定の詳細・シェアの見本の代わりに置く見本の舞台。
///
/// 選んでいる色のアイコンを大きく（ライトの外観）、その下にホーム画面の表示名、ライトとダークの外観のアイコンを小さく並べる。
/// 大きさは舞台の大きさ（`AppIconPreviewMetrics`）で決め、ほかの見本と同じ場所（`AppearancePreviewLayout`）に置く。
struct AppearanceIconPreview: View {
    let layout: AppearancePreviewLayout

    @Environment(AppearanceStore.self) private var store
    @Environment(\.appTheme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isSide = layout.arrangement == .sideBySide
        let color = store.appIconColor
        GeometryReader { proxy in
            let metrics = AppIconPreviewMetrics(size: proxy.size, isAccessibilitySize: dynamicTypeSize.isAccessibilitySize)
            VStack(spacing: 0) {
                AppIconImage(color: color, isDark: false, side: metrics.largeSide)
                    .shadow(color: .black.opacity(0.35), radius: metrics.largeSide * 0.13, y: metrics.largeSide * 0.1)
                Text(verbatim: Self.displayName)
                    // ホーム画面のアイコンの名前に合わせ、テーマの書体ではなくシステムの書体にする
                    .font(.footnote)
                    .foregroundStyle(theme.palette.onSurface.color)
                    .lineLimit(1)
                    .padding(.top, AppIconPreviewMetrics.nameSpacing)
                HStack(spacing: AppIconPreviewMetrics.smallSpacing) {
                    appearanceSample(color: color, isDark: false, side: metrics.smallSide)
                    appearanceSample(color: color, isDark: true, side: metrics.smallSide)
                }
                .padding(.top, AppIconPreviewMetrics.samplesSpacing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(.vertical, AppearancePreviewLayout.verticalPadding)
        .padding(.horizontal, AppearancePreviewLayout.horizontalPadding)
        // ほかの見本と同じ大きさの場所に置き、タブを替えてもトレーの高さを変えない
        .frame(width: isSide ? layout.stageWidth : nil, height: isSide ? nil : layout.stageHeight)
        .frame(maxWidth: isSide ? nil : .infinity, maxHeight: isSide ? .infinity : nil)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("アイコンの見本"))
        .accessibilityValue(Text(verbatim: color.label(locale: locale)))
        .accessibilityIdentifier("appearance.icon.preview")
    }

    private func appearanceSample(color: OshiColor, isDark: Bool, side: CGFloat) -> some View {
        VStack(spacing: AppIconPreviewMetrics.sampleLabelSpacing) {
            AppIconImage(color: color, isDark: isDark, side: side)
            Text(isDark ? "ダーク" : "ライト")
                .font(theme.typography.text(.caption2))
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
                .lineLimit(1)
        }
    }

    /// ホーム画面に出るアプリの名前（言語ごとの `CFBundleDisplayName`。日本語は「推し活カウント」）。
    private static var displayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? ""
    }
}

/// 「アイコン」のタブの見本の大きさ。舞台の大きさ（余白を除く）に、大きいアイコン・名前・小さい 2 つのアイコンと見出しを収める。
nonisolated struct AppIconPreviewMetrics: Equatable, Sendable {
    /// 大きいアイコンの一辺の上限（pt。デザインの大きさ）。
    static let maximumLargeSide: CGFloat = 132
    /// 大きいアイコンの一辺の下限（pt）。とても小さい舞台でも見分けられる大きさ。
    static let minimumLargeSide: CGFloat = 48
    /// 小さいアイコンの、大きいアイコンに対する割合（デザインの 60pt / 132pt）。
    static let smallFraction: CGFloat = 60.0 / 132.0
    /// 大きいアイコンと名前の間（pt）。
    static let nameSpacing: CGFloat = 8
    /// 名前と小さいアイコンの間（pt）。
    static let samplesSpacing: CGFloat = 22
    /// 小さいアイコンどうしの間（pt）。
    static let smallSpacing: CGFloat = 28
    /// 小さいアイコンと見出しの間（pt）。
    static let sampleLabelSpacing: CGFloat = 6
    /// 名前と見出しの文字に空ける高さ（pt）。
    static let textHeight: CGFloat = 36
    /// アクセシビリティの大きな文字のときの `textHeight`（文字は `accessibility1` まで大きくする）。
    static let accessibilityTextHeight: CGFloat = 64

    let largeSide: CGFloat
    let smallSide: CGFloat

    /// 舞台の大きさ `size`（余白を除く）と、アクセシビリティの大きな文字か `isAccessibilitySize` から決める。
    init(size: CGSize, isAccessibilitySize: Bool) {
        let width = size.width.isFinite ? max(size.width, 0) : 0
        let height = size.height.isFinite ? max(size.height, 0) : 0
        let text = isAccessibilitySize ? Self.accessibilityTextHeight : Self.textHeight
        let fixed = Self.nameSpacing + Self.samplesSpacing + Self.sampleLabelSpacing + text
        // 縦: 大きいアイコン + 小さいアイコン + 間と文字。横: 大きいアイコンと、小さいアイコン 2 つと間
        let byHeight = (height - fixed) / (1 + Self.smallFraction)
        let byWidth = min(width, (width - Self.smallSpacing) / (2 * Self.smallFraction))
        let side = min(Self.maximumLargeSide, byHeight, byWidth)
        largeSide = max(side, Self.minimumLargeSide)
        smallSide = largeSide * Self.smallFraction
    }
}

extension View {
    /// ホーム画面に出ているアイコンの色を UI テストから読む口を置く（メモリ上のストアのときだけ。`AppIconSynchronizer`）。
    /// 値は `OshiColor` の生の値（訳さない）。メモリ上のストアではシステムの API を呼ばないので、UI テストはこの口で確かめる。
    func appIconUITestMarker(_ color: OshiColor?, isEnabled: Bool = LaunchOptions.usesInMemoryStore) -> some View {
        overlay(alignment: .topLeading) {
            if isEnabled, let color {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: color.rawValue))
                    .accessibilityIdentifier("appearance.icon.homeScreen")
                    .allowsHitTesting(false)
            }
        }
    }
}

#Preview("アイコンのタブ") {
    ScrollView {
        AppearanceIconSettings()
            .padding()
    }
    .environment(AppearanceStore.volatile(
        suiteName: "jp.shilokuma.OshiCon.PreviewAppearance",
        directory: FileManager.default.temporaryDirectory.appending(path: "PreviewAppearancePhotos", directoryHint: .isDirectory)
    ))
}

#Preview("アイコンの見本") {
    AppearanceIconPreview(layout: AppearancePreviewLayout(containerSize: CGSize(width: 402, height: 734), isAccessibilitySize: false))
        .environment(AppearanceStore.volatile(
            suiteName: "jp.shilokuma.OshiCon.PreviewAppearance",
            directory: FileManager.default.temporaryDirectory.appending(path: "PreviewAppearancePhotos", directoryHint: .isDirectory)
        ))
}
