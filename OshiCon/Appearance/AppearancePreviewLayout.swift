//
//  AppearancePreviewLayout.swift
//  OshiCon
//

import CoreGraphics

/// 着せ替えの画面で、見本（ホーム・予定の詳細・シェアのカード）と設定のトレーをどう並べ、見本をどの大きさで見せるか。画面から切り離してテストする。
///
/// 見本はスクロールする設定の外に置き、どの設定を変えているときも見えるようにする。見本の下に、見本の切り替えと「全画面」のボタンの行を置く。
/// - 幅の狭い画面（縦向きの iPhone・iPad の狭い分割）: 見本を上のまん中に大きく置き、その下に設定のトレーを置く（`.pinnedTop`）。
///   見本の高さは中身の高さの 54%（縦向きの iPhone で画面の高さの 45% 前後）。トレーには 200pt より多く残す。
///   アクセシビリティの大きな文字では 30% までにし、行が高くなった設定に場所を譲る
/// - 幅の広い画面（iPad・横向きの iPhone）: 見本を左、設定を右に並べる（`.sideBySide`）。見本は列の高さに収め、幅は 280pt・画面の幅の 40% まで
///
/// 画面の大きさは、ナビゲーションバーを除いた中身の大きさ（`GeometryReader` の大きさ）。着せ替えの画面ではタブバーを隠す。
nonisolated struct AppearancePreviewLayout: Equatable, Sendable {
    nonisolated enum Arrangement: Equatable, Sendable {
        /// 見本を上に置き、その下に設定のトレーを置く。
        case pinnedTop
        /// 見本を左、設定を右に並べる。
        case sideBySide
    }

    /// 見本と切り替えの行の左右の余白（pt）。
    static let horizontalPadding: CGFloat = 20
    /// 見本の上と、切り替えの行の下の余白（pt）。
    static let verticalPadding: CGFloat = 12
    /// 見本と、その下の切り替えの行の間（pt）。
    static let controlsSpacing: CGFloat = 10
    /// 切り替えの行（見本の切り替えと「全画面」）の高さ（pt）。
    static let controlsHeight: CGFloat = 44
    /// アクセシビリティの大きな文字のときの `controlsHeight`（行の文字は `accessibility1` まで大きくする）。
    static let accessibilityControlsHeight: CGFloat = 60
    /// 上に置く見本の高さが、中身の高さに占める割合。縦向きの iPhone で、画面の高さ（バーを含む）の 45% 前後になる。
    static let pinnedPreviewFraction: CGFloat = 0.54
    /// アクセシビリティの大きな文字のときの `pinnedPreviewFraction`。設定の行が高くなるので、見本を小さくして設定に場所を譲る。
    static let accessibilityPinnedPreviewFraction: CGFloat = 0.3
    /// 上に置くとき、設定のトレーに残す高さの下限（pt）。いちばん小さい iPhone でも、タブと設定の 2〜3 行が見える。
    static let minimumTrayHeight: CGFloat = 200
    /// 上に置くときの見本の高さの上限（pt）。iPad の狭い分割などで縦に長いときに大きくしすぎない。
    static let maximumPinnedPreviewHeight: CGFloat = 480
    /// 左に並べるときの見本の幅の上限（pt）。
    static let maximumSidePreviewWidth: CGFloat = 280
    /// 左の列の幅（余白を含む）が、画面の幅に占める割合の上限。設定に 6 割より多く残す。
    static let maximumSideColumnFraction: CGFloat = 0.4
    /// 左の列の、切り替えの行の幅の下限（pt）。見本が細いときも、切り替え（記号）と「全画面」が収まるようにする。
    static let minimumSideContentWidth: CGFloat = 200
    /// 見本の高さの下限（pt）。とても小さい窓でも、見本が見分けられる大きさを保つ。
    static let minimumPreviewHeight: CGFloat = 120
    /// これより幅が広ければ、縦長でも左右に並べる（iPad の縦向き）。
    static let sideBySideMinimumWidth: CGFloat = 700
    /// 横長の画面で左右に並べる幅の下限（pt）。横長の画面は高さが足りないので、横向きの iPhone でサイドバーを出して
    /// 中身が狭くなったとき（幅 500pt ほど）も左右に並べる。これより狭い横長の窓は、上に置く。
    static let landscapeMinimumWidth: CGFloat = 480

    let arrangement: Arrangement
    /// ホームと予定の詳細の見本を見せる大きさ（pt）。縦横の比は見本を組む大きさ（`AppearancePreview.canvasSize`）のまま。
    let previewSize: CGSize
    /// シェアのカードの見本（正方形）の一辺（pt）。見本の高さと、見本を置く幅（余白を除く）に収め、書き出す大きさ（`ShareCardSize.points`）より大きくしない。
    let shareCardSide: CGFloat
    /// 見本を置く幅（余白を含む。pt）。`.pinnedTop` では中身の幅、`.sideBySide` では左の列の幅。横に送る見本の 1 枚の幅でもある。
    /// 左の列は、切り替えの行が収まるよう幅 `minimumSideContentWidth` までは広げるが、画面の幅の 40% は超えない。
    let stageWidth: CGFloat
    /// 切り替えの行に空ける高さ（pt）。
    let controlsHeight: CGFloat

    /// 中身の大きさ `containerSize` と、アクセシビリティの大きな文字か `isAccessibilitySize` から決める。
    init(containerSize: CGSize, isAccessibilitySize: Bool) {
        let width = Self.sanitized(containerSize.width)
        let height = Self.sanitized(containerSize.height)
        let aspectRatio = AppearancePreview.canvasSize.width / AppearancePreview.canvasSize.height
        let controls = isAccessibilitySize ? Self.accessibilityControlsHeight : Self.controlsHeight
        let chrome = Self.verticalPadding * 2 + Self.controlsSpacing + controls
        let isWide = width >= Self.sideBySideMinimumWidth || (width > height && width >= Self.landscapeMinimumWidth)
        if isWide {
            arrangement = .sideBySide
            let maxWidth = min(Self.maximumSidePreviewWidth, width * Self.maximumSideColumnFraction - Self.horizontalPadding * 2)
            let previewHeight = max(min(height - chrome, maxWidth / aspectRatio), Self.minimumPreviewHeight)
            previewSize = AppearancePreview.displaySize(height: previewHeight)
            let previewColumn = previewSize.width + Self.horizontalPadding * 2
            let controlsColumn = max(previewSize.width, Self.minimumSideContentWidth) + Self.horizontalPadding * 2
            stageWidth = max(min(controlsColumn, width * Self.maximumSideColumnFraction), previewColumn)
        } else {
            arrangement = .pinnedTop
            let fraction = isAccessibilitySize ? Self.accessibilityPinnedPreviewFraction : Self.pinnedPreviewFraction
            // トレーに `minimumTrayHeight` を残せる高さまで。細い窓では、見本が左右の余白の内側に収まる高さまで
            let widthLimit = max(width - Self.horizontalPadding * 2, 0) / aspectRatio
            let fittingHeight = min(height * fraction, height - chrome - Self.minimumTrayHeight, widthLimit)
            let previewHeight = min(max(fittingHeight, Self.minimumPreviewHeight), Self.maximumPinnedPreviewHeight)
            previewSize = AppearancePreview.displaySize(height: previewHeight)
            stageWidth = width
        }
        controlsHeight = controls
        let cardWidth = max(stageWidth - Self.horizontalPadding * 2, 0)
        shareCardSide = min(previewSize.height, cardWidth, ShareCardSize.points)
    }

    /// 横に並べた見本の `page` を、`selected` を映しているときに横へずらす幅（pt。右が正）。
    ///
    /// 見本は並びの上ではどれもホームの見本と同じ幅にそろえ、幅の広いシェアのカードはその幅から左右にはみ出して描く。
    /// そのままだと、となりの予定の詳細の見本に重なるので、はみ出す幅のぶんだけよける。
    /// - シェアのカードがとなりにのぞいているとき: カードを右へずらし、ほかの見本と同じだけのぞかせる
    /// - シェアのカードを映しているとき: カードはまん中のまま、ほかの見本を左へずらしてカードの下に重ねない
    func carouselOffset(of page: AppearancePreview.Kind, selected: AppearancePreview.Kind) -> CGFloat {
        let overflow = max((shareCardSide - previewSize.width) / 2, 0)
        switch (page == .share, selected == .share) {
        case (true, false):
            return overflow
        case (false, true):
            return -overflow
        default:
            return 0
        }
    }

    /// 見本と切り替えの行を合わせた高さ（余白を含む。pt）。`.pinnedTop` では、この下が設定のトレーになる。
    var stageHeight: CGFloat {
        previewSize.height + Self.controlsSpacing + controlsHeight + Self.verticalPadding * 2
    }

    /// 測れていない（0・負・無限・NaN）大きさは 0 として扱う。
    private static func sanitized(_ length: CGFloat) -> CGFloat {
        length.isFinite ? max(length, 0) : 0
    }
}
