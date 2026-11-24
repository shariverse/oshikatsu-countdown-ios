//
//  LockScreenNotificationCard.swift
//  OshiConTests
//

@testable import OshiCon
import SwiftUI

/// App Store 用スクリーンショットで、ロック画面に重ねる予定の通知（1 件）。iOS のロック画面の通知の見た目に寄せる
/// （左にアプリのアイコン、右に太字のタイトル・届いた時刻、その下にサブタイトルと本文）。
///
/// 文面は、アプリが実際に予約する通知と同じ `ReminderContent`（タイトルは予定名、サブタイトルは推しの名前、本文はタイミングと日付・時刻）。
/// 地のぼかしは重ねる側（screenshots.html）が描くので、ここでは半透明の地と文字だけを描く。出荷するアプリには入れない（テストのターゲットだけ）。
struct LockScreenNotificationCard: View {
    let content: ReminderContent
    let icon: UIImage
    /// 届いた時刻の表示（「今」・「now」など）。
    let time: String

    /// iOS のロック画面の通知の幅（6.9 inch の iPhone の画面の幅から左右の余白を除いた幅）。
    static let width: CGFloat = 410
    static let cornerRadius: CGFloat = 24

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(uiImage: icon)
                .resizable()
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline) {
                    Text(content.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(time)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Text(content.subtitle)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                Text(content.body)
                    .font(.system(size: 15))
                    .lineLimit(3)
            }
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(width: Self.width, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .fill(.white.opacity(0.16))
        )
        .environment(\.colorScheme, .dark)
    }
}
