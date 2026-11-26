//
//  AppearanceTryOnScreen.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// 全画面の試着。着せ替えの画面の「全画面」から開き、見本（ホーム・予定の詳細・シェアのカード）を画面いっぱいに出す。
///
/// - 上に「閉じる」と「試着中」、下に見本の切り替えと、Plus でない人には「Plus で使う」
/// - 長押ししている間は、着せ替える前（標準）の見た目を出して比べられる。読み上げでは、見本の操作「着せ替える前と比べる」で切り替える
/// - 見本は押せない（中の予定や絞り込みは反応しない）。読み上げでは 1 つの要素にする
///
/// 見本は、実際の画面と同じく画面の大きさと文字の大きさのまま組む（縮めない）。シェアのカードは、書き出す大きさより大きくしない。
struct AppearanceTryOnScreen: View {
    /// 登録した推し（推しの並び）。見本の推しと飾りに使う。
    let oshis: [Oshi]
    /// 着せ替えの画面の「背景」で選んでいる推し（共通なら nil）。着せ替えの画面の見本と同じく、ホームの見本をその推しで絞り込む。
    var backgroundOshiID: Oshi.ID?
    /// 映している見本。着せ替えの画面と同じものを切り替える。
    @Binding var kind: AppearancePreview.Kind
    /// 「Plus で使う」を押したとき。全画面を閉じてから課金画面を開くのは、開く側が受け持つ。
    let onOpenPaywall: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceStore.self) private var store
    @Environment(\.isPlusUnlocked) private var isPlusUnlocked
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var storedEvents: [StoredEvent]
    /// 見本を長押ししている間は true。
    @GestureState private var isPressing = false
    /// 読み上げの操作「着せ替える前と比べる」で切り替えた、着せ替える前の見た目。
    @State private var isComparingByAction = false

    /// 上のバー（「閉じる」と「試着中」）の高さ（pt）。ホームの見本の中身は、この下から並べる。
    private static let topBarHeight: CGFloat = 44
    /// 見本の上下に重ねるバーの、画面の端からの余白（pt）。
    private static let barPadding: CGFloat = 16
    /// シェアのカードの上下に空ける高さ（pt）。上のバーと下のバーに重ねない。
    private static let shareVerticalMargin: CGFloat = 150

    /// 着せ替える前（標準）の見た目を出しているか。
    private var isComparing: Bool {
        isPressing || isComparingByAction
    }

    var body: some View {
        GeometryReader { proxy in
            // 見本は安全領域の外まで画面いっぱいに出す。安全領域の幅は、外へ広げる前のここで測る（広げた後は 0 になる）
            let insets = proxy.safeAreaInsets
            let size = CGSize(
                width: proxy.size.width + insets.leading + insets.trailing,
                height: proxy.size.height + insets.top + insets.bottom
            )
            // 開いたまま日付が変わっても数え直せるよう、ホームと同じく 1 分ごと（分の変わり目）に今日を確かめる
            TimelineView(.everyMinute) { context in
                preview(size: size, insets: insets, now: context.date)
            }
            .ignoresSafeArea()
        }
        .overlay(alignment: .top) {
            topBar
        }
        .overlay(alignment: .bottom) {
            bottomBar
        }
        .background {
            theme.palette.background.color
                .ignoresSafeArea()
        }
        .font(theme.typography.text(.body))
        .tint(theme.palette.brand.color)
    }

    // MARK: - 見本

    private func preview(size: CGSize, insets: EdgeInsets, now: Date) -> some View {
        let content = AppearancePreview.content(
            events: storedEvents.compactMap(OshiConStore.event(from:)),
            oshis: oshis,
            selectedOshiID: backgroundOshiID,
            // 端末のタイムゾーンを変えたときも、その日付で数える
            today: CalendarDay(now, calendar: .autoupdatingCurrent),
            now: now
        )
        return ZStack {
            screen(content: content, size: size, insets: insets, now: now)
                .frame(width: size.width, height: size.height)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isComparing)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            // 見本は押せないので、その上に長押しを受ける透明な面を重ねる。読み上げと UI テストには、この面を見本として見せる
            Color.clear
                .contentShape(Rectangle())
                .gesture(compareGesture)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: kind.accessibilityLabel()))
                .accessibilityValue(
                    Text(verbatim: AppearancePreview.tryOnAccessibilityValue(
                        of: store.settings,
                        kind: kind,
                        content: content,
                        isComparing: isComparing
                    ))
                )
                .accessibilityAction(named: Text("着せ替える前と比べる")) {
                    isComparingByAction.toggle()
                }
                .accessibilityIdentifier("appearance.tryOn.preview")
        }
    }

    /// 映している見本（`kind`）の画面。長押ししている間は、着せ替える前（標準）の見た目で描く。
    /// どの背景の写真（共通・推しごと）を映すかは、実際の画面と同じ規則で見本ごとに決める。
    @ViewBuilder
    private func screen(content: HomeContent, size: CGSize, insets: EdgeInsets, now: Date) -> some View {
        let rendering = AppearancePreview.rendering(settings: store.settings, kind: kind, content: content, isComparing: isComparing)
        let horizontalInset = max(insets.leading, insets.trailing)
        switch kind {
        case .home:
            AppearanceHomePreview(
                rendering: rendering,
                content: content,
                decorationOshis: oshis,
                photos: store.photos,
                topInset: insets.top + Self.topBarHeight + Self.barPadding,
                horizontalInset: horizontalInset
            )
        case .eventDetail:
            AppearanceDetailPreview(
                rendering: rendering,
                item: AppearancePreview.featuredItem(of: content),
                decorationOshis: oshis,
                photos: store.photos,
                horizontalInset: horizontalInset
            )
        case .share:
            AppearanceSharePreview(
                rendering: rendering,
                item: AppearancePreview.featuredItem(of: content),
                now: now,
                photos: store.photos,
                side: shareCardSide(size: size, insets: insets)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.palette.background.color)
        }
    }

    /// 長押ししている間だけ、着せ替える前の見た目にする。指を離すと試着に戻る。
    private var compareGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .updating($isPressing) { value, state, _ in
                if case .second(true, _) = value {
                    state = true
                }
            }
    }

    /// シェアのカードを見せる一辺（pt）。画面の幅と、上下のバーの間に収め、書き出す大きさ（`ShareCardSize.points`）より大きくしない。
    private func shareCardSide(size: CGSize, insets: EdgeInsets) -> CGFloat {
        let width = size.width - insets.leading - insets.trailing - Self.barPadding * 2
        let height = size.height - insets.top - insets.bottom - Self.shareVerticalMargin * 2
        return max(min(width, height, ShareCardSize.points), 0)
    }

    // MARK: - 上のバー

    private var topBar: some View {
        ZStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(theme.palette.onSurface.color)
                        .frame(width: Self.topBarHeight, height: Self.topBarHeight)
                        .background(theme.palette.surface.color, in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(theme.palette.outlineVariant.color)
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("閉じる")
                .accessibilityIdentifier("appearance.tryOn.close")
                Spacer(minLength: 0)
            }
            statusBadge
        }
        .frame(height: Self.topBarHeight)
        .padding(.horizontal, Self.barPadding)
        .padding(.top, 8)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    /// 「試着中」。長押ししている間は「着せ替える前」。
    private var statusBadge: some View {
        Text(isComparing ? "着せ替える前" : "試着中")
            .font(theme.typography.text(.footnote, weight: .bold))
            .lineLimit(1)
            .foregroundStyle((isComparing ? theme.palette.onSurface : theme.palette.onBrand).color)
            .padding(.horizontal, 14)
            .frame(minHeight: 30)
            .background((isComparing ? theme.palette.surface : theme.palette.brand).color, in: Capsule())
            .overlay {
                if isComparing {
                    Capsule()
                        .strokeBorder(theme.palette.outlineVariant.color)
                }
            }
            // 見本の読み上げの値で同じことを伝える
            .accessibilityHidden(true)
            .accessibilityIdentifier("appearance.tryOn.status")
    }

    // MARK: - 下のバー

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Label("長押しで、着せ替える前と比べる", systemImage: "arrow.counterclockwise")
                .font(theme.typography.text(.caption))
                .foregroundStyle(theme.palette.onSurfaceVariant.color)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .frame(minHeight: 30)
                .background(theme.palette.surface.color, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(theme.palette.outlineVariant.color)
                }
                // 読み上げでは、見本の操作「着せ替える前と比べる」で切り替える
                .accessibilityHidden(true)
            ViewThatFits(in: .horizontal) {
                controls(switcher: .titles)
                controls(switcher: .symbols)
            }
        }
        .padding(.horizontal, Self.barPadding)
        .padding(.bottom, 12)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func controls(switcher: AppearancePreviewSwitcher.Content) -> some View {
        HStack(spacing: 8) {
            AppearancePreviewSwitcher(
                selection: $kind,
                content: switcher,
                showsTrack: false,
                identifierPrefix: "appearance.tryOn.previewKind"
            )
            if !isPlusUnlocked {
                Button(action: onOpenPaywall) {
                    Text("Plus で使う")
                        .font(theme.typography.text(.footnote, weight: .bold))
                        .lineLimit(1)
                        .foregroundStyle(theme.palette.onBrand.color)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 38)
                        .background(theme.palette.brand.color, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("appearance.tryOn.openPaywall")
            }
        }
        .padding(3)
        .background(theme.palette.surface.color, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(theme.palette.outlineVariant.color)
        }
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
    }
}

#Preview("試着（Plus でない）") {
    @Previewable @State var kind = AppearancePreview.Kind.home
    AppearanceTryOnScreen(oshis: [], kind: $kind) {}
        .environment(AppearanceStore.volatile(
            suiteName: "jp.shilokuma.OshiCon.PreviewAppearance",
            directory: FileManager.default.temporaryDirectory.appending(path: "PreviewAppearancePhotos", directoryHint: .isDirectory)
        ))
        .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
