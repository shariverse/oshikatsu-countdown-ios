//
//  AppearanceHomePreview.swift
//  OshiCon
//

import SwiftUI

/// 着せ替えの画面に置くホームの見本（試着）。ホームの部品（先頭のカード・予定の行）を iPhone の縦の画面の大きさで組み、縮めて見せる。
///
/// 地は `AppearanceScreenBackground` で、選んだ写真・ON/OFF・強さをその場で映す。見本は 1 枚の絵として読み上げ、押せない。
/// 見本の中の文字の大きさは、画面のダイナミックタイプによらず標準の大きさにする（縮めた絵なので、大きくすると崩れる）。
struct AppearanceHomePreview: View {
    let rendering: AppearanceRendering
    let content: HomeContent
    /// 飾りに使う推し（登録した推し。見本の予定の推しではない）。
    let decorationOshis: [Oshi]
    /// 背景の写真の置き場所（`AppearanceStore.photos`）。
    let photos: OshiPhotoLibrary

    @Environment(\.appTheme) private var theme
    @Environment(\.displayScale) private var displayScale

    /// 見本の上の、ステータスバーの分の余白（pt）。
    private let topInset: CGFloat = 54
    private let cornerRadius: CGFloat = 24

    var body: some View {
        let canvas = AppearancePreview.canvasSize
        let factor = AppearancePreview.displayScaleFactor
        let size = AppearancePreview.displaySize
        home
            .frame(width: canvas.width, height: canvas.height, alignment: .top)
            .background {
                AppearanceScreenBackground(rendering: rendering, oshis: decorationOshis, photos: photos)
                    // 縮めて見せるので、写真は見せる大きさに合わせて読む
                    .environment(\.displayScale, displayScale * factor)
            }
            .clipped()
            .dynamicTypeSize(.large)
            .environment(\.horizontalSizeClass, .compact)
            .environment(\.verticalSizeClass, .regular)
            .scaleEffect(factor, anchor: .topLeading)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(theme.palette.outlineVariant.color)
            }
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("ホームの見本"))
            .accessibilityValue(Text(AppearancePreview.accessibilityValue(of: rendering)))
            .accessibilityIdentifier("appearance.preview")
    }

    private var home: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !content.oshis.isEmpty {
                OshiFilterBar(oshis: content.oshis, selection: .constant(nil))
            }
            if let featured = content.featured {
                FeaturedEventCard(item: featured)
            }
            HomeSection(title: "これからの予定") {
                ForEach(Array(AppearancePreview.rows(of: content).enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 68)
                    }
                    HomeEventRow(item: item)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, topInset)
    }
}

/// Preview で使う見本の中身。
private enum AppearanceHomePreviewSample {
    static var content: HomeContent {
        let now = Date()
        return AppearancePreview.content(events: [], oshis: [], today: CalendarDay(now, calendar: .current), now: now)
    }
}

#Preview("標準") {
    AppearanceHomePreview(
        rendering: .standard,
        content: AppearanceHomePreviewSample.content,
        decorationOshis: [],
        photos: .shared
    )
    .padding()
}

#Preview("飾り（ダーク）") {
    AppearanceHomePreview(
        rendering: AppearanceRendering(backgroundPhoto: nil, showsOshiPhotoDecoration: true),
        content: AppearanceHomePreviewSample.content,
        decorationOshis: [Oshi(name: "ミナト", color: .navy)],
        photos: .shared
    )
    .padding()
    .preferredColorScheme(.dark)
}
