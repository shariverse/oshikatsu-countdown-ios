//
//  AppearanceBackgroundLayoutTests.swift
//  OshiConTests
//

import CoreGraphics
@testable import OshiCon
import Testing

struct AppearanceBackgroundLayoutTests {
    private let ratio = PhotoCrop.backgroundAspectRatio

    @Test("縦向きの iPhone では、写真で地を覆い、左右の余りを作らない")
    func portraitPhoneCovers() {
        let container = CGSize(width: 402, height: 874)
        let layout = AppearanceBackgroundLayout(containerSize: container)
        #expect(!layout.showsSideFill)
        #expect(layout.photoFrame.minX <= 0)
        #expect(layout.photoFrame.minY <= 0)
        #expect(layout.photoFrame.maxX >= container.width)
        #expect(layout.photoFrame.maxY >= container.height)
        #expect(abs(layout.photoFrame.midX - container.width / 2) < 0.001)
        #expect(abs(layout.photoFrame.midY - container.height / 2) < 0.001)
        #expect(abs(layout.photoFrame.width / layout.photoFrame.height - ratio) < 0.0001)
    }

    @Test("地が写真より細長いときは、高さに合わせて覆い、左右を同じだけはみ出させる")
    func narrowContainerCoversByHeight() {
        let container = CGSize(width: 300, height: 1_000)
        let layout = AppearanceBackgroundLayout(containerSize: container)
        #expect(!layout.showsSideFill)
        #expect(layout.photoFrame.minY == 0)
        #expect(layout.photoFrame.height == 1_000)
        #expect(abs(layout.photoFrame.width - 1_000 * ratio) < 0.001)
        #expect(layout.photoFrame.width > 300)
        #expect(abs(layout.photoFrame.midX - 150) < 0.001)
    }

    @Test("左右の余りが 1pt に満たないほど写真に近い地では、幅に合わせて覆い、上下を同じだけはみ出させる")
    func almostMatchingContainerCoversByWidth() {
        let height: CGFloat = 874
        let width = height * ratio + 0.5
        let layout = AppearanceBackgroundLayout(containerSize: CGSize(width: width, height: height))
        #expect(!layout.showsSideFill)
        #expect(abs(layout.photoFrame.width - width) < 0.001)
        #expect(layout.photoFrame.height > height)
        #expect(abs(layout.photoFrame.midY - height / 2) < 0.001)
    }

    @Test(
        "iPad・横向きでは、写真を高さに合わせて中央に置き、左右の余りをぼかしで埋める",
        arguments: [
            CGSize(width: 874, height: 402),
            CGSize(width: 1_032, height: 1_376),
            CGSize(width: 1_376, height: 1_032)
        ]
    )
    func wideContainerCentersPhoto(container: CGSize) {
        let layout = AppearanceBackgroundLayout(containerSize: container)
        #expect(layout.showsSideFill)
        #expect(layout.photoFrame.minY == 0)
        #expect(layout.photoFrame.height == container.height)
        #expect(abs(layout.photoFrame.width - container.height * ratio) < 0.001)
        #expect(abs(layout.photoFrame.minX - (container.width - layout.photoFrame.maxX)) < 0.001)
        #expect(layout.photoFrame.minX > 0)
    }

    @Test("左右の余りが 1pt に満たなければ、余りを作らずに覆う")
    func tinyGapCovers() {
        let height: CGFloat = 874
        let container = CGSize(width: height * ratio + 0.9, height: height)
        let layout = AppearanceBackgroundLayout(containerSize: container)
        #expect(!layout.showsSideFill)
        #expect(layout.photoFrame.width >= container.width - 0.001)
        #expect(layout.photoFrame.height >= container.height)

        let wider = AppearanceBackgroundLayout(containerSize: CGSize(width: height * ratio + 1.5, height: height))
        #expect(wider.showsSideFill)
    }

    @Test("読んだ写真の縦横比で置く")
    func usesGivenAspectRatio() {
        let layout = AppearanceBackgroundLayout(containerSize: CGSize(width: 1_000, height: 500), photoAspectRatio: 0.5)
        #expect(layout.showsSideFill)
        #expect(layout.photoFrame == CGRect(x: 375, y: 0, width: 250, height: 500))
    }

    @Test(
        "地の大きさが 0 や縦横比が 0 でも、何も置かない",
        arguments: [CGSize.zero, CGSize(width: 0, height: 500), CGSize(width: 500, height: 0)]
    )
    func emptyContainer(container: CGSize) {
        let layout = AppearanceBackgroundLayout(containerSize: container)
        #expect(layout.photoFrame == .zero)
        #expect(!layout.showsSideFill)
        #expect(layout.decodePixelLength(displayScale: 3) == 1)
        #expect(AppearanceBackgroundLayout(containerSize: CGSize(width: 400, height: 800), photoAspectRatio: 0).photoFrame == .zero)
    }

    @Test("読む長辺は、置く枠の長い辺を画素にし、取り込みの上限で抑える")
    func decodePixelLength() {
        // 横向きの iPhone（@3x）: 高さ 402pt → 1206px
        let landscape = AppearanceBackgroundLayout(containerSize: CGSize(width: 874, height: 402))
        #expect(landscape.decodePixelLength(displayScale: 3) == 1_206)
        // 縦向きの iPhone（@3x）と iPad Pro 13-inch（@2x）は上限の 2560px
        let portrait = AppearanceBackgroundLayout(containerSize: CGSize(width: 402, height: 874))
        #expect(portrait.decodePixelLength(displayScale: 3) == PhotoResizer.maxBackgroundPixelLength)
        let pad = AppearanceBackgroundLayout(containerSize: CGSize(width: 1_032, height: 1_376))
        #expect(pad.decodePixelLength(displayScale: 2) == PhotoResizer.maxBackgroundPixelLength)
        // 倍率が 1 より小さく渡っても 1 として数える
        let small = AppearanceBackgroundLayout(containerSize: CGSize(width: 100, height: 300), photoAspectRatio: 0.5)
        #expect(small.decodePixelLength(displayScale: 0) == 300)
    }

    @Test("予定の詳細では、上の写真の部分を除いた残りに敷く")
    func visibleRect() {
        let size = CGSize(width: 402, height: 874)
        func visible(excluding top: CGFloat) -> CGRect {
            AppearanceBackgroundLayout.visibleRect(containerSize: size, excludedTopHeight: top)
        }
        #expect(visible(excluding: 0) == CGRect(origin: .zero, size: size))
        #expect(visible(excluding: 300) == CGRect(x: 0, y: 300, width: 402, height: 574))
        // 地より大きい・負の値は地の中に収める
        #expect(visible(excluding: 1_000) == CGRect(x: 0, y: 874, width: 402, height: 0))
        #expect(visible(excluding: -20) == CGRect(origin: .zero, size: size))
    }

    @Test("写真を読む前（地の色に幕）でも、地の上の推し色の文字と本文が 4.5:1 以上（ライトとダーク）", arguments: AppearanceIntensity.allCases, [false, true])
    func contrastBeforeLoading(intensity: AppearanceIntensity, isDark: Bool) {
        let theme = AppTheme.shipping
        for isDecorated in [false, true] {
            let ground = intensity.ground(
                over: theme.palette.background.resolved(isDark: isDark),
                in: theme,
                isDark: isDark,
                isDecorated: isDecorated
            )
            for color in OshiColor.allCases {
                #expect(color.text(in: theme).resolved(isDark: isDark).contrastRatio(with: ground) >= 4.5, "\(color) \(isDecorated)")
            }
            #expect(theme.palette.onSurface.resolved(isDark: isDark).contrastRatio(with: ground) >= 4.5, "\(isDecorated)")
            #expect(theme.palette.onSurfaceVariant.resolved(isDark: isDark).contrastRatio(with: ground) >= 4.5, "\(isDecorated)")
        }
    }
}
