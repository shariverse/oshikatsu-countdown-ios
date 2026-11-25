//
//  AppearancePreviewSwitcher.swift
//  OshiCon
//

import SwiftUI

/// 見本の切り替え（ホーム・予定の詳細・シェア）。着せ替えの画面の見本の下と、全画面の試着の下のバーに置く。
///
/// 選んでいる見本はアクセントの塗りで示し、読み上げでは選んでいるかを伝える。
/// 幅が足りないときに記号だけで出せるよう、文字と記号を選べる（置く側が `ViewThatFits` で切り替える）。
struct AppearancePreviewSwitcher: View {
    /// 中身の出し方。
    enum Content {
        /// 名前（`ホーム`・`予定の詳細`・`シェア`）。
        case titles
        /// 記号（SF Symbols）。名前は読み上げと、長押しの大きな表示に残す。
        case symbols
    }

    @Binding var selection: AppearancePreview.Kind
    var content: Content = .titles
    /// 切り替えの地（カードの地の色と細い線）を描くか。全画面の試着ではバーの地の上に置くので描かない。
    var showsTrack = true
    /// UI テストで選択肢を探す identifier の頭（`<頭>.home` など）。全画面の試着は、下に残る着せ替えの画面の切り替えと分ける。
    var identifierPrefix = "appearance.previewKind"

    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 1 つの選択肢の高さ（pt）。上下の余白と合わせて、押せる高さを 44pt にする。
    private static let segmentHeight: CGFloat = 38
    private static let trackPadding: CGFloat = 3

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppearancePreview.Kind.allCases) { kind in
                segment(kind)
            }
        }
        .padding(Self.trackPadding)
        .background {
            if showsTrack {
                Capsule()
                    .fill(theme.palette.surface.color)
                Capsule()
                    .strokeBorder(theme.palette.outlineVariant.color)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("見本の切り替え")
    }

    private func segment(_ kind: AppearancePreview.Kind) -> some View {
        let isSelected = selection == kind
        return Button {
            withAnimation(reduceMotion ? nil : .snappy) {
                selection = kind
            }
        } label: {
            Group {
                switch content {
                case .titles:
                    Text(verbatim: kind.title())
                        .lineLimit(1)
                case .symbols:
                    Image(systemName: kind.systemImage)
                }
            }
            .font(theme.typography.text(.footnote, weight: isSelected ? .bold : .regular))
            .foregroundStyle((isSelected ? theme.palette.onBrand : theme.palette.onSurfaceVariant).color)
            .padding(.horizontal, 14)
            .frame(minWidth: 44, minHeight: Self.segmentHeight)
            .background {
                if isSelected {
                    Capsule()
                        .fill(theme.palette.brand.color)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: kind.title()))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("\(identifierPrefix).\(kind.rawValue)")
        .accessibilityShowsLargeContentViewer {
            Label {
                Text(verbatim: kind.title())
            } icon: {
                Image(systemName: kind.systemImage)
            }
        }
    }
}

#Preview("切り替え") {
    @Previewable @State var selection = AppearancePreview.Kind.home
    VStack(spacing: 16) {
        AppearancePreviewSwitcher(selection: $selection)
        AppearancePreviewSwitcher(selection: $selection, content: .symbols)
        AppearancePreviewSwitcher(selection: $selection, showsTrack: false)
            .padding(6)
            .background(.ultraThinMaterial, in: Capsule())
    }
    .padding()
}
