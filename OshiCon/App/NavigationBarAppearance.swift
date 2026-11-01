//
//  NavigationBarAppearance.swift
//  OshiCon
//

import UIKit

/// ナビゲーションバーのタイトルの書体を、テーマの書体にそろえる（Discussion #148 の Q2）。
///
/// アプリの起動時に 1 回、バーができる前に呼ぶ。`UINavigationBar` の外観の `titleTextAttributes`・`largeTitleTextAttributes` の
/// `.font` だけを替え、地・影・Liquid Glass・スクロールの端の効果（`standardAppearance` などの外観のオブジェクト）には触れない。
/// 日本語以外の言語では何もしない（システムの書体のまま）。
enum NavigationBarAppearance {
    /// `bar` のタイトルの書体を替える。既定は全部のバーに効く外観のプロキシ。
    static func applyTitleFonts(
        to bar: UINavigationBar = .appearance(),
        typography: AppTheme.Typography = AppTheme.shipping.typography,
        locale: Locale = .app
    ) {
        if let font = titleFont(.large, typography: typography, locale: locale) {
            bar.largeTitleTextAttributes = (bar.largeTitleTextAttributes ?? [:]).merging([.font: font]) { $1 }
        }
        if let font = titleFont(.inline, typography: typography, locale: locale) {
            bar.titleTextAttributes = (bar.titleTextAttributes ?? [:]).merging([.font: font]) { $1 }
        }
    }

    /// バーのタイトルの書体。日本語以外の言語、または書体を読み込めないときは nil（システムの書体のまま）。
    ///
    /// 大きさは iOS の標準のタイトルにそろえる。大きいタイトルはダイナミックタイプの文字の大きさ（`traits`。既定は今の設定）に合わせて大きくし、
    /// inline は文字の大きさに関わらず 17pt のままにする（標準の inline タイトルも大きくならず、高さの決まったバーの中で大きくすると切れるため。Issue #158）
    static func titleFont(
        _ title: AppTheme.Typography.BarTitle,
        typography: AppTheme.Typography,
        locale: Locale,
        traits: UITraitCollection? = nil
    ) -> UIFont? {
        guard let face = typography.barTitleFace(title, locale: locale), let font = UIFont(name: face.name, size: face.size) else {
            return nil
        }
        switch title {
        case .large:
            return UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font, compatibleWith: traits)
        case .inline:
            return font
        }
    }
}
