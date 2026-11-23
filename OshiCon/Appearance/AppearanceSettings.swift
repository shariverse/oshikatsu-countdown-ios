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
    /// 地のハートと十字を、写真のある推しの丸い写真に替える。既定は OFF。
    var isDecorationEnabled: Bool
    /// 背景の写真に掛ける暗幕とぼかしの強さ。
    var intensity: AppearanceIntensity
    /// 背景の写真のファイル名（`OshiPhotoLibrary` の中の `<UUID>.jpg`）。選んでいなければ nil。
    var backgroundPhotoFileName: String?

    init(
        isBackgroundEnabled: Bool = true,
        isDecorationEnabled: Bool = false,
        intensity: AppearanceIntensity = .default,
        backgroundPhotoFileName: String? = nil
    ) {
        self.isBackgroundEnabled = isBackgroundEnabled
        self.isDecorationEnabled = isDecorationEnabled
        self.intensity = intensity
        self.backgroundPhotoFileName = backgroundPhotoFileName
    }

    /// UserDefaults から読む。書いていない項目は既定の値。写真の置き場所の外を指すファイル名は無いものとする。
    init(defaults: UserDefaults) {
        let fileName = defaults.string(forKey: AppStorageKey.appearanceBackgroundPhoto)
        let intensity = defaults.string(forKey: AppStorageKey.appearanceIntensity).flatMap(AppearanceIntensity.init(rawValue:))
        self.init(
            isBackgroundEnabled: defaults.object(forKey: AppStorageKey.appearanceBackgroundEnabled) as? Bool ?? true,
            isDecorationEnabled: defaults.object(forKey: AppStorageKey.appearanceDecorationEnabled) as? Bool ?? false,
            intensity: intensity ?? .default,
            backgroundPhotoFileName: fileName.flatMap { OshiPhotoLibrary.isValidFileName($0) ? $0 : nil }
        )
    }

    /// UserDefaults に書く。写真が無ければファイル名のキーを消す。
    func write(to defaults: UserDefaults) {
        defaults.set(isBackgroundEnabled, forKey: AppStorageKey.appearanceBackgroundEnabled)
        defaults.set(isDecorationEnabled, forKey: AppStorageKey.appearanceDecorationEnabled)
        defaults.set(intensity.rawValue, forKey: AppStorageKey.appearanceIntensity)
        if let backgroundPhotoFileName {
            defaults.set(backgroundPhotoFileName, forKey: AppStorageKey.appearanceBackgroundPhoto)
        } else {
            defaults.removeObject(forKey: AppStorageKey.appearanceBackgroundPhoto)
        }
    }
}

/// 背景の写真に掛ける暗幕とぼかしの強さ（弱・中・強）。
///
/// 幕の色はライトでは地の色（`palette.background`）、ダークでは黒。幕の不透明度は、写真が真っ白・真っ黒のときでも、
/// 地の上に直接描く文字（見出し・案内。本文の色 `onSurface`・`onSurfaceVariant`）が 4.5:1 以上になる値にする（`AppearanceIntensityTests`）。
/// 推し色の文字はカードの上に描くので数えない（飾りの `OshiPhotoDecoration` と同じ基準）。
/// 飾り（推しの丸い写真）を重ねないときは、写真が見えるよう本文の色だけで 4.5:1 を守れる薄さにする。
/// 飾りを重ねるときだけ、丸い写真が真っ白・真っ黒でも 4.5:1 以上になるよう幕を濃くする（`OshiPhotoDecorationTests`）。
nonisolated enum AppearanceIntensity: String, CaseIterable, Sendable {
    case weak
    case medium
    case strong

    static let `default` = Self.medium

    /// 縦長の写真の左右の余り（iPad・横向き）を埋める、同じ写真のぼかしの半径（pt）。どの強さでも同じ。
    static let sideFillBlurRadius: CGFloat = 60

    /// 写真に掛ける幕の不透明度（0〜1）。`isDecorated` は、写真の上に飾り（推しの丸い写真）を重ねるか。
    func scrimOpacity(isDark: Bool, isDecorated: Bool) -> Double {
        isDecorated ? decoratedScrimOpacity(isDark: isDark) : plainScrimOpacity(isDark: isDark)
    }

    /// 飾りを重ねないときの幕の不透明度。弱・中・強の違いが分かるよう 0.06 ずつ離す。
    private func plainScrimOpacity(isDark: Bool) -> Double {
        switch (self, isDark) {
        case (.weak, false):
            0.74
        case (.medium, false):
            0.80
        case (.strong, false):
            0.86
        case (.weak, true):
            0.70
        case (.medium, true):
            0.76
        case (.strong, true):
            0.82
        }
    }

    /// 飾りを重ねるときの幕の不透明度。飾りの分の余裕を残し、弱・中・強の違いが分かるよう 0.05 ずつ離す。
    private func decoratedScrimOpacity(isDark: Bool) -> Double {
        switch (self, isDark) {
        case (.weak, false):
            0.86
        case (.medium, false):
            0.91
        case (.strong, false):
            0.96
        case (.weak, true):
            0.82
        case (.medium, true):
            0.87
        case (.strong, true):
            0.92
        }
    }

    /// 写真に掛けるぼかしの半径（pt）。
    var blurRadius: CGFloat {
        switch self {
        case .weak:
            12
        case .medium:
            20
        case .strong:
            30
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
    /// 地のハートと十字を、写真のある推しの丸い写真に替えるか。
    let showsOshiPhotoDecoration: Bool

    /// 標準の見た目（着せ替えなし）。
    static let standard = Self(backgroundPhoto: nil, showsOshiPhotoDecoration: false)

    init(backgroundPhoto: BackgroundPhoto?, showsOshiPhotoDecoration: Bool) {
        self.backgroundPhoto = backgroundPhoto
        self.showsOshiPhotoDecoration = showsOshiPhotoDecoration
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
        showsOshiPhotoDecoration = settings.isDecorationEnabled
    }

    /// 標準の見た目か。
    var isStandard: Bool {
        self == .standard
    }
}
