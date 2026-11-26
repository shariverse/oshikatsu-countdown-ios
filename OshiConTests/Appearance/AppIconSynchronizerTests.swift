//
//  AppIconSynchronizerTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import Testing

/// ホーム画面のアプリアイコンを合わせる係（`AppIconSynchronizer`）。替えるたびにシステムが知らせるので、替える回数を確かめる。
@MainActor
struct AppIconSynchronizerTests {
    @Test("今のアイコンと同じなら替えない（前面に来るたびに知らせが出ない）")
    func keepsSameIcon() async {
        let switcher = RecordingAppIconSwitcher(current: "AppIcon-Mint")
        let synchronizer = AppIconSynchronizer(switcher: switcher)
        await synchronizer.synchronize(to: "AppIcon-Mint")
        await synchronizer.synchronize(to: "AppIcon-Mint")
        #expect(switcher.requests.isEmpty)
        #expect(synchronizer.currentIconName == "AppIcon-Mint")
        #expect(synchronizer.currentColor == .mint)
    }

    @Test("違うアイコンなら 1 回だけ替える。Plus でなくなったら主アイコンに戻し、また Plus になったら選んだ色に戻す")
    func changesOnce() async {
        let switcher = RecordingAppIconSwitcher(current: nil)
        let synchronizer = AppIconSynchronizer(switcher: switcher)
        // Plus でミントを選ぶ
        await synchronizer.synchronize(to: AppIconRule.iconName(selected: .mint, isPlusUnlocked: true))
        #expect(switcher.requests == ["AppIcon-Mint"])
        #expect(synchronizer.currentColor == .mint)
        // 解約・期限切れ: 主アイコン（ピンク）に戻す。選んだ色は設定に残る
        await synchronizer.synchronize(to: AppIconRule.iconName(selected: .mint, isPlusUnlocked: false))
        #expect(switcher.requests == ["AppIcon-Mint", nil])
        #expect(synchronizer.currentColor == .pink)
        // また Plus になったら戻す
        await synchronizer.synchronize(to: AppIconRule.iconName(selected: .mint, isPlusUnlocked: true))
        #expect(switcher.requests == ["AppIcon-Mint", nil, "AppIcon-Mint"])
    }

    @Test("Plus でなければ、色を選んでもホーム画面のアイコンを替えない")
    func lockedDoesNotChange() async {
        let switcher = RecordingAppIconSwitcher(current: nil)
        let synchronizer = AppIconSynchronizer(switcher: switcher)
        for color in OshiColor.allCases {
            await synchronizer.synchronize(to: AppIconRule.iconName(selected: color, isPlusUnlocked: false))
        }
        #expect(switcher.requests.isEmpty)
    }

    @Test("替えている間に色を続けて選んだら、終わってからいちばん新しい色に 1 回だけ替える")
    func coalescesWhileChanging() async {
        let switcher = RecordingAppIconSwitcher(current: nil)
        switcher.suspendsNextChange()
        let synchronizer = AppIconSynchronizer(switcher: switcher)
        let first = Task {
            await synchronizer.synchronize(to: "AppIcon-Red")
        }
        await switcher.waitUntilSuspended()
        await synchronizer.synchronize(to: "AppIcon-Blue")
        await synchronizer.synchronize(to: "AppIcon-Navy")
        await synchronizer.synchronize(to: "AppIcon-Purple")
        switcher.resume()
        await first.value
        #expect(switcher.requests == ["AppIcon-Red", "AppIcon-Purple"])
        #expect(synchronizer.currentIconName == "AppIcon-Purple")
    }

    @Test("替えている間に元の色に戻したら、終わってから元の色に戻す")
    func returnsWhileChanging() async {
        let switcher = RecordingAppIconSwitcher(current: nil)
        switcher.suspendsNextChange()
        let synchronizer = AppIconSynchronizer(switcher: switcher)
        let first = Task {
            await synchronizer.synchronize(to: "AppIcon-Red")
        }
        await switcher.waitUntilSuspended()
        await synchronizer.synchronize(to: nil)
        switcher.resume()
        await first.value
        #expect(switcher.requests == ["AppIcon-Red", nil])
        #expect(synchronizer.currentIconName == nil)
    }

    @Test("替えられなかったアイコンは、出したいアイコンが変わるまで替え直さない")
    func doesNotRetryFailure() async {
        let switcher = RecordingAppIconSwitcher(current: nil)
        switcher.failingNames = ["AppIcon-Red"]
        let synchronizer = AppIconSynchronizer(switcher: switcher)
        await synchronizer.synchronize(to: "AppIcon-Red")
        await synchronizer.synchronize(to: "AppIcon-Red")
        #expect(switcher.requests == ["AppIcon-Red"])
        #expect(synchronizer.currentIconName == nil)
        // ほかの色を選んだら替え、その後はまた試す
        await synchronizer.synchronize(to: "AppIcon-Blue")
        switcher.failingNames = []
        await synchronizer.synchronize(to: "AppIcon-Red")
        #expect(switcher.requests == ["AppIcon-Red", "AppIcon-Blue", "AppIcon-Red"])
        #expect(synchronizer.currentIconName == "AppIcon-Red")
    }

    @Test("端末が代替アイコンを使えなければ替えない")
    func unsupported() async {
        let switcher = RecordingAppIconSwitcher(current: nil, supportsAlternateIcons: false)
        let synchronizer = AppIconSynchronizer(switcher: switcher)
        await synchronizer.synchronize(to: "AppIcon-Mint")
        #expect(switcher.requests.isEmpty)
    }

    @Test("メモリ上のストアのときは、システムの API を呼ばない代わりで替えたことにする")
    func inMemory() async {
        let synchronizer = AppIconSynchronizer.forLaunch(usesInMemoryStore: true)
        #expect(synchronizer.currentColor == .pink)
        await synchronizer.synchronize(to: "AppIcon-Navy")
        #expect(synchronizer.currentColor == .navy)
    }
}

/// 頼まれたアイコンを覚えておく代わり。替えるところで止めたり、失敗させたりできる。
@MainActor
private final class RecordingAppIconSwitcher: AppIconSwitching {
    private struct ChangeFailed: Error {}

    let supportsAlternateIcons: Bool
    private(set) var alternateIconName: String?
    /// 頼まれた順のアイコンの名前（nil は主アイコン）。
    private(set) var requests: [String?] = []
    /// 失敗させるアイコンの名前。
    var failingNames: Set<String> = []

    private var suspendsNext = false
    private var suspended: CheckedContinuation<Void, Never>?
    private var onSuspended: CheckedContinuation<Void, Never>?

    init(current: String?, supportsAlternateIcons: Bool = true) {
        alternateIconName = current
        self.supportsAlternateIcons = supportsAlternateIcons
    }

    /// 次に替えるところで、`resume()` まで止める。
    func suspendsNextChange() {
        suspendsNext = true
    }

    /// 替えるところで止まるまで待つ。
    func waitUntilSuspended() async {
        guard suspended == nil else {
            return
        }
        await withCheckedContinuation { onSuspended = $0 }
    }

    func resume() {
        suspended?.resume()
        suspended = nil
    }

    func setAlternateIconName(_ name: String?) async throws {
        requests.append(name)
        if suspendsNext {
            suspendsNext = false
            await withCheckedContinuation { continuation in
                suspended = continuation
                onSuspended?.resume()
                onSuspended = nil
            }
        }
        if let name, failingNames.contains(name) {
            throw ChangeFailed()
        }
        alternateIconName = name
    }
}
