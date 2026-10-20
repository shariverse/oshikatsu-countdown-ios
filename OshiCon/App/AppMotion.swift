//
//  AppMotion.swift
//  OshiCon
//

import SwiftUI

/// 画面の控えめな動き（カードの出入り・残り日数の数字の変化・初回の導線の歩の切り替え）。長さと曲線をここにまとめる。
/// 「視差効果を減らす」（`accessibilityReduceMotion`）がオンのときは、動き（拡大・横に滑る・数字が回る）を付けず、
/// 出入りは短いフェードだけにする。ウィジェットには付けない（描き直しの動きはシステムに任せる）。
nonisolated enum AppMotion {
    /// 動きを付ける場所。
    enum Element: CaseIterable, Sendable {
        /// ホームの予定（先頭のカード・一覧の行）が増える・消える・入れ替わる。
        case homeCards
        /// 残り日数の数字（ホームの先頭のカード・一覧の行・予定の詳細の日数）が変わる。
        case countdownNumber
        /// 初回の導線の歩が切り替わる。
        case onboardingStep
    }

    /// 動きの付け方。
    enum Style: Equatable, Sendable {
        /// 短いフェードとわずかな拡大で出入りする。
        case fadeAndScale
        /// 数字が桁ごとに入れ替わる（`contentTransition(.numericText)`）。
        case numericText
        /// 横から滑り込む。
        case slide
        /// フェードだけ（「視差効果を減らす」）。
        case fade
        /// 動かさない（「視差効果を減らす」）。
        case none
    }

    /// 動きの長さ（秒）。
    static let duration: TimeInterval = 0.25
    /// 出入りで拡大を始める大きさ（わずかに小さいところから元の大きさへ）。
    static let insertionScale: CGFloat = 0.96

    /// 場所と「視差効果を減らす」から、動きの付け方を決める。
    static func style(for element: Element, reduceMotion: Bool) -> Style {
        switch (element, reduceMotion) {
        case (.homeCards, false):
            .fadeAndScale
        case (.countdownNumber, false):
            .numericText
        case (.onboardingStep, false):
            .slide
        case (.homeCards, true), (.onboardingStep, true):
            .fade
        case (.countdownNumber, true):
            .none
        }
    }

    /// 動きの曲線。動かさないときは nil（アニメーションを付けない）。
    static func animation(for style: Style) -> Animation? {
        switch style {
        case .fadeAndScale, .numericText, .fade:
            .easeInOut(duration: duration)
        case .slide:
            // 初回の導線は前からこの曲線で滑らせているので変えない
            .default
        case .none:
            nil
        }
    }

    /// 出入りの transition。
    static func transition(for style: Style) -> AnyTransition {
        switch style {
        case .fadeAndScale:
            .opacity.combined(with: .scale(scale: insertionScale))
        case .slide:
            .move(edge: .trailing)
        case .fade:
            .opacity
        case .numericText, .none:
            .identity
        }
    }
}

extension View {
    /// 残り日数の数字が変わるときに、桁ごとに入れ替える（「視差効果を減らす」では動かさない）。
    func countdownNumberTransition(_ number: Int) -> some View {
        modifier(CountdownNumberTransition(number: number))
    }
}

private struct CountdownNumberTransition: ViewModifier {
    let number: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let style = AppMotion.style(for: .countdownNumber, reduceMotion: reduceMotion)
        if style == .numericText {
            content
                .contentTransition(.numericText(value: Double(number)))
                .animation(AppMotion.animation(for: style), value: number)
        } else {
            content
        }
    }
}
