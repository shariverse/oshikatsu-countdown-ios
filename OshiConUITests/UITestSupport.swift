//
//  UITestSupport.swift
//  OshiConUITests
//

import XCTest

// UI テストで共通に使う操作。
//
// 遅い CI の Simulator（起動した直後は特に遅い）では、短いタッチ（`tap()`）が効かないことがある（#317）。
// 「ホーム」のタブを押しても、選択の印が動きかけて元のタブに戻る・スイッチを押しても切り替わらない、という形で起きた。
// 手元では負荷をかけても再現しないので、押した後に効いたことを確かめ、効いていなければ押し直す。

extension XCUIApplication {
    /// タブバーの `title` のタブを押し、選ばれるまで待つ。選ばれなければ押し直す（選ばれているタブは押さない。押すと、そのタブの画面がいちばん上に戻る）。
    @MainActor
    func selectTab(_ title: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = tabBars.firstMatch.buttons[title]
        XCTAssertTrue(button.waitForExistence(timeout: 5), title, file: file, line: line)
        for _ in 0..<3 where !button.isSelected {
            button.tap()
            _ = button.wait(for: \.isSelected, toEqual: true, timeout: 5)
        }
        XCTAssertTrue(button.isSelected, title, file: file, line: line)
    }
}

extension XCUIElement {
    /// Form の行のスイッチ（この要素は行ぜんたい）を押して、値を `expected`（"1" か "0"）にする。切り替わらなければ押し直す。
    /// 行のまん中（ラベルの文字）を押しても切り替わらないので、行の右端にあるスイッチのまん中（右端から 45pt ほど）を押す。
    /// 送った後の惰性が止まってから呼ぶ（動いている間に押すと、スクロールが止まるだけで切り替わらない）。
    @MainActor
    func setSwitch(to expected: String, file: StaticString = #filePath, line: UInt = #line) {
        let control = coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5)).withOffset(CGVector(dx: -45, dy: 0))
        for _ in 0..<3 where value as? String != expected {
            control.tap()
            let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", expected), object: self)
            _ = XCTWaiter().wait(for: [changed], timeout: 5)
        }
        XCTAssertEqual(value as? String, expected, identifier, file: file, line: line)
    }

    /// この要素の位置が動かなくなるまで待つ（送った後の惰性が止まるのを待つ）。位置を続けて 2 回読んで同じなら、止まったとみなす。
    @MainActor
    func waitUntilStill(timeout: TimeInterval = 5) {
        var last = frame
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
            let current = frame
            if current == last { return }
            last = current
        }
    }
}
