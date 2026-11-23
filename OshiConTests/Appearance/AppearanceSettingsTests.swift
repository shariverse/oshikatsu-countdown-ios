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

    @Test("強さは弱・中・強の 3 段階で、強いほど幕が濃く（0.05 以上の差）、ぼかしが大きい", arguments: [false, true], [false, true])
    func ordering(isDark: Bool, isDecorated: Bool) {
        let all = AppearanceIntensity.allCases
        #expect(all == [.weak, .medium, .strong])
        for (weaker, stronger) in zip(all, all.dropFirst()) {
            let difference = stronger.scrimOpacity(isDark: isDark, isDecorated: isDecorated)
                - weaker.scrimOpacity(isDark: isDark, isDecorated: isDecorated)
            #expect(difference >= 0.05 - 1e-9)
            #expect(weaker.blurRadius < stronger.blurRadius)
        }
        for intensity in all {
            #expect(intensity.scrimOpacity(isDark: isDark, isDecorated: isDecorated) > 0)
            #expect(intensity.scrimOpacity(isDark: isDark, isDecorated: isDecorated) < 1)
            #expect(intensity.blurRadius < AppearanceIntensity.sideFillBlurRadius)
        }
    }

    @Test("飾りを重ねるときだけ幕を濃くし、重ねないときは写真が見えるよう薄くする", arguments: [false, true])
    func decoratedIsDenser(isDark: Bool) {
        for intensity in AppearanceIntensity.allCases {
            #expect(
                intensity.scrimOpacity(isDark: isDark, isDecorated: false) < intensity.scrimOpacity(isDark: isDark, isDecorated: true),
                "\(intensity)"
            )
        }
    }

    @Test("背景の推しが見えるよう、飾りを重ねないときの幕は強でも半分ほどまでにし、弱はぼかさない")
    func photoStaysVisible() {
        #expect(AppearanceIntensity.weak.scrimOpacity(isDark: false, isDecorated: false) == 0.15)
        #expect(AppearanceIntensity.weak.scrimOpacity(isDark: true, isDecorated: false) == 0.25)
        #expect(AppearanceIntensity.weak.blurRadius == 0)
        for intensity in AppearanceIntensity.allCases {
            for isDark in [false, true] {
                #expect(intensity.scrimOpacity(isDark: isDark, isDecorated: false) <= 0.55, "\(intensity) \(isDark)")
            }
            #expect(intensity.blurRadius <= 10, "\(intensity)")
        }
    }

    @Test(
        "ホームの上の端は、写真が真っ白・真っ黒でもステータスバーの文字（ライトは黒、ダークは白）が 4.5:1 以上になる濃さで幕の色に覆う",
        arguments: PaletteContrastTests.themes, [false, true]
    )
    func statusBarFadeContrast(theme: AppTheme, isDark: Bool) {
        let scrim = AppearanceIntensity.scrimColor(in: theme).resolved(isDark: isDark)
        let statusBarText = isDark ? RGBColor.white : .black
        for photo in [RGBColor.white, .black] {
            let ground = photo.mixed(with: scrim, fraction: AppearanceIntensity.statusBarFadeOpacity)
            #expect(statusBarText.contrastRatio(with: ground) >= 4.5, "\(photo)")
        }
    }

    @Test("幕の色はライトでは地の色、ダークでは黒")
    func scrimColor() {
        let scrim = AppearanceIntensity.scrimColor(in: theme)
        #expect(scrim.light == theme.palette.background.light)
        #expect(scrim.dark == .black)
    }

    @Test(
        "背景の写真の上で地の上に直接描く本文（見出し・案内）は、板（カードの地）の上に描くので、写真の色や幕の濃さによらず 4.5:1 以上（ライトとダーク）",
        arguments: PaletteContrastTests.themes, [false, true]
    )
    func textPlateContrast(theme: AppTheme, isDark: Bool) {
        // 幕は薄いので、写真が真っ白・真っ黒だと地の上の本文は 4.5:1 を保てない。そのため文字の後ろに不透明な板を敷く
        let palette = theme.palette
        let plate = AppearanceTextPlate.color(in: theme).resolved(isDark: isDark)
        #expect(plate == palette.surface.resolved(isDark: isDark))
        #expect(palette.onSurface.resolved(isDark: isDark).contrastRatio(with: plate) >= 4.5)
        #expect(palette.onSurfaceVariant.resolved(isDark: isDark).contrastRatio(with: plate) >= 4.5)
    }
}
