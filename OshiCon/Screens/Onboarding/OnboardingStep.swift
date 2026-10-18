//
//  OnboardingStep.swift
//  OshiCon
//

import SwiftUI

/// 推し・予定の入力の画面を、初回の導線の 1 歩として出すときの見た目と動き。
/// 見出しに「ステップ N / 2」、上に「あとで」、下に次へ進むボタンを置く（シートの「キャンセル」「保存」の代わり）。
struct OnboardingStep {
    /// ナビゲーションバーの見出し（`ステップ 1 / 2`）。
    let title: String
    /// 入力の上に大きく出す見出し。
    let heading: String
    /// 見出しの下の説明。
    var message: String?
    /// 保存して次へ進むボタンの文言。
    let primaryActionTitle: String
    /// 「あとで」。保存せずに次へ進む。
    let onSkip: () -> Void

    /// 1 歩目: 推しの登録。
    static func oshi(onSkip: @escaping () -> Void) -> Self {
        Self(
            title: "ステップ 1 / 2",
            heading: "あなたの推しを教えてね",
            primaryActionTitle: "次へ：最初の予定を登録",
            onSkip: onSkip
        )
    }

    /// 2 歩目: 最初の予定。
    static func firstEvent(onSkip: @escaping () -> Void) -> Self {
        Self(
            title: "ステップ 2 / 2",
            heading: "最初の予定を登録しよう",
            message: "ライブ・誕生日・発売日など、楽しみな日を 1 つ入れてみてね。",
            primaryActionTitle: "保存してはじめる",
            onSkip: onSkip
        )
    }
}

/// 導線の 1 歩の見出し。Form の先頭に置く。
struct OnboardingHeading: View {
    let step: OnboardingStep

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(step.heading)
                    .font(AppFont.text(.title2, weight: .bold))
                    .foregroundStyle(AppPalette.onSurface.color)
                    .accessibilityAddTraits(.isHeader)
                if let message = step.message {
                    Text(message)
                        .font(AppFont.text(.subheadline))
                        .foregroundStyle(AppPalette.onSurfaceVariant.color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 4))
    }
}

/// 導線の 1 歩の、画面の下に置く次へ進むボタン。
struct OnboardingPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.text(.headline, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isEnabled)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
        .background(AppPalette.background.color)
    }
}
