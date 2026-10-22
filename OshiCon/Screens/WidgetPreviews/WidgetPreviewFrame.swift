//
//  WidgetPreviewFrame.swift
//  OshiCon
//

import SwiftUI

/// アプリの中でウィジェットの中身を、ホーム画面のウィジェットと同じ大きさ・余白・地で描く枠（Preview・見本の撮影で使う）。
/// アプリでは `containerBackground(for: .widget)` が描かれないので、地はこの枠が描く。
struct WidgetPreviewFrame<Content: View>: View {
    /// ウィジェットの大きさ。HIG の Widgets のサイズの表の、幅 430pt の iPhone の値（2×2 は 170×170、4×2 は 364×170）。
    /// iPhone 17（幅 402pt）の実際の大きさとはわずかに違うが、テーマの見比べには十分なので 1 つに固定する。
    enum Family {
        case systemSmall
        case systemMedium

        var size: CGSize {
            switch self {
            case .systemSmall:
                CGSize(width: 170, height: 170)
            case .systemMedium:
                CGSize(width: 364, height: 170)
            }
        }
    }

    /// ウィジェットの中身の余白（システムの既定の余白）。
    static var contentMargin: CGFloat {
        16
    }

    /// ウィジェットの角の丸み。
    static var cornerRadius: CGFloat {
        22
    }

    let family: Family
    let background: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(Self.contentMargin)
            .frame(width: family.size.width, height: family.size.height)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }
}

/// ウィジェット 2 種を、枠に入れてテーマを当てて描く。
enum WidgetPreview {
    /// カウントダウンウィジェット（2×2）。
    static func countdown(_ content: CountdownWidgetContent, theme: AppTheme = .shipping) -> some View {
        WidgetPreviewFrame(family: .systemSmall, background: CountdownWidgetView.containerColor(for: content, in: theme).color) {
            CountdownWidgetView(content: content)
        }
        .environment(\.appTheme, theme)
    }

    /// 推しカウントウィジェット（4×2）。
    static func upcoming(_ content: UpcomingWidgetContent, theme: AppTheme = .shipping) -> some View {
        WidgetPreviewFrame(family: .systemMedium, background: UpcomingWidgetView.containerColor(in: theme).color) {
            UpcomingWidgetView(content: content)
        }
        .environment(\.appTheme, theme)
    }
}

#Preview("カウントダウン") {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            WidgetPreview.countdown(.sample)
            WidgetPreview.countdown(.notSelected)
        }
        HStack(spacing: 16) {
            WidgetPreview.countdown(.missing)
            WidgetPreview.countdown(.unavailable)
        }
    }
    .padding()
}

#Preview("推しカウント") {
    VStack(spacing: 16) {
        WidgetPreview.upcoming(.sample)
        WidgetPreview.upcoming(.rows([]))
        WidgetPreview.upcoming(.unavailable)
    }
    .padding()
}
