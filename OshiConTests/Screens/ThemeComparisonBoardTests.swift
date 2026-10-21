//
//  ThemeComparisonBoardTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

@MainActor
struct ThemeComparisonBoardTests {
    @Test("比べる見本は、既定のテーマとすべての案を AppTheme.all の順に並べる")
    func showsAllThemes() {
        let board = ThemeComparisonBoard()
        #expect(board.themes.map(\.id) == AppTheme.all.map(\.id))
        #expect(board.themes.first == .standard)
    }

    @Test("比べる見本のホームには、先頭のカードと、これからの予定が行の数だけある")
    func showsFeaturedAndUpcoming() {
        let board = ThemeComparisonBoard(now: Date(timeIntervalSince1970: 1_792_540_800))
        #expect(board.content.featured != nil)
        #expect(board.content.upcoming.count >= ThemeComparisonBoard.upcomingRows)
    }
}
