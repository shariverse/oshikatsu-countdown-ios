//
//  OshiColorPicker.swift
//  OshiCon
//

import SwiftUI

/// 推し色を 12 色から 1 つ選ぶ、色の丸の並び。読み上げでは色の名前と、選んでいるかを伝える（ラジオボタンと同じ扱い）。
struct OshiColorPicker: View {
    @Binding var selection: OshiColor

    /// 丸の見た目の大きさ。押せる範囲は 44pt 以上にする。
    private let dotSize: CGFloat = 32
    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(OshiColor.allCases, id: \.self) { color in
                Button {
                    selection = color
                } label: {
                    dot(color, isSelected: color == selection)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(color.label)
                .accessibilityValue(position(of: color))
                .accessibilityAddTraits(color == selection ? [.isSelected] : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("推し色")
    }

    /// 読み上げで何個目かを伝える（iOS にはラジオボタンの trait が無いので、選択中の trait と合わせて伝える）。
    private func position(of color: OshiColor) -> String {
        let index = (OshiColor.allCases.firstIndex(of: color) ?? 0) + 1
        return "\(OshiColor.allCases.count) 個中 \(index) 個目"
    }

    private func dot(_ color: OshiColor, isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(color.fill)
                .frame(width: dotSize, height: dotSize)
            if isSelected {
                Circle()
                    .strokeBorder(color.textColor, lineWidth: 2)
                    .frame(width: dotSize + 8, height: dotSize + 8)
                Image(systemName: "checkmark")
                    .font(.system(size: dotSize * 0.45, weight: .bold))
                    .foregroundStyle(color.onFill)
            }
        }
    }
}

#Preview {
    @Previewable @State var selection = OshiColor.pink
    OshiColorPicker(selection: $selection)
        .padding()
}
