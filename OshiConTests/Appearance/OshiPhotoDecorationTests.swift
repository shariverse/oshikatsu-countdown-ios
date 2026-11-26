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

    @Test("出さない推しは使わない。出す推しに写真のある推しがいなければ、テーマの模様のまま")
    func excludedOshis() {
        let first = Oshi(name: "A", photoFileName: photoA)
        let second = Oshi(name: "B")
        let third = Oshi(name: "C", photoFileName: photoC)
        let style = OshiPhotoDecorationStyle(opacity: 0.8, amount: 1, excludedOshiIDs: [first.id])
        let decoration = OshiPhotoDecoration(oshis: [first, second, third], style: style)
        #expect(decoration.photoFileNames == [photoC])
        #expect(decoration.opacity == 0.8)
        #expect(decoration.amount == 1)

        let onlySecond = OshiPhotoDecorationStyle(excludedOshiIDs: [first.id, third.id])
        #expect(!OshiPhotoDecoration(oshis: [first, second, third], style: onlySecond).hasPhotos)
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

    @Test("丸い写真は指定の一辺の正方形で、丸の外は透明、中は写真の色")
    func circularImage() throws {
        let source = try #require(Self.solidImage(width: 300, height: 200, red: 255))
        let circular = try #require(OshiPhotoDecoration.circularImage(from: source, pixelLength: 64))
        #expect(circular.width == 64)
        #expect(circular.height == 64)
        let pixels = try #require(Self.rgbaPixels(of: circular))
        // 角は丸の外なので透明
        #expect(pixels.alpha(x: 0, y: 0) == 0)
        #expect(pixels.alpha(x: 63, y: 63) == 0)
        // 中央は写真の色（不透明な赤）
        #expect(pixels.alpha(x: 32, y: 32) == 255)
        #expect(pixels.red(x: 32, y: 32) == 255)
        #expect(OshiPhotoDecoration.circularImage(from: source, pixelLength: 0) == nil)
    }

    /// 1 色で塗った画像。
    private static func solidImage(width: Int, height: Int, red: CGFloat) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.setFillColor(red: red / 255, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    /// 画像を RGBA の画素に描き直したもの。
    private struct RGBAPixels {
        let width: Int
        let bytes: [UInt8]

        func red(x: Int, y: Int) -> UInt8 {
            bytes[(y * width + x) * 4]
        }

        func alpha(x: Int, y: Int) -> UInt8 {
            bytes[(y * width + x) * 4 + 3]
        }
    }

    private static func rgbaPixels(of image: CGImage) -> RGBAPixels? {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return false
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        return drawn ? RGBAPixels(width: image.width, bytes: bytes) : nil
    }
}

struct OshiPhotoDecorationLayoutTests {
    @Test("量 0 は直径 32pt・間隔 128pt、量 1 は直径も間隔も 64pt（丸どうしが接する）。範囲の外は収める")
    func diameterAndSpacing() {
        #expect(OshiPhotoDecorationLayout.diameter(amount: 0) == 32)
        #expect(OshiPhotoDecorationLayout.spacing(amount: 0) == 128)
        #expect(OshiPhotoDecorationLayout.diameter(amount: 0.25) == 40)
        #expect(OshiPhotoDecorationLayout.spacing(amount: 0.25) == 112)
        #expect(OshiPhotoDecorationLayout.diameter(amount: 1) == 64)
        #expect(OshiPhotoDecorationLayout.spacing(amount: 1) == 64)
        #expect(OshiPhotoDecorationLayout.diameter(amount: -1) == 32)
        #expect(OshiPhotoDecorationLayout.diameter(amount: 2) == 64)
        #expect(OshiPhotoDecorationLayout.diameter(amount: .nan) == 32)
    }

    @Test("量を増やすほど、地を覆う割合が増え、量 1 では 9 割ほどを覆う", arguments: [CGSize(width: 390, height: 845), CGSize(width: 700, height: 500)])
    func coverageGrowsWithAmount(size: CGSize) {
        let amounts = Array(stride(from: 0.0, through: 1.0, by: 0.25))
        let coverages = amounts.map { Self.coverage(in: size, amount: $0) }
        for (lower, higher) in zip(coverages, coverages.dropFirst()) {
            #expect(lower < higher, "\(coverages)")
        }
        #expect(coverages[0] < 0.1, "\(coverages)")
        #expect(coverages[1] < 0.15, "\(coverages)")
        #expect(coverages[4] > 0.85, "\(coverages)")
    }

    @Test("どの量でも、丸どうしは重ならない", arguments: [0.0, 0.25, 0.5, 0.75, 1.0])
    func circlesDoNotOverlap(amount: Double) {
        let circles = OshiPhotoDecorationLayout.circles(in: CGSize(width: 400, height: 500), amount: amount)
        #expect(!circles.isEmpty)
        for (index, circle) in circles.enumerated() {
            for other in circles[(index + 1)...] {
                let distance = hypot(circle.rect.midX - other.rect.midX, circle.rect.midY - other.rect.midY)
                #expect(distance >= (circle.rect.width + other.rect.width) / 2 - 0.001, "\(circle) \(other)")
            }
        }
    }

    @Test("地に少しでもかかる丸だけを置き、地の外の丸は置かない", arguments: [0.0, 1.0])
    func circlesIntersectGround(amount: Double) {
        let size = CGSize(width: 390, height: 845)
        let circles = OshiPhotoDecorationLayout.circles(in: size, amount: amount)
        let ground = CGRect(origin: .zero, size: size)
        #expect(circles.allSatisfy { $0.rect.intersects(ground) })
    }

    @Test("大きさが 0 の地には丸を置かない")
    func emptyGround() {
        #expect(OshiPhotoDecorationLayout.circles(in: .zero, amount: 1).isEmpty)
        #expect(OshiPhotoDecorationLayout.circles(in: CGSize(width: 400, height: 0), amount: 1).isEmpty)
    }

    @Test("推しが 3 人以上なら、となり合う丸はどれも別の推し", arguments: [3, 4, 5, 7])
    func neighborsDiffer(count: Int) {
        let circles = OshiPhotoDecorationLayout.circles(in: CGSize(width: 600, height: 800), amount: 1)
        let spacing = OshiPhotoDecorationLayout.spacing(amount: 1)
        var neighborPairs = 0
        for (index, circle) in circles.enumerated() {
            for other in circles[(index + 1)...] {
                let distance = hypot(circle.rect.midX - other.rect.midX, circle.rect.midY - other.rect.midY)
                guard distance < spacing * 1.01 else {
                    continue
                }
                neighborPairs += 1
                let photo = OshiPhotoDecorationLayout.photoIndex(row: circle.row, column: circle.column, count: count)
                let otherPhoto = OshiPhotoDecorationLayout.photoIndex(row: other.row, column: other.column, count: count)
                #expect(photo != otherPhoto, "\(circle) \(other)")
            }
        }
        #expect(neighborPairs > 0)
    }

    @Test("どの推しも使い、番号は 0 から人数より小さい")
    func usesEveryOshi() {
        let circles = OshiPhotoDecorationLayout.circles(in: CGSize(width: 390, height: 845), amount: 0.5)
        for count in 1...6 {
            let indices = Set(circles.map { OshiPhotoDecorationLayout.photoIndex(row: $0.row, column: $0.column, count: count) })
            #expect(indices == Set(0..<count))
        }
        #expect(OshiPhotoDecorationLayout.photoIndex(row: 3, column: 2, count: 0) == 0)
    }

    /// 地の格子の点のうち、どれかの丸の中にある割合。
    private static func coverage(in size: CGSize, amount: Double) -> Double {
        let circles = OshiPhotoDecorationLayout.circles(in: size, amount: amount)
        let step: CGFloat = 6
        var inside = 0
        var total = 0
        var y = step / 2
        while y < size.height {
            var x = step / 2
            while x < size.width {
                total += 1
                if circles.contains(where: { hypot($0.rect.midX - x, $0.rect.midY - y) <= $0.rect.width / 2 }) {
                    inside += 1
                }
                x += step
            }
            y += step
        }
        return Double(inside) / Double(max(total, 1))
    }
}
