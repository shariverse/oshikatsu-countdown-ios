//
//  OnboardingFlowView.swift
//  OshiCon
//

import SwiftUI

/// 初回の導線。ステップ 1 / 2 で推しを登録し、ステップ 2 / 2 で最初の予定を登録してタブへ進む。
/// どちらも「あとで」で保存せずに次へ進める。2 歩目から 1 歩目には戻らない（登録した推しを同じ画面でもう一度登録させないため）。
struct OnboardingFlowView: View {
    /// 導線を終えた（「あとで」を含む）。
    let onFinish: () -> Void

    @State private var step = Step.oshi
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Step: Equatable {
        case oshi
        /// 最初の予定。1 歩目で登録した推しを選んでおく。
        case firstEvent(registeredOshiID: Oshi.ID?)
    }

    var body: some View {
        Group {
            switch step {
            case .oshi:
                OshiEditorScreen(
                    oshi: nil,
                    onboarding: .oshi {
                        step = .firstEvent(registeredOshiID: nil)
                    },
                    onSaved: { oshi in
                        step = .firstEvent(registeredOshiID: oshi.id)
                    }
                )
            case let .firstEvent(registeredOshiID):
                EventEditorScreen(
                    event: nil,
                    preselectedOshiID: registeredOshiID,
                    onboarding: .firstEvent(onSkip: onFinish),
                    onSaved: { _ in onFinish() }
                )
                .transition(AppMotion.transition(for: stepMotion))
            }
        }
        .animation(AppMotion.animation(for: stepMotion), value: step)
    }

    /// 歩の切り替え。「視差効果を減らす」では横に滑らせずフェードにする。
    private var stepMotion: AppMotion.Style {
        AppMotion.style(for: .onboardingStep, reduceMotion: reduceMotion)
    }
}

#Preview {
    OnboardingFlowView {}
        .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
