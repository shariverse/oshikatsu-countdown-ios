//
//  OshiAvatar.swift
//  OshiCon
//

import SwiftUI

/// 推しのアバター。写真があれば丸く切り抜いて推し色で縁取り、無ければ推し色の丸に頭文字を置く。
/// 名前は横に並べて出す前提なので、読み上げの対象にしない。
struct OshiAvatar: View {
    let name: String
    let color: OshiColor
    var photo: Image?
    var size: CGFloat = 40

    @Environment(\.appTheme) private var theme

    /// 写真の縁取りの太さ。アバターの大きさに合わせる（44pt で約 2.8pt、96pt で 6pt）。
    private var photoRingWidth: CGFloat {
        max(2, size / 16)
    }

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
                // 写真だけでは推し色が分からないので、推し色で縁取る。地の上の線なので、ダークでも沈まない文字の色にする
                Circle()
                    .strokeBorder(color.text(in: theme).color, lineWidth: photoRingWidth)
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
            // 写真の代わりに SF Symbols の画像を入れて、縁取りを見る
            OshiAvatar(name: "LUMINA", color: .pink, photo: Image(systemName: "person.crop.square.fill"), size: 48)
            OshiAvatar(name: "ミナト", color: .navy, photo: Image(systemName: "person.crop.square.fill"), size: 48)
            OshiAvatar(name: "ソラ", color: .yellow, photo: Image(systemName: "person.crop.square.fill"), size: 96)
        }
        HStack {
            ForEach(OshiColor.allCases, id: \.self) { color in
                OshiColorDot(color: color)
            }
        }
    }
    .padding()
}
