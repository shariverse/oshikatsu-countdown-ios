//
//  AppearanceSharePreview.swift
//  OshiCon
//

import SwiftUI

/// 着せ替えの見本のシェアのカード（試着）。シェアのカード（`ShareCardView`）をそのまま描き、一辺 `side` に縮めて見せる。
///
/// シェアのカードは背景の写真だけを地に使う（`ShareCardStyle.appearance(_:)`）。暗幕とぼかし・飾りは関わらない。
/// カードに描く写真は、実際のシェアと同じく読み込み終えてから渡す（`ShareCardImages`）。読み込む間は、今の画像を出したままにする。
struct AppearanceSharePreview: View {
    let rendering: AppearanceRendering
    /// 見本に出す予定（ホームの見本の先頭のカードと同じ予定）。無ければ何も出さない。
    let item: HomeContent.Item?
    /// 今日を数える時刻。
    let now: Date
    /// 背景の写真の置き場所（`AppearanceStore.photos`）。
    let photos: OshiPhotoLibrary
    /// カードを見せる一辺（pt）。
    let side: CGFloat

    @Environment(\.appTheme) private var theme
    @Environment(\.displayScale) private var displayScale
    @State private var images = ShareCardImages()

    /// 読み込む画像を決めるもの。変わったら読み直す。
    private struct ImageRequest: Hashable {
        let photoFileName: String?
        let background: ShareCardStyle.Background
        let pixelLength: Int
    }

    var body: some View {
        if let item {
            // 端末のタイムゾーンを変えたときも、その日付で数える
            let content = ShareCardContent(
                event: item.event,
                oshi: item.oshi,
                now: now,
                calendar: .autoupdatingCurrent,
                locale: item.locale
            )
            let style = ShareCardStyle.appearance(rendering)
            let factor = max(side, 0) / ShareCardSize.points
            let request = ImageRequest(
                photoFileName: content.photoFileName,
                background: style.background,
                pixelLength: Int((max(side, 0) * displayScale).rounded(.up))
            )
            let shape = RoundedRectangle(cornerRadius: theme.shape.section * factor)
            ShareCardView(content: content, style: style, images: images)
                .scaleEffect(factor, anchor: .topLeading)
                .frame(width: max(side, 0), height: max(side, 0), alignment: .topLeading)
                .clipShape(shape)
                .overlay {
                    shape.strokeBorder(theme.palette.brand.color, lineWidth: 1.5)
                }
                .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
                .task(id: request) {
                    let loaded = await ShareCardImages.load(
                        content: content,
                        style: style,
                        backgroundPhotos: photos,
                        maxPixelLength: max(request.pixelLength, 1)
                    )
                    guard !Task.isCancelled else {
                        return
                    }
                    images = loaded
                }
        }
    }
}

#Preview("標準") {
    let now = Date()
    let content = AppearancePreview.content(events: [], oshis: [], today: CalendarDay(now, calendar: .current), now: now)
    AppearanceSharePreview(
        rendering: .standard,
        item: AppearancePreview.featuredItem(of: content),
        now: now,
        photos: .shared,
        side: 240
    )
    .padding()
}
