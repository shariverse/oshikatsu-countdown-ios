//
//  PhotoCropShape.swift
//  OshiCon
//

import SwiftUI

/// 写真の調整画面（`PhotoCropScreen`）の枠の形。枠の外を暗くする形と、枠の線に使う。
nonisolated enum PhotoCropShape: Sendable {
    /// 推しの丸。
    case circle
    /// 背景の写真。iPhone の画面に似せた角の丸い長方形。
    case roundedRectangle

    /// 角の丸い長方形の角の半径の、短い辺に対する割合。
    static let cornerRadiusRatio: CGFloat = 0.12

    /// `rect` いっぱいに描いた枠の形。
    func path(in rect: CGRect) -> Path {
        switch self {
        case .circle:
            Path(ellipseIn: rect)
        case .roundedRectangle:
            Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) * Self.cornerRadiusRatio, style: .continuous)
        }
    }
}
