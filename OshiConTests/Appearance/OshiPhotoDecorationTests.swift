//
//  OshiPhotoDecorationTests.swift
//  OshiConTests
//

import CoreGraphics
import Foundation
@testable import OshiCon
import Testing

struct CrossesAndHeartsPatternTests {
    @Test("地にかかるタイルを左右上下にくり返し、模様に左上から行ごとの通し番号を付ける")
    func placedMarks() {
        // 幅 400 は 3 列（0・180・360）、高さ 500 は 3 行（0・220・440）
        let placed = CrossesAndHeartsPattern.placedMarks(in: CGSize(width: 400, height: 500))
        let marks = CrossesAndHeartsPattern.marks
        #expect(placed.count == 3 * 3 * marks.count)
        #expect(placed.map(\.slot) == Array(0..<placed.count))
        for (index, mark) in marks.enumerated() {
            #expect(placed[index].center == mark.position)
            #expect(placed[index].isCross == mark.isCross)
            #expect(placed[index].size == mark.size)
        }
        // 2 列目の最初の模様は、タイルの幅だけ右
        let secondColumn = placed[marks.count]
        #expect(secondColumn.center == CGPoint(x: marks[0].position.x + 180, y: marks[0].position.y))
        // 2 行目の最初の模様は、タイルの高さだけ下
        let secondRow = placed[3 * marks.count]
        #expect(secondRow.center == CGPoint(x: marks[0].position.x, y: marks[0].position.y + 220))
    }

    @Test("大きさが 0 の地には模様を置かない")
    func emptyGround() {
        #expect(CrossesAndHeartsPattern.placedMarks(in: .zero).isEmpty)
        #expect(CrossesAndHeartsPattern.placedMarks(in: CGSize(width: 400, height: 0)).isEmpty)
    }
}

struct OshiPhotoDecorationTests {
    private let photoA = "\(UUID().uuidString).jpg"
    private let photoC = "\(UUID().uuidString).jpg"

    @Test("写真のある推しを渡した順にくり返し、写真の無い推しのところは今の模様のまま")
    func assignsInOrder() {
        let decoration = OshiPhotoDecoration(oshis: [
            Oshi(name: "A", photoFileName: photoA),
            Oshi(name: "B"),
            Oshi(name: "C", photoFileName: photoC)
        ])
        #expect(decoration.hasPhotos)
        let assigned = (0..<7).map { decoration.photoFileName(forSlot: $0) }
        #expect(assigned == [photoA, nil, photoC, photoA, nil, photoC, photoA])
        #expect(decoration.distinctPhotoFileNames == [photoA, photoC])
    }

    @Test("写真のある推しがいなければ、すべて今の模様のまま")
    func noPhotos() {
        for oshis in [[], [Oshi(name: "A"), Oshi(name: "B")]] {
            let decoration = OshiPhotoDecoration(oshis: oshis)
            #expect(!decoration.hasPhotos)
            #expect(decoration.distinctPhotoFileNames.isEmpty)
            #expect((0..<10).allSatisfy { decoration.photoFileName(forSlot: $0) == nil })
        }
    }

    @Test("写真の置き場所の外を指すファイル名は、写真が無いものとする")
    func invalidFileName() {
        let decoration = OshiPhotoDecoration(oshis: [
            Oshi(name: "A", photoFileName: "../secret.jpg"),
            Oshi(name: "B", photoFileName: photoA)
        ])
        #expect(decoration.photoFileNames == [nil, photoA])
        #expect(decoration.photoFileName(forSlot: 0) == nil)
        #expect(decoration.photoFileName(forSlot: 1) == photoA)
        #expect(!OshiPhotoDecoration(oshis: [Oshi(name: "A", photoFileName: "photo.png")]).hasPhotos)
    }

    @Test("負の通し番号には写真を置かない")
    func negativeSlot() {
        let decoration = OshiPhotoDecoration(oshis: [Oshi(name: "A", photoFileName: photoA)])
        #expect(decoration.photoFileName(forSlot: -1) == nil)
        #expect(decoration.photoFileName(forSlot: 0) == photoA)
    }

    @Test("丸い写真は模様と同じ中心に、模様の高さの 2.5 倍の直径で置く")
    func photoRect() {
        let mark = CrossesAndHeartsPattern.PlacedMark(slot: 0, isCross: true, center: CGPoint(x: 100, y: 50), size: 16)
        let rect = OshiPhotoDecoration.photoRect(for: mark)
        #expect(rect == CGRect(x: 80, y: 30, width: 40, height: 40))
        #expect(OshiPhotoDecoration.maxPhotoDiameter == 40)
    }

    @Test("写真はいちばん大きい丸の直径を画素にした大きさで読む")
    func decodePixelLength() {
        #expect(OshiPhotoDecoration.decodePixelLength(displayScale: 3) == 120)
        #expect(OshiPhotoDecoration.decodePixelLength(displayScale: 2) == 80)
        #expect(OshiPhotoDecoration.decodePixelLength(displayScale: 0) == 40)
    }

    @Test("写真は縦横比を保って丸を覆い、中央に置く")
    func imageRect() {
        let circle = CGRect(x: 10, y: 20, width: 40, height: 40)
        #expect(OshiPhotoDecoration.imageRect(imageSize: CGSize(width: 120, height: 120), filling: circle) == circle)
        let wide = OshiPhotoDecoration.imageRect(imageSize: CGSize(width: 200, height: 100), filling: circle)
        #expect(wide == CGRect(x: -10, y: 20, width: 80, height: 40))
        let tall = OshiPhotoDecoration.imageRect(imageSize: CGSize(width: 100, height: 300), filling: circle)
        #expect(tall == CGRect(x: 10, y: -20, width: 40, height: 120))
        #expect(OshiPhotoDecoration.imageRect(imageSize: .zero, filling: circle) == circle)
    }

    @Test("丸い写真どうしは、となりのタイルのものとも重ならない")
    func photosDoNotOverlap() {
        let tile = CrossesAndHeartsPattern.tileSize
        let marks = CrossesAndHeartsPattern.placedMarks(in: CGSize(width: tile.width * 3, height: tile.height * 3))
        let rects = marks.map(OshiPhotoDecoration.photoRect(for:))
        for (index, rect) in rects.enumerated() {
            for other in rects[(index + 1)...] {
                let distance = hypot(rect.midX - other.midX, rect.midY - other.midY)
                #expect(distance >= (rect.width + other.width) / 2, "\(rect) \(other)")
            }
        }
    }

    @Test(
        "背景の写真が無いとき、丸い写真が真っ白・真っ黒でも、地の上の本文が 4.5:1 以上（ライトとダーク）",
        arguments: [false, true]
    )
    func contrast(isDark: Bool) {
        // 背景の写真の上に重ねるときは、地の上の本文の後ろに板を敷くので（AppearanceTextPlate）、ここでは数えない
        let palette = AppTheme.shipping.palette
        let ground = palette.background.resolved(isDark: isDark)
        for photo in [RGBColor.white, .black] {
            let decorated = OshiPhotoDecoration.ground(ground, under: photo)
            #expect(palette.onSurface.resolved(isDark: isDark).contrastRatio(with: decorated) >= 4.5, "\(photo)")
            #expect(palette.onSurfaceVariant.resolved(isDark: isDark).contrastRatio(with: decorated) >= 4.5, "\(photo)")
        }
    }
}
