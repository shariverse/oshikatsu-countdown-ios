//
//  AppIconTests.swift
//  OshiConTests
//

import CoreGraphics
import Foundation
@testable import OshiCon
import Testing

/// 着せ替えのアプリアイコン（`AppIconRule`・`AppIconPalette`）と、アプリに入った代替アイコン・Icon Composer のファイル。
struct AppIconTests {
    private typealias Object = [String: Any]

    /// リポジトリの最上位（このファイルは OshiConTests/Appearance/ にある）。
    private static let repository = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private static let alternateColors = OshiColor.allCases.filter { $0 != .pink }

    // MARK: - アイコンの名前

    @Test("ピンクは主アイコン（nil）、ほかの 11 色はそれぞれ別の代替アイコンの名前")
    func names() {
        #expect(AppIconRule.alternateIconName(for: .pink) == nil)
        let names = Self.alternateColors.compactMap(AppIconRule.alternateIconName(for:))
        #expect(names.count == 11)
        #expect(Set(names).count == 11)
        #expect(AppIconRule.alternateIconName(for: .mint) == "AppIcon-Mint")
    }

    @Test("アイコンの名前から色を引ける。nil はピンク、知らない名前は nil", arguments: OshiColor.allCases)
    func colorForName(color: OshiColor) {
        #expect(AppIconRule.color(forAlternateIconName: AppIconRule.alternateIconName(for: color)) == color)
        #expect(AppIconRule.color(forAlternateIconName: "AppIcon-Unknown") == nil)
    }

    @Test("ホーム画面に出すのは、Plus が使えれば選んだ色、使えなければどの色を選んでいても主アイコン", arguments: OshiColor.allCases)
    func iconName(selected: OshiColor) {
        #expect(AppIconRule.iconName(selected: selected, isPlusUnlocked: true) == AppIconRule.alternateIconName(for: selected))
        #expect(AppIconRule.iconName(selected: selected, isPlusUnlocked: false) == nil)
    }

    @Test("今のアイコンと同じなら替えない。違えば替える。端末が代替アイコンを使えなければ替えない")
    func request() {
        #expect(AppIconRule.request(desired: nil, current: nil, supportsAlternateIcons: true) == .keep)
        #expect(AppIconRule.request(desired: "AppIcon-Mint", current: "AppIcon-Mint", supportsAlternateIcons: true) == .keep)
        #expect(AppIconRule.request(desired: "AppIcon-Mint", current: nil, supportsAlternateIcons: true) == .change(to: "AppIcon-Mint"))
        #expect(AppIconRule.request(desired: nil, current: "AppIcon-Mint", supportsAlternateIcons: true) == .change(to: nil))
        let switched = AppIconRule.request(desired: "AppIcon-Navy", current: "AppIcon-Mint", supportsAlternateIcons: true)
        #expect(switched == .change(to: "AppIcon-Navy"))
        #expect(AppIconRule.request(desired: "AppIcon-Mint", current: nil, supportsAlternateIcons: false) == .keep)
    }

    // MARK: - 設定

    @Test("アイコンの色は、書いたことが無ければピンク。書いた色を読め、知らない値はピンク")
    func settings() throws {
        let defaults = try AppearanceFixtures.makeDefaults()
        #expect(AppearanceSettings(defaults: defaults).appIconColor == .pink)

        var settings = AppearanceSettings()
        settings.appIconColor = .mint
        settings.write(to: defaults)
        #expect(defaults.string(forKey: AppStorageKey.appearanceAppIcon) == "mint")
        #expect(AppearanceSettings(defaults: defaults) == settings)

        defaults.set("rainbow", forKey: AppStorageKey.appearanceAppIcon)
        #expect(AppearanceSettings(defaults: defaults).appIconColor == .pink)
    }

    @Test("Plus でなくても選んだ色を書き、作り直しても読める。描く着せ替え（地）は変えない")
    @MainActor
    func storeKeepsColor() throws {
        let defaults = try AppearanceFixtures.makeDefaults()
        let store = AppearanceStore(defaults: defaults, photos: OshiPhotoLibrary(directory: FileManager.default.temporaryDirectory))
        store.appIconColor = .navy
        #expect(AppearanceStore(defaults: defaults, photos: store.photos).appIconColor == .navy)
        #expect(store.rendering(isPlusUnlocked: true) == AppearanceRendering(settings: AppearanceSettings(), isPlusUnlocked: true))
    }

    // MARK: - 色

    @Test("ライトは推し色の地に白いハート。ダークは暗い地に淡いハートで、ライトの地より暗く、ハートとの差が 7:1 以上", arguments: OshiColor.allCases)
    func palette(color: OshiColor) {
        #expect(AppIconPalette.ground(of: color, isDark: false) == color.rgb)
        #expect(AppIconPalette.heart(of: color, isDark: false) == .white)
        let darkGround = AppIconPalette.ground(of: color, isDark: true)
        let darkHeart = AppIconPalette.heart(of: color, isDark: true)
        #expect(darkGround.relativeLuminance < color.rgb.relativeLuminance)
        #expect(darkHeart.contrastRatio(with: darkGround) >= 7)
    }

    @Test("ピンクのダークは今のアイコン（暗い地 #200D15・ハート #FFB1C8）のまま")
    func pinkKeepsCurrentIcon() {
        #expect(AppIconPalette.ground(of: .pink, isDark: true) == RGBColor(hex: 0x200D15))
        #expect(AppIconPalette.heart(of: .pink, isDark: true) == RGBColor(hex: 0xFFB1C8))
    }

    // MARK: - アプリに入ったアイコン

    @Test("アプリの Info.plist に、主アイコン AppIcon と 11 色の代替アイコンが入っている（iPhone と iPad）", arguments: ["CFBundleIcons", "CFBundleIcons~ipad"])
    func infoPlist(key: String) throws {
        // テストはアプリの中で動くので、Bundle.main がアプリになる。
        // Bundle の Info.plist は端末に合わない `~ipad` のキーを畳むので、ファイルをそのまま読む
        let url = Bundle.main.bundleURL.appending(path: "Info.plist")
        let plist = try #require(try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? Object)
        let icons = try #require(plist[key] as? Object, "\(key)")
        let primary = try #require(icons["CFBundlePrimaryIcon"] as? Object)
        #expect(primary["CFBundleIconName"] as? String == "AppIcon")
        let alternates = try #require(icons["CFBundleAlternateIcons"] as? Object)
        let expected = Set(Self.alternateColors.compactMap(AppIconRule.alternateIconName(for:)))
        #expect(Set(alternates.keys) == expected)
        for (name, value) in alternates {
            #expect((value as? Object)?["CFBundleIconName"] as? String == name)
        }
    }

    @Test("Icon Composer のファイルの色が AppIconPalette と同じで、図柄・影・透け方は主アイコンのまま", arguments: OshiColor.allCases)
    func iconComposerFile(color: OshiColor) throws {
        let primary = try Self.iconDocument(named: "AppIcon")
        let name = AppIconRule.alternateIconName(for: color) ?? "AppIcon"
        let icon = try Self.iconDocument(named: name)

        let fills = try #require(icon["fill-specializations"] as? [Object])
        #expect(try Self.color(in: fills, appearance: nil) == AppIconPalette.ground(of: color, isDark: false))
        #expect(try Self.color(in: fills, appearance: "dark") == AppIconPalette.ground(of: color, isDark: true))

        let groups = try #require(icon["groups"] as? [Object])
        let layers = try #require(groups.first?["layers"] as? [Object])
        #expect(groups.count == 1 && layers.count == 1)
        let heart = try #require(layers.first)
        #expect(heart["image-name"] as? String == "heart.svg")
        let heartFills = try #require(heart["fill-specializations"] as? [Object])
        #expect(try Self.color(in: heartFills, appearance: "dark") == AppIconPalette.heart(of: color, isDark: true))

        // 色のほか（影・透け方・対応する形）は主アイコンと同じ
        var group = groups[0]
        var primaryGroup = try #require((primary["groups"] as? [Object])?.first)
        group["layers"] = nil
        primaryGroup["layers"] = nil
        #expect(NSDictionary(dictionary: group).isEqual(to: primaryGroup))
        #expect(NSDictionary(dictionary: try #require(icon["supported-platforms"] as? Object))
            .isEqual(to: try #require(primary["supported-platforms"] as? Object)))

        // 図柄のハートの形は主アイコンと同じ
        let path = try Self.heartPath(in: name)
        let primaryPath = try Self.heartPath(in: "AppIcon")
        #expect(path == primaryPath)
    }

    @Test("リポジトリの代替アイコンのファイルは 11 色ぶんだけ")
    func alternateIconFiles() throws {
        let directory = Self.repository.appending(path: "OshiCon/AlternateAppIcons")
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false))
            .filter { $0.hasSuffix(".icon") }
        let expected = Self.alternateColors.compactMap(AppIconRule.alternateIconName(for:)).map { "\($0).icon" }
        #expect(Set(files) == Set(expected))
    }

    private static func iconDirectory(named name: String) -> URL {
        name == "AppIcon"
            ? repository.appending(path: "OshiCon/AppIcon.icon")
            : repository.appending(path: "OshiCon/AlternateAppIcons/\(name).icon")
    }

    private static func iconDocument(named name: String) throws -> Object {
        let data = try Data(contentsOf: iconDirectory(named: name).appending(path: "icon.json"))
        return try #require(try JSONSerialization.jsonObject(with: data) as? Object)
    }

    /// `fill-specializations` のうち、外観 `appearance`（nil は既定）の単色。
    private static func color(in fills: [Object], appearance: String?) throws -> RGBColor {
        let fill = try #require(fills.first { $0["appearance"] as? String == appearance })
        let solid = try #require((fill["value"] as? Object)?["solid"] as? String)
        // "srgb:r,g,b,a"（0〜1 の小数 5 桁）
        let channels = try #require(solid.split(separator: ":").last).split(separator: ",").compactMap { Double($0) }
        try #require(channels.count == 4)
        // 小数 5 桁から 0〜255 に戻す
        func byte(_ value: Double) -> Double {
            (value * 255).rounded() / 255
        }
        return RGBColor(red: byte(channels[0]), green: byte(channels[1]), blue: byte(channels[2]))
    }

    /// 図柄の SVG のハートの形（path の d）。
    private static func heartPath(in name: String) throws -> String {
        let svg = try String(contentsOf: iconDirectory(named: name).appending(path: "Assets/heart.svg"), encoding: .utf8)
        let start = try #require(svg.range(of: " d=\""))
        let rest = svg[start.upperBound...]
        let end = try #require(rest.firstIndex(of: "\""))
        return String(rest[..<end])
    }
}

/// 「アイコン」のタブの見本の大きさ。
struct AppIconPreviewMetricsTests {
    @Test("縦向きの iPhone の舞台では、大きいアイコンをデザインの 132pt、小さいアイコンを 60pt にする")
    func designSize() {
        let metrics = AppIconPreviewMetrics(size: CGSize(width: 362, height: 420), isAccessibilitySize: false)
        #expect(metrics.largeSide == 132)
        #expect(abs(metrics.smallSide - 60) < 0.001)
    }

    @Test("低い舞台では、大きいアイコン・名前・小さいアイコンが高さに収まるよう小さくする")
    func fitsHeight() {
        let size = CGSize(width: 362, height: 200)
        let metrics = AppIconPreviewMetrics(size: size, isAccessibilitySize: false)
        let fixed = AppIconPreviewMetrics.nameSpacing + AppIconPreviewMetrics.samplesSpacing
            + AppIconPreviewMetrics.sampleLabelSpacing + AppIconPreviewMetrics.textHeight
        #expect(metrics.largeSide < 132)
        #expect(metrics.largeSide + metrics.smallSide + fixed <= size.height + 0.001)
    }

    @Test("細い舞台では幅に収め、とても小さい舞台でも 48pt より小さくしない")
    func fitsWidthAndMinimum() {
        let narrow = AppIconPreviewMetrics(size: CGSize(width: 100, height: 600), isAccessibilitySize: false)
        #expect(narrow.largeSide <= 100)
        #expect(narrow.smallSide * 2 + AppIconPreviewMetrics.smallSpacing <= 100 + 0.001)
        let tiny = AppIconPreviewMetrics(size: CGSize(width: 10, height: 10), isAccessibilitySize: true)
        #expect(tiny.largeSide == AppIconPreviewMetrics.minimumLargeSide)
    }

    @Test("アクセシビリティの大きな文字では、文字の分を多く空ける")
    func accessibilitySize() {
        let size = CGSize(width: 362, height: 240)
        let regular = AppIconPreviewMetrics(size: size, isAccessibilitySize: false)
        let large = AppIconPreviewMetrics(size: size, isAccessibilitySize: true)
        #expect(large.largeSide < regular.largeSide)
    }
}
