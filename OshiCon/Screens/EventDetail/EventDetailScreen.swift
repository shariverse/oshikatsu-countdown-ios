//
//  EventDetailScreen.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// 予定の詳細。推しの写真（無ければテーマの模様。出荷するテーマは推し色を黒に寄せた地に十字とハート）の上に中身のカードを重ね、秒単位のカウントダウンと進み具合を出す。
/// 上のボタンでピン留めの切り替え・画像でシェア（プレビューのシート）・編集・削除（確認を出す）をする。予定が消えたら（削除・推しの削除など）前の画面に戻る。
struct EventDetailScreen: View {
    let eventID: OshiEvent.ID

    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.appTheme) private var theme
    @Environment(AppearanceStore.self) private var appearance
    @Environment(\.isPlusUnlocked) private var isPlusUnlocked
    @Query private var storedEvents: [StoredEvent]
    /// 着せ替えの飾りに使う推し（ホームと同じ並び）。
    @Query(sort: OshiConStore.oshiOrder)
    private var storedOshis: [StoredOshi]
    /// 上の写真の下端。着せ替えの地を、上の写真より下にだけ敷くのに使う。
    @State private var headerPosition = AppearanceDetailHeaderPosition()
    @State private var isEditing = false
    @State private var isSharing = false
    @State private var isConfirmingDelete = false
    @State private var failureMessage: String?
    /// ピン留めを切り替えたときの触覚。
    @Environment(\.haptic) private var haptic

    private static let photoHeight: CGFloat = 300
    /// 横向きの iPhone（縦が狭い）では、写真で画面が埋まらないよう低くする。
    private static let compactPhotoHeight: CGFloat = 140
    private static let cardOverlap: CGFloat = 28
    /// 上の写真の下端を測る座標（スクロールの枠。地と同じく画面の上端から）。
    nonisolated private static let scrollSpace = "eventDetail.scroll"

    init(eventID: OshiEvent.ID) {
        self.eventID = eventID
        _storedEvents = Query(filter: #Predicate<StoredEvent> { $0.id == eventID })
    }

    /// 最新の予定と推し。保存した値が壊れていて読めないときも nil。
    private var current: (event: OshiEvent, oshi: Oshi?)? {
        guard let stored = storedEvents.first, let event = OshiConStore.event(from: stored) else {
            return nil
        }
        return (event, stored.oshi.map(OshiConStore.oshi(from:)))
    }

    var body: some View {
        Group {
            if let current {
                content(event: current.event, oshi: current.oshi)
            } else {
                ThemeScreenBackground()
                    .ignoresSafeArea()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .modifier(DetailNavigationBarBackground())
        // 予定が消えた・読めないときは前の画面に戻る。作り直しや遷移の途中でも戻れるよう、ホームの積み重ねから外す
        .onChange(of: current == nil, initial: true) { _, isMissing in
            if isMissing {
                isSharing = false
                leave()
            }
        }
        .alert(
            failureMessage ?? "",
            isPresented: Binding { failureMessage != nil } set: { if !$0 { failureMessage = nil } }
        ) {
            Button("閉じる", role: .cancel) {}
        }
    }

    private func content(event: OshiEvent, oshi: Oshi?) -> some View {
        ScrollView {
            ZStack(alignment: .top) {
                // 写真は画面の幅いっぱいに敷き、カードだけ読みやすい幅に収める
                EventDetailHeader(oshi: oshi, color: oshi?.color ?? .black)
                    .frame(height: photoHeight)
                    .clipped()
                    // 横向きでは左右の安全領域の外まで敷く
                    .ignoresSafeArea(edges: .horizontal)
                    // スクロールで動いた上の写真の下端を、着せ替えの地に伝える（この画面の本体は描き直さない）
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .named(Self.scrollSpace)).maxY
                    } action: { maxY in
                        headerPosition.update(headerMaxY: maxY)
                    }
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    EventDetailCard(detail: EventDetailContent(event: event, oshi: oshi, now: context.date, calendar: zonedCalendar))
                }
                .frame(maxWidth: 720)
                .padding(.top, photoHeight - Self.cardOverlap)
            }
        }
        .ignoresSafeArea(edges: .top)
        .coordinateSpace(.named(Self.scrollSpace))
        .appearanceUITestMarker(AppearanceUITestMarker.eventDetailIdentifier, rendering: rendering)
        // Plus の着せ替え（上の写真より下の地だけ）。Plus でなければカードの地の色のまま。購入・解約・期限切れでその場で切り替わる
        .background(
            AppearanceDetailBackground(
                rendering: rendering,
                oshis: storedOshis.map(OshiConStore.oshi(from:)),
                photos: appearance.photos,
                header: headerPosition
            )
            .ignoresSafeArea()
        )
        .toolbar { toolbar(event: event) }
        // ウィジェットのリンクで画面を切り替えるときは、編集とシェアのシートと削除の確認を閉じる
        .onChange(of: router.sheetDismissal) {
            isEditing = false
            isSharing = false
            isConfirmingDelete = false
        }
        .sheet(isPresented: $isEditing) {
            // 開いた時点の最新の予定を渡す（古い値だと、外したピン留めを書き戻してしまう）
            EventEditorScreen(event: event)
        }
        .sheet(isPresented: $isSharing) {
            // Plus で背景の写真を敷いているときは、カードの地もその写真にする（それ以外は出荷するテーマのカード）
            ShareCardPreviewScreen(event: event, oshi: oshi, style: .appearance(rendering), backgroundPhotos: appearance.photos)
        }
        .alert("この予定を削除しますか？", isPresented: $isConfirmingDelete) {
            Button("削除", role: .destructive) {
                delete(event)
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text(EventDetailContent(event: event, oshi: oshi, now: .now, calendar: zonedCalendar).deleteMessage)
        }
    }

    /// Plus が使えるかと着せ替えの設定から、実際に描くもの。
    private var rendering: AppearanceRendering {
        appearance.rendering(isPlusUnlocked: isPlusUnlocked)
    }

    private var photoHeight: CGFloat {
        verticalSizeClass == .compact ? Self.compactPhotoHeight : Self.photoHeight
    }

    /// 端末のタイムゾーンを変えたときも、次の秒からその日付で数える。
    private var zonedCalendar: Calendar {
        .autoupdatingCurrent
    }

    @ToolbarContentBuilder private func toolbar(event: OshiEvent) -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(
                event.isPinned ? "ピン留めを外す" : "ピン留めする",
                systemImage: event.isPinned ? "pin.slash" : "pin"
            ) {
                setPinned(!event.isPinned, event: event)
            }
            .accessibilityIdentifier("eventDetail.pin")
            // シェアの入口はここだけ（ホームの行・ウィジェットには置かない）
            Button("画像でシェア", systemImage: "square.and.arrow.up") {
                isSharing = true
            }
            .accessibilityIdentifier("eventDetail.share")
            Button("編集", systemImage: "pencil") {
                isEditing = true
            }
            Menu("その他の操作", systemImage: "ellipsis") {
                Button("予定を削除", systemImage: "trash", role: .destructive) {
                    isConfirmingDelete = true
                }
            }
        }
    }

    private func leave() {
        let route = HomeRoute.eventDetail(eventID)
        if router.homePath.contains(route) {
            router.homePath.removeAll { $0 == route }
        } else {
            dismiss()
        }
    }

    private func setPinned(_ isPinned: Bool, event: OshiEvent) {
        do {
            try OshiConStore(context: modelContext).setPinned(isPinned, eventID: event.id)
            haptic(.pinChanged(isPinned: isPinned))
        } catch {
            failureMessage = String(localized: "保存できませんでした")
        }
    }

    private func delete(_ event: OshiEvent) {
        do {
            try OshiConStore(context: modelContext).deleteEvent(id: event.id)
            // 予定が消えると onChange で前の画面に戻る（leave）
        } catch {
            failureMessage = String(localized: "削除できませんでした")
        }
    }
}

/// 詳細のナビゲーションバー。iOS 26 ではボタンがガラス風の丸になるので地を出さず写真を見せる。
/// それより前の版ではボタンに地が付かず、明るい写真の上で見えにくいので、すりガラスの地を出す。
private struct DetailNavigationBarBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.toolbarBackground(.hidden, for: .navigationBar)
        } else {
            content
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }
}

/// 詳細の上に敷く推しの写真。写真が無い・読めないときはテーマの模様（出荷するテーマは推し色を黒に寄せた地に十字とハート）。
private struct EventDetailHeader: View {
    let oshi: Oshi?
    let color: OshiColor
    var photos = OshiPhotoLibrary.shared

    @Environment(\.displayScale) private var displayScale
    @State private var photo: Image?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ThemePhotoPlaceholder(color: color)
                if let photo {
                    photo
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
            }
            .task(id: oshi?.photoFileName) {
                photo = nil
                guard let fileName = oshi?.photoFileName else {
                    return
                }
                let pixels = Int((max(proxy.size.width, proxy.size.height) * displayScale).rounded(.up))
                let image = await photos.loadImage(fileName: fileName, maxPixelLength: pixels)
                photo = image.map { Image(decorative: $0, scale: 1) }
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        EventDetailScreen(eventID: UUID())
    }
    .environment(AppRouter())
    // 端末の設定に触れない着せ替えの設定
    .environment(AppearanceStore.volatile(
        suiteName: "jp.shilokuma.OshiCon.PreviewAppearance",
        directory: FileManager.default.temporaryDirectory.appending(path: "PreviewAppearancePhotos", directoryHint: .isDirectory)
    ))
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
