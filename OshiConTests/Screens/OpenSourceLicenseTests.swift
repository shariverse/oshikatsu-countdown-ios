//
//  OpenSourceLicenseTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct OpenSourceLicenseTests {
    @Test("同梱している書体を載せ、ライセンスの本文をアプリから読める", arguments: OpenSourceLicense.all)
    func licenseTextIsBundled(license: OpenSourceLicense) throws {
        let text = try #require(license.licenseText())
        #expect(text.contains("SIL OPEN FONT LICENSE Version 1.1"))
        #expect(text.contains(license.author))
    }

    @Test("Info.plist の書体はどれもライセンスの一覧に載っている")
    func everyBundledFontIsListed() throws {
        let fonts = try #require(Bundle.main.object(forInfoDictionaryKey: "UIAppFonts") as? [String])
        #expect(!fonts.isEmpty)
        for font in fonts {
            let listed = OpenSourceLicense.all.contains { font.hasPrefix($0.name.replacingOccurrences(of: " ", with: "")) }
            #expect(listed, "\(font) がオープンソースライセンスの一覧に無い")
        }
    }

    @Test("バージョンは CFBundleShortVersionString。読めなければ空")
    func appVersion() {
        #expect(AppVersion.displayText(infoDictionary: ["CFBundleShortVersionString": "1.2.3", "CFBundleVersion": "45"]) == "1.2.3")
        #expect(AppVersion.displayText(infoDictionary: [:]).isEmpty)
        #expect(AppVersion.displayText(infoDictionary: nil).isEmpty)
        #expect(!AppVersion.displayText().isEmpty)
    }
}
