//
//  OshiPhotoPicker.swift
//  OshiCon
//

import PhotosUI
import SwiftUI

/// 推しの登録・編集で写真を選ぶ部品。今の写真を丸く出し、「写真を選ぶ / 写真を変える」と「写真を外す」を置く。
/// `PhotosPicker` は写真ライブラリへのアクセスの許可が要らない（選んだ写真だけを受け取る）。
/// 写真が無いときの見た目（推し色の丸と頭文字）は `placeholder` で渡す（推しの登録・編集の画面でアバターを渡す）。
/// 選んだ写真を読んでいる間は `isLoading` を true にする（読み終わる前に保存させないため）。
/// 写真を読めたら調整画面（`PhotoCropScreen`）を全画面で出し、「完了」で切り抜いた見た目のプレビューと範囲つきの差し替えにする。
/// 「やめる」では何も変えない（前の写真・プレビュー・`photoChange` のまま）。
/// 写真があるときは「位置を調整」で今の写真から調整画面を開き直せる。保存してある写真はその JPEG を元に切り抜き直し（狭める調整だけになる）、
/// 選んだばかりの写真は、元の選んだ写真と前の範囲から開き直す。
struct OshiPhotoPicker<Placeholder: View>: View {
    /// 保存してある写真のファイル名。
    let currentPhotoFileName: String?
    @Binding var photoChange: PhotoChange
    @Binding var isLoading: Bool
    var photos = OshiPhotoLibrary.shared
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var selectedItem: PhotosPickerItem?
    @State private var preview: Image?
    @State private var loadFailed = false
    /// 調整画面で調整中の写真。nil なら調整画面を出していない。
    @State private var cropping: PendingCrop?
    @Environment(\.displayScale) private var displayScale
    @Environment(\.appTheme) private var theme

    private let avatarSize: CGFloat = 96
    /// 調整画面で描く写真の短い辺（pt）。枠の上限（`PhotoCropLayout.maximumFrameSide`）の枠を、拡大なしで引き伸ばさずに描ける大きさ。
    private var cropDisplayShortSide: Int {
        Int(PhotoCropLayout.maximumFrameSide * displayScale)
    }
    /// 調整画面で描く写真の長辺の上限（画素）。パノラマなどで大きくなりすぎないようにする。
    private let cropDisplayMaxLongSide = 4_096

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
            .font(theme.typography.text(.subheadline, weight: .bold))
            .disabled(isLoading)
            if hasPhoto {
                Button("位置を調整") {
                    // Task が動き出す前に立て、続けて押しても 1 回だけ開く
                    isLoading = true
                    Task {
                        await readjust()
                    }
                }
                .font(theme.typography.text(.subheadline, weight: .bold))
                .disabled(isLoading)
            }
            if loadFailed {
                Text("写真を読み込めませんでした")
                    .font(theme.typography.text(.footnote))
                    .foregroundStyle(theme.palette.destructive.color)
            }
        }
        // Form・List の行の中で、行のどこを押しても全部のボタンが動かないよう、ボタンを押せる範囲をそれぞれの文字に限る
        .buttonStyle(.borderless)
        .task(id: currentPhotoFileName) {
            await loadCurrentPhoto()
        }
        .task(id: selectedItem) {
            guard let selectedItem else {
                return
            }
            await load(selectedItem)
            // 選んだ写真を戻し、読み込めなかった同じ写真をもう一度選んでも読み直せるようにする
            self.selectedItem = nil
        }
        .fullScreenCover(item: $cropping) { pending in
            PhotoCropScreen(
                image: pending.source.image,
                initialCrop: pending.initialCrop ?? pending.source.initialCrop,
                onCancel: {
                    cropping = nil
                },
                onDone: { crop in
                    cropping = nil
                    // 保存してある写真から開いて何も変えずに「完了」したら、書き直さない（JPEG の画質を落とさない）
                    if pending.isSavedPhoto, crop == pending.source.initialCrop.clamped() {
                        return
                    }
                    // Task が動き出す前に立て、閉じるアニメーションの間に保存させない
                    isLoading = true
                    Task {
                        await apply(pending.data, crop: crop)
                    }
                }
            )
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
        let image = await photos.loadImage(fileName: currentPhotoFileName, maxPixelLength: pixels)
        // 読んでいる間に写真を選び直していたら、選んだ写真のプレビューを残す
        guard case .keep = photoChange, let image else {
            return
        }
        preview = Image(decorative: image, scale: 1)
    }

    /// 選んだ写真を読み、調整画面を出す。プレビューと `photoChange` は「完了」まで変えない。
    private func load(_ item: PhotosPickerItem) async {
        isLoading = true
        loadFailed = false
        defer {
            isLoading = false
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            loadFailed = true
            return
        }
        await openCropScreen(data: data, initialCrop: nil)
    }

    /// 今の写真から調整画面を開き直す。選んだばかりの写真なら元の写真と前の範囲から、保存してある写真ならその JPEG から開く。
    private func readjust() async {
        isLoading = true
        loadFailed = false
        defer {
            isLoading = false
        }
        switch photoChange {
        case let .replace(data, crop):
            await openCropScreen(data: data, initialCrop: crop)
        case .keep:
            guard let currentPhotoFileName, let data = await photos.photoData(fileName: currentPhotoFileName) else {
                loadFailed = true
                return
            }
            await openCropScreen(data: data, initialCrop: nil, isSavedPhoto: true)
        case .remove:
            return
        }
    }

    /// 写真を調整画面で描ける大きさに読み、調整画面を出す。`initialCrop` が無ければ写真全体から始める。
    private func openCropScreen(data: Data, initialCrop: PhotoCrop?, isSavedPhoto: Bool = false) async {
        let source = await photos.cropSource(data: data, shortSidePixels: cropDisplayShortSide, maxLongSidePixels: cropDisplayMaxLongSide)
        // 読んでいる間に画面を離れて `.task(id: selectedItem)` が取り消されたら出さない（「位置を調整」の Task は取り消されないので効かない。
        // 画面が消えていれば調整画面は出ない）
        guard !Task.isCancelled else {
            return
        }
        guard let source else {
            loadFailed = true
            return
        }
        cropping = PendingCrop(data: data, source: source, initialCrop: initialCrop, isSavedPhoto: isSavedPhoto)
    }

    /// 調整画面の「完了」。切り抜いた見た目のプレビューを出し、範囲つきの差し替えにする。
    private func apply(_ data: Data, crop: PhotoCrop) async {
        loadFailed = false
        defer {
            isLoading = false
        }
        guard let image = await photos.croppedPreviewImage(data: data, crop: crop, maxPixelLength: Int(avatarSize * 3)) else {
            loadFailed = true
            return
        }
        preview = Image(decorative: image, scale: 1)
        photoChange = .replace(data, crop: crop)
    }
}

/// 調整画面で調整中の写真。写真ごとに id を変え、調整画面を作り直す（前の写真の範囲を引き継がない）。
private struct PendingCrop: Identifiable {
    let id = UUID()
    let data: Data
    let source: PhotoCropSource
    /// 開いたときの範囲。nil なら写真全体（`source.initialCrop`）。
    let initialCrop: PhotoCrop?
    /// 保存してある写真から開いたか（何も変えずに「完了」したら書き直さない）。
    let isSavedPhoto: Bool
}

#Preview {
    @Previewable @State var change = PhotoChange.keep
    @Previewable @State var isLoading = false
    OshiPhotoPicker(currentPhotoFileName: nil, photoChange: $change, isLoading: $isLoading) {
        OshiAvatar(name: "ミナト", color: .pink, size: 96)
    }
    .padding()
}
