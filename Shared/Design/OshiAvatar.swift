//
//  OshiAvatar.swift
//  OshiCon
//

import SwiftUI

/// 推しのアバター。写真があれば丸く切り抜き、無ければ推し色の丸に頭文字を置く。
/// 名前は横に並べて出す前提なので、読み上げの対象にしない。
struct OshiAvatar: View {
    let name: String
    let color: OshiColor
    var photo: Image?
    var size: CGFloat = 40

    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            Circle()
                .fill(color.fill)
            if let photo {
                photo
                    .resizable()
                    .scaledToFill()
                    // UI テストで写真を描いたことを確かめる（読み上げは変えない。丸ごと accessibilityHidden）
                    .accessibilityIdentifier("oshiAvatar.photo")
            } else {
                Text(InputText.firstCharacter(of: name))
                    // 丸の大きさに合わせる。文字の大きさの設定で丸からはみ出さないよう、ダイナミックタイプで変えない
                    .font(.custom(theme.typography.textFaces.bold, fixedSize: size * 0.4))
                    .foregroundStyle(color.onFill)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

/// 推し色の小さな丸（一覧の行・推しカウントの行）。
struct OshiColorDot: View {
    let color: OshiColor
    var size: CGFloat = 10

    var body: some View {
        Circle()
            .fill(color.fill)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            OshiAvatar(name: "LUMINA", color: .pink, size: 48)
            OshiAvatar(name: "ミナト", color: .navy, size: 48)
            OshiAvatar(name: "👨‍👩‍👧", color: .mint, size: 48)
        }
        HStack {
            ForEach(OshiColor.allCases, id: \.self) { color in
                OshiColorDot(color: color)
            }
        }
    }
    .padding()
}
