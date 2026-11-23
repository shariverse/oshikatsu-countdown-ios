//
//  OshiPhotoDecorationView.swift
//  OshiCon
//

import SwiftUI

/// 着せ替えの飾り（Plus）。選んだ推しの丸い写真を、互い違いの並びで並べる（`OshiPhotoDecoration`・`OshiPhotoDecorationLayout`）。地は描かない（透明）。
///
/// ホームと予定の詳細の地の色、または背景の写真（`AppearanceBackgroundPhotoView`）の上に重ねる。
/// 写真は `photos`（推しの写真の置き場所）から、いちばん大きい丸の大きさに縮め、丸の外を透明にしてメインの外で読む。読む前はテーマの模様を描く。
/// ほかの画面（課金画面・シェアのカード・テーマの見本）の地（`ThemeScreenBackground`）は変えない。
struct OshiPhotoDecorationLayer: View {
    let oshis: [Oshi]
    let style: OshiPhotoDecorationStyle
    var photos = OshiPhotoLibrary.shared

    @Environment(\.displayScale) private var displayScale
    @State private var images: [String: CGImage] = [:]

    nonisolated private struct LoadRequest: Equatable, Sendable {
        let fileNames: [String]
        let pixelLength: Int
    }

    var body: some View {
        let decoration = OshiPhotoDecoration(oshis: oshis, style: style)
        let request = LoadRequest(
            fileNames: decoration.photoFileNames,
            pixelLength: OshiPhotoDecoration.decodePixelLength(displayScale: displayScale)
        )
        OshiPhotoDecorationMarks(decoration: decoration, images: images)
            // 推しの写真の差し替え・出す推しの変更・推しの追加と削除・画面の倍率が変わったら読み直す。読み直す間は今の写真を出したままにする
            .task(id: request) {
                let loaded = await Self.load(request, from: photos)
                guard !Task.isCancelled else {
                    return
                }
                images = loaded
            }
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    /// 写真を並行して読み、丸の外を透明にする（どちらもメインの外）。読めなかった写真は含めない。
    private static func load(_ request: LoadRequest, from photos: OshiPhotoLibrary) async -> [String: CGImage] {
        await withTaskGroup(of: (String, CGImage?).self) { group in
            for fileName in request.fileNames {
                group.addTask {
                    let image = await photos.loadImage(fileName: fileName, maxPixelLength: request.pixelLength)
                    return (fileName, image.flatMap { OshiPhotoDecoration.circularImage(from: $0, pixelLength: request.pixelLength) })
                }
            }
            var loaded: [String: CGImage] = [:]
            for await (fileName, image) in group {
                loaded[fileName] = image
            }
            return loaded
        }
    }
}

/// 読んだ丸い写真 `images`（ファイル名ごと。丸の外は透明）で、推しの丸い写真の飾りを描く。地は描かない。
///
/// 写真のある推しがいないとき・読む前（`images` に無い）は、テーマの模様（出荷するテーマはハートと十字）を描く。
/// 読めなかった推しの写真は飛ばし、読めた推しの写真だけを順にくり返す。
struct OshiPhotoDecorationMarks: View {
    let decoration: OshiPhotoDecoration
    let images: [String: CGImage]

    @Environment(\.appTheme) private var theme

    var body: some View {
        let photos = decoration.photoFileNames.compactMap { images[$0] }
        let ornament: AdaptiveColor? = switch theme.decoration.screenBackground {
        case .none:
            nil
        case let .crossesAndHearts(ornament):
            ornament
        }
        Canvas { context, size in
            guard !photos.isEmpty else {
                guard let ornament else {
                    return
                }
                let color = ornament.color.opacity(AppTheme.ScreenBackground.markOpacity)
                var heart = context.resolve(Image(systemName: "heart.fill"))
                heart.shading = .color(color)
                for mark in CrossesAndHeartsPattern.placedMarks(in: size) {
                    CrossesAndHeartsPattern.draw(mark, in: context, color: color, heart: heart)
                }
                return
            }
            let resolved = photos.map { context.resolve(Image(decorative: $0, scale: 1).interpolation(.high)) }
            // 丸どうしは重ならないので、まとめて同じ不透明度で描く
            context.opacity = decoration.opacity
            for circle in OshiPhotoDecorationLayout.circles(in: size, amount: decoration.amount) {
                let index = OshiPhotoDecorationLayout.photoIndex(row: circle.row, column: circle.column, count: resolved.count)
                context.draw(resolved[index], in: circle.rect)
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// 地の色 `ground` に、推しの丸い写真の飾り（`OshiPhotoDecorationLayer`）を重ねた画面の地（背景の写真を敷かないとき）。
struct OshiPhotoDecorationBackground: View {
    let ground: AdaptiveColor
    let oshis: [Oshi]
    let style: OshiPhotoDecorationStyle
    var photos = OshiPhotoLibrary.shared

    var body: some View {
        ground.color
            .overlay {
                OshiPhotoDecorationLayer(oshis: oshis, style: style, photos: photos)
            }
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}

/// Preview で使う推し（写真のある 2 人と、写真の無い 1 人）と、読んだ丸い写真。
private enum OshiPhotoDecorationPreview {
    static let minato = "00000000-0000-0000-0000-000000000001.jpg"
    static let lumina = "00000000-0000-0000-0000-000000000002.jpg"

    static let oshis = [
        Oshi(name: "ミナト", color: .navy, photoFileName: minato),
        Oshi(name: "ひなた", color: .yellow),
        Oshi(name: "LUMINA", color: .pink, photoFileName: lumina)
    ]

    static func decoration(_ style: OshiPhotoDecorationStyle = .default) -> OshiPhotoDecoration {
        OshiPhotoDecoration(oshis: oshis, style: style)
    }

    static let images: [String: CGImage] = [
        minato: PhotoCropPreviewImage.make(width: 400, height: 400),
        lumina: PhotoCropPreviewImage.make(width: 600, height: 400)
    ].compactMapValues { OshiPhotoDecoration.circularImage(from: $0, pixelLength: 192) }
}

#Preview("推しの写真の飾り") {
    OshiPhotoDecorationMarks(decoration: OshiPhotoDecorationPreview.decoration(), images: OshiPhotoDecorationPreview.images)
        .background(AppTheme.shipping.palette.background.color)
        .ignoresSafeArea()
}

#Preview("埋め尽くす（ダーク）") {
    OshiPhotoDecorationMarks(
        decoration: OshiPhotoDecorationPreview.decoration(OshiPhotoDecorationStyle(opacity: 0.8, amount: 1)),
        images: OshiPhotoDecorationPreview.images
    )
    .background(AppTheme.shipping.palette.background.color)
    .ignoresSafeArea()
    .preferredColorScheme(.dark)
}

#Preview("背景の写真の上に飾り") {
    ZStack {
        AppearanceBackgroundPhotoLayers(
            image: PhotoCropPreviewImage.make(width: 900, height: 1_950),
            intensity: .medium,
            isDecorated: true
        )
        OshiPhotoDecorationMarks(
            decoration: OshiPhotoDecorationPreview.decoration(OshiPhotoDecorationStyle(amount: 0.6)),
            images: OshiPhotoDecorationPreview.images
        )
    }
    .ignoresSafeArea()
}

#Preview("写真のある推しがいない（今の模様）") {
    OshiPhotoDecorationBackground(
        ground: AppTheme.shipping.palette.background,
        oshis: [Oshi(name: "ミナト", color: .navy)],
        style: .default
    )
    .ignoresSafeArea()
}
