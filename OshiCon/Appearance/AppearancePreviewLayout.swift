//
//  AppearancePreviewLayout.swift
//  OshiCon
//

import CoreGraphics

/// 着せ替えの画面で、ホームの見本と設定（Form）をどう並べ、見本をどの大きさで見せるか。画面から切り離してテストする。
///
/// 見本はスクロールする設定の外に置き、どの設定を変えているときも見えるようにする。
/// - 幅の狭い画面（縦向きの iPhone・iPad の狭い分割）: 見本を上に固定し、その下で設定をスクロールする（`.pinnedTop`）。
///   見本の帯は画面の高さの 45%（アクセシビリティの大きな文字では 30%）までにし、いちばん小さい iPhone でも設定に半分より多く残す
/// - 幅の広い画面（iPad・横向きの iPhone）: 見本を左、設定を右に並べる（`.sideBySide`）。見本は列の高さに収め、幅は 280pt・画面の幅の 40% まで
///
/// 画面の大きさは、ナビゲーションバー・タブバーを除いた中身の大きさ（`GeometryReader` の大きさ）。
nonisolated struct AppearancePreviewLayout: Equatable, Sendable {
    nonisolated enum Arrangement: Equatable, Sendable {
        /// 見本を上に固定し、その下で設定をスクロールする。
        case pinnedTop
        /// 見本を左、設定を右に並べる。
        case sideBySide
    }

    /// 見本の左右の余白（pt）。
    static let horizontalPadding: CGFloat = 20
    /// 見本の上下の余白（pt）。
    static let verticalPadding: CGFloat = 12
    /// 左の列で、見本と下の文（「見本」と説明）の間（pt）。
    static let sideSpacing: CGFloat = 12
    /// 上に固定する帯（余白を含む）が、画面の高さに占める割合の上限。
    static let pinnedHeightFraction: CGFloat = 0.45
    /// アクセシビリティの大きな文字のときの `pinnedHeightFraction`。設定の行が高くなるので、見本を小さくして設定に場所を譲る。
    static let accessibilityPinnedHeightFraction: CGFloat = 0.3
    /// 上に固定するときの見本の高さの上限（pt）。iPad の狭い分割などで縦に長いときに大きくしすぎない。
    static let maximumPinnedPreviewHeight: CGFloat = 340
    /// 左の列で、見本の下の文に空けておく高さ（pt）。収まらない文は縮めて収める（`minimumScaleFactor`）。
    static let sideCaptionHeight: CGFloat = 72
    /// アクセシビリティの大きな文字のときの `sideCaptionHeight`。
    static let accessibilitySideCaptionHeight: CGFloat = 120
    /// 左に並べるときの見本の幅の上限（pt）。
    static let maximumSidePreviewWidth: CGFloat = 280
    /// 左の列の幅（余白を含む）が、画面の幅に占める割合の上限。設定に 6 割より多く残す。
    static let maximumSideColumnFraction: CGFloat = 0.4
    /// 左の列の、見本の下の文の幅の下限（pt）。見本が細いときも説明の文が読めるようにする。
    static let minimumSideContentWidth: CGFloat = 160
    /// 見本の高さの下限（pt）。とても小さい窓でも、見本が見分けられる大きさを保つ。
    static let minimumPreviewHeight: CGFloat = 120
    /// これより幅が広ければ、縦長でも左右に並べる（iPad の縦向き）。
    static let sideBySideMinimumWidth: CGFloat = 700
    /// 横長の画面で左右に並べる幅の下限（pt）。横長の画面は高さが足りないので、横向きの iPhone でサイドバーを出して
    /// 中身が狭くなったとき（幅 500pt ほど）も左右に並べる。これより狭い横長の窓は、上に固定する。
    static let landscapeMinimumWidth: CGFloat = 480

    let arrangement: Arrangement
    /// 見本を見せる大きさ（pt）。縦横の比はホームの見本（`AppearancePreview.canvasSize`）のまま。
    let previewSize: CGSize
    /// 「見本」と説明の文に使える高さ（pt）。上に固定するときは見本の高さ（文は見本の右）、左の列では見本の下に空けた高さ。
    let captionHeight: CGFloat
    /// 左の列の幅（余白を含む。pt）。`.sideBySide` のときに使う（`.pinnedTop` では中身の幅）。
    /// 見本の下の文が読めるよう幅 `minimumSideContentWidth` までは広げるが、画面の幅の 40% は超えない。
    let sideColumnWidth: CGFloat

    /// 中身の大きさ `containerSize` と、アクセシビリティの大きな文字か `isAccessibilitySize` から決める。
    init(containerSize: CGSize, isAccessibilitySize: Bool) {
        let width = Self.sanitized(containerSize.width)
        let height = Self.sanitized(containerSize.height)
        let aspectRatio = AppearancePreview.canvasSize.width / AppearancePreview.canvasSize.height
        let isWide = width >= Self.sideBySideMinimumWidth || (width > height && width >= Self.landscapeMinimumWidth)
        if isWide {
            arrangement = .sideBySide
            let caption = isAccessibilitySize ? Self.accessibilitySideCaptionHeight : Self.sideCaptionHeight
            let fittingHeight = height - Self.verticalPadding * 2 - Self.sideSpacing - caption
            let maxWidth = min(Self.maximumSidePreviewWidth, width * Self.maximumSideColumnFraction - Self.horizontalPadding * 2)
            let previewHeight = max(min(fittingHeight, maxWidth / aspectRatio), Self.minimumPreviewHeight)
            previewSize = AppearancePreview.displaySize(height: previewHeight)
            captionHeight = caption
            let previewColumn = previewSize.width + Self.horizontalPadding * 2
            let readableColumn = max(previewSize.width, Self.minimumSideContentWidth) + Self.horizontalPadding * 2
            sideColumnWidth = max(min(readableColumn, width * Self.maximumSideColumnFraction), previewColumn)
        } else {
            arrangement = .pinnedTop
            let fraction = isAccessibilitySize ? Self.accessibilityPinnedHeightFraction : Self.pinnedHeightFraction
            let fittingHeight = height * fraction - Self.verticalPadding * 2
            let previewHeight = min(max(fittingHeight, Self.minimumPreviewHeight), Self.maximumPinnedPreviewHeight)
            previewSize = AppearancePreview.displaySize(height: previewHeight)
            captionHeight = previewSize.height
            sideColumnWidth = width
        }
    }

    /// 上に固定する帯の高さ（余白を含む。pt）。`.pinnedTop` のときに使う。
    var pinnedHeight: CGFloat {
        previewSize.height + Self.verticalPadding * 2
    }

    /// 測れていない（0・負・無限・NaN）大きさは 0 として扱う。
    private static func sanitized(_ length: CGFloat) -> CGFloat {
        length.isFinite ? max(length, 0) : 0
    }
}
