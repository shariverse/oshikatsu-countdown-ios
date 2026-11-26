//
//  AppearanceBackgroundPhoto.swift
//  OshiCon
//

import SwiftUI

/// ホームと予定の詳細の地に敷く、着せ替えの背景の写真（Plus）。写真は `photos`（`AppearanceStore.photos`）から、地の大きさに合わせて縮めて読む。
///
/// ほかの画面（課金画面・シェアのカード・テーマの見本）の地（`ThemeScreenBackground`）は変えない。敷くかどうかは `AppearanceRendering` が決める。
/// 予定の詳細では、上の横長の写真の部分（`excludedTopHeight`）には敷かない。
struct AppearanceBackgroundPhotoView: View {
    let photo: AppearanceRendering.BackgroundPhoto
    let photos: OshiPhotoLibrary
    /// 写真の上に飾り（推しの丸い写真）を重ねるか。重ねるときは幕を濃くする（`AppearanceBackgroundStyle.scrimOpacity(isDark:isDecorated:)`）。
    let isDecorated: Bool
    /// 上から何 pt を写真を敷かずに空けるか（予定の詳細の上の写真の部分）。空けた所には何も描かない（下の地が見える）。
    var excludedTopHeight: CGFloat = 0

    @Environment(\.displayScale) private var displayScale
    /// 読んだ写真。写真が替わっても、新しい写真を読むまでは前の写真のまま。
    @State private var loaded: CGImage?

    nonisolated private struct LoadRequest: Equatable, Sendable {
        let fileName: String
        let pixelLength: Int
    }

    var body: some View {
        GeometryReader { proxy in
            let pixelLength = AppearanceBackgroundLayout(containerSize: proxy.size).decodePixelLength(displayScale: displayScale)
            AppearanceBackgroundPhotoLayers(
                // 写真が替わったら（差し替え・ホームの絞り込みで推しの背景と共通の背景を切り替えたとき）、新しい写真を読むまで前の写真を出したままにする
                // （読む間に地の色へ戻ってちらつかないように）。読めなければ写真を出さない
                image: loaded,
                style: photo.style,
                isDecorated: isDecorated,
                excludedTopHeight: excludedTopHeight
            )
            // 画面の大きさ（回転・iPad の分割）が変わったら読み直す。読み直す間は今の写真を出したままにする。
            // 強さ（幕・ぼかし）と飾りの有無は読み込みに関わらないので、変えても読み直さない
            .task(id: LoadRequest(fileName: photo.fileName, pixelLength: pixelLength)) {
                let image = await photos.loadImage(fileName: photo.fileName, maxPixelLength: pixelLength)
                // 続けて切り替えたときは、後から頼んだ写真だけを出す
                guard !Task.isCancelled else {
                    return
                }
                loaded = image
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// 読んだ背景の写真 `image` に、ぼかしと幕を掛けて描く。写真が無い（読む前・読めない）ときはテーマの地の色に幕を掛ける。
///
/// - 幕の色と不透明度・ぼかしの量は `AppearanceBackgroundStyle`（ライトは地の色、ダークは黒。飾りを重ねる `isDecorated` ときは幕を濃くする）
/// - iPad・横向きでは写真を高さに合わせて中央に置き、左右の余りを同じ写真の強いぼかしで埋める（`AppearanceBackgroundLayout`）
/// - 読み上げ・押せる範囲を変えない
struct AppearanceBackgroundPhotoLayers: View {
    let image: CGImage?
    let style: AppearanceBackgroundStyle
    var isDecorated = false
    var excludedTopHeight: CGFloat = 0

    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let visible = AppearanceBackgroundLayout.visibleRect(containerSize: proxy.size, excludedTopHeight: excludedTopHeight)
            ZStack {
                theme.palette.background.color
                if let image {
                    photoLayers(image, size: proxy.size)
                }
                AppearanceBackgroundStyle.scrimColor(in: theme).color
                    .opacity(style.scrimOpacity(isDark: colorScheme == .dark, isDecorated: isDecorated))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .mask(alignment: .topLeading) {
                Rectangle()
                    .frame(width: visible.width, height: visible.height)
                    .offset(y: visible.minY)
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    @ViewBuilder private func photoLayers(_ image: CGImage, size: CGSize) -> some View {
        let layout = AppearanceBackgroundLayout(
            containerSize: size,
            photoAspectRatio: CGFloat(image.width) / CGFloat(max(image.height, 1))
        )
        let picture = Image(decorative: image, scale: 1)
        if layout.showsSideFill {
            // 左右の余りは、同じ写真で地を覆って強くぼかす
            picture
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
                .blur(radius: AppearanceBackgroundStyle.sideFillBlurRadius, opaque: true)
                .clipped()
        }
        picture
            .resizable()
            .frame(width: layout.photoFrame.width, height: layout.photoFrame.height)
            .blur(radius: style.blurRadius, opaque: true)
            .clipped()
            .position(x: layout.photoFrame.midX, y: layout.photoFrame.midY)
    }
}

/// 着せ替えの写真（背景の写真・推しの丸い写真の飾り）の上の端に掛ける、幕の色のグラデーション。
/// 幕が薄くても・飾りが濃くても、ステータスバーの文字（時刻・電池）が写真の色によらず読めるようにする。
///
/// 上から半分は `AppearanceBackgroundStyle.statusBarFadeOpacity` のまま覆い、そこから下の端に向けて消す。ホームの地（`AppearanceScreenBackground`）で使う。
struct AppearanceStatusBarFade: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        let scrim = AppearanceBackgroundStyle.scrimColor(in: theme).color
        LinearGradient(
            stops: [
                .init(color: scrim.opacity(AppearanceBackgroundStyle.statusBarFadeOpacity), location: 0),
                .init(color: scrim.opacity(AppearanceBackgroundStyle.statusBarFadeOpacity), location: 0.5),
                .init(color: scrim.opacity(0), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: AppearanceBackgroundStyle.statusBarFadeHeight)
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// Preview で背景の上に置く、地の上に直接描く文字（見出し・案内）。ホームと同じく、背景の写真の上では後ろに板を敷く。
private struct AppearanceBackgroundPreviewText: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("これからの予定")
                .font(theme.typography.text(.headline, weight: .bold))
                .foregroundStyle(theme.palette.onSurface.color)
                .appearanceTextPlate()
            Text("この推しの予定はまだありません")
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
                .appearanceTextPlate()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.isOverAppearancePhoto, true)
    }
}

#Preview("背景の写真（既定の暗幕とぼかし）") {
    AppearanceBackgroundPreviewText()
        .background(
            AppearanceBackgroundPhotoLayers(image: PhotoCropPreviewImage.make(width: 900, height: 1_950), style: .default)
                .ignoresSafeArea()
        )
}

#Preview("背景の写真（暗幕 0%・ぼかしなし・ダーク）") {
    AppearanceBackgroundPreviewText()
        .background(
            AppearanceBackgroundPhotoLayers(
                image: PhotoCropPreviewImage.make(width: 900, height: 1_950),
                style: AppearanceBackgroundStyle(scrim: 0, blur: 0)
            )
                .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
}

#Preview("横向き（左右をぼかしで埋める）", traits: .landscapeLeft) {
    AppearanceBackgroundPreviewText()
        .background(
            AppearanceBackgroundPhotoLayers(
                image: PhotoCropPreviewImage.make(width: 900, height: 1_950),
                style: AppearanceBackgroundStyle(scrim: 1, blur: 1)
            )
                .ignoresSafeArea()
        )
}

#Preview("予定の詳細（上の写真の部分を空ける）") {
    AppearanceBackgroundPhotoLayers(
        image: PhotoCropPreviewImage.make(width: 900, height: 1_950),
        style: .default,
        excludedTopHeight: 300
    )
    .background(AppTheme.shipping.palette.surface.color)
    .ignoresSafeArea()
}

#Preview("読む前（写真なし）") {
    AppearanceBackgroundPreviewText()
        .background(AppearanceBackgroundPhotoLayers(image: nil, style: .default).ignoresSafeArea())
}
