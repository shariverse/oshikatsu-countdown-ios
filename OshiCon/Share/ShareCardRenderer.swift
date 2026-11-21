//
//  ShareCardRenderer.swift
//  OshiCon
//

import SwiftUI
import UIKit

/// 書き出したシェアのカードの画像（正方形の PNG）。
nonisolated struct ShareCardImage: Sendable {
    let cgImage: CGImage
    let pngData: Data
}

/// シェアのカードを、端末の中で決まった大きさ（`ShareCardSize.pixelLength` 四方）の PNG に書き出す。通信しない。
/// `ImageRenderer` を使うので、メインアクターで描く。
enum ShareCardRenderer {
    /// 写真を読み込み終えてから描く。書き出せなければ nil。
    static func render(
        _ content: ShareCardContent,
        style: ShareCardStyle = .shipping,
        photos: OshiPhotoLibrary = .shared
    ) async -> ShareCardImage? {
        let images = await ShareCardImages.load(content: content, style: style, photos: photos)
        return render(content, style: style, images: images)
    }

    /// 読み込んである画像で描く。書き出せなければ nil。
    static func render(_ content: ShareCardContent, style: ShareCardStyle = .shipping, images: ShareCardImages) -> ShareCardImage? {
        render(ShareCardView(content: content, style: style, images: images))
    }

    /// カードの View を書き出す（テストで外から Environment を変えて確かめるため、View を受ける口も持つ）。
    static func render(_ card: some View) -> ShareCardImage? {
        let renderer = ImageRenderer(content: card)
        renderer.proposedSize = ProposedViewSize(width: ShareCardSize.points, height: ShareCardSize.points)
        renderer.scale = ShareCardSize.scale
        renderer.isOpaque = true
        guard let image = renderer.cgImage, let data = UIImage(cgImage: image).pngData() else {
            return nil
        }
        return ShareCardImage(cgImage: image, pngData: data)
    }
}
