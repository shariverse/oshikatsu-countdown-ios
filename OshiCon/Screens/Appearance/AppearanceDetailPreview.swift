//
//  AppearanceDetailPreview.swift
//  OshiCon
//

import SwiftUI

/// 着せ替えの見本の予定の詳細（試着）。予定の詳細の部品（中身のカード `EventDetailCard`・地 `AppearanceDetailBackground`）を組み、
/// 上の写真より下の地に、選んだ写真・ON/OFF・暗幕とぼかし・飾りをその場で映す。
///
/// 予定の詳細の画面（`EventDetailScreen`）と同じ並べ方にする: 上に推しの写真（無ければテーマの模様）、その下端に少し重ねて中身のカード。
/// 写真の高さとカードの重なりは `EventDetailScreen` の値に合わせている（そちらを変えたら、ここも合わせる）。
/// 残りの時・分・秒は、実際の画面と同じく 1 秒ごとに数える。
struct AppearanceDetailPreview: View {
    let rendering: AppearanceRendering
    /// 見本に出す予定（ホームの見本の先頭のカードと同じ予定）。無ければ地だけを出す。
    let item: HomeContent.Item?
    /// 飾りに使う推し（登録した推し。見本の予定の推しではない）。
    let decorationOshis: [Oshi]
    /// 背景の写真の置き場所（`AppearanceStore.photos`）。
    let photos: OshiPhotoLibrary
    /// 中身のカードの左右に空ける幅（pt）。横向きの全画面で、安全領域の外に文字を出さない。
    var horizontalInset: CGFloat = 0

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    /// 上の写真の下端。着せ替えの地を、上の写真より下にだけ敷くのに使う（見本はスクロールしないので、写真の高さのまま）。
    @State private var headerPosition = AppearanceDetailHeaderPosition(bottom: regularPhotoHeight)

    /// 上の写真の高さ（pt）。`EventDetailScreen` と同じ。
    private static let regularPhotoHeight: CGFloat = 300
    /// 横向きの iPhone（縦が狭い）での上の写真の高さ（pt）。`EventDetailScreen` と同じ。
    private static let compactPhotoHeight: CGFloat = 140
    /// 中身のカードを上の写真に重ねる高さ（pt）。`EventDetailScreen` と同じ。
    private static let cardOverlap: CGFloat = 28

    private var photoHeight: CGFloat {
        verticalSizeClass == .compact ? Self.compactPhotoHeight : Self.regularPhotoHeight
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppearanceDetailPreviewHeader(oshi: item?.oshi, color: item?.color ?? .black)
                .frame(height: photoHeight)
                .clipped()
            if let item {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    EventDetailCard(
                        detail: EventDetailContent(
                            event: item.event,
                            oshi: item.oshi,
                            now: context.date,
                            // 端末のタイムゾーンを変えたときも、次の秒からその日付で数える
                            calendar: .autoupdatingCurrent,
                            locale: item.locale
                        )
                    )
                }
                .frame(maxWidth: 720)
                .padding(.horizontal, horizontalInset)
                .padding(.top, photoHeight - Self.cardOverlap)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            AppearanceDetailBackground(rendering: rendering, oshis: decorationOshis, photos: photos, header: headerPosition)
        }
        // 縦が狭くなって（横向きの全画面）写真の高さが変わったら、地を敷く範囲も合わせる
        .onChange(of: photoHeight, initial: true) { _, height in
            headerPosition.update(headerMaxY: height)
        }
    }
}

/// 見本の予定の詳細の上に敷く推しの写真。写真が無い・読めないときはテーマの模様（`EventDetailScreen` の上の写真と同じ描き方）。
private struct AppearanceDetailPreviewHeader: View {
    let oshi: Oshi?
    let color: OshiColor
    var photos = OshiPhotoLibrary.shared

    @Environment(\.displayScale) private var displayScale
    @State private var photo: Image?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ThemePhotoPlaceholder(color: color)
                if let photo {
                    photo
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
            }
            .task(id: oshi?.photoFileName) {
                photo = nil
                guard let fileName = oshi?.photoFileName else {
                    return
                }
                let pixels = Int((max(proxy.size.width, proxy.size.height) * displayScale).rounded(.up))
                let image = await photos.loadImage(fileName: fileName, maxPixelLength: pixels)
                photo = image.map { Image(decorative: $0, scale: 1) }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Preview で使う見本の予定。
private enum AppearanceDetailPreviewSample {
    static var item: HomeContent.Item? {
        let now = Date()
        let content = AppearancePreview.content(events: [], oshis: [], today: CalendarDay(now, calendar: .current), now: now)
        return AppearancePreview.featuredItem(of: content)
    }
}

#Preview("標準") {
    AppearancePhoneFrame(width: 180) {
        AppearanceDetailPreview(rendering: .standard, item: AppearanceDetailPreviewSample.item, decorationOshis: [], photos: .shared)
    }
    .padding()
}

#Preview("飾り（ダーク）") {
    AppearancePhoneFrame(width: 180) {
        AppearanceDetailPreview(
            rendering: AppearanceRendering(backgroundPhoto: nil, decoration: .default),
            item: AppearanceDetailPreviewSample.item,
            decorationOshis: [Oshi(name: "ミナト", color: .navy)],
            photos: .shared
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}
