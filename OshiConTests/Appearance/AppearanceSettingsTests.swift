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

    @Test("書いたことが無ければ、背景は ON・飾りは OFF・暗幕 0.5・ぼかし 0.4・写真なし・飾りは濃さ 0.4・量 0.25・すべての推しを出す")
    func defaults() throws {
        let settings = AppearanceSettings(defaults: try AppearanceFixtures.makeDefaults())
        #expect(settings == AppearanceSettings())
        #expect(settings.isBackgroundEnabled)
        #expect(!settings.isDecorationEnabled)
        #expect(settings.backgroundStyle == .default)
        #expect(settings.backgroundStyle.scrim == 0.5)
        #expect(settings.backgroundStyle.blur == 0.4)
        #expect(settings.backgroundPhotoFileName == nil)
        #expect(settings.decorationStyle == .default)
        #expect(settings.decorationStyle.opacity == 0.4)
        #expect(settings.decorationStyle.amount == 0.25)
        #expect(settings.decorationStyle.excludedOshiIDs.isEmpty)
    }

    @Test("書いた設定を読める。写真を外して書くと、ファイル名のキーが消える")
    func readWrite() throws {
        let defaults = try AppearanceFixtures.makeDefaults()
        let settings = AppearanceSettings(
            isBackgroundEnabled: false,
            isDecorationEnabled: true,
            backgroundStyle: AppearanceBackgroundStyle(scrim: 0.85, blur: 0.15),
            backgroundPhotoFileName: photoFileName,
            decorationStyle: OshiPhotoDecorationStyle(opacity: 0.85, amount: 1, excludedOshiIDs: [UUID(), UUID()])
        )
        settings.write(to: defaults)
        #expect(AppearanceSettings(defaults: defaults) == settings)

        var removed = settings
        removed.backgroundPhotoFileName = nil
        removed.write(to: defaults)
        #expect(AppearanceSettings(defaults: defaults) == removed)
        #expect(defaults.object(forKey: AppStorageKey.appearanceBackgroundPhoto) == nil)
    }

    @Test("知らない前の版の強さは既定、写真の置き場所の外を指すファイル名は写真なし、範囲の外の暗幕・ぼかし・濃さ・量は範囲に収め、UUID でない推しの id は読まない")
    func invalidValues() throws {
        let defaults = try AppearanceFixtures.makeDefaults()
        let oshiID = UUID()
        defaults.set("extreme", forKey: AppStorageKey.appearanceIntensity)
        #expect(AppearanceSettings(defaults: defaults).backgroundStyle == .default)
        defaults.set(5.0, forKey: AppStorageKey.appearanceBackgroundScrim)
        defaults.set(-1.0, forKey: AppStorageKey.appearanceBackgroundBlur)
        defaults.set("../Library/secret.jpg", forKey: AppStorageKey.appearanceBackgroundPhoto)
        defaults.set(5.0, forKey: AppStorageKey.appearanceDecorationOpacity)
        defaults.set(-1.0, forKey: AppStorageKey.appearanceDecorationAmount)
        defaults.set(["not-a-uuid", oshiID.uuidString], forKey: AppStorageKey.appearanceDecorationExcludedOshis)
        let settings = AppearanceSettings(defaults: defaults)
        #expect(settings.backgroundStyle == AppearanceBackgroundStyle(scrim: 1, blur: 0))
        #expect(settings.backgroundPhotoFileName == nil)
        #expect(settings.decorationStyle.opacity == 1)
        #expect(settings.decorationStyle.amount == 0)
        #expect(settings.decorationStyle.excludedOshiIDs == [oshiID])

        // 型の違う値は書いていないものとして既定に戻す
        defaults.set("dark", forKey: AppStorageKey.appearanceBackgroundScrim)
        defaults.set("blurry", forKey: AppStorageKey.appearanceBackgroundBlur)
        defaults.set("dark", forKey: AppStorageKey.appearanceDecorationOpacity)
        defaults.set("many", forKey: AppStorageKey.appearanceDecorationAmount)
        let typeMismatch = AppearanceSettings(defaults: defaults)
        #expect(typeMismatch.backgroundStyle == .default)
        #expect(typeMismatch.decorationStyle.opacity == OshiPhotoDecorationStyle.defaultOpacity)
        #expect(typeMismatch.decorationStyle.amount == OshiPhotoDecorationStyle.defaultAmount)
    }

    @Test(
        "前の版（TestFlight）で保存した強さは、同じ見た目になる暗幕とぼかしの位置に読み替える",
        arguments: [("weak", 0.25, 0.0), ("medium", 0.5, 0.4), ("strong", 0.75, 1.0)]
    )
    func legacyIntensity(rawValue: String, scrim: Double, blur: Double) throws {
        let defaults = try AppearanceFixtures.makeDefaults()
        defaults.set(rawValue, forKey: AppStorageKey.appearanceIntensity)
        let settings = AppearanceSettings(defaults: defaults)
        #expect(settings.backgroundStyle == AppearanceBackgroundStyle(scrim: scrim, blur: blur))
        #expect(AppearanceBackgroundStyle(legacyIntensity: rawValue) == settings.backgroundStyle)
    }

    @Test("暗幕とぼかしを書いていれば前の版の強さより優先し、書いたときに前の版の強さのキーを消す")
    func legacyIntensityIsReplaced() throws {
        let defaults = try AppearanceFixtures.makeDefaults()
        defaults.set("strong", forKey: AppStorageKey.appearanceIntensity)
        // 片方だけ書いてあれば、書いていないほうだけ前の版の強さから読む
        defaults.set(0.1, forKey: AppStorageKey.appearanceBackgroundScrim)
        #expect(AppearanceSettings(defaults: defaults).backgroundStyle == AppearanceBackgroundStyle(scrim: 0.1, blur: 1))

        var settings = AppearanceSettings(defaults: defaults)
        settings.backgroundStyle.blur = 0.2
        settings.write(to: defaults)
        #expect(defaults.object(forKey: AppStorageKey.appearanceIntensity) == nil)
        #expect(defaults.double(forKey: AppStorageKey.appearanceBackgroundScrim) == 0.1)
        #expect(defaults.double(forKey: AppStorageKey.appearanceBackgroundBlur) == 0.2)
        #expect(AppearanceSettings(defaults: defaults) == settings)
    }

    @Test("Plus が使えないときは、設定にかかわらず標準の見た目にする")
    func lockedIsStandard() {
        let settings = AppearanceSettings(
            isBackgroundEnabled: true,
            isDecorationEnabled: true,
            backgroundStyle: AppearanceBackgroundStyle(scrim: 1, blur: 1),
            backgroundPhotoFileName: photoFileName
        )
        let rendering = AppearanceRendering(settings: settings, isPlusUnlocked: false)
        #expect(rendering == .standard)
        #expect(rendering.isStandard)
        #expect(rendering.backgroundPhoto == nil)
        #expect(!rendering.showsOshiPhotoDecoration)
    }

    @Test("Plus が使え、背景を ON にして写真を選んでいれば、その写真を選んだ暗幕とぼかしで敷く")
    func unlockedBackground() {
        let style = AppearanceBackgroundStyle(scrim: 0.25, blur: 0)
        let settings = AppearanceSettings(
            isBackgroundEnabled: true,
            isDecorationEnabled: false,
            backgroundStyle: style,
            backgroundPhotoFileName: photoFileName
        )
        let rendering = AppearanceRendering(settings: settings, isPlusUnlocked: true)
        #expect(rendering.backgroundPhoto == AppearanceRendering.BackgroundPhoto(fileName: photoFileName, style: style))
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

    @Test("飾りを ON にしていれば、設定の濃さ・量・出す推しで描く。OFF なら濃さ・量を持たず、背景も無ければ標準の見た目")
    func decorationStyle() {
        let style = OshiPhotoDecorationStyle(opacity: 0.7, amount: 0.9, excludedOshiIDs: [UUID()])
        let on = AppearanceRendering(
            settings: AppearanceSettings(isBackgroundEnabled: false, isDecorationEnabled: true, decorationStyle: style),
            isPlusUnlocked: true
        )
        #expect(on.decoration == style)
        let off = AppearanceRendering(
            settings: AppearanceSettings(isBackgroundEnabled: false, isDecorationEnabled: false, decorationStyle: style),
            isPlusUnlocked: true
        )
        #expect(off.decoration == nil)
        #expect(off.isStandard)
    }

    @Test("地に写真（背景の写真か飾り）を描くときだけ、文字の後ろに板を敷き、上の端を覆う")
    func drawsPhotosOnGround() {
        let photo = AppearanceRendering.BackgroundPhoto(fileName: photoFileName, style: .default)
        #expect(!AppearanceRendering.standard.drawsPhotosOnGround)
        #expect(AppearanceRendering(backgroundPhoto: photo, decoration: nil).drawsPhotosOnGround)
        #expect(AppearanceRendering(backgroundPhoto: nil, decoration: .default).drawsPhotosOnGround)
        #expect(AppearanceRendering(backgroundPhoto: photo, decoration: .default).drawsPhotosOnGround)
    }
}

struct OshiPhotoDecorationStyleTests {
    @Test("濃さは 0.1〜1、量は 0〜1 に収め、NaN は既定にする")
    func clamps() {
        let low = OshiPhotoDecorationStyle(opacity: 0, amount: -0.5)
        #expect(low.opacity == 0.1)
        #expect(low.amount == 0)
        let high = OshiPhotoDecorationStyle(opacity: 2, amount: 3)
        #expect(high.opacity == 1)
        #expect(high.amount == 1)
        let nan = OshiPhotoDecorationStyle(opacity: .nan, amount: .nan)
        #expect(nan.opacity == OshiPhotoDecorationStyle.defaultOpacity)
        #expect(nan.amount == OshiPhotoDecorationStyle.defaultAmount)

        // 後から入れた値も範囲に収める（スライダー・ストアから）
        var style = OshiPhotoDecorationStyle()
        style.opacity = 1.5
        style.amount = -1
        #expect(style.opacity == 1)
        #expect(style.amount == 0)
        style.opacity = 0.55
        #expect(style.opacity == 0.55)
    }

    @Test("既定ではすべての推しを出し、外した推しだけを出さない")
    func includes() {
        let shown = Oshi(name: "A")
        let hidden = Oshi(name: "B")
        #expect(OshiPhotoDecorationStyle.default.includes(shown))
        #expect(OshiPhotoDecorationStyle.default.includes(hidden))
        let style = OshiPhotoDecorationStyle(excludedOshiIDs: [hidden.id])
        #expect(style.includes(shown))
        #expect(!style.includes(hidden))
    }

    @Test("既定の濃さは初めの版（0.15）より濃い")
    func defaultIsDenserThanFirstVersion() {
        #expect(OshiPhotoDecorationStyle.defaultOpacity > 0.15)
        #expect(OshiPhotoDecorationStyle.opacityRange.contains(OshiPhotoDecorationStyle.defaultOpacity))
        #expect(OshiPhotoDecorationStyle.amountRange.contains(OshiPhotoDecorationStyle.defaultAmount))
    }
}

struct AppearanceBackgroundStyleTests {
    private let theme = AppTheme.shipping

    /// スライダーの位置（0〜1 を 5% ずつ）。
    private let positions = (0...20).map { Double($0) / 20 }

    @Test("暗幕とぼかしは 0〜1 に収め、NaN は既定にする")
    func clamps() {
        let low = AppearanceBackgroundStyle(scrim: -0.5, blur: -1)
        #expect(low.scrim == 0)
        #expect(low.blur == 0)
        let high = AppearanceBackgroundStyle(scrim: 2, blur: 3)
        #expect(high.scrim == 1)
        #expect(high.blur == 1)
        let nan = AppearanceBackgroundStyle(scrim: .nan, blur: .nan)
        #expect(nan == .default)

        // 後から入れた値も範囲に収める（スライダー・ストアから）
        var style = AppearanceBackgroundStyle()
        style.scrim = 1.5
        style.blur = -1
        #expect(style.scrim == 1)
        #expect(style.blur == 0)
        style.blur = .nan
        #expect(style.blur == AppearanceBackgroundStyle.defaultBlur)
        style.scrim = 0.35
        #expect(style.scrim == 0.35)
    }

    @Test("既定は前の版の「中」と同じ位置（暗幕 0.5・ぼかし 0.4）。知らない前の版の強さは読まない")
    func defaultIsMedium() {
        #expect(AppearanceBackgroundStyle.default == AppearanceBackgroundStyle(scrim: 0.5, blur: 0.4))
        #expect(AppearanceBackgroundStyle(legacyIntensity: "medium") == .default)
        #expect(AppearanceBackgroundStyle(legacyIntensity: "extreme") == nil)
        #expect(AppearanceBackgroundStyle(legacyIntensity: "") == nil)
    }

    @Test(
        "前の版の弱・中・強の位置で、幕の不透明度（ライト・ダーク × 飾りの OFF・ON）とぼかしの半径が前の版とちょうど同じ",
        arguments: [
            ("weak", [0.15, 0.25, 0.35, 0.45], 0.0),
            ("medium", [0.30, 0.40, 0.50, 0.60], 4.0),
            ("strong", [0.45, 0.55, 0.65, 0.75], 10.0)
        ]
    )
    func reproducesLegacyPresets(rawValue: String, scrimOpacities: [Double], blurRadius: Double) throws {
        let style = try #require(AppearanceBackgroundStyle(legacyIntensity: rawValue))
        let actual = [
            style.scrimOpacity(isDark: false, isDecorated: false),
            style.scrimOpacity(isDark: true, isDecorated: false),
            style.scrimOpacity(isDark: false, isDecorated: true),
            style.scrimOpacity(isDark: true, isDecorated: true)
        ]
        for (value, expected) in zip(actual, scrimOpacities) {
            #expect(abs(value - expected) < 1e-9, "\(rawValue) \(actual)")
        }
        #expect(abs(Double(style.blurRadius) - blurRadius) < 1e-9, "\(rawValue)")
    }

    @Test(
        "位置を上げるほど幕は濃く、ぼかしは強い。どの位置でも幕は 1 より薄く、ぼかしは左右の余りのぼかしより小さい",
        arguments: [false, true], [false, true]
    )
    func monotonic(isDark: Bool, isDecorated: Bool) {
        for (lower, higher) in zip(positions, positions.dropFirst()) {
            let weaker = AppearanceBackgroundStyle(scrim: lower, blur: lower)
            let stronger = AppearanceBackgroundStyle(scrim: higher, blur: higher)
            let weakerScrim = weaker.scrimOpacity(isDark: isDark, isDecorated: isDecorated)
            #expect(weakerScrim < stronger.scrimOpacity(isDark: isDark, isDecorated: isDecorated), "\(lower)")
            #expect(weaker.blurRadius < stronger.blurRadius, "\(lower)")
        }
        for position in positions {
            let style = AppearanceBackgroundStyle(scrim: position, blur: position)
            #expect(style.scrimOpacity(isDark: isDark, isDecorated: isDecorated) >= 0)
            #expect(style.scrimOpacity(isDark: isDark, isDecorated: isDecorated) < 1)
            #expect(style.blurRadius >= 0)
            #expect(style.blurRadius < AppearanceBackgroundStyle.sideFillBlurRadius)
        }
    }

    @Test("暗幕とぼかしは別々に効く（暗幕の位置はぼかしを変えず、ぼかしの位置は幕を変えない）")
    func independent() {
        let base = AppearanceBackgroundStyle(scrim: 0.3, blur: 0.7)
        var scrimChanged = base
        scrimChanged.scrim = 0.9
        #expect(scrimChanged.blurRadius == base.blurRadius)
        var blurChanged = base
        blurChanged.blur = 0.1
        #expect(blurChanged.scrimOpacity(isDark: false, isDecorated: false) == base.scrimOpacity(isDark: false, isDecorated: false))
    }

    @Test("ダークは 0.1、飾りを重ねるときは 0.2 だけ幕を濃くする（どの位置でも）")
    func darkAndDecoratedOffsets() {
        for position in positions {
            let style = AppearanceBackgroundStyle(scrim: position)
            let plain = style.scrimOpacity(isDark: false, isDecorated: false)
            #expect(abs(style.scrimOpacity(isDark: true, isDecorated: false) - plain - 0.1) < 1e-9, "\(position)")
            #expect(abs(style.scrimOpacity(isDark: false, isDecorated: true) - plain - 0.2) < 1e-9, "\(position)")
            #expect(abs(style.scrimOpacity(isDark: true, isDecorated: true) - plain - 0.3) < 1e-9, "\(position)")
        }
    }

    @Test("背景の推しが見えるよう、いちばん濃くしても飾りを重ねないときの幕は 0.6（ダークは 0.7）まで、ぼかしは 10pt まで。0 なら幕もぼかしも無い")
    func photoStaysVisible() {
        let strongest = AppearanceBackgroundStyle(scrim: 1, blur: 1)
        #expect(abs(strongest.scrimOpacity(isDark: false, isDecorated: false) - 0.6) < 1e-9)
        #expect(abs(strongest.scrimOpacity(isDark: true, isDecorated: false) - 0.7) < 1e-9)
        #expect(abs(strongest.scrimOpacity(isDark: true, isDecorated: true) - 0.9) < 1e-9)
        #expect(strongest.blurRadius == 10)
        let weakest = AppearanceBackgroundStyle(scrim: 0, blur: 0)
        #expect(weakest.scrimOpacity(isDark: false, isDecorated: false) == 0)
        #expect(weakest.blurRadius == 0)
    }

    @Test(
        "ホームの上の端は、写真が真っ白・真っ黒でもステータスバーの文字（ライトは黒、ダークは白）が 4.5:1 以上になる濃さで幕の色に覆う",
        arguments: PaletteContrastTests.themes, [false, true]
    )
    func statusBarFadeContrast(theme: AppTheme, isDark: Bool) {
        let scrim = AppearanceBackgroundStyle.scrimColor(in: theme).resolved(isDark: isDark)
        let statusBarText = isDark ? RGBColor.white : .black
        for photo in [RGBColor.white, .black] {
            let ground = photo.mixed(with: scrim, fraction: AppearanceBackgroundStyle.statusBarFadeOpacity)
            #expect(statusBarText.contrastRatio(with: ground) >= 4.5, "\(photo)")
        }
    }

    @Test("幕の色はライトでは地の色、ダークでは黒")
    func scrimColor() {
        let scrim = AppearanceBackgroundStyle.scrimColor(in: theme)
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
