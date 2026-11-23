//
//  AppearanceScreenBackground.swift
//  OshiCon
//

import SwiftUI

/// 着せ替えで描くもの（`AppearanceRendering`）に合わせたホームの地。
///
/// - 背景の写真があれば、暗幕とぼかしを掛けた写真（`AppearanceBackgroundPhotoView`）を敷き、上の端をステータスバーのために幕の色で覆い（`AppearanceStatusBarFade`）、
///   飾りが ON ならその上に推しの丸い写真の飾りを重ねる
/// - 背景の写真が無く飾りが ON なら、地の色に推しの丸い写真の飾り（写真の無い推しのところは今の模様）
/// - どちらも無ければ、テーマの地（`ThemeScreenBackground`）のまま
///
/// ホーム（`HomeScreen`）と、着せ替えの画面の見本（試着）で使う。予定の詳細は `AppearanceDetailBackground`。読み上げ・押せる範囲を変えない。
struct AppearanceScreenBackground: View {
    let rendering: AppearanceRendering
    /// 飾りに使う推し（並びの順）。
    let oshis: [Oshi]
    /// 背景の写真の置き場所（`AppearanceStore.photos`）。
    let photos: OshiPhotoLibrary

    @Environment(\.appTheme) private var theme

    var body: some View {
        Group {
            if let photo = rendering.backgroundPhoto {
                ZStack {
                    AppearanceBackgroundPhotoView(photo: photo, photos: photos, isDecorated: rendering.showsOshiPhotoDecoration)
                    // 幕が薄いので、ステータスバーの文字が読めるよう上の端だけ幕の色で覆う
                    AppearanceStatusBarFade()
                    if rendering.showsOshiPhotoDecoration {
                        OshiPhotoDecorationLayer(oshis: oshis)
                    }
                }
            } else if rendering.showsOshiPhotoDecoration {
                OshiPhotoDecorationBackground(ground: theme.palette.background, oshis: oshis)
            } else {
                ThemeScreenBackground()
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
