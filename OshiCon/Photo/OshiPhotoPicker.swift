//
//  OshiPhotoPicker.swift
//  OshiCon
//

import PhotosUI
import SwiftUI

/// 推しの登録・編集で写真を選ぶ部品。今の写真を丸く出し、「写真を選ぶ / 写真を変える」と「写真を外す」を置く。
/// `PhotosPicker` は写真ライブラリへのアクセスの許可が要らない（選んだ写真だけを受け取る）。
/// 写真が無いときの見た目（推し色の丸と頭文字）は `placeholder` で渡す（推しの登録・編集の画面でアバターを渡す）。
struct OshiPhotoPicker<Placeholder: View>: View {
    /// 保存してある写真のファイル名。
    let currentPhotoFileName: String?
    @Binding var photoChange: PhotoChange
    var photos = OshiPhotoLibrary()
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var selectedItem: PhotosPickerItem?
    @State private var preview: Image?
    @State private var isLoading = false
    @State private var loadFailed = false

    private let avatarSize: CGFloat = 96

    private var hasPhoto: Bool {
        switch photoChange {
        case .keep:
            currentPhotoFileName != nil
        case .remove:
            false
        case .replace:
            true
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            photoView
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
                .accessibilityHidden(true)
                .overlay {
                    if isLoading {
                        ProgressView()
                    }
                }
            HStack(spacing: 16) {
                PhotosPicker(hasPhoto ? "写真を変える" : "写真を選ぶ", selection: $selectedItem, matching: .images)
                if hasPhoto {
                    Button("写真を外す", role: .destructive) {
                        selectedItem = nil
                        preview = nil
                        photoChange = .remove
                    }
                }
            }
            .font(.subheadline.bold())
            .disabled(isLoading)
            if loadFailed {
                Text("写真を読み込めませんでした")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .task(id: currentPhotoFileName) {
            await loadCurrentPhoto()
        }
        .onChange(of: selectedItem) { _, item in
            guard let item else {
                return
            }
            Task {
                await load(item)
            }
        }
    }

    @ViewBuilder private var photoView: some View {
        if hasPhoto, let preview {
            preview
                .resizable()
                .scaledToFill()
        } else {
            placeholder()
        }
    }

    private func loadCurrentPhoto() async {
        guard case .keep = photoChange, let currentPhotoFileName else {
            return
        }
        let pixels = Int(avatarSize * 3)
        if let image = await photos.loadImage(fileName: currentPhotoFileName, maxPixelLength: pixels) {
            preview = Image(decorative: image, scale: 1)
        }
    }

    private func load(_ item: PhotosPickerItem) async {
        isLoading = true
        loadFailed = false
        defer {
            isLoading = false
        }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = await photos.previewImage(data: data, maxPixelLength: Int(avatarSize * 3)) else {
            loadFailed = true
            return
        }
        preview = Image(decorative: image, scale: 1)
        photoChange = .replace(data)
    }
}

#Preview {
    @Previewable @State var change = PhotoChange.keep
    OshiPhotoPicker(currentPhotoFileName: nil, photoChange: $change) {
        Circle().fill(.pink)
    }
    .padding()
}
