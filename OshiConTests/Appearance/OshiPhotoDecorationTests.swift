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

    @Test("写真のある推しを渡した順に使い、写真の無い推しは使わない")
    func usesOshisWithPhotosInOrder() {
        let decoration = OshiPhotoDecoration(oshis: [
            Oshi(name: "A", photoFileName: photoA),
            Oshi(name: "B"),
            Oshi(name: "C", photoFileName: photoC)
        ])
        #expect(decoration.hasPhotos)
        #expect(decoration.photoFileNames == [photoA, photoC])
        #expect(decoration.opacity == OshiPhotoDecorationStyle.defaultOpacity)
        #expect(decoration.amount == OshiPhotoDecorationStyle.defaultAmount)
    }

    @Test("写真のある推しがいなければ、テーマの模様のまま")
    func noPhotos() {
        for oshis in [[], [Oshi(name: "A"), Oshi(name: "B")]] {
            let decoration = OshiPhotoDecoration(oshis: oshis)
            #expect(!decoration.hasPhotos)
            #expect(decoration.photoFileNames.isEmpty)
        }
    }

    @Test("写真の置き場所の外を指すファイル名は使わず、同じ写真は 1 回だけ使う")
    func invalidAndDuplicatedFileNames() {
        let decoration = OshiPhotoDecoration(oshis: [
            Oshi(name: "A", photoFileName: "../secret.jpg"),
            Oshi(name: "B", photoFileName: photoA),
            Oshi(name: "C", photoFileName: photoA)
        ])
        #expect(decoration.photoFileNames == [photoA])
        #expect(!OshiPhotoDecoration(oshis: [Oshi(name: "A", photoFileName: "photo.png")]).hasPhotos)
    }

    @Test("写真はいちばん大きい丸（64pt）の直径を画素にした大きさで読む")
    func decodePixelLength() {
        #expect(OshiPhotoDecoration.decodePixelLength(displayScale: 3) == 192)
        #expect(OshiPhotoDecoration.decodePixelLength(displayScale: 2) == 128)
        #expect(OshiPhotoDecoration.decodePixelLength(displayScale: 0) == 64)
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
}
