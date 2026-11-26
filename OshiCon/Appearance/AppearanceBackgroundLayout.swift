//
//  AppearanceBackgroundLayout.swift
//  OshiCon
//

import CoreGraphics

/// 着せ替えの背景の写真（縦長。`PhotoCrop.backgroundAspectRatio`）を、地の大きさに合わせて置く規則。
///
/// - 地が写真と同じくらいか、写真より細長い（縦向きの iPhone）ときは、写真で地を覆う（はみ出した分は切る）
/// - 地のほうが横に広い（iPad・横向き）ときは、写真を地の高さに合わせて中央に置き、左右の余りを同じ写真の強いぼかしで埋める（`showsSideFill`）
nonisolated struct AppearanceBackgroundLayout: Equatable, Sendable {
    /// 左右の余りがこれ（pt。両側の合計）より小さければ、余りを作らず写真で覆う（端に細い帯を出さない）。
    static let sideFillThreshold: CGFloat = 1

    /// 写真を置く枠（地の座標）。地から外にはみ出すことがある。
    let photoFrame: CGRect
    /// 左右の余りを、同じ写真の強いぼかし（`AppearanceBackgroundStyle.sideFillBlurRadius`）で埋めるか。
    let showsSideFill: Bool

    /// 大きさ `containerSize` の地に、縦横比 `photoAspectRatio`（幅 ÷ 高さ）の写真を置く。
    init(containerSize: CGSize, photoAspectRatio: CGFloat = PhotoCrop.backgroundAspectRatio) {
        let width = max(containerSize.width, 0)
        let height = max(containerSize.height, 0)
        guard width > 0, height > 0, photoAspectRatio > 0 else {
            photoFrame = .zero
            showsSideFill = false
            return
        }
        let fittedWidth = height * photoAspectRatio
        if width - fittedWidth >= Self.sideFillThreshold {
            // 地のほうが横に広い: 高さに合わせて中央に置く
            photoFrame = CGRect(x: (width - fittedWidth) / 2, y: 0, width: fittedWidth, height: height)
            showsSideFill = true
        } else {
            // 写真で地を覆う最小の大きさにし、中央に置く
            let coverHeight = max(height, width / photoAspectRatio)
            let coverWidth = coverHeight * photoAspectRatio
            photoFrame = CGRect(x: (width - coverWidth) / 2, y: (height - coverHeight) / 2, width: coverWidth, height: coverHeight)
            showsSideFill = false
        }
    }

    /// 写真を読む長辺（画素）。置く枠の長い辺を画面の倍率 `displayScale` で画素にし、取り込みの上限（`PhotoResizer.maxBackgroundPixelLength`）で抑える。
    func decodePixelLength(displayScale: CGFloat) -> Int {
        let needed = (max(photoFrame.width, photoFrame.height) * max(displayScale, 1)).rounded(.up)
        return Int(min(max(needed, 1), CGFloat(PhotoResizer.maxBackgroundPixelLength)))
    }

    /// 大きさ `containerSize` の地のうち、上の `excludedTopHeight`（予定の詳細の上の写真の部分）を除いて写真を見せる範囲。
    static func visibleRect(containerSize: CGSize, excludedTopHeight: CGFloat) -> CGRect {
        let width = max(containerSize.width, 0)
        let height = max(containerSize.height, 0)
        let top = min(max(excludedTopHeight, 0), height)
        return CGRect(x: 0, y: top, width: width, height: height - top)
    }
}
