//
//  OshiPhotoDecoration.swift
//  OshiCon
//

import CoreGraphics

/// 着せ替えの飾り（Plus）: 地のハートと十字（`CrossesAndHeartsPattern`）の位置に、推しの丸い写真を順に散らす規則。
///
/// - 模様の通し番号（`slot`）ごとに、推しを渡した順（ホームの絞り込みと同じ並び）にくり返して割り当てる
/// - 割り当てた推しに写真があれば丸い写真を、写真が無ければ今の模様（ハート・十字）を描く
/// - 写真のある推しが 1 人もいなければ、すべて今の模様
/// - 丸い写真は薄く（`photoOpacity`）描き、地の上の本文が 4.5:1 以上になるようにする（`OshiPhotoDecorationTests`）
nonisolated struct OshiPhotoDecoration: Equatable, Sendable {
    /// 丸い写真の不透明度。写真が真っ白・真っ黒でも、地（背景の写真に幕を掛けた地を含む）の上の本文が 4.5:1 以上になる値。
    static let photoOpacity = 0.15
    /// 丸い写真の直径の、模様の高さに対する倍率（模様は 10〜16pt と小さいので、顔が分かる大きさに広げる）。
    static let photoScale: CGFloat = 2.5

    /// 推しごとの写真のファイル名（渡した順）。写真が無い・置き場所の外を指す推しは nil。
    let photoFileNames: [String?]

    /// 推し `oshis`（並べたい順）から決める。
    init(oshis: [Oshi]) {
        photoFileNames = oshis.map { oshi in
            oshi.photoFileName.flatMap { OshiPhotoLibrary.isValidFileName($0) ? $0 : nil }
        }
    }

    /// 写真のある推しがいるか。いなければ今の模様のまま。
    var hasPhotos: Bool {
        photoFileNames.contains { $0 != nil }
    }

    /// 読む写真のファイル名（重なりを除き、渡した順）。
    var distinctPhotoFileNames: [String] {
        var seen = Set<String>()
        return photoFileNames.compactMap { $0 }.filter { seen.insert($0).inserted }
    }

    /// 通し番号 `slot` の模様の位置に描く写真のファイル名。今の模様のままにするところは nil。
    func photoFileName(forSlot slot: Int) -> String? {
        guard hasPhotos, slot >= 0 else {
            return nil
        }
        return photoFileNames[slot % photoFileNames.count]
    }

    /// 模様 `mark` の位置に置く丸い写真の枠（地の座標。中心は模様と同じ）。
    static func photoRect(for mark: CrossesAndHeartsPattern.PlacedMark) -> CGRect {
        let diameter = mark.size * photoScale
        return CGRect(x: mark.center.x - diameter / 2, y: mark.center.y - diameter / 2, width: diameter, height: diameter)
    }

    /// いちばん大きい丸い写真の直径（pt）。
    static var maxPhotoDiameter: CGFloat {
        (CrossesAndHeartsPattern.marks.map(\.size).max() ?? 0) * photoScale
    }

    /// 写真を読む長辺（画素）。いちばん大きい丸の直径を画面の倍率 `displayScale` で画素にする。
    static func decodePixelLength(displayScale: CGFloat) -> Int {
        Int(max((maxPhotoDiameter * max(displayScale, 1)).rounded(.up), 1))
    }

    /// 大きさ `imageSize` の写真で丸の枠 `circle` を覆う、写真を描く枠（縦横比を保ち、中央に置く。はみ出した分は丸で切る）。
    static func imageRect(imageSize: CGSize, filling circle: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return circle
        }
        let scale = max(circle.width / imageSize.width, circle.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(x: circle.midX - width / 2, y: circle.midY - height / 2, width: width, height: height)
    }

    /// 色 `ground` の地に、色 `photo` の丸い写真を `photoOpacity` で重ねた色（コントラストを確かめるのに使う）。
    static func ground(_ ground: RGBColor, under photo: RGBColor) -> RGBColor {
        ground.mixed(with: photo, fraction: photoOpacity)
    }
}
