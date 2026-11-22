//
//  PhotoWidgetAppearanceTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct PhotoWidgetAppearanceTests {
    @Test("フルカラーで Plus のときは、写真をそのまま描き、文字の後ろに暗幕を敷き、「Plus で使えます」を出さない")
    func fullColorUnlocked() {
        let appearance = PhotoWidgetAppearance(isFullColor: true, isPlusUnlocked: true)
        #expect(!appearance.isMonochrome)
        #expect(appearance.showsScrim)
        #expect(appearance.photoOpacity == 1)
        #expect(appearance.eventOpacity == 1)
        #expect(!appearance.showsPlusBadge)
    }

    @Test("1 色の描き方（tinted）では、写真を白黒で薄く描き、暗幕を敷かない")
    func monochromeUnlocked() {
        let appearance = PhotoWidgetAppearance(isFullColor: false, isPlusUnlocked: true)
        #expect(appearance.isMonochrome)
        #expect(!appearance.showsScrim)
        #expect(appearance.photoOpacity == PhotoWidgetAppearance.monochromePhotoOpacity)
        #expect(appearance.photoOpacity < 1)
        #expect(appearance.eventOpacity == 1)
        #expect(!appearance.showsPlusBadge)
    }

    @Test("Plus でないときは、写真と文字を薄くして「Plus で使えます」を重ねる", arguments: [true, false])
    func locked(isFullColor: Bool) {
        let unlocked = PhotoWidgetAppearance(isFullColor: isFullColor, isPlusUnlocked: true)
        let locked = PhotoWidgetAppearance(isFullColor: isFullColor, isPlusUnlocked: false)
        #expect(locked.showsPlusBadge)
        #expect(locked.photoOpacity < unlocked.photoOpacity)
        #expect(locked.eventOpacity < unlocked.eventOpacity)
        #expect(locked.showsScrim == unlocked.showsScrim)
        #expect(locked.isMonochrome == !isFullColor)
    }

    @Test("暗幕は、白い写真の上でも白い文字が 4.5:1 以上になる濃さ")
    func scrimContrast() {
        let ground = RGBColor.white.mixed(with: .black, fraction: PhotoWidgetAppearance.scrimOpacity)
        #expect(ground.contrastRatio(with: .white) >= 4.5)
    }

    @Test("地は、予定のときは推し色の塗り、ほかはテーマのカードの地", arguments: [AppTheme.shipping])
    func containerColor(theme: AppTheme) {
        for isPlusUnlocked in [true, false] {
            let content = PhotoWidgetContent.sample(isPlusUnlocked: isPlusUnlocked)
            guard case let .event(event) = content else {
                Issue.record("見本は予定")
                return
            }
            #expect(event.isPlusUnlocked == isPlusUnlocked)
            #expect(PhotoWidgetView.containerColor(for: content, in: theme) == AdaptiveColor(light: event.color.rgb, dark: event.color.rgb))
        }
        for content in [PhotoWidgetContent.notSelected, .missing, .unavailable] {
            #expect(PhotoWidgetView.containerColor(for: content, in: theme) == theme.palette.surface)
        }
    }
}
