//
//  AppFontTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import SwiftUI
import Testing
import UIKit

struct AppFontTests {
    @Test("同梱した本文の書体が登録されている", arguments: AppFont.TextFace.allCases)
    func textFaceIsRegistered(face: AppFont.TextFace) {
        #expect(UIFont(name: face.rawValue, size: 17) != nil)
    }

    @Test(
        "同梱した数字の書体（可変フォント）は、太さを付けるとその太さの字形になる（既定の Thin にならない）",
        arguments: [(UIFont.Weight.regular, 400), (.medium, 500), (.bold, 700)]
    )
    func numeralWeightSelectsVariation(weight: UIFont.Weight, expectedWeightAxis: Int) {
        #expect(UIFont.fontNames(forFamilyName: AppFont.numeralFamily).isEmpty == false)
        let descriptor = UIFontDescriptor(fontAttributes: [.family: AppFont.numeralFamily])
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        let font = UIFont(descriptor: descriptor, size: 20)
        #expect(font.familyName == AppFont.numeralFamily)
        // 可変フォントの wght 軸（'wght' = 0x77676874）の値
        let variation = CTFontCopyVariation(font as CTFont) as? [NSNumber: NSNumber]
        #expect(variation?[NSNumber(value: 0x7767_6874)]?.intValue == expectedWeightAxis)
    }

    @Test("太さは regular・medium・bold に丸める")
    func faceForWeight() {
        #expect(AppFont.face(for: .light) == .regular)
        #expect(AppFont.face(for: .regular) == .regular)
        #expect(AppFont.face(for: .medium) == .medium)
        #expect(AppFont.face(for: .semibold) == .bold)
        #expect(AppFont.face(for: .bold) == .bold)
        #expect(AppFont.face(for: .black) == .bold)
    }

    @Test("テキストスタイルの標準の大きさは iOS の既定と同じ")
    func defaultSizes() {
        let styles: [(Font.TextStyle, UIFont.TextStyle)] = [
            (.largeTitle, .largeTitle), (.title, .title1), (.title2, .title2), (.title3, .title3),
            (.headline, .headline), (.body, .body), (.callout, .callout), (.subheadline, .subheadline),
            (.footnote, .footnote), (.caption, .caption1), (.caption2, .caption2)
        ]
        let traits = UITraitCollection(preferredContentSizeCategory: .large)
        for (style, uiStyle) in styles {
            #expect(AppFont.defaultSize(of: style) == UIFont.preferredFont(forTextStyle: uiStyle, compatibleWith: traits).pointSize)
        }
    }
}
