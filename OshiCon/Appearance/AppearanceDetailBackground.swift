//
//  AppearanceDetailBackground.swift
//  OshiCon
//

import Observation
import SwiftUI

/// 予定の詳細の上の写真の下端（地の座標。上から何 pt か）。スクロールで上の写真が動いたら、詳細の画面が書き換える。
///
/// 詳細の画面の本体はこの値を読まないので、スクロールで描き直すのは地（`AppearanceDetailBackground`）だけ。
@Observable
final class AppearanceDetailHeaderPosition {
    /// 上の写真の下端。上の写真が画面の上に隠れたら 0。
    private(set) var bottom: CGFloat

    init(bottom: CGFloat = 0) {
        self.bottom = bottom
    }

    /// 上の写真の下端 `maxY`（地の座標）を受け取る。上に隠れた分は 0 にし、変わったときだけ書く（同じ値で地を描き直さない）。
    func update(headerMaxY maxY: CGFloat) {
        let clamped = max(maxY, 0)
        if clamped != bottom {
            bottom = clamped
        }
    }
}

/// 着せ替えで描くもの（`AppearanceRendering`）に合わせた予定の詳細の地。
///
/// - 標準: 今までどおりカードの地の色（`palette.surface`）だけ
/// - 背景の写真: 暗幕とぼかしを掛けた写真（`AppearanceBackgroundPhotoView`）を、上の写真の下端（`header`）より下にだけ敷く
/// - 飾り: 推しの丸い写真の飾り（`OshiPhotoDecorationLayer`）を、上の写真の下端より下にだけ重ねる（背景の写真があればその上）
///
/// 読み上げ・押せる範囲を変えない。
struct AppearanceDetailBackground: View {
    let rendering: AppearanceRendering
    /// 飾りに使う推し（並びの順）。
    let oshis: [Oshi]
    /// 背景の写真の置き場所（`AppearanceStore.photos`）。
    let photos: OshiPhotoLibrary
    let header: AppearanceDetailHeaderPosition

    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            theme.palette.surface.color
            // 標準のときは上の写真の下端を読まない（スクロールで描き直さない）
            if !rendering.isStandard {
                dressed(excludedTopHeight: header.bottom)
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    @ViewBuilder private func dressed(excludedTopHeight: CGFloat) -> some View {
        if let photo = rendering.backgroundPhoto {
            AppearanceBackgroundPhotoView(
                photo: photo,
                photos: photos,
                isDecorated: rendering.showsOshiPhotoDecoration,
                excludedTopHeight: excludedTopHeight
            )
        }
        if let decoration = rendering.decoration {
            OshiPhotoDecorationLayer(oshis: oshis, style: decoration)
                .mask(alignment: .topLeading) {
                    GeometryReader { proxy in
                        let visible = AppearanceBackgroundLayout.visibleRect(
                            containerSize: proxy.size,
                            excludedTopHeight: excludedTopHeight
                        )
                        Rectangle()
                            .frame(width: visible.width, height: visible.height)
                            .offset(y: visible.minY)
                    }
                }
        }
    }
}

#Preview("背景の写真と飾り（上の 300pt を空ける）") {
    AppearanceDetailBackground(
        rendering: AppearanceRendering(
            backgroundPhoto: .init(fileName: "00000000-0000-0000-0000-000000000001.jpg", style: .default),
            decoration: .default
        ),
        oshis: [Oshi(name: "ミナト", color: .navy)],
        photos: OshiPhotoLibrary(directory: FileManager.default.temporaryDirectory),
        header: AppearanceDetailHeaderPosition(bottom: 300)
    )
    .ignoresSafeArea()
}

#Preview("飾りだけ（ダーク）") {
    AppearanceDetailBackground(
        rendering: AppearanceRendering(backgroundPhoto: nil, decoration: .default),
        oshis: [Oshi(name: "ミナト", color: .navy)],
        photos: .shared,
        header: AppearanceDetailHeaderPosition(bottom: 300)
    )
    .ignoresSafeArea()
    .preferredColorScheme(.dark)
}
