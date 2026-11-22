//
//  AppearanceUITestMarkerTests.swift
//  OshiConTests
//

@testable import OshiCon
import Testing

struct AppearanceUITestMarkerTests {
    private let photo = "00000000-0000-0000-0000-000000000001.jpg"

    @Test("標準の見た目は standard")
    func standard() {
        #expect(AppearanceUITestMarker.value(of: .standard) == "standard")
    }

    @Test("Plus でなければ、写真と飾りを選んでいても standard")
    func lockedIsStandard() {
        let settings = AppearanceSettings(isDecorationEnabled: true, backgroundPhotoFileName: photo)
        #expect(AppearanceUITestMarker.value(of: AppearanceRendering(settings: settings, isPlusUnlocked: false)) == "standard")
    }

    @Test("背景の写真は強さを付けて、飾りは decoration で表す", arguments: [
        (AppearanceIntensity.weak, false, "photo:weak"),
        (.medium, true, "photo:medium,decoration"),
        (.strong, false, "photo:strong")
    ])
    func photoAndDecoration(intensity: AppearanceIntensity, decoration: Bool, expected: String) {
        let rendering = AppearanceRendering(
            backgroundPhoto: .init(fileName: photo, intensity: intensity),
            showsOshiPhotoDecoration: decoration
        )
        #expect(AppearanceUITestMarker.value(of: rendering) == expected)
    }

    @Test("飾りだけは decoration")
    func decorationOnly() {
        let rendering = AppearanceRendering(backgroundPhoto: nil, showsOshiPhotoDecoration: true)
        #expect(AppearanceUITestMarker.value(of: rendering) == "decoration")
    }
}
