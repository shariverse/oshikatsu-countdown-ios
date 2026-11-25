//
//  ChekiPhoto.swift
//  OshiCon
//

import SwiftUI

/// チェキ（インスタント写真）の枠の寸法。枠の幅から、写真の大きさ・余白・右下のハートの大きさを決める。
nonisolated struct ChekiPhotoLayout: Equatable, Sendable {
    /// 枠の幅。
    let width: CGFloat

    /// 枠の高さ（幅の約 1.26 倍）。
    var height: CGFloat {
        width * 106 / 84
    }

    /// 写真の左右と上の余白。
    var border: CGFloat {
        width * 5 / 84
    }

    /// 写真の下の余白（チェキの書き込みの場所）。
    var bottomBorder: CGFloat {
        width * 17 / 84
    }

    /// 写真の大きさ。
    var photoSize: CGSize {
        CGSize(width: width - border * 2, height: height - border - bottomBorder)
    }

    /// 右下のハートの大きさ。下の余白に収める。
    var heartSize: CGFloat {
        bottomBorder * 0.65
    }

    /// 枠の角の丸み。
    var cornerRadius: CGFloat {
        max(2, width * 3 / 84)
    }

    /// `degrees` だけ傾けた枠が収まる大きさ。傾けても、まわりの文字に重ならないよう場所を取る。
    func boundingSize(tiltDegrees degrees: Double) -> CGSize {
        let radians = abs(degrees) * .pi / 180
        return CGSize(
            width: width * cos(radians) + height * sin(radians),
            height: width * sin(radians) + height * cos(radians)
        )
    }
}

/// チェキ（インスタント写真）風の推しの写真。白い枠に写真を入れ、右下に推し色の小さなハートを置いて、少し傾ける。
/// 写真が無いときは、写真の場所をテーマの模様（`ThemePhotoPlaceholder`）で埋めて頭文字を置く。
/// 名前は横に並べて出す前提なので、読み上げの対象にしない。
struct ChekiPhoto: View {
    let name: String
    let color: OshiColor
    var photo: Image?
    /// 枠の幅。高さは幅から決まる（`ChekiPhotoLayout`）。文字の大きさの設定では変えない。
    var width: CGFloat = 84
    /// 傾き（度。正は時計回り）。
    var tilt: Double = 5

    @Environment(\.appTheme) private var theme

    var body: some View {
        let layout = ChekiPhotoLayout(width: width)
        let bounds = layout.boundingSize(tiltDegrees: tilt)
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: layout.cornerRadius)
                .fill(.white)
                // 白いカードの上でも枠の形が分かるよう、ごく薄い縁を付ける
                .overlay {
                    RoundedRectangle(cornerRadius: layout.cornerRadius)
                        .strokeBorder(.black.opacity(0.12), lineWidth: 0.5)
                }
            picture
                .frame(width: layout.photoSize.width, height: layout.photoSize.height)
                .clipped()
                .padding(.top, layout.border)
        }
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "heart.fill")
                .resizable()
                .scaledToFit()
                .frame(width: layout.heartSize, height: layout.heartSize)
                .foregroundStyle(color.fill)
                .padding(.trailing, layout.border)
                .padding(.bottom, (layout.bottomBorder - layout.heartSize) / 2)
        }
        .frame(width: layout.width, height: layout.height)
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
        .rotationEffect(.degrees(tilt))
        .frame(width: bounds.width, height: bounds.height)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    @ViewBuilder private var picture: some View {
        if let photo {
            photo
                .resizable()
                .scaledToFill()
                // UI テストで写真を描いたことを確かめる口。アバター（`OshiAvatar`）と同じ名前にする
                .accessibilityIdentifier("oshiAvatar.photo")
        } else {
            ThemePhotoPlaceholder(color: color)
                .overlay {
                    Text(InputText.firstCharacter(of: name))
                        // 写真の場所の大きさに合わせる。文字の大きさの設定ではみ出さないよう、ダイナミックタイプで変えない
                        .font(.custom(theme.typography.textFaces.bold, fixedSize: width * 0.3))
                        .foregroundStyle(color.onFill)
                }
        }
    }
}

/// 推しの写真を読んで、チェキ風に出す。読むまでと、写真が無い・読めないときは模様と頭文字。
struct OshiChekiPhoto: View {
    let oshi: Oshi
    var width: CGFloat = 84
    var tilt: Double = 5
    var photos = OshiPhotoLibrary.shared

    @Environment(\.displayScale) private var displayScale
    @State private var photo: Image?

    var body: some View {
        ChekiPhoto(name: oshi.name, color: oshi.color, photo: photo, width: width, tilt: tilt)
            .task(id: oshi.photoFileName) {
                photo = nil
                guard let fileName = oshi.photoFileName else {
                    return
                }
                let size = ChekiPhotoLayout(width: width).photoSize
                let length = Int((max(size.width, size.height) * displayScale).rounded(.up))
                let image = await photos.loadImage(fileName: fileName, maxPixelLength: length)
                photo = image.map { Image(decorative: $0, scale: 1) }
            }
    }
}

#Preview {
    HStack(spacing: 24) {
        ChekiPhoto(name: "LUMINA", color: .pink, photo: Image(systemName: "person.crop.square.fill"))
        ChekiPhoto(name: "ミナト", color: .navy, width: 92, tilt: -4)
    }
    .padding(32)
}
