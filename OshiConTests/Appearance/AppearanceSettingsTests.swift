//
//  AppearanceSettingsTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

/// 着せ替えのテストで使う値。
nonisolated enum AppearanceFixtures {
    /// 取り込みで付ける形のファイル名。
    static let photoFileName = "6F9619FF-8B86-D011-B42D-00C04FC964FF.jpg"

    /// テストごとの UserDefaults（端末の設定を書き換えない）。
    static func makeDefaults() throws -> UserDefaults {
        let suiteName = "AppearanceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

struct AppearanceSettingsTests {
    private let photoFileName = AppearanceFixtures.photoFileName

    @Test("書いたことが無ければ、背景は ON・飾りは OFF・強さは中・写真なし")
    func defaults() throws {
        let settings = AppearanceSettings(defaults: try AppearanceFixtures.makeDefaults())
        #expect(settings == AppearanceSettings())
        #expect(settings.isBackgroundEnabled)
        #expect(!settings.isDecorationEnabled)
        #expect(settings.intensity == .medium)
        #expect(settings.backgroundPhotoFileName == nil)
    }

    @Test("書いた設定を読める。写真を外して書くと、ファイル名のキーが消える")
    func readWrite() throws {
        let defaults = try AppearanceFixtures.makeDefaults()
        let settings = AppearanceSettings(
            isBackgroundEnabled: false,
            isDecorationEnabled: true,
            intensity: .strong,
            backgroundPhotoFileName: photoFileName
        )
        settings.write(to: defaults)
        #expect(AppearanceSettings(defaults: defaults) == settings)

        var removed = settings
        removed.backgroundPhotoFileName = nil
        removed.write(to: defaults)
        #expect(AppearanceSettings(defaults: defaults) == removed)
        #expect(defaults.object(forKey: AppStorageKey.appearanceBackgroundPhoto) == nil)
    }

    @Test("知らない強さは中、写真の置き場所の外を指すファイル名は写真なしとして読む")
    func invalidValues() throws {
        let defaults = try AppearanceFixtures.makeDefaults()
        defaults.set("extreme", forKey: AppStorageKey.appearanceIntensity)
        defaults.set("../Library/secret.jpg", forKey: AppStorageKey.appearanceBackgroundPhoto)
        let settings = AppearanceSettings(defaults: defaults)
        #expect(settings.intensity == .medium)
        #expect(settings.backgroundPhotoFileName == nil)
    }

    @Test("Plus が使えないときは、設定にかかわらず標準の見た目にする")
    func lockedIsStandard() {
        let settings = AppearanceSettings(
            isBackgroundEnabled: true,
            isDecorationEnabled: true,
            intensity: .strong,
            backgroundPhotoFileName: photoFileName
        )
        let rendering = AppearanceRendering(settings: settings, isPlusUnlocked: false)
        #expect(rendering == .standard)
        #expect(rendering.isStandard)
        #expect(rendering.backgroundPhoto == nil)
        #expect(!rendering.showsOshiPhotoDecoration)
    }

    @Test("Plus が使え、背景を ON にして写真を選んでいれば、その写真を選んだ強さで敷く")
    func unlockedBackground() {
        let settings = AppearanceSettings(
            isBackgroundEnabled: true,
            isDecorationEnabled: false,
            intensity: .weak,
            backgroundPhotoFileName: photoFileName
        )
        let rendering = AppearanceRendering(settings: settings, isPlusUnlocked: true)
        #expect(rendering.backgroundPhoto == AppearanceRendering.BackgroundPhoto(fileName: photoFileName, intensity: .weak))
        #expect(!rendering.showsOshiPhotoDecoration)
        #expect(!rendering.isStandard)
    }

    @Test(
        "Plus が使えても、背景を OFF にしているか写真が無ければ背景は敷かない",
        arguments: [
            AppearanceSettings(isBackgroundEnabled: false, backgroundPhotoFileName: AppearanceFixtures.photoFileName),
            AppearanceSettings(isBackgroundEnabled: true, backgroundPhotoFileName: nil),
            AppearanceSettings(isBackgroundEnabled: true, backgroundPhotoFileName: "../secret.jpg")
        ]
    )
    func unlockedWithoutBackground(settings: AppearanceSettings) {
        let rendering = AppearanceRendering(settings: settings, isPlusUnlocked: true)
        #expect(rendering.backgroundPhoto == nil)
        #expect(rendering.isStandard)
    }

    @Test("飾りは、Plus が使えて ON にしているときだけ推しの写真にする。背景の ON/OFF にはよらない", arguments: [false, true], [false, true])
    func decoration(isDecorationEnabled: Bool, isBackgroundEnabled: Bool) {
        let settings = AppearanceSettings(
            isBackgroundEnabled: isBackgroundEnabled,
            isDecorationEnabled: isDecorationEnabled,
            backgroundPhotoFileName: photoFileName
        )
        let unlocked = AppearanceRendering(settings: settings, isPlusUnlocked: true)
        #expect(unlocked.showsOshiPhotoDecoration == isDecorationEnabled)
        #expect((unlocked.backgroundPhoto != nil) == isBackgroundEnabled)
        #expect(!AppearanceRendering(settings: settings, isPlusUnlocked: false).showsOshiPhotoDecoration)
    }
}

struct AppearanceIntensityTests {
    private let theme = AppTheme.shipping

    @Test("強さは弱・中・強の 3 段階で、強いほど幕が濃く、ぼかしが大きい", arguments: [false, true])
    func ordering(isDark: Bool) {
        let all = AppearanceIntensity.allCases
        #expect(all == [.weak, .medium, .strong])
        for (weaker, stronger) in zip(all, all.dropFirst()) {
            #expect(weaker.scrimOpacity(isDark: isDark) < stronger.scrimOpacity(isDark: isDark))
            #expect(weaker.blurRadius < stronger.blurRadius)
        }
        for intensity in all {
            #expect(intensity.scrimOpacity(isDark: isDark) > 0)
            #expect(intensity.scrimOpacity(isDark: isDark) < 1)
            #expect(intensity.blurRadius < AppearanceIntensity.sideFillBlurRadius)
        }
    }

    @Test("幕の色はライトでは地の色、ダークでは黒")
    func scrimColor() {
        let scrim = AppearanceIntensity.scrimColor(in: theme)
        #expect(scrim.light == theme.palette.background.light)
        #expect(scrim.dark == .black)
    }

    @Test(
        "どの強さでも、写真が真っ白・真っ黒のときに、地の上に直接描く本文（見出し・案内）が 4.5:1 以上（ライトとダーク）",
        arguments: AppearanceIntensity.allCases, [false, true]
    )
    func contrast(intensity: AppearanceIntensity, isDark: Bool) {
        // 推し色の文字はカードの上に描くので数えない（飾りと同じ基準）
        let palette = theme.palette
        for photo in [RGBColor.white, .black] {
            let ground = intensity.ground(over: photo, in: theme, isDark: isDark)
            #expect(palette.onSurface.resolved(isDark: isDark).contrastRatio(with: ground) >= 4.5, "\(photo)")
            #expect(palette.onSurfaceVariant.resolved(isDark: isDark).contrastRatio(with: ground) >= 4.5, "\(photo)")
        }
    }
}
