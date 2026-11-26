//
//  AppearancePreviewStage.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// 着せ替えの画面で、設定のトレーの外に置く見本の舞台。上のまん中か、左の列（`AppearancePreviewLayout`）。
///
/// 見本（ホーム・予定の詳細・シェアのカード。`AppearancePreviewCarousel`）と、その下の切り替えと「全画面」の行（`AppearancePreviewControls`）を並べる。
/// 選んだ写真と設定を、Plus によらずその場で見本に映す（試着）。設定を変えている間もスクロールで流れないよう、トレーには入れない。
struct AppearancePreviewStage: View {
    let layout: AppearancePreviewLayout
    /// 登録した推し（推しの並び）。見本の推しと飾りに使う。
    let oshis: [Oshi]
    /// 「背景」で選んでいる推し（共通なら nil）。ホームの見本をその推しで絞り込み、予定の詳細とシェアのカードの見本にその推しの予定を出す。
    var backgroundOshiID: Oshi.ID?
    /// 映している見本。
    @Binding var kind: AppearancePreview.Kind
    /// 「全画面」を押したとき。nil なら「全画面」を出さない。
    var onFullScreen: (() -> Void)?

    @Environment(AppearanceStore.self) private var store
    @Query private var storedEvents: [StoredEvent]

    var body: some View {
        let isSide = layout.arrangement == .sideBySide
        VStack(spacing: AppearancePreviewLayout.controlsSpacing) {
            // 開いたまま日付が変わっても数え直せるよう、ホームと同じく 1 分ごと（分の変わり目）に今日を確かめる
            TimelineView(.everyMinute) { context in
                AppearancePreviewCarousel(
                    layout: layout,
                    kind: $kind,
                    settings: store.settings,
                    content: content(now: context.date),
                    now: context.date,
                    decorationOshis: oshis,
                    photos: store.photos
                )
            }
            AppearancePreviewControls(kind: $kind, onFullScreen: onFullScreen)
                .frame(height: layout.controlsHeight)
                .padding(.horizontal, AppearancePreviewLayout.horizontalPadding)
        }
        .padding(.vertical, AppearancePreviewLayout.verticalPadding)
        .frame(width: isSide ? layout.stageWidth : nil)
        .frame(maxWidth: isSide ? nil : .infinity, maxHeight: isSide ? .infinity : nil, alignment: .top)
        // 左の列では、となりの見本を設定の上にはみ出させない
        .clipped()
    }

    private func content(now: Date) -> HomeContent {
        AppearancePreview.content(
            events: storedEvents.compactMap(OshiConStore.event(from:)),
            oshis: oshis,
            selectedOshiID: backgroundOshiID,
            // 端末のタイムゾーンを変えたときも、その日付で数える
            today: CalendarDay(now, calendar: .autoupdatingCurrent),
            now: now
        )
    }
}

/// 見本を横に並べ、横のスワイプで送る。まん中の見本を大きく見せ、となりの見本は薄く小さくのぞかせる。
///
/// 見本は押せず（中の予定や絞り込みは反応しない）、読み上げでは 1 つの要素にする（名前は映している見本、値は映しているもの）。
/// 見本を替えるのは、横のスワイプと、下の切り替え（`AppearancePreviewSwitcher`）。
/// どの背景の写真（共通・推しごと）を映すかは、見本ごとに実際の画面と同じ規則で決める（`AppearancePreview.rendering(settings:kind:content:)`）。
struct AppearancePreviewCarousel: View {
    let layout: AppearancePreviewLayout
    @Binding var kind: AppearancePreview.Kind
    /// 着せ替えの設定。Plus によらず、そのまま映す。
    let settings: AppearanceSettings
    let content: HomeContent
    let now: Date
    /// 飾りに使う推し（登録した推し）。
    let decorationOshis: [Oshi]
    /// 背景の写真の置き場所（`AppearanceStore.photos`）。
    let photos: OshiPhotoLibrary

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// となりの見本との間（pt）。
    private static let spacing: CGFloat = 28

    var body: some View {
        // どの見本も、並びの上ではホームの見本と同じ幅にそろえる（どの見本もまん中で止まる）。幅の広いシェアのカードは、その幅からはみ出して描く
        let pageWidth = layout.previewSize.width
        let item = AppearancePreview.featuredItem(of: content)
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: Self.spacing) {
                    ForEach(AppearancePreview.Kind.allCases) { pageKind in
                        page(pageKind, item: item)
                            .frame(width: pageWidth, height: layout.previewSize.height)
                            // 幅の広いシェアのカードが、となりの見本に重ならないようよける
                            .offset(x: layout.carouselOffset(of: pageKind, selected: kind))
                            .animation(reduceMotion ? nil : .snappy, value: kind)
                            .scrollTransition(.interactive, axis: .horizontal) { view, phase in
                                view
                                    .opacity(1 - abs(phase.value) * 0.5)
                                    .scaleEffect(1 - abs(phase.value) * 0.2)
                            }
                            .allowsHitTesting(false)
                            .id(pageKind)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, max((layout.stageWidth - pageWidth) / 2, 0), for: .scrollContent)
            // 速く払っても、となりの見本までで止める（iPad でも 1 枚ずつ送る）
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: position)
            .scrollIndicators(.hidden)
            // 見本の影を上下で切らない（左右は舞台が切る）
            .scrollClipDisabled()
            // 回転・画面の分割で見本の大きさが変わると、スクロールの位置が前の大きさのまま残り、映している見本がまん中からずれる。
            // 新しい並びになってから、映している見本へ送り直す
            .onChange(of: layout) {
                let shown = kind
                Task { @MainActor in
                    if kind != shown {
                        kind = shown
                    }
                    proxy.scrollTo(shown, anchor: .center)
                }
            }
        }
        .frame(height: layout.previewSize.height)
        // 読み上げと UI テストには、見本の並びではなく、見えている範囲に重ねた 1 つの要素を見せる
        // （並びそのものを 1 つの要素にすると、画面の外まで続く並びの幅が要素の大きさになる）
        .accessibilityHidden(true)
        .overlay {
            Color.clear
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: kind.accessibilityLabel()))
                .accessibilityValue(Text(verbatim: AppearancePreview.accessibilityValue(of: rendering(of: kind), kind: kind)))
                .accessibilityHint(Text("選んだ写真と設定を、その場で見本に映します"))
                .accessibilityIdentifier("appearance.preview")
        }
    }

    /// スクロールの位置。スワイプで送ったら映している見本を替え、切り替えで見本を替えたらその見本まで送る。
    private var position: Binding<AppearancePreview.Kind?> {
        Binding {
            kind
        } set: { scrolled in
            if let scrolled, scrolled != kind {
                kind = scrolled
            }
        }
    }

    /// 見本 `pageKind` で描くもの。
    private func rendering(of pageKind: AppearancePreview.Kind) -> AppearanceRendering {
        AppearancePreview.rendering(settings: settings, kind: pageKind, content: content)
    }

    @ViewBuilder
    private func page(_ pageKind: AppearancePreview.Kind, item: HomeContent.Item?) -> some View {
        let pageRendering = rendering(of: pageKind)
        switch pageKind {
        case .home:
            AppearancePhoneFrame(width: layout.previewSize.width) {
                AppearanceHomePreview(rendering: pageRendering, content: content, decorationOshis: decorationOshis, photos: photos)
            }
        case .eventDetail:
            AppearancePhoneFrame(width: layout.previewSize.width) {
                AppearanceDetailPreview(rendering: pageRendering, item: item, decorationOshis: decorationOshis, photos: photos)
            }
        case .share:
            AppearanceSharePreview(rendering: pageRendering, item: item, now: now, photos: photos, side: layout.shareCardSide)
        }
    }
}

/// 見本の下の行。見本の切り替え（ホーム・予定の詳細・シェア）と、全画面の試着を開く「全画面」。
///
/// 幅に収まらないとき（長い訳・大きな文字・左の細い列）は、「全画面」を記号だけにし、それでも収まらなければ切り替えも記号にする。
/// バーの中の文字と同じく大きくしすぎず、長押しで大きく表示できるようにする。
struct AppearancePreviewControls: View {
    @Binding var kind: AppearancePreview.Kind
    /// 「全画面」を押したとき。nil なら「全画面」を出さない。
    var onFullScreen: (() -> Void)?

    @Environment(\.appTheme) private var theme

    var body: some View {
        ViewThatFits(in: .horizontal) {
            row(switcher: .titles, showsFullScreenTitle: true)
            row(switcher: .titles, showsFullScreenTitle: false)
            row(switcher: .symbols, showsFullScreenTitle: false)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func row(switcher: AppearancePreviewSwitcher.Content, showsFullScreenTitle: Bool) -> some View {
        HStack(spacing: 8) {
            AppearancePreviewSwitcher(selection: $kind, content: switcher)
            if let onFullScreen {
                fullScreenButton(showsTitle: showsFullScreenTitle, action: onFullScreen)
            }
        }
    }

    private func fullScreenButton(showsTitle: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                if showsTitle {
                    Text("全画面")
                        .lineLimit(1)
                }
            }
            .font(theme.typography.text(.footnote, weight: .bold))
            .foregroundStyle(theme.palette.brand.color)
            .padding(.horizontal, showsTitle ? 14 : 0)
            .frame(minWidth: 44, minHeight: 44)
            .background(theme.palette.surface.color, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(theme.palette.outlineVariant.color)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("全画面")
        .accessibilityIdentifier("appearance.fullScreen")
        .accessibilityShowsLargeContentViewer {
            Label("全画面", systemImage: "arrow.up.left.and.arrow.down.right")
        }
    }
}

/// Preview で使う、空から始める着せ替えの設定（端末の設定と写真の置き場所に触れない）。
private enum AppearancePreviewStagePreview {
    static func store() -> AppearanceStore {
        AppearanceStore.volatile(
            suiteName: "jp.shilokuma.OshiCon.PreviewAppearance",
            directory: FileManager.default.temporaryDirectory.appending(path: "PreviewAppearancePhotos", directoryHint: .isDirectory)
        )
    }
}

#Preview("上に置く") {
    @Previewable @State var kind = AppearancePreview.Kind.home
    AppearancePreviewStage(
        layout: AppearancePreviewLayout(containerSize: CGSize(width: 402, height: 734), isAccessibilitySize: false),
        oshis: [],
        kind: $kind,
        onFullScreen: {}
    )
    .environment(AppearancePreviewStagePreview.store())
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}

#Preview("左の列") {
    @Previewable @State var kind = AppearancePreview.Kind.home
    AppearancePreviewStage(
        layout: AppearancePreviewLayout(containerSize: CGSize(width: 1_000, height: 900), isAccessibilitySize: false),
        oshis: [],
        kind: $kind
    )
    .environment(AppearancePreviewStagePreview.store())
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
