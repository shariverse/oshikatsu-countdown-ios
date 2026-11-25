//
//  AppearancePreviewLayoutTests.swift
//  OshiConTests
//

import CoreGraphics
@testable import OshiCon
import Testing

/// 着せ替えの画面で、見本と設定のトレーをどう並べ、見本をどの大きさで見せるか（`AppearancePreviewLayout`）。
///
/// 画面の大きさは、ナビゲーションバーを除いた中身の大きさ（端末の大きさから数えたおよその値。着せ替えの画面ではタブバーを隠す）。
struct AppearancePreviewLayoutTests {
    /// 縦向きの iPhone の中身の大きさ（SE（第 3 世代）・17e・17・17 Pro Max）。
    nonisolated static let portraitPhones: [CGSize] = [
        CGSize(width: 375, height: 603),
        CGSize(width: 390, height: 719),
        CGSize(width: 402, height: 734),
        CGSize(width: 440, height: 816)
    ]

    /// `portraitPhones` の端末の画面の高さ（バーを含む。pt）。
    nonisolated static let portraitScreenHeights: [CGFloat] = [667, 844, 874, 956]

    /// 横向きの iPhone（SE（第 3 世代）・17 Pro Max・17 Pro Max でサイドバーを出したとき）と、iPad Pro 13 インチ（横向きでサイドバーあり・縦向き）の中身の大きさ。
    nonisolated static let wideScreens: [CGSize] = [
        CGSize(width: 667, height: 343),
        CGSize(width: 832, height: 375),
        CGSize(width: 512, height: 380),
        CGSize(width: 1_056, height: 958),
        CGSize(width: 1_032, height: 1_290)
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

    @Test("縦向きの iPhone では見本を上に大きく置き、いちばん小さい iPhone でも設定のトレーに 200pt を残す", arguments: portraitPhones)
    func portraitPhonePlacesPreviewOnTop(size: CGSize) {
        let layout = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        #expect(layout.arrangement == .pinnedTop)
        // 見本は中身の高さの半分より大きい
        #expect(layout.previewSize.height > size.height / 2)
        #expect(layout.previewSize.height <= size.height * AppearancePreviewLayout.pinnedPreviewFraction + 0.0001)
        #expect(size.height - layout.stageHeight >= AppearancePreviewLayout.minimumTrayHeight - 0.0001)
        // 見本はまん中に置き、左右に余白が残る
        #expect(layout.stageWidth == size.width)
        #expect(layout.previewSize.width < size.width - AppearancePreviewLayout.horizontalPadding * 2)
        #expect(layout.controlsHeight == AppearancePreviewLayout.controlsHeight)
        expectAspectRatio(layout)
    }

    @Test("縦向きの iPhone の見本の高さは、画面の高さの 45% 前後", arguments: zip(portraitPhones, portraitScreenHeights))
    func portraitPhonePreviewIsAboutHalfOfScreen(size: CGSize, screenHeight: CGFloat) {
        let layout = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        #expect((0.43...0.5).contains(layout.previewSize.height / screenHeight))
    }

    @Test("アクセシビリティの大きな文字では、上の見本を小さくし、設定のトレーに半分より多く残す", arguments: portraitPhones)
    func accessibilitySizeShrinksPinnedPreview(size: CGSize) {
        let regular = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        let large = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: true)
        #expect(large.arrangement == .pinnedTop)
        #expect(large.previewSize.height < regular.previewSize.height)
        #expect(large.previewSize.height >= AppearancePreviewLayout.minimumPreviewHeight)
        #expect(large.previewSize.height <= size.height * AppearancePreviewLayout.accessibilityPinnedPreviewFraction + 0.0001)
        #expect(size.height - large.stageHeight > size.height / 2)
        // 切り替えの行は、大きくなった文字のぶん高くする
        #expect(large.controlsHeight == AppearancePreviewLayout.accessibilityControlsHeight)
        expectAspectRatio(large)
    }

    @Test("縦に長い画面では、上の見本を大きくしすぎない")
    func pinnedPreviewHasMaximumHeight() {
        let layout = AppearancePreviewLayout(containerSize: CGSize(width: 507, height: 1_300), isAccessibilitySize: false)
        #expect(layout.arrangement == .pinnedTop)
        #expect(layout.previewSize.height == AppearancePreviewLayout.maximumPinnedPreviewHeight)
    }

    @Test("縦に長くて細い窓では、上の見本を左右の余白の内側に収める")
    func pinnedPreviewFitsNarrowWidth() {
        let size = CGSize(width: 200, height: 1_000)
        let layout = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        #expect(layout.arrangement == .pinnedTop)
        #expect(abs(layout.previewSize.width - (size.width - AppearancePreviewLayout.horizontalPadding * 2)) < 0.0001)
        expectAspectRatio(layout)
    }

    @Test("iPad と横向きの iPhone では、見本を左、設定を右に並べ、見本と切り替えの行を高さに収める", arguments: wideScreens)
    func wideScreenPlacesPreviewBeside(size: CGSize) {
        let layout = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        #expect(layout.arrangement == .sideBySide)
        #expect(layout.stageHeight <= size.height + 0.0001)
        // 設定に 6 割より多く残す
        #expect(layout.stageWidth <= size.width * AppearancePreviewLayout.maximumSideColumnFraction + 0.0001)
        #expect(layout.stageWidth >= layout.previewSize.width + AppearancePreviewLayout.horizontalPadding * 2 - 0.0001)
        #expect(layout.previewSize.width <= AppearancePreviewLayout.maximumSidePreviewWidth + 0.0001)
        expectAspectRatio(layout)
    }

    @Test("iPad の広い画面では、見本を幅 280pt まで大きくする")
    func iPadPreviewUsesMaximumWidth() {
        let layout = AppearancePreviewLayout(containerSize: CGSize(width: 1_056, height: 958), isAccessibilitySize: false)
        #expect(abs(layout.previewSize.width - AppearancePreviewLayout.maximumSidePreviewWidth) < 0.0001)
    }

    @Test("左の列では、アクセシビリティの大きな文字のとき切り替えの行を高くし、そのぶん見本を小さくする")
    func accessibilitySizeReservesControlsInSideColumn() {
        let size = CGSize(width: 832, height: 375)
        let regular = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        let large = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: true)
        #expect(large.arrangement == .sideBySide)
        #expect(large.controlsHeight == AppearancePreviewLayout.accessibilityControlsHeight)
        #expect(large.previewSize.height < regular.previewSize.height)
        #expect(large.stageHeight <= size.height + 0.0001)
    }

    @Test("見本が細いときも、左の列は切り替えの行が収まる幅を保つ")
    func sideColumnKeepsMinimumContentWidth() {
        let layout = AppearancePreviewLayout(containerSize: CGSize(width: 667, height: 343), isAccessibilitySize: false)
        #expect(layout.previewSize.width < AppearancePreviewLayout.minimumSideContentWidth)
        #expect(layout.stageWidth == AppearancePreviewLayout.minimumSideContentWidth + AppearancePreviewLayout.horizontalPadding * 2)
    }

    @Test("横長でいちばん狭い幅でも、左の列は画面の幅の 40% を超えない")
    func sideColumnStaysWithinFraction() {
        let size = CGSize(width: AppearancePreviewLayout.landscapeMinimumWidth, height: 360)
        let layout = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        #expect(layout.arrangement == .sideBySide)
        #expect(layout.stageWidth <= size.width * AppearancePreviewLayout.maximumSideColumnFraction + 0.0001)
        #expect(layout.stageWidth >= layout.previewSize.width + AppearancePreviewLayout.horizontalPadding * 2)
    }

    @Test("iPad の狭い分割とスライドオーバーでは、見本を上に置く", arguments: narrowSplits)
    func narrowSplitPinsPreview(size: CGSize) {
        let layout = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        #expect(layout.arrangement == .pinnedTop)
        #expect(layout.previewSize.width <= size.width - AppearancePreviewLayout.horizontalPadding * 2 + 0.0001)
        expectAspectRatio(layout)
    }

    @Test("横長でも狭い窓は、見本を上に置く")
    func narrowLandscapeWindowPinsPreview() {
        let layout = AppearancePreviewLayout(containerSize: CGSize(width: 460, height: 400), isAccessibilitySize: false)
        #expect(layout.arrangement == .pinnedTop)
    }

    @Test(
        "シェアのカードの見本は、見本の高さと見本を置く幅に収め、書き出す大きさより大きくしない",
        arguments: portraitPhones + wideScreens + narrowSplits,
        [false, true]
    )
    func shareCardFitsStage(size: CGSize, isAccessibilitySize: Bool) {
        let layout = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: isAccessibilitySize)
        #expect(layout.shareCardSide > 0)
        #expect(layout.shareCardSide <= layout.previewSize.height + 0.0001)
        #expect(layout.shareCardSide <= layout.stageWidth - AppearancePreviewLayout.horizontalPadding * 2 + 0.0001)
        #expect(layout.shareCardSide <= ShareCardSize.points)
    }

    @Test("縦向きの iPhone 17 では、シェアのカードの見本を書き出す大きさのまま見せる")
    func shareCardUsesFullSizeOnPhone() {
        let layout = AppearancePreviewLayout(containerSize: CGSize(width: 402, height: 734), isAccessibilitySize: false)
        #expect(layout.shareCardSide == ShareCardSize.points)
    }

    @Test("幅の広いシェアのカードは、となりにのぞくときは右へ、映しているときはほかの見本を左へ、はみ出す幅だけよける")
    func carouselOffsetAvoidsOverlap() {
        let layout = AppearancePreviewLayout(containerSize: CGSize(width: 402, height: 734), isAccessibilitySize: false)
        let overflow = (layout.shareCardSide - layout.previewSize.width) / 2
        #expect(overflow > 0)
        // ホーム・予定の詳細を映しているとき: シェアのカードだけ右へ
        for selected in [AppearancePreview.Kind.home, .eventDetail] {
            #expect(layout.carouselOffset(of: .home, selected: selected) == 0)
            #expect(layout.carouselOffset(of: .eventDetail, selected: selected) == 0)
            #expect(layout.carouselOffset(of: .share, selected: selected) == overflow)
        }
        // シェアのカードを映しているとき: カードはまん中のまま、ほかの見本を左へ
        #expect(layout.carouselOffset(of: .share, selected: .share) == 0)
        #expect(layout.carouselOffset(of: .home, selected: .share) == -overflow)
        #expect(layout.carouselOffset(of: .eventDetail, selected: .share) == -overflow)
    }

    @Test("シェアのカードが見本の幅からはみ出さないとき（iPad の左の列）は、どの見本もよけない")
    func carouselOffsetIsZeroWithoutOverflow() {
        let layout = AppearancePreviewLayout(containerSize: CGSize(width: 1_056, height: 958), isAccessibilitySize: false)
        #expect(layout.shareCardSide <= layout.previewSize.width + 0.0001)
        for page in AppearancePreview.Kind.allCases {
            for selected in AppearancePreview.Kind.allCases {
                #expect(layout.carouselOffset(of: page, selected: selected) == 0)
            }
        }
    }

    @Test("測れていない大きさでは、見本をいちばん小さい大きさで上に置く", arguments: [
        CGSize.zero,
        CGSize(width: -1, height: -1),
        CGSize(width: CGFloat.nan, height: CGFloat.infinity)
    ])
    func invalidSizeFallsBackToMinimum(size: CGSize) {
        let layout = AppearancePreviewLayout(containerSize: size, isAccessibilitySize: false)
        #expect(layout.arrangement == .pinnedTop)
        #expect(layout.previewSize.height == AppearancePreviewLayout.minimumPreviewHeight)
        #expect(layout.shareCardSide == 0)
        expectAspectRatio(layout)
    }
}
