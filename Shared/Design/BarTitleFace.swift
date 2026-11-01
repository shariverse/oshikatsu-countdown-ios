//
//  BarTitleFace.swift
//  OshiCon
//

import SwiftUI

extension AppTheme.Typography {
    /// ナビゲーションバーのタイトルの形。
    nonisolated enum BarTitle: CaseIterable, Sendable {
        /// 大きいタイトル（推し・設定）。
        case large
        /// 小さいタイトル（inline。シート・ライセンス・初回の導線・iPad のサイドバー）。
        case inline

        /// 大きさの基準にするテキストスタイル（iOS の標準のタイトルと同じ）。
        var textStyle: Font.TextStyle {
            switch self {
            case .large:
                .largeTitle
            case .inline:
                .headline
            }
        }

        /// iOS の標準のタイトルの太さ。テーマの書体では `TextFaces.name(for:)` で丸める。
        var systemWeight: Font.Weight {
            switch self {
            case .large:
                .bold
            case .inline:
                .semibold
            }
        }
    }

    /// バーのタイトルの書体（PostScript 名と、ダイナミックタイプが標準のときの大きさ）。
    nonisolated struct BarTitleFace: Hashable, Sendable {
        let name: String
        let size: CGFloat
    }

    /// バーのタイトルの書体。日本語ではテーマの書体、ほかの言語は nil（システムの書体のまま。太さ・大きさを真似て上書きしない）。
    func barTitleFace(_ title: BarTitle, locale: Locale = .app) -> BarTitleFace? {
        guard AppFont.usesBundledTextFace(locale: locale) else {
            return nil
        }
        return BarTitleFace(name: textFaces.name(for: title.systemWeight), size: AppFont.defaultSize(of: title.textStyle))
    }
}
