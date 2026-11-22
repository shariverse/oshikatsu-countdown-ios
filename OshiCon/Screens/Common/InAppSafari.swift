//
//  InAppSafari.swift
//  OshiCon
//

import SafariServices
import SwiftUI

extension View {
    /// この中の `Link`（と `openURL`）で開く Web のページを、Safari アプリに移らず、アプリの中の Safari の画面（`SFSafariViewController`）で開く。
    ///
    /// - ページを読み込むのは Safari（アプリとは別のプロセス）で、アプリは通信の中身や閲覧の情報に触れない。
    ///   アプリが読み込みを受け持つ `WKWebView` は使わない（通信しない方針。プライバシーポリシーの「通信について」）
    /// - http・https 以外の URL（設定アプリなど）は、これまでどおりシステムに渡す
    func opensWebLinksInApp() -> some View {
        modifier(InAppSafariModifier())
    }
}

/// アプリの中の Safari の画面で開くページ。
nonisolated struct InAppSafariPage {
    let url: URL

    /// `SFSafariViewController` は http・https だけを開ける（ほかを渡すと例外で落ちる）ので、それ以外では作らない。
    init?(url: URL) {
        guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            return nil
        }
        self.url = url
    }
}

private struct InAppSafariModifier: ViewModifier {
    @State private var presenter = InAppSafariPresenter()

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                guard let page = InAppSafariPage(url: url), presenter.present(page) else {
                    return .systemAction
                }
                return .handled
            })
            .background(InAppSafariAnchor(presenter: presenter))
    }
}

/// `SFSafariViewController` を UIKit のモーダルで出す。
///
/// SwiftUI の `.sheet` に入れると、Safari の閉じるボタン（iOS 26 は「閉じる」、それより前は「完了」）で Safari 自身が閉じたあとに SwiftUI もシートを閉じようとして、
/// 下にあるシート（課金画面）まで閉じてしまう。Apple の想定どおり UIKit で出し、閉じるのは Safari に任せる。
private final class InAppSafariPresenter {
    /// この画面の中に置いた UIViewController。ここから出すと、シートの上でもその上に重なる。
    weak var anchor: UIViewController?

    /// 出せたら true。画面に載っていない・ほかのものを出している間は false（呼ぶ側がシステムに渡す）。
    func present(_ page: InAppSafariPage) -> Bool {
        guard let anchor, anchor.viewIfLoaded?.window != nil, anchor.presentedViewController == nil else {
            return false
        }
        anchor.present(SFSafariViewController(url: page.url), animated: true)
        return true
    }
}

/// `InAppSafariPresenter` が出すときの起点になる、見えない UIViewController。
private struct InAppSafariAnchor: UIViewControllerRepresentable {
    let presenter: InAppSafariPresenter

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.isUserInteractionEnabled = false
        presenter.anchor = controller
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        presenter.anchor = controller
    }
}
