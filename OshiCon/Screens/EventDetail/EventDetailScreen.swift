//
//  EventDetailScreen.swift
//  OshiCon
//

import SwiftData
import SwiftUI

/// 予定の詳細。推しの写真（無ければ推し色の斜めの縞）の上に中身のカードを重ね、秒単位のカウントダウンと進み具合を出す。
/// 上のボタンでピン留めの切り替え・編集・削除（確認を出す）をする。予定が消えたら（削除・ウィジェットなどから）前の画面に戻る。
struct EventDetailScreen: View {
    let eventID: OshiEvent.ID

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar
    @Environment(\.timeZone) private var timeZone
    @Query private var storedEvents: [StoredEvent]
    @State private var isEditing = false
    @State private var isConfirmingDelete = false
    @State private var failureMessage: String?

    private static let photoHeight: CGFloat = 300
    private static let cardOverlap: CGFloat = 28

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
                AppPalette.background.color
                    .ignoresSafeArea()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onChange(of: storedEvents.isEmpty, initial: true) { _, isEmpty in
            if isEmpty {
                dismiss()
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
                EventDetailHeader(oshi: oshi, color: oshi?.color ?? .black)
                    .frame(height: Self.photoHeight)
                    .clipped()
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    EventDetailCard(detail: EventDetailContent(event: event, oshi: oshi, now: context.date, calendar: zonedCalendar))
                }
                .padding(.top, Self.photoHeight - Self.cardOverlap)
            }
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea(edges: .top)
        .background(AppPalette.surface.color.ignoresSafeArea())
        .toolbar { toolbar(event: event) }
        .sheet(isPresented: $isEditing) {
            // 開いた時点の最新の予定を渡す（古い値だと、外したピン留めを書き戻してしまう）
            EventEditorScreen(event: event)
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

    /// 端末のタイムゾーンを変えたときも、その日付で数える。
    private var zonedCalendar: Calendar {
        var calendar = calendar
        calendar.timeZone = timeZone
        return calendar
    }

    @ToolbarContentBuilder private func toolbar(event: OshiEvent) -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(
                event.isPinned ? "ピン留めを外す" : "ピン留めする",
                systemImage: event.isPinned ? "pin.slash" : "pin"
            ) {
                setPinned(!event.isPinned, event: event)
            }
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

    private func setPinned(_ isPinned: Bool, event: OshiEvent) {
        do {
            try OshiConStore(context: modelContext).setPinned(isPinned, eventID: event.id)
        } catch {
            failureMessage = "保存できませんでした"
        }
    }

    private func delete(_ event: OshiEvent) {
        do {
            try OshiConStore(context: modelContext).deleteEvent(id: event.id)
            // 予定が消えると onChange で前の画面に戻る
        } catch {
            failureMessage = "削除できませんでした"
        }
    }
}

/// 詳細の上に敷く推しの写真。写真が無い・読めないときは推し色の斜めの縞。
private struct EventDetailHeader: View {
    let oshi: Oshi?
    let color: OshiColor
    var photos = OshiPhotoLibrary.shared

    @Environment(\.displayScale) private var displayScale
    @State private var photo: Image?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                StripedBackground(color: color)
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
    .modelContainer(for: [StoredOshi.self, StoredEvent.self], inMemory: true)
}
