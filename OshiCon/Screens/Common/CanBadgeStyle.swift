//
//  CanBadgeStyle.swift
//  OshiCon
//

import SwiftUI

/// 缶バッジ風のアバターの寸法。アバターの一辺から、輪の太さとツヤの場所を決める。
nonisolated struct CanBadgeLayout: Equatable, Sendable {
    /// アバターの一辺。
    let size: CGFloat

    /// 推し色の輪の太さ。アバターの写真の縁取り（`OshiAvatar`）と同じ太さにする。
    var ringWidth: CGFloat {
        max(2, size / 16)
    }

    /// ツヤ（左上の楕円）の枠。アバターの左上を原点にする。
    var glossFrame: CGRect {
        CGRect(x: size * 0.16, y: size * 0.09, width: size * 0.42, height: size * 0.26)
    }
}

extension View {
    /// アバター（`OshiAvatar`・`OshiPhotoAvatar`）を缶バッジ風にする。推し色の輪で縁取り、上にツヤを置いて、薄い影を落とす。
    /// アプリの画面だけで使う（ウィジェット・ライブアクティビティ・シェアのカードのアバターは変えない）。
    /// 輪・ツヤ・影は飾りで、読み上げ・押せる範囲を変えない。`size` はアバターの一辺。
    func canBadgeStyle(color: OshiColor, size: CGFloat) -> some View {
        modifier(CanBadgeStyleModifier(color: color, layout: CanBadgeLayout(size: size)))
    }
}

private struct CanBadgeStyleModifier: ViewModifier {
    /// ツヤの傾き（度）。
    private static let glossTilt: Double = -24

    let color: OshiColor
    let layout: CanBadgeLayout

    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack(alignment: .topLeading) {
                    // 写真の無いアバター（推し色の丸と頭文字）にも輪を付ける。地の上の線なので、ダークでも沈まない文字の色にする
                    Circle()
                        .strokeBorder(color.text(in: theme).color, lineWidth: layout.ringWidth)
                    Ellipse()
                        .fill(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                        .frame(width: layout.glossFrame.width, height: layout.glossFrame.height)
                        .rotationEffect(.degrees(Self.glossTilt))
                        .offset(x: layout.glossFrame.minX, y: layout.glossFrame.minY)
                }
                .frame(width: layout.size, height: layout.size, alignment: .topLeading)
                .clipShape(Circle())
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.3), radius: 2.5, x: 0, y: 2)
    }
}

#Preview {
    HStack(spacing: 16) {
        OshiAvatar(name: "LUMINA", color: .pink, photo: Image(systemName: "person.crop.square.fill"), size: 48)
            .canBadgeStyle(color: .pink, size: 48)
        OshiAvatar(name: "ミナト", color: .navy, size: 48)
            .canBadgeStyle(color: .navy, size: 48)
        OshiAvatar(name: "遠征", color: .black, size: 48)
            .canBadgeStyle(color: .black, size: 48)
    }
    .padding()
}
