//
//  AppearanceSettings.swift
//  OshiCon
//

import CoreGraphics
import Foundation

/// 推し活カウントダウン Plus の着せ替えの設定。アプリ全体で 1 つ。
///
/// アプリだけの UserDefaults（`AppStorageKey`。`PrivacyInfo.xcprivacy` の CA92.1）に置き、SwiftData のスキーマは変えない。
/// 背景の写真のファイルは推しの写真と同じ置き場所（`OshiPhotoLibrary`。App Group のコンテナ）に置く。
/// Plus が使えなくなっても設定とファイルは残す（描くものは `AppearanceRendering` が決める）。
nonisolated struct AppearanceSettings: Equatable, Sendable {
    /// 背景の写真をホームと予定の詳細の地に敷く（写真を選んだときだけ効く）。既定は ON。
    var isBackgroundEnabled: Bool
    /// 地のハートと十字の代わりに、推しの丸い写真を並べる。既定は OFF。
    var isDecorationEnabled: Bool
    /// 背景の写真に掛ける暗幕とぼかしの強さ。
    var intensity: AppearanceIntensity
    /// 背景の写真のファイル名（`OshiPhotoLibrary` の中の `<UUID>.jpg`）。選んでいなければ nil。
    var backgroundPhotoFileName: String?
    /// 飾りの濃さ・量・出す推し。飾りが OFF でも残す。
    var decorationStyle: OshiPhotoDecorationStyle

    init(
        isBackgroundEnabled: Bool = true,
        isDecorationEnabled: Bool = false,
        intensity: AppearanceIntensity = .default,
        backgroundPhotoFileName: String? = nil,
        decorationStyle: OshiPhotoDecorationStyle = .default
    ) {
        self.isBackgroundEnabled = isBackgroundEnabled
        self.isDecorationEnabled = isDecorationEnabled
        self.intensity = intensity
        self.backgroundPhotoFileName = backgroundPhotoFileName
        self.decorationStyle = decorationStyle
    }

    /// UserDefaults から読む。書いていない項目は既定の値。写真の置き場所の外を指すファイル名は無いものとする。
    /// 飾りの濃さ・量は範囲に収め、出さない推しの id は UUID として読めるものだけを使う。
    init(defaults: UserDefaults) {
        let fileName = defaults.string(forKey: AppStorageKey.appearanceBackgroundPhoto)
        let intensity = defaults.string(forKey: AppStorageKey.appearanceIntensity).flatMap(AppearanceIntensity.init(rawValue:))
        let opacity = defaults.object(forKey: AppStorageKey.appearanceDecorationOpacity) as? Double
        let amount = defaults.object(forKey: AppStorageKey.appearanceDecorationAmount) as? Double
        let excluded = defaults.stringArray(forKey: AppStorageKey.appearanceDecorationExcludedOshis) ?? []
        self.init(
            isBackgroundEnabled: defaults.object(forKey: AppStorageKey.appearanceBackgroundEnabled) as? Bool ?? true,
            isDecorationEnabled: defaults.object(forKey: AppStorageKey.appearanceDecorationEnabled) as? Bool ?? false,
            intensity: intensity ?? .default,
            backgroundPhotoFileName: fileName.flatMap { OshiPhotoLibrary.isValidFileName($0) ? $0 : nil },
            decorationStyle: OshiPhotoDecorationStyle(
                opacity: opacity ?? OshiPhotoDecorationStyle.defaultOpacity,
                amount: amount ?? OshiPhotoDecorationStyle.defaultAmount,
                excludedOshiIDs: Set(excluded.compactMap(UUID.init(uuidString:)))
            )
        )
    }

    /// UserDefaults に書く。写真が無ければファイル名のキーを消す。出さない推しの id は並べて書く（同じ設定なら同じ値になる）。
    func write(to defaults: UserDefaults) {
        defaults.set(isBackgroundEnabled, forKey: AppStorageKey.appearanceBackgroundEnabled)
        defaults.set(isDecorationEnabled, forKey: AppStorageKey.appearanceDecorationEnabled)
        defaults.set(intensity.rawValue, forKey: AppStorageKey.appearanceIntensity)
        defaults.set(decorationStyle.opacity, forKey: AppStorageKey.appearanceDecorationOpacity)
        defaults.set(decorationStyle.amount, forKey: AppStorageKey.appearanceDecorationAmount)
        defaults.set(decorationStyle.excludedOshiIDs.map(\.uuidString).sorted(), forKey: AppStorageKey.appearanceDecorationExcludedOshis)
        if let backgroundPhotoFileName {
            defaults.set(backgroundPhotoFileName, forKey: AppStorageKey.appearanceBackgroundPhoto)
        } else {
            defaults.removeObject(forKey: AppStorageKey.appearanceBackgroundPhoto)
        }
    }
}

/// 背景の写真に掛ける暗幕とぼかしの強さ（弱・中・強）。
///
/// 幕の色はライトでは地の色（`palette.background`）、ダークでは黒。背景の推しが見えるよう、幕は薄く、ぼかしは小さくする（弱はぼかさない）。
/// 幕では文字の読みやすさを守らない。背景の写真を敷いているときは、地の上に直接描く文字（見出し・案内）の後ろに
/// カードの地の色の板を敷き（`AppearanceTextPlate`）、写真の色や幕の濃さによらず 4.5:1 以上にする。
/// 飾り（推しの丸い写真）を重ねるときは、写真の上でも丸い写真が見分けられるよう幕を少し濃くする。
nonisolated enum AppearanceIntensity: String, CaseIterable, Sendable {
    case weak
    case medium
    case strong

    static let `default` = Self.medium

    /// 縦長の写真の左右の余り（iPad・横向き）を埋める、同じ写真のぼかしの半径（pt）。どの強さでも同じ。
    static let sideFillBlurRadius: CGFloat = 60

    /// ホームの地の上の端に掛ける、幕の色のグラデーションの高さ（pt。ステータスバーより少し下まで）。
    /// 幕が薄いので、写真の色によってはステータスバーの文字（時刻・電池）が読めなくなる。上の端だけ幕の色で覆う。
    static let statusBarFadeHeight: CGFloat = 110

    /// 上の端のグラデーションの、いちばん上の不透明度。写真が真っ白・真っ黒でもステータスバーの文字（ライトは黒、ダークは白）が 4.5:1 以上になる濃さ。
    static let statusBarFadeOpacity = 0.85

    /// 写真に掛ける幕の不透明度（0〜1）。`isDecorated` は、写真の上に飾り（推しの丸い写真）を重ねるか。
    func scrimOpacity(isDark: Bool, isDecorated: Bool) -> Double {
        isDecorated ? decoratedScrimOpacity(isDark: isDark) : plainScrimOpacity(isDark: isDark)
    }

    /// 飾りを重ねないときの幕の不透明度。弱は写真がほぼそのまま見える薄さにし、弱・中・強の違いが分かるよう 0.15 ずつ離す。
    /// ダークは地を暗く保つため、ライトより 0.1 濃くする。
    private func plainScrimOpacity(isDark: Bool) -> Double {
        switch (self, isDark) {
        case (.weak, false):
            0.15
        case (.medium, false):
            0.30
        case (.strong, false):
            0.45
        case (.weak, true):
            0.25
        case (.medium, true):
            0.40
        case (.strong, true):
            0.55
        }
    }

    /// 飾りを重ねるときの幕の不透明度。重ねないときより 0.2 濃くし、写真の上でも丸い写真が見分けられるようにする。
    private func decoratedScrimOpacity(isDark: Bool) -> Double {
        switch (self, isDark) {
        case (.weak, false):
            0.35
        case (.medium, false):
            0.50
        case (.strong, false):
            0.65
        case (.weak, true):
            0.45
        case (.medium, true):
            0.60
        case (.strong, true):
            0.75
        }
    }

    /// 写真に掛けるぼかしの半径（pt）。弱は推しがはっきり見えるようぼかさない。
    var blurRadius: CGFloat {
        switch self {
        case .weak:
            0
        case .medium:
            4
        case .strong:
            10
        }
    }

    /// 写真に掛ける幕の色。ライトでは地の色、ダークでは黒。
    static func scrimColor(in theme: AppTheme) -> AdaptiveColor {
        AdaptiveColor(light: theme.palette.background.light, dark: .black)
    }

    /// 色 `photo` の写真に幕を掛けた後の地の色（ぼかしは色を変えないので数えない）。コントラストを確かめるのに使う。
    func ground(over photo: RGBColor, in theme: AppTheme, isDark: Bool, isDecorated: Bool) -> RGBColor {
        photo.mixed(
            with: Self.scrimColor(in: theme).resolved(isDark: isDark),
            fraction: scrimOpacity(isDark: isDark, isDecorated: isDecorated)
        )
    }
}

/// 着せ替えで実際に描くもの。Plus が使えるかと設定（`AppearanceSettings`）から決める。
///
/// Plus が使えないときは標準（背景の写真も推しの写真の飾りも無し）にする。設定とファイルはそのまま残す（また使えるようになったら戻る）。
nonisolated struct AppearanceRendering: Equatable, Sendable {
    /// 地に敷く背景の写真。
    nonisolated struct BackgroundPhoto: Equatable, Sendable {
        let fileName: String
        let intensity: AppearanceIntensity
    }

    /// 地に敷く背景の写真。敷かないときは nil。
    let backgroundPhoto: BackgroundPhoto?
    /// 地に並べる推しの丸い写真の飾りの濃さ・量・出す推し。飾りを描かないときは nil。
    let decoration: OshiPhotoDecorationStyle?

    /// 標準の見た目（着せ替えなし）。
    static let standard = Self(backgroundPhoto: nil, decoration: nil)

    init(backgroundPhoto: BackgroundPhoto?, decoration: OshiPhotoDecorationStyle?) {
        self.backgroundPhoto = backgroundPhoto
        self.decoration = decoration
    }

    /// 地のハートと十字の代わりに、推しの丸い写真の飾りを描くか。
    var showsOshiPhotoDecoration: Bool {
        decoration != nil
    }

    /// Plus が使えるかと設定から決める。背景の写真は、Plus が使え、背景を ON にしていて、写真を選んでいるときだけ敷く。
    init(settings: AppearanceSettings, isPlusUnlocked: Bool) {
        guard isPlusUnlocked else {
            self = .standard
            return
        }
        if settings.isBackgroundEnabled,
           let fileName = settings.backgroundPhotoFileName,
           OshiPhotoLibrary.isValidFileName(fileName) {
            backgroundPhoto = BackgroundPhoto(fileName: fileName, intensity: settings.intensity)
        } else {
            backgroundPhoto = nil
        }
        // 飾りが OFF のときは濃さ・量を持たない（設定に残っていても標準の見た目と同じにする）
        decoration = settings.isDecorationEnabled ? settings.decorationStyle : nil
    }

    /// 標準の見た目か。
    var isStandard: Bool {
        self == .standard
    }
}
