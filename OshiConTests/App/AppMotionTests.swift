//
//  AppMotionTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import SwiftUI
import Testing

struct AppMotionTests {
    @Test("ふだんは、カードはフェードと拡大、数字は桁ごとの入れ替え、初回の導線は横に滑らせる")
    func fullMotion() {
        #expect(AppMotion.style(for: .homeCards, reduceMotion: false) == .fadeAndScale)
        #expect(AppMotion.style(for: .countdownNumber, reduceMotion: false) == .numericText)
        #expect(AppMotion.style(for: .onboardingStep, reduceMotion: false) == .slide)
    }

    @Test("「視差効果を減らす」では、拡大・数字の入れ替え・横に滑らせる動きを付けない", arguments: AppMotion.Element.allCases)
    func reduceMotion(element: AppMotion.Element) {
        let style = AppMotion.style(for: element, reduceMotion: true)
        #expect(style == .fade || style == .none)
        #expect(![AppMotion.Style.fadeAndScale, .numericText, .slide].contains(style))
    }

    @Test("「視差効果を減らす」では、出入りはフェードだけで、数字は動かさない")
    func reduceMotionStyles() {
        #expect(AppMotion.style(for: .homeCards, reduceMotion: true) == .fade)
        #expect(AppMotion.style(for: .onboardingStep, reduceMotion: true) == .fade)
        #expect(AppMotion.style(for: .countdownNumber, reduceMotion: true) == .none)
        #expect(AppMotion.animation(for: .none) == nil)
    }

    @Test("動きは短い（0.25 秒）。初回の導線は今の曲線のまま")
    func durations() {
        #expect(AppMotion.duration == 0.25)
        #expect(AppMotion.animation(for: .fadeAndScale) == .easeInOut(duration: 0.25))
        #expect(AppMotion.animation(for: .numericText) == .easeInOut(duration: 0.25))
        #expect(AppMotion.animation(for: .fade) == .easeInOut(duration: 0.25))
        #expect(AppMotion.animation(for: .slide) == .default)
        #expect(AppMotion.insertionScale > 0.9 && AppMotion.insertionScale < 1)
    }
}
