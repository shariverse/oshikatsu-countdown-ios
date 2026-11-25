//
//  LockScreenCapture.swift
//  OshiConUITests
//

import CoreGraphics
import UIKit
import XCTest

/// App Store 用スクリーンショットのロック画面を、壁紙が暗く写っていないことを確かめてから残す。
///
/// ロック画面は、まれに壁紙が暗くなっていく途中の状態で写る（1.3.0 の iPad 13 inch で、ほとんど黒いものと半分ほど暗いものがあった。#313）。
/// どの操作で起きるかは分かっていない（手元で同じ流れをまねても再現しなかった）ので、撮った画面の壁紙の部分の明るさで見分け、
/// 暗ければロックし直して撮り直す。
extension XCTestCase {
    /// ロック画面を撮って `name` の添付に残す。壁紙が暗ければ `relock` でロックし直して 2 回まで撮り直し、それでも暗ければ失敗にする
    /// （スクリプトがこのテストを撮り直す）。`relock` が false を返したら（撮れる状態に戻せなかった）そこでやめる。
    /// iPhone Duo はロックできず、ロック画面を使わないので確かめない。
    @MainActor
    func captureLockScreen(_ name: String, relock: () -> Bool) -> Bool {
        let isIPhoneDuo = ProcessInfo.processInfo.environment["APP_STORE_DISPLAY_TYPE"] == "APP_IPHONE_DUO"
        for attempt in 1...3 {
            let screenshot = XCUIScreen.main.screenshot()
            let brightness = screenshot.image.cgImage.flatMap(LockScreenWallpaper.brightness(of:))
            if isIPhoneDuo || brightness.map({ $0 >= LockScreenWallpaper.minimumBrightness }) ?? true {
                let attachment = XCTAttachment(screenshot: screenshot)
                attachment.name = name
                attachment.lifetime = .keepAlways
                add(attachment)
                return true
            }
            print("\(name) の壁紙が暗く写りました（明るさ \(brightness.map { String(format: "%.1f", $0) } ?? "-")、\(attempt) 回目）")
            guard attempt < 3, relock() else {
                break
            }
        }
        XCTFail("\(name) の壁紙が暗く写りました")
        return false
    }
}

/// ロック画面の壁紙の部分の明るさ。
enum LockScreenWallpaper {
    /// 壁紙の部分の明るさ（0〜255）の下限。これより暗ければ撮り直す。
    /// 普段は 61.9〜81.7（1.3.0 の iPhone 6.9・6.1 inch と iPad 13 inch の既定の壁紙）、暗く写ったものは 6.9 と 33.2 だった
    static let minimumBrightness = 45.0

    /// 縮めて測る幅（px）。明るさの平均を見るだけなので、細かさは要らない
    private static let sampleWidth = 64

    /// 壁紙の部分（画面の高さの 35%〜80%。時計の下から、ライブアクティビティの帯の上まで）の明るさの平均（0〜255）。
    /// 明るさは sRGB の値の 0.299R + 0.587G + 0.114B（測ったときの値と同じ式）。
    static func brightness(of image: CGImage) -> Double? {
        guard image.width > 0, let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }
        let width = sampleWidth
        let height = max(1, image.height * width / image.width)
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) else {
                return false
            }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        // ビットマップの行は上から並ぶ
        let rows = Int(Double(height) * 0.35)..<Int(Double(height) * 0.8)
        guard drawn, !rows.isEmpty else {
            return nil
        }
        var total = 0.0
        for row in rows {
            for column in 0..<width {
                let index = (row * width + column) * 4
                total += 0.299 * Double(pixels[index]) + 0.587 * Double(pixels[index + 1]) + 0.114 * Double(pixels[index + 2])
            }
        }
        return total / Double(rows.count * width)
    }
}
