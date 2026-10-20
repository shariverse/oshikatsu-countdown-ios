//
//  HapticTriggerTests.swift
//  OshiConTests
//

@testable import OshiCon
import SwiftUI
import Testing

struct HapticTriggerTests {
    @Test("何も起きていなければ触覚を返さない")
    func initial() {
        #expect(HapticTrigger().feedback == nil)
    }

    @Test("保存が成功したら success、ピン留めを切り替えたら軽い impact")
    func feedbackForEvent() {
        var trigger = HapticTrigger()
        trigger.fire(.saved)
        #expect(trigger.feedback == .success)
        trigger.fire(.pinChanged(isPinned: true))
        #expect(trigger.feedback == .impact(weight: .light))
        trigger.fire(.pinChanged(isPinned: false))
        #expect(trigger.feedback == .impact(weight: .light))
    }

    @Test("同じ出来事が続いても値が変わり、そのたびに鳴る")
    func repeatedEventChangesValue() {
        var trigger = HapticTrigger()
        trigger.fire(.saved)
        let first = trigger
        trigger.fire(.saved)
        #expect(trigger != first)
        #expect(trigger.count == 2)
    }
}
