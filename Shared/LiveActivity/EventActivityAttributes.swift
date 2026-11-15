//
//  EventActivityAttributes.swift
//  OshiCon
//

import ActivityKit
import Foundation

/// 当日の開演までを数えるライブアクティビティの中身。アプリが作り、Widget Extension が描く。
///
/// 変わる中身は持たない。残りの時間は `Text(timerInterval:)` で端末が数え、開演を過ぎたことは
/// `staleDate`（開演の時刻）を過ぎて古くなったことで知る。通信もプッシュも使わない。
/// 文言はアプリの言語で作って入れる（予定の名前などと一緒に、作ったときの値のまま描く）。
nonisolated struct EventActivityAttributes: ActivityAttributes, Hashable {
    /// 変わる中身は無い。
    struct ContentState: Codable, Hashable, Sendable {}

    let eventID: UUID
    /// 推しの名前（推しなしの予定は種類）。
    let heading: String
    let title: String
    /// `OshiColor` の rawValue。
    let colorRawValue: String
    /// 開演（開始）の時刻。
    let startDate: Date
    /// カウントダウンを始める時刻（開演の 3 時間前）。`Text(timerInterval:)` の範囲の始まり。
    let countdownBegin: Date
    /// 残りの見出し（`開演まで`・`発売まで` など）。
    let untilText: String
    /// 開始の時刻（`開演 17:00` など）。
    let startText: String
    /// 開演を過ぎた後の文言（`今日は当日！`）。
    let startedText: String

    var color: OshiColor {
        OshiColor(rawValue: colorRawValue) ?? .black
    }

    /// 押したときに開く画面。
    var link: WidgetLink {
        .eventDetail(eventID)
    }
}
