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
    /// 背景の写真に掛ける暗幕の濃さとぼかしの強さ。背景が OFF でも残す。
    var backgroundStyle: AppearanceBackgroundStyle
    /// 背景の写真のファイル名（`OshiPhotoLibrary` の中の `<UUID>.jpg`）。選んでいなければ nil。
    var backgroundPhotoFileName: String?
    /// 飾りの濃さ・量・出す推し。飾りが OFF でも残す。
    var decorationStyle: OshiPhotoDecorationStyle

    init(
        isBackgroundEnabled: Bool = true,
        isDecorationEnabled: Bool = false,
        backgroundStyle: AppearanceBackgroundStyle = .default,
        backgroundPhotoFileName: String? = nil,
        decorationStyle: OshiPhotoDecorationStyle = .default
    ) {
        self.isBackgroundEnabled = isBackgroundEnabled
        self.isDecorationEnabled = isDecorationEnabled
        self.backgroundStyle = backgroundStyle
        self.backgroundPhotoFileName = backgroundPhotoFileName
        self.decorationStyle = decorationStyle
    }

    /// UserDefaults から読む。書いていない項目は既定の値。写真の置き場所の外を指すファイル名は無いものとする。
    /// 暗幕・ぼかし・飾りの濃さ・量は範囲に収め、出さない推しの id は UUID として読めるものだけを使う。
    /// 暗幕とぼかしを書いていなければ、前の版の強さ（弱・中・強。`AppStorageKey.appearanceIntensity`）から読み替える。
    init(defaults: UserDefaults) {
        let fileName = defaults.string(forKey: AppStorageKey.appearanceBackgroundPhoto)
        let legacyStyle = defaults.string(forKey: AppStorageKey.appearanceIntensity)
            .flatMap(AppearanceBackgroundStyle.init(legacyIntensity:)) ?? .default
        let scrim = defaults.object(forKey: AppStorageKey.appearanceBackgroundScrim) as? Double
        let blur = defaults.object(forKey: AppStorageKey.appearanceBackgroundBlur) as? Double
        let opacity = defaults.object(forKey: AppStorageKey.appearanceDecorationOpacity) as? Double
        let amount = defaults.object(forKey: AppStorageKey.appearanceDecorationAmount) as? Double
        let excluded = defaults.stringArray(forKey: AppStorageKey.appearanceDecorationExcludedOshis) ?? []
        self.init(
            isBackgroundEnabled: defaults.object(forKey: AppStorageKey.appearanceBackgroundEnabled) as? Bool ?? true,
            isDecorationEnabled: defaults.object(forKey: AppStorageKey.appearanceDecorationEnabled) as? Bool ?? false,
            backgroundStyle: AppearanceBackgroundStyle(scrim: scrim ?? legacyStyle.scrim, blur: blur ?? legacyStyle.blur),
            backgroundPhotoFileName: fileName.flatMap { OshiPhotoLibrary.isValidFileName($0) ? $0 : nil },
            decorationStyle: OshiPhotoDecorationStyle(
                opacity: opacity ?? OshiPhotoDecorationStyle.defaultOpacity,
                amount: amount ?? OshiPhotoDecorationStyle.defaultAmount,
                excludedOshiIDs: Set(excluded.compactMap(UUID.init(uuidString:)))
            )
        )
    }

    /// UserDefaults に書く。写真が無ければファイル名のキーを消す。出さない推しの id は並べて書く（同じ設定なら同じ値になる）。
    /// 暗幕とぼかしを書いたら、前の版の強さのキーは使わないので消す。
    func write(to defaults: UserDefaults) {
        defaults.set(isBackgroundEnabled, forKey: AppStorageKey.appearanceBackgroundEnabled)
        defaults.set(isDecorationEnabled, forKey: AppStorageKey.appearanceDecorationEnabled)
        defaults.set(backgroundStyle.scrim, forKey: AppStorageKey.appearanceBackgroundScrim)
        defaults.set(backgroundStyle.blur, forKey: AppStorageKey.appearanceBackgroundBlur)
        defaults.removeObject(forKey: AppStorageKey.appearanceIntensity)
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

/// 背景の写真に掛ける暗幕の濃さとぼかしの強さ。着せ替えの画面の 2 つのスライダー（0〜1）で変える。
///
/// 幕の色はライトでは地の色（`palette.background`）、ダークでは黒。背景の推しが見えるよう、いちばん濃く・強くしても
/// 幕は 0.6（ライト・飾りなし）、ぼかしは 10pt までにする。
/// 幕では文字の読みやすさを守らない。背景の写真を敷いているときは、地の上に直接描く文字（見出し・案内）の後ろに
/// カードの地の色の板を敷き（`AppearanceTextPlate`）、写真の色や幕の濃さによらず 4.5:1 以上にする。
/// 飾り（推しの丸い写真）を重ねるときは、写真の上でも丸い写真が見分けられるよう幕を少し濃くする。
nonisolated struct AppearanceBackgroundStyle: Equatable, Sendable {
    /// 暗幕の濃さ（スライダーの位置）の範囲。0 は幕なし（ライト・飾りなし）、1 はいちばん濃い。
    static let scrimRange: ClosedRange<Double> = 0...1
    /// ぼかしの強さ（スライダーの位置）の範囲。0 はぼかさない、1 はいちばん強い。
    static let blurRange: ClosedRange<Double> = 0...1
    /// 暗幕の濃さの既定。前の版の「中」（幕 0.30）と同じ。
    static let defaultScrim = 0.5
    /// ぼかしの強さの既定。前の版の「中」（4pt）と同じ。
    static let defaultBlur = 0.4

    /// 暗幕の濃さをいちばん濃くしたときの、ライトで飾りを重ねないときの幕の不透明度。前の版の「強」（0.45）が位置 0.75 になる。
    static let maxPlainScrimOpacity = 0.6
    /// ダークの外観で幕に足す不透明度。地を暗く保つため、ライトより濃くする。
    static let darkScrimOffset = 0.1
    /// 飾り（推しの丸い写真）を重ねるときに幕に足す不透明度。写真の上でも丸い写真が見分けられるようにする。
    static let decoratedScrimOffset = 0.2
    /// ぼかしの強さをいちばん強くしたときの半径（pt）。前の版の「強」と同じ。
    static let maxBlurRadius: CGFloat = 10

    static let `default` = Self()

    /// 縦長の写真の左右の余り（iPad・横向き）を埋める、同じ写真のぼかしの半径（pt）。暗幕とぼかしの設定によらず同じ。
    static let sideFillBlurRadius: CGFloat = 60

    /// ホームの地の上の端に掛ける、幕の色のグラデーションの高さ（pt。ステータスバーより少し下まで）。
    /// 幕は薄くでき、飾り（推しの丸い写真）は濃くできるので、写真の色によってはステータスバーの文字（時刻・電池）が読めなくなる。上の端だけ幕の色で覆う。
    static let statusBarFadeHeight: CGFloat = 110

    /// 上の端のグラデーションの、いちばん上の不透明度。写真が真っ白・真っ黒でもステータスバーの文字（ライトは黒、ダークは白）が 4.5:1 以上になる濃さ。
    static let statusBarFadeOpacity = 0.85

    /// 暗幕の濃さ（スライダーの位置）。範囲の外の値は範囲に収める。
    var scrim: Double {
        didSet {
            scrim = Self.clamped(scrim, to: Self.scrimRange, fallback: Self.defaultScrim)
        }
    }

    /// ぼかしの強さ（スライダーの位置）。範囲の外の値は範囲に収める。
    var blur: Double {
        didSet {
            blur = Self.clamped(blur, to: Self.blurRange, fallback: Self.defaultBlur)
        }
    }

    init(scrim: Double = defaultScrim, blur: Double = defaultBlur) {
        self.scrim = Self.clamped(scrim, to: Self.scrimRange, fallback: Self.defaultScrim)
        self.blur = Self.clamped(blur, to: Self.blurRange, fallback: Self.defaultBlur)
    }

    /// 前の版（TestFlight）で保存した強さ（`weak`・`medium`・`strong`）を、同じ見た目になるスライダーの位置にする。知らない値なら nil。
    init?(legacyIntensity: String) {
        switch legacyIntensity {
        case "weak":
            self.init(scrim: 0.25, blur: 0)
        case "medium":
            self.init(scrim: 0.5, blur: 0.4)
        case "strong":
            self.init(scrim: 0.75, blur: 1)
        default:
            return nil
        }
    }

    /// 写真に掛ける幕の不透明度（0〜1）。`isDecorated` は、写真の上に飾り（推しの丸い写真）を重ねるか。
    /// ライトで飾りを重ねないときは 0〜0.6 で、ダークは 0.1、飾りを重ねるときは 0.2 濃くする（いちばん濃くて 0.9）。
    func scrimOpacity(isDark: Bool, isDecorated: Bool) -> Double {
        Self.maxPlainScrimOpacity * scrim
            + (isDark ? Self.darkScrimOffset : 0)
            + (isDecorated ? Self.decoratedScrimOffset : 0)
    }

    /// 写真に掛けるぼかしの半径（pt）。0 ならぼかさない。
    var blurRadius: CGFloat {
        Self.maxBlurRadius * CGFloat(blur)
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

    private static func clamped(_ value: Double, to range: ClosedRange<Double>, fallback: Double) -> Double {
        value.isNaN ? fallback : min(max(value, range.lowerBound), range.upperBound)
    }
}

/// 着せ替えで実際に描くもの。Plus が使えるかと設定（`AppearanceSettings`）から決める。
///
/// Plus が使えないときは標準（背景の写真も推しの写真の飾りも無し）にする。設定とファイルはそのまま残す（また使えるようになったら戻る）。
nonisolated struct AppearanceRendering: Equatable, Sendable {
    /// 地に敷く背景の写真。
    nonisolated struct BackgroundPhoto: Equatable, Sendable {
        let fileName: String
        let style: AppearanceBackgroundStyle
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
            backgroundPhoto = BackgroundPhoto(fileName: fileName, style: settings.backgroundStyle)
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

    /// 地に写真（背景の写真か、推しの丸い写真の飾り）を描くか。
    ///
    /// 描くときは、写真の色や濃さによらず読めるよう、ホームの地の上に直接描く文字の後ろに板を敷き（`AppearanceTextPlate`）、
    /// ホームの上の端をステータスバーのために幕の色で覆う（`AppearanceStatusBarFade`）。
    /// 飾りだけで写真のある推しがいない（テーマの模様のまま）ときも、同じにする（出す推しが変わるたびに見出しが変わらないように）。
    var drawsPhotosOnGround: Bool {
        !isStandard
    }
}
