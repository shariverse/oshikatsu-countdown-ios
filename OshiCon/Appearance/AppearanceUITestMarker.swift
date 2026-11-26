//
//  AppearanceUITestMarker.swift
//  OshiCon
//

import SwiftUI

/// ホームと予定の詳細の地に描いている着せ替え（`AppearanceRendering`）を、UI テストから読む口。
///
/// 地（`AppearanceScreenBackground`・`AppearanceDetailBackground`）は読み上げから外しているので、UI テストからは見えない。
/// メモリ上のストア（`-useInMemoryStore`。UI テストとスクリーンショット）のときだけ、1pt の透明な要素に描いているものを値として置く。
/// 端末のストアで動くアプリでは置かない（読み上げ・押せる範囲・並びを変えない）。
nonisolated enum AppearanceUITestMarker {
    /// ホームの地の口の identifier。
    static let homeIdentifier = "home.appearance"
    /// 予定の詳細の地の口の identifier。
    static let eventDetailIdentifier = "eventDetail.appearance"

    /// 描いているものを表す値（訳さない）。標準なら `standard`、着せ替えなら背景の写真（共通は `photo`、推しごとは `oshiPhoto`）と
    /// `decoration` を `,` でつなぐ。
    /// 暗幕とぼかしの濃さは見本の読み上げの値（`AppearancePreview.accessibilityValue(of:locale:)`）で確かめる。
    static func value(of rendering: AppearanceRendering) -> String {
        guard !rendering.isStandard else {
            return "standard"
        }
        var parts: [String] = []
        if let photo = rendering.backgroundPhoto {
            parts.append(photo.isOshiBackground ? "oshiPhoto" : "photo")
        }
        if rendering.showsOshiPhotoDecoration {
            parts.append("decoration")
        }
        return parts.joined(separator: ",")
    }
}

extension View {
    /// 描いている着せ替えを UI テストから読む口を置く（`AppearanceUITestMarker`）。`isEnabled` が false なら何も置かない。
    func appearanceUITestMarker(
        _ identifier: String,
        rendering: AppearanceRendering,
        isEnabled: Bool = LaunchOptions.usesInMemoryStore
    ) -> some View {
        overlay(alignment: .topLeading) {
            if isEnabled {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: AppearanceUITestMarker.value(of: rendering)))
                    .accessibilityIdentifier(identifier)
                    .allowsHitTesting(false)
            }
        }
    }
}
