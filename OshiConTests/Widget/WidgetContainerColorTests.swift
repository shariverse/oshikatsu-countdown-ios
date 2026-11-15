//
//  WidgetContainerColorTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

struct WidgetContainerColorTests {
    @Test("カウントダウンの地は、予定のときは推し色の塗り、ほかはテーマのカードの地", arguments: [AppTheme.shipping])
    func countdownContainerColor(theme: AppTheme) throws {
        guard case let .event(event) = CountdownWidgetContent.sample else {
            Issue.record("見本は予定")
            return
        }
        #expect(CountdownWidgetView.containerColor(for: .sample, in: theme) == AdaptiveColor(light: event.color.rgb, dark: event.color.rgb))
        for content in [CountdownWidgetContent.notSelected, .missing, .unavailable] {
            #expect(CountdownWidgetView.containerColor(for: content, in: theme) == theme.palette.surface)
        }
    }

    @Test("推しカウントの地は、テーマの入力欄の地", arguments: [AppTheme.shipping])
    func upcomingContainerColor(theme: AppTheme) {
        #expect(UpcomingWidgetView.containerColor(in: theme) == theme.palette.surfaceContainer)
    }
}
