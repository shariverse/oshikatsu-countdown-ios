//
//  ShareCardRenderer.swift
//  OshiCon
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// 書き出したシェアのカードの画像（正方形の PNG）。共有シート（`ShareLink`）には PNG の画像だけを渡す。
nonisolated struct ShareCardImage: Sendable, Transferable {
    let cgImage: CGImage
    let pngData: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { image in
            image.pngData
        }
    }
}

/// シェアのカードを、端末の中で決まった大きさ（`ShareCardSize.pixelLength` 四方）の PNG に書き出す。通信しない。
/// `ImageRenderer` を使うので、メインアクターで描く。
enum ShareCardRenderer {
    /// 写真を読み込み終えてから描く。書き出せなければ nil。
    static func render(
        _ content: ShareCardContent,
        style: ShareCardStyle = .shipping,
        photos: OshiPhotoLibrary = .shared,
        backgroundPhotos: OshiPhotoLibrary? = nil
    ) async -> ShareCardImage? {
        let images = await ShareCardImages.load(content: content, style: style, photos: photos, backgroundPhotos: backgroundPhotos)
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
