//
//  PhotoWidgetAppearance.swift
//  OshiCon
//

import Foundation

/// 推しの写真ウィジェットの描き分け。描き方（フルカラーか、tinted などの 1 色か）と Plus が使えるかで、暗幕・写真と文字の濃さ・「Plus で使えます」を決める。
/// View から切り離してテストする。
nonisolated struct PhotoWidgetAppearance: Equatable, Sendable {
    /// 文字の後ろの暗幕（黒）の不透明度。白い写真の上でも白い文字が 4.5:1 以上になる濃さ。
    static let scrimOpacity = 0.6
    /// 1 色の描き方で写真を描く不透明度。写真も文字も同じ色合いで塗られるので、写真を薄くして文字を読めるようにする。
    static let monochromePhotoOpacity = 0.5
    /// Plus でないときの見本の写真（写真が無いときの模様）の不透明度。
    static let lockedPhotoOpacity = 0.4
    /// Plus でないときの見本の文字の不透明度。
    static let lockedEventOpacity = 0.6

    /// tinted・clear などの 1 色の描き方か。写真を白黒にして色合いを乗せる。
    let isMonochrome: Bool
    let isPlusUnlocked: Bool

    init(isFullColor: Bool, isPlusUnlocked: Bool) {
        isMonochrome = !isFullColor
        self.isPlusUnlocked = isPlusUnlocked
    }

    /// 写真の上の文字の後ろに暗幕を敷くか。1 色の描き方では暗幕も文字と同じ色で塗られて文字が読めなくなるので敷かない。
    var showsScrim: Bool {
        !isMonochrome
    }

    /// 写真（写真が無いときの模様）の不透明度。
    var photoOpacity: Double {
        (isMonochrome ? Self.monochromePhotoOpacity : 1) * (isPlusUnlocked ? 1 : Self.lockedPhotoOpacity)
    }

    /// 日数・予定名などの文字の不透明度。
    var eventOpacity: Double {
        isPlusUnlocked ? 1 : Self.lockedEventOpacity
    }

    /// 「Plus で使えます」を重ねるか。
    var showsPlusBadge: Bool {
        !isPlusUnlocked
    }
}
