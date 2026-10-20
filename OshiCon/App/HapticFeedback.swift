//
//  HapticFeedback.swift
//  OshiCon
//

import SwiftUI

/// 触覚を返す合図。`fire(_:)` で値が変わるたびに、`hapticFeedback(_:)` を付けた View が 1 回だけ触覚を返す。
/// 同じ出来事が続いても鳴るよう、回数も持つ。触覚の ON / OFF はアプリに置かず、端末の設定（システムの触覚）に従う。
nonisolated struct HapticTrigger: Equatable, Sendable {
    /// 触覚を返す出来事。
    enum Event: Equatable, Sendable {
        /// 予定・推しの保存が成功した。
        case saved
        /// ピン留めを切り替えた（保存が成功したあと）。
        case pinChanged(isPinned: Bool)
    }

    private(set) var event: Event?
    private(set) var count = 0

    mutating func fire(_ event: Event) {
        self.event = event
        count += 1
    }

    /// 返す触覚。まだ何も起きていなければ返さない。
    var feedback: SensoryFeedback? {
        switch event {
        case .saved:
            .success
        case .pinChanged:
            .impact(weight: .light)
        case nil:
            nil
        }
    }
}

extension View {
    /// `trigger` が変わったら、その出来事の触覚を返す。
    func hapticFeedback(_ trigger: HapticTrigger) -> some View {
        sensoryFeedback(trigger: trigger) { _, newValue in
            newValue.feedback
        }
    }
}
