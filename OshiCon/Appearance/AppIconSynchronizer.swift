//
//  AppIconSynchronizer.swift
//  OshiCon
//

import Observation
import os
import SwiftUI
import UIKit

/// ホーム画面のアプリアイコンを替える口。アプリでは `UIApplication`、メモリ上のストアと Unit テストでは覚えておくだけの代わりを使う。
protocol AppIconSwitching: AnyObject {
    /// 端末が代替アイコンを使えるか。
    var supportsAlternateIcons: Bool { get }
    /// 今のアイコンの名前。主アイコンなら nil。
    var alternateIconName: String? { get }
    /// `name` のアイコンに替える（nil は主アイコン）。
    func setAlternateIconName(_ name: String?) async throws
}

/// `UIApplication` でホーム画面のアイコンを替える。替えるたびに、システムが利用者に知らせる。
final class SystemAppIconSwitcher: AppIconSwitching {
    var supportsAlternateIcons: Bool {
        UIApplication.shared.supportsAlternateIcons
    }

    var alternateIconName: String? {
        UIApplication.shared.alternateIconName
    }

    func setAlternateIconName(_ name: String?) async throws {
        try await UIApplication.shared.setAlternateIconName(name)
    }
}

/// システムの API を呼ばず、替えたアイコンの名前を覚えておくだけの代わり（メモリ上のストア・Unit テスト・Preview）。
final class InMemoryAppIconSwitcher: AppIconSwitching {
    let supportsAlternateIcons: Bool
    private(set) var alternateIconName: String?

    init(supportsAlternateIcons: Bool = true, alternateIconName: String? = nil) {
        self.supportsAlternateIcons = supportsAlternateIcons
        self.alternateIconName = alternateIconName
    }

    func setAlternateIconName(_ name: String?) async throws {
        alternateIconName = name
    }
}

/// ホーム画面のアプリアイコンを、出したいアイコン（`AppIconRule.iconName(selected:isPlusUnlocked:)`）に合わせる。
///
/// - 今のアイコンと同じなら替えない（替えるたびにシステムが利用者に知らせるので、きっかけと回数を最小にする）
/// - 替えている間に出したいアイコンが変わったら、終わってからいちばん新しいものに 1 回だけ替える（色を続けて押しても、そのたびには替えない）
/// - 替えられなかったアイコンは、出したいアイコンが変わるまで替え直さない（前面に来るたびに試し続けない）
///
/// メモリ上のストア（UI テスト・スクリーンショット）ではシステムの API を呼ばない（`InMemoryAppIconSwitcher`）。
@Observable
final class AppIconSynchronizer {
    private static let logger = Logger(subsystem: "jp.shilokuma.OshiCon", category: "AppIconSynchronizer")

    /// ホーム画面に出ているアイコンの名前（主アイコンなら nil）。合わせるたびに読み直す（起動の途中では `UIApplication` を読まない）。
    private(set) var currentIconName: String?

    @ObservationIgnored private let switcher: any AppIconSwitching
    /// 替えている途中か。
    @ObservationIgnored private var isChanging = false
    /// 替えている間に頼まれた、いちばん新しい出したいアイコン。
    @ObservationIgnored private var pending: String??
    /// 替えられなかったアイコン。出したいアイコンが変わるまで替え直さない。
    @ObservationIgnored private var failed: String??

    init(switcher: any AppIconSwitching) {
        self.switcher = switcher
    }

    /// 起動するときの係。メモリ上のストアのときはシステムの API を呼ばない。
    static func forLaunch(usesInMemoryStore: Bool = LaunchOptions.usesInMemoryStore) -> AppIconSynchronizer {
        AppIconSynchronizer(switcher: usesInMemoryStore ? InMemoryAppIconSwitcher() : SystemAppIconSwitcher())
    }

    /// ホーム画面に出ているアイコンの色。知らない名前ならピンク（主アイコン）とする。
    var currentColor: OshiColor {
        AppIconRule.color(forAlternateIconName: currentIconName) ?? .defaultColor
    }

    /// ホーム画面のアイコンを `desired`（nil は主アイコン）に合わせる。替えている途中なら、終わってから合わせる。
    func synchronize(to desired: String?) async {
        if failed != nil, failed != .some(desired) {
            failed = nil
        }
        guard !isChanging else {
            pending = .some(desired)
            return
        }
        isChanging = true
        defer {
            isChanging = false
        }
        var target = desired
        while true {
            await change(to: target)
            guard let next = pending else {
                return
            }
            pending = nil
            target = next
        }
    }

    private func change(to desired: String?) async {
        let request = AppIconRule.request(
            desired: desired,
            current: switcher.alternateIconName,
            supportsAlternateIcons: switcher.supportsAlternateIcons
        )
        guard case let .change(name) = request, failed != .some(desired) else {
            currentIconName = switcher.alternateIconName
            return
        }
        do {
            try await switcher.setAlternateIconName(name)
        } catch {
            failed = .some(desired)
            Self.logger.error("アプリアイコンを替えられなかった（\(name ?? "AppIcon", privacy: .public)）: \(error.localizedDescription, privacy: .public)")
        }
        currentIconName = switcher.alternateIconName
    }
}

/// ホーム画面のアプリアイコンを、着せ替えで選んだ色と Plus の状態に合わせる。
///
/// アイコンを替えられるのはアプリが前面にあるときだけなので、前面にある間だけ合わせる。
/// 合わせるきっかけは、色を選んだとき・Plus が使えるようになった／使えなくなったとき・前面に来たとき（裏にいる間に期限が切れたとき）。
/// 今のアイコンと同じなら替えないので、前面に来るたびにシステムの知らせが出ることはない。
private struct AppIconSynchronization: ViewModifier {
    let synchronizer: AppIconSynchronizer
    let plus: PlusStore
    let appearance: AppearanceStore

    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        let desired = AppIconRule.iconName(selected: appearance.appIconColor, isPlusUnlocked: plus.isUnlocked)
        content
            .environment(synchronizer)
            .onChange(of: Trigger(desired: desired, isActive: scenePhase == .active), initial: true) { _, trigger in
                guard trigger.isActive else {
                    return
                }
                Task {
                    await synchronizer.synchronize(to: trigger.desired)
                }
            }
    }

    private struct Trigger: Equatable {
        let desired: String?
        let isActive: Bool
    }
}

extension View {
    /// ホーム画面のアプリアイコンを、着せ替えで選んだ色と Plus の状態に合わせる。画面は `@Environment(AppIconSynchronizer.self)` で今のアイコンを引く。
    func synchronizesAppIcon(_ synchronizer: AppIconSynchronizer, plus: PlusStore, appearance: AppearanceStore) -> some View {
        modifier(AppIconSynchronization(synchronizer: synchronizer, plus: plus, appearance: appearance))
    }
}
