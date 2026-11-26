//
//  AppearancePreviewLayoutTests.swift
//  OshiConTests
//

import CoreGraphics
@testable import OshiCon
import Testing

/// 着せ替えの画面で、ホームの見本と設定をどう並べ、見本をどの大きさで見せるか（`AppearancePreviewLayout`）。
///
/// 画面の大きさは、ナビゲーションバーとタブバーを除いた中身の大きさ（端末の大きさから数えたおよその値）。
struct AppearancePreviewLayoutTests {
    /// 縦向きの iPhone の中身の大きさ（SE（第 3 世代）・17e・17 Pro・17 Pro Max）。
    nonisolated static let portraitPhones: [CGSize] = [
        CGSize(width: 375, height: 554),
        CGSize(width: 390, height: 670),
        CGSize(width: 402, height: 685),
        CGSize(width: 440, height: 767)
    ]

    /// 横向きの iPhone（SE（第 3 世代）・17 Pro Max・17 Pro Max でサイドバーを出したとき）と、iPad Pro 13 インチ（横向きでサイドバーあり・縦向き）の中身の大きさ。
    nonisolated static let wideScreens: [CGSize] = [
        CGSize(width: 667, height: 311),
        CGSize(width: 832, height: 387),
        CGSize(width: 512, height: 380),
        CGSize(width: 1_056, height: 938),
        CGSize(width: 1_032, height: 1_270)
    ]

    /// iPad の狭い分割（縦向きの半分・横向きの半分）とスライドオーバー。
    nonisolated static let narrowSplits: [CGSize] = [
        CGSize(width: 507, height: 1_300),
        CGSize(width: 688, height: 1_000),
        CGSize(width: 320, height: 1_000)
    ]

    private func expectAspectRatio(_ layout: AppearancePreviewLayout) {
        let canvas = AppearancePreview.canvasSize
        #expect(abs(layout.previewSize.width / layout.previewSize.height - canvas.width / canvas.height) < 0.0001)
    }

    @Test("縦向きの iPhone では見本を上に固定し、いちばん小さい iPhone でも設定に画面の半分より多く残す", arguments: portraitPhones)
    func portraitPhonePinsPreview(size: CGSize) {
        let layout = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        #expect(layout.arrangement == .pinnedTop)
        #expect(layout.pinnedHeight <= size.height * AppearancePreviewLayout.pinnedHeightFraction + 0.0001)
        #expect(size.height - layout.pinnedHeight > size.height / 2)
        // 見本は見分けられる大きさ（幅 90pt 以上）で、見本の右に説明の文を置く場所が残る
        #expect(layout.previewSize.width >= 90)
        #expect(layout.previewSize.width < size.width / 2)
        #expect(layout.captionHeight == layout.previewSize.height)
        expectAspectRatio(layout)
    }

    @Test("アクセシビリティの大きな文字では、上に固定する見本を小さくし、設定に 7 割を残す", arguments: portraitPhones)
    func accessibilitySizeShrinksPinnedPreview(size: CGSize) {
        let regular = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        let large = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: true)
        #expect(large.arrangement == .pinnedTop)
        #expect(large.previewSize.height < regular.previewSize.height)
        #expect(large.previewSize.height >= AppearancePreviewLayout.minimumPreviewHeight)
        #expect(large.pinnedHeight <= size.height * 0.3 + 0.0001)
        expectAspectRatio(large)
    }

    @Test("縦に長い画面では、上に固定する見本を大きくしすぎない")
    func pinnedPreviewHasMaximumHeight() {
        let layout = AppearancePreviewLayout(containerSize: CGSize(width: 507, height: 1_300), isAccessibilitySize: false)
        #expect(layout.arrangement == .pinnedTop)
        #expect(layout.previewSize.height == AppearancePreviewLayout.maximumPinnedPreviewHeight)
    }

    @Test("iPad と横向きの iPhone では、見本を左、設定を右に並べ、見本と下の文を高さに収める", arguments: wideScreens)
    func wideScreenPlacesPreviewBeside(size: CGSize) {
        let layout = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        #expect(layout.arrangement == .sideBySide)
        let columnHeight = layout.previewSize.height + AppearancePreviewLayout.sideSpacing + layout.captionHeight
            + AppearancePreviewLayout.verticalPadding * 2
        #expect(columnHeight <= size.height + 0.0001)
        // 設定に 6 割より多く残す
        #expect(layout.sideColumnWidth <= size.width * AppearancePreviewLayout.maximumSideColumnFraction + 0.0001)
        #expect(layout.previewSize.width <= AppearancePreviewLayout.maximumSidePreviewWidth + 0.0001)
        #expect(layout.captionHeight == AppearancePreviewLayout.sideCaptionHeight)
        expectAspectRatio(layout)
    }

    @Test("iPad の広い画面では、見本を幅 280pt まで大きくする")
    func iPadPreviewUsesMaximumWidth() {
        let layout = AppearancePreviewLayout(containerSize: CGSize(width: 1_056, height: 938), isAccessibilitySize: false)
        #expect(abs(layout.previewSize.width - AppearancePreviewLayout.maximumSidePreviewWidth) < 0.0001)
    }

    @Test("左の列では、アクセシビリティの大きな文字のとき見本の下の文に広く空ける")
    func accessibilitySizeReservesCaptionInSideColumn() {
        let size = CGSize(width: 832, height: 387)
        let regular = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        let large = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: true)
        #expect(large.arrangement == .sideBySide)
        #expect(large.captionHeight == AppearancePreviewLayout.accessibilitySideCaptionHeight)
        #expect(large.previewSize.height < regular.previewSize.height)
    }

    @Test("見本が細いときも、左の列は説明の文が読める幅を保つ")
    func sideColumnKeepsMinimumContentWidth() {
        let layout = AppearancePreviewLayout(containerSize: CGSize(width: 667, height: 311), isAccessibilitySize: false)
        #expect(layout.previewSize.width < AppearancePreviewLayout.minimumSideContentWidth)
        #expect(layout.sideColumnWidth == AppearancePreviewLayout.minimumSideContentWidth + AppearancePreviewLayout.horizontalPadding * 2)
    }

    @Test("横長でいちばん狭い幅でも、左の列は画面の幅の 40% を超えない")
    func sideColumnStaysWithinFraction() {
        let size = CGSize(width: AppearancePreviewLayout.landscapeMinimumWidth, height: 360)
        let layout = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        #expect(layout.arrangement == .sideBySide)
        #expect(layout.sideColumnWidth <= size.width * AppearancePreviewLayout.maximumSideColumnFraction + 0.0001)
        #expect(layout.sideColumnWidth >= layout.previewSize.width + AppearancePreviewLayout.horizontalPadding * 2)
    }

    @Test("iPad の狭い分割とスライドオーバーでは、見本を上に固定する", arguments: narrowSplits)
    func narrowSplitPinsPreview(size: CGSize) {
        let layout = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        #expect(layout.arrangement == .pinnedTop)
        expectAspectRatio(layout)
    }

    @Test("横長でも狭い窓は、見本を上に固定する")
    func narrowLandscapeWindowPinsPreview() {
        let layout = AppearancePreviewLayout(containerSize: CGSize(width: 460, height: 400), isAccessibilitySize: false)
        #expect(layout.arrangement == .pinnedTop)
    }

    @Test("測れていない大きさでは、見本をいちばん小さい大きさで上に固定する", arguments: [
        CGSize.zero,
        CGSize(width: -1, height: -1),
        CGSize(width: CGFloat.nan, height: CGFloat.infinity)
    ])
    func invalidSizeFallsBackToMinimum(size: CGSize) {
        let layout = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        #expect(layout.arrangement == .pinnedTop)
        #expect(layout.previewSize.height == AppearancePreviewLayout.minimumPreviewHeight)
        expectAspectRatio(layout)
    }
}
