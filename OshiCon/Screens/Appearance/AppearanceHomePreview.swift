//
//  AppearanceHomePreview.swift
//  OshiCon
//

import SwiftUI

/// 着せ替えの見本のホーム（試着）。ホームの部品（絞り込み・先頭のカード・予定の行）を組み、地に選んだ写真・ON/OFF・暗幕とぼかし・飾りをその場で映す。
/// 「背景」で推しを選んでいるときは、その推しで絞り込んだホームを出す（`HomeContent.selectedOshiID`。絞り込みの選択にも映す）。
///
/// 着せ替えの画面では iPhone の縦の画面の大きさで組んで縮め（`AppearancePhoneFrame`）、全画面の試着では画面の大きさのまま出す。
/// 押せなくするのと、読み上げを 1 つの要素にまとめるのは、置く側（`AppearancePreviewCarousel`・`AppearanceTryOnScreen`）が受け持つ。
struct AppearanceHomePreview: View {
    let rendering: AppearanceRendering
    let content: HomeContent
    /// 飾りに使う推し（登録した推し。見本の予定の推しではない）。
    let decorationOshis: [Oshi]
    /// 背景の写真の置き場所（`AppearanceStore.photos`）。
    let photos: OshiPhotoLibrary
    /// 中身の上に空ける高さ（pt）。ステータスバーとバーの分。地はこの余白の下にも敷く。
    var topInset: CGFloat = AppearancePreview.canvasTopInset
    /// 中身の左右に足す幅（pt）。横向きの全画面で、安全領域の外に文字を出さない。
    var horizontalInset: CGFloat = 0

    var body: some View {
        home
            // 実際のホームと同じく、背景の写真・飾りの上では見出しの後ろに板を敷く
            .environment(\.isOverAppearancePhoto, rendering.drawsPhotosOnGround)
            // 実際のホームと同じく、広い画面でも読みやすい幅に収める
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                AppearanceScreenBackground(rendering: rendering, oshis: decorationOshis, photos: photos)
            }
    }

    private var home: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !content.oshis.isEmpty {
                OshiFilterBar(oshis: content.oshis, selection: .constant(content.selectedOshiID))
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
        .padding(.horizontal, horizontalInset)
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
    AppearancePhoneFrame(width: 180) {
        AppearanceHomePreview(
            rendering: .standard,
            content: AppearanceHomePreviewSample.content,
            decorationOshis: [],
            photos: .shared
        )
    }
    .padding()
}

#Preview("飾り（ダーク）") {
    AppearancePhoneFrame(width: 180) {
        AppearanceHomePreview(
            rendering: AppearanceRendering(backgroundPhoto: nil, decoration: .default),
            content: AppearanceHomePreviewSample.content,
            decorationOshis: [Oshi(name: "ミナト", color: .navy)],
            photos: .shared
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}
