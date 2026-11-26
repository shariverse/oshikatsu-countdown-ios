//
//  ShareCardPreviewScreen.swift
//  OshiCon
//

import SwiftUI

/// シェアのプレビュー（予定の詳細のツールバーから開くシート）。書き出す画像そのものを見本に出し、載せる項目（会場・推しの写真）を切り替えてから、
/// `ShareLink` で正方形の PNG の画像だけを渡す（文やリンクは添えない）。画像は端末の中で作り、通信しない。
/// 会場は既定で載せず、会場の無い予定では切り替えを出さない。写真は既定で載せ、写真の無い推し・推しなしの予定では切り替えを出さない。
struct ShareCardPreviewScreen: View {
    let event: OshiEvent
    let oshi: Oshi?
    /// カードの見た目の差し替え口（Plus の着せ替えは、ここに推しの写真の地を渡す）。
    var style: ShareCardStyle = .shipping
    var photos = OshiPhotoLibrary.shared
    /// 地の画像（`style` の `.photo`）の置き場所。nil なら `photos`。着せ替えの背景の写真は `AppearanceStore.photos` を渡す。
    var backgroundPhotos: OshiPhotoLibrary?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var options = ShareCardContent.Options()
    /// 最後に書き出した画像と、そのときの中身。書き出せなかったときは `image` が nil。
    @State private var rendered: Rendered?

    /// 横向きの iPhone（縦が狭い）では、見本で画面が埋まらないよう小さくする。
    private static let compactPreviewLength: CGFloat = 220

    private struct Rendered {
        let content: ShareCardContent
        let image: ShareCardImage?
    }

    /// 端末のタイムゾーンを変えたときも、その日付で数える。
    private func makeContent(now: Date) -> ShareCardContent {
        ShareCardContent(event: event, oshi: oshi, now: now, calendar: .autoupdatingCurrent, options: options)
    }

    var body: some View {
        // 開いたまま日付が変わっても書き出し直せるよう、ホームと同じく 1 分ごと（分の変わり目）に今日を確かめる。
        // 中身は日の単位なので、同じ日のうちは変わらず、書き出し直さない
        TimelineView(.everyMinute) { context in
            let content = makeContent(now: context.date)
            screen(content: content)
                // 切り替えや日付が変わったら書き出し直す（写真は読み込み終えてから描く）
                .task(id: content) {
                    let images = await ShareCardImages.load(
                        content: content,
                        style: style,
                        photos: photos,
                        backgroundPhotos: backgroundPhotos
                    )
                    guard !Task.isCancelled else {
                        return
                    }
                    rendered = Rendered(content: content, image: ShareCardRenderer.render(content, style: style, images: images))
                }
        }
    }

    private func screen(content: ShareCardContent) -> some View {
        NavigationStack {
            Form {
                Section {
                    preview(content: content)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                if content.canIncludeVenue || content.canIncludePhoto {
                    Section {
                        if content.canIncludeVenue {
                            Toggle("会場を載せる", isOn: $options.includesVenue)
                                .accessibilityIdentifier("shareCard.includesVenue")
                        }
                        if content.canIncludePhoto {
                            Toggle("推しの写真を載せる", isOn: $options.includesPhoto)
                                .accessibilityIdentifier("shareCard.includesPhoto")
                        }
                    } header: {
                        Text("載せる項目")
                    } footer: {
                        if content.canIncludePhoto {
                            Text("写真を載せないときは、推し色の模様にします")
                        }
                    }
                    .themeRowBackground()
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.palette.background.color)
            .navigationTitle("画像でシェア")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                shareButton(content: content)
            }
        }
        .font(theme.typography.text(.body))
        .tint(theme.palette.brand.color)
    }

    // MARK: 見本

    /// 書き出した画像をそのまま縮めて見せる（共有する画像と同じ見た目）。
    private func preview(content: ShareCardContent) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: verticalSizeClass == .compact ? Self.compactPreviewLength : ShareCardSize.points)
            .overlay {
                if let rendered, let image = rendered.image {
                    Image(decorative: image.cgImage, scale: ShareCardSize.scale)
                        .resizable()
                        .scaledToFit()
                } else if rendered != nil {
                    Text("画像を作れませんでした")
                        .font(theme.typography.text(.footnote))
                        .foregroundStyle(theme.palette.onSurfaceVariant.color)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ProgressView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.shape.section))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(content.accessibilityLabel)
            .accessibilityAddTraits(.isImage)
            .accessibilityIdentifier("shareCard.preview")
    }

    // MARK: シェア

    /// 共有シートを開くボタン。今の中身で書き出し終えるまでは押せない。
    private func shareButton(content: ShareCardContent) -> some View {
        Group {
            if let rendered, rendered.content == content, let image = rendered.image {
                ShareLink(
                    item: image,
                    preview: SharePreview(content.title, image: Image(decorative: image.cgImage, scale: ShareCardSize.scale))
                ) {
                    shareLabel
                }
            } else {
                Button {} label: {
                    shareLabel
                }
                .disabled(true)
            }
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("shareCard.share")
        .padding(.horizontal)
        .padding(.vertical, 12)
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
        .background(theme.palette.background.color)
    }

    private var shareLabel: some View {
        Label("シェアする", systemImage: "square.and.arrow.up")
            .font(theme.typography.text(.headline, weight: .bold))
            .frame(maxWidth: .infinity, minHeight: 32)
    }
}

#Preview("写真なし・会場あり") {
    let calendar = Calendar.autoupdatingCurrent
    let oshi = Oshi(name: "LUMINA", color: .pink)
    ShareCardPreviewScreen(
        event: OshiEvent(
            oshiID: oshi.id,
            kind: .live,
            title: "5th LIVE 東京公演",
            day: CalendarDay(calendar.date(byAdding: .day, value: 12, to: .now) ?? .now, calendar: calendar),
            startTime: TimeOfDay(hour: 18, minute: 0),
            venue: "東京ドーム",
            createdAt: .now
        ),
        oshi: oshi
    )
}
