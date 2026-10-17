//
//  OshiPhotoAvatar.swift
//  OshiCon
//

import SwiftUI

/// 推しのアバターに、取り込んだ写真を読んで出す。読むまでと、写真が無い・読めないときは推し色の丸と頭文字。
struct OshiPhotoAvatar: View {
    let oshi: Oshi
    var size: CGFloat = 40
    var photos = OshiPhotoLibrary.shared

    @Environment(\.displayScale) private var displayScale
    @State private var photo: Image?

    var body: some View {
        OshiAvatar(name: oshi.name, color: oshi.color, photo: photo, size: size)
            .task(id: oshi.photoFileName) {
                photo = nil
                guard let fileName = oshi.photoFileName else {
                    return
                }
                let image = await photos.loadImage(fileName: fileName, maxPixelLength: Int((size * displayScale).rounded(.up)))
                photo = image.map { Image(decorative: $0, scale: 1) }
            }
    }
}

#Preview {
    OshiPhotoAvatar(oshi: Oshi(name: "ミナト", color: .navy), size: 48)
}
