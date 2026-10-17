//
//  OnboardingFlowView.swift
//  OshiCon
//

import SwiftUI

/// 初回の導線。推しの登録と最初の予定の 2 歩はタスク 13 で作る。今は導線を終えるボタンだけを置く。
struct OnboardingFlowView: View {
    /// 導線を終えた（「あとで」を含む）。
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("推し活カウントダウン")
                .font(AppFont.text(.title, weight: .bold))
            Button("はじめる", action: onFinish)
                .buttonStyle(.borderedProminent)
                .font(AppFont.text(.headline, weight: .bold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppPalette.background.color)
    }
}

#Preview {
    OnboardingFlowView {}
}
