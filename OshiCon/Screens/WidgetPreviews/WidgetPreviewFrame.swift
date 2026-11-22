//
//  WidgetPreviewFrame.swift
//  OshiCon
//

import SwiftUI
import WidgetKit

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
    /// 中身に余白を付けるか。`contentMarginsDisabled()` のウィジェット（推しの写真）は、余白を中身が付けるので false。
    var padsContent = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padsContent ? Self.contentMargin : 0)
            .frame(width: family.size.width, height: family.size.height)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }
}

/// ウィジェット 3 種を、枠に入れてテーマを当てて描く。
enum WidgetPreview {
    /// 推しの写真ウィジェット（2×2・4×2）。`renderingMode` に `.accented` を渡すと tinted の描き方に寄せる
    /// （アプリでは地が外されないので、暗い地の上に白で描く）。
    static func photo(
        _ content: PhotoWidgetContent,
        family: PhotoWidgetView.Family,
        photo: CGImage? = nil,
        renderingMode: WidgetRenderingMode = .fullColor,
        theme: AppTheme = .shipping
    ) -> some View {
        let isFullColor = renderingMode == .fullColor
        let frameFamily: WidgetPreviewFrame<PhotoWidgetView>.Family = family == .systemSmall ? .systemSmall : .systemMedium
        let background = isFullColor ? PhotoWidgetView.containerColor(for: content, in: theme).color : Color(white: 0.15)
        return WidgetPreviewFrame(family: frameFamily, background: background, padsContent: false) {
            PhotoWidgetView(content: content, family: family, photo: photo, renderingMode: renderingMode)
        }
        .environment(\.appTheme, theme)
    }

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

    /// カウントダウンウィジェットのロック画面の形。端末が単色で描く見た目に寄せて、暗い壁紙の上に白で描く。
    /// 丸の地（`AccessoryWidgetBackground`）はアプリでは描かれないので、半透明の丸で代わりに描く。
    static func countdownLockScreen(
        _ content: CountdownWidgetContent,
        family: CountdownAccessoryView.Family,
        theme: AppTheme = .shipping
    ) -> some View {
        CountdownAccessoryView(content: content, family: family)
            .frame(width: lockScreenSize(family).width, height: lockScreenSize(family).height)
            .background {
                if family == .circular {
                    Circle().fill(.white.opacity(0.18))
                }
            }
            .foregroundStyle(.white)
            .environment(\.appTheme, theme)
            .environment(\.colorScheme, .dark)
    }

    /// ロック画面の形の大きさ。HIG の Widgets のサイズの表の、幅 430pt の iPhone の値。
    private static func lockScreenSize(_ family: CountdownAccessoryView.Family) -> CGSize {
        switch family {
        case .circular:
            CGSize(width: 76, height: 76)
        case .rectangular:
            CGSize(width: 172, height: 76)
        case .inline:
            CGSize(width: 257, height: 26)
        }
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

/// 推しの写真の代わりの画像（Preview）。
@MainActor private var previewPhoto: CGImage? {
    ImageRenderer(
        content: LinearGradient(colors: [.white, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(Image(systemName: "person.fill").font(.system(size: 140)).foregroundStyle(.white.opacity(0.8)))
            .frame(width: 340, height: 340)
    ).cgImage
}

#Preview("推しの写真") {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            WidgetPreview.photo(.sample, family: .systemSmall, photo: previewPhoto)
            WidgetPreview.photo(.sample, family: .systemSmall)
        }
        WidgetPreview.photo(.sample, family: .systemMedium, photo: previewPhoto)
        WidgetPreview.photo(.sample, family: .systemMedium)
    }
    .padding()
}

#Preview("推しの写真（Plus でない・tinted）") {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            WidgetPreview.photo(.sample(isPlusUnlocked: false), family: .systemSmall, photo: previewPhoto)
            WidgetPreview.photo(.sample, family: .systemSmall, photo: previewPhoto, renderingMode: .accented)
        }
        WidgetPreview.photo(.sample(isPlusUnlocked: false), family: .systemMedium, photo: previewPhoto)
        WidgetPreview.photo(.sample, family: .systemMedium, photo: previewPhoto, renderingMode: .accented)
    }
    .padding()
}

#Preview("推しの写真（予定なし）") {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            WidgetPreview.photo(.notSelected, family: .systemSmall)
            WidgetPreview.photo(.missing, family: .systemSmall)
        }
        WidgetPreview.photo(.unavailable, family: .systemMedium)
    }
    .padding()
}

#Preview("ロック画面") {
    VStack(spacing: 20) {
        ForEach(Array([CountdownWidgetContent.sample, .notSelected].enumerated()), id: \.offset) { _, content in
            HStack(spacing: 16) {
                WidgetPreview.countdownLockScreen(content, family: .circular)
                WidgetPreview.countdownLockScreen(content, family: .rectangular)
            }
            WidgetPreview.countdownLockScreen(content, family: .inline)
        }
    }
    .padding(24)
    .background(LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom))
}
