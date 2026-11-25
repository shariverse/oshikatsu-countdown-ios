//
//  OshiCon.swift
//  OshiCon
//
//  Created by 村石 拓海 on 2024/05/12.
//

import SwiftData
import SwiftUI

@main
struct OshiCon: App {
    @State private var router = AppRouter()
    /// SwiftData のストア。開けなかったときはその旨の画面を出す。
    private let container: Result<ModelContainer, any Error>
    /// 予定の通知。押して起動したときの通知を受け取れるよう、起動の途中で作って delegate にする。ストアを開けなかったときは nil。
    private let reminders: ReminderScheduler?
    /// 当日の開演までのライブアクティビティ。ストアを開けなかったときは nil。
    private let liveActivities: LiveActivityScheduler?
    /// Plus の購入の状態。取引の変化（`Transaction.updates`）を取りこぼさないよう、起動の途中で作って監視を始める。
    private let plus: PlusStore
    /// Plus の着せ替えの設定と背景の写真。画面は `@Environment(AppearanceStore.self)` で引く。
    private let appearance: AppearanceStore

    init() {
        LaunchOptions.applyDefaultEnvironment()
        NavigationBarAppearance.applyTitleFonts()
        plus = PlusStore()
        appearance = AppearanceStore.forLaunch()
        let location: OshiConStore.Location = LaunchOptions.usesInMemoryStore ? .inMemory : .appGroup
        container = Result { try OshiConStore.makeContainer(location) }
        var sampleOshiIDs: [SampleData.Role: Oshi.ID] = [:]
        if LaunchOptions.seedsSampleData, case let .success(container) = container {
            sampleOshiIDs = Self.seedSampleData(into: container)
        }
        reminders = (try? container.get()).map { ReminderScheduler(container: $0) }
        liveActivities = (try? container.get()).map { LiveActivityScheduler(container: $0) }
        if LaunchOptions.seedsSampleData, !LaunchOptions.showsSampleLiveActivity {
            LiveActivityScheduler.endAll()
        }
        if LaunchOptions.appliesSampleAppearance, let directory = LaunchOptions.sampleOshiPhotosDirectory {
            Self.applySampleAppearance(to: appearance, photosIn: directory)
        }
        if let role = LaunchOptions.sampleOshiBackground,
           let oshiID = sampleOshiIDs[role],
           let directory = LaunchOptions.sampleOshiPhotosDirectory {
            Self.applySampleOshiBackground(to: appearance, role: role, oshiID: oshiID, photosIn: directory)
        }
    }

    /// 見本の推しと予定を入れる（メモリ上のストアのときだけ呼ぶ）。名前と予定名は画面の言語（`-AppleLanguages` で変えられる）で選ぶ。
    /// 端末の言語ではなくアプリが選んだ言語（`Locale.app`）にし、文言と見本の言語をそろえる。
    /// App Store 用スクリーンショットでは、UI テストから渡された写真を見本の推しに付ける（`LaunchOptions.sampleOshiPhotosDirectory`）。
    /// 入れた見本の推しの id を、役どころごとに返す（推しごとの背景の写真を入れるのに使う）。
    @discardableResult
    private static func seedSampleData(into container: ModelContainer) -> [SampleData.Role: Oshi.ID] {
        let now = Date.now
        let calendar = Calendar.autoupdatingCurrent
        var sample = SampleData.make(today: CalendarDay(now, calendar: calendar), now: now, locale: .app)
        if LaunchOptions.startsSampleStreamSoon {
            sample = sample.startingStreamSoon(now: now, calendar: calendar)
        }
        if let directory = LaunchOptions.sampleOshiPhotosDirectory {
            sample = SampleData.attachingPhotos(to: sample, from: directory, library: .shared)
        }
        // 推しは役どころの並びで作るので、並べ替えの前に役どころと結び付ける
        let oshiIDs = Dictionary(uniqueKeysWithValues: zip(SampleData.Role.allCases, sample.oshis.map(\.id)))
        // 写真は役どころの並びで付けるので、並べ替えは写真を付けた後にする
        if let role = LaunchOptions.sampleTopOshi {
            sample = sample.movingToTop(role)
        }
        SampleData.insert(sample, into: container.mainContext, now: now)
        return oshiIDs
    }

    /// 着せ替えに、見本のいちばん上の推し（アイドルグループ）の写真を背景に敷き、飾りを入れる（App Store 用スクリーンショット。`LaunchOptions.appliesSampleAppearance`）。
    private static func applySampleAppearance(to appearance: AppearanceStore, photosIn directory: URL) {
        guard let background = sampleBackground(of: .group, photosIn: directory) else {
            return
        }
        appearance.isDecorationEnabled = true
        Task {
            _ = try? await appearance.replaceBackgroundPhoto(background.data, crop: background.crop)
        }
    }

    /// 着せ替えの推し `oshiID`（役どころ `role`）の背景に、その推しの写真を敷く（スクリーンショット。`LaunchOptions.sampleOshiBackground`）。
    private static func applySampleOshiBackground(
        to appearance: AppearanceStore,
        role: SampleData.Role,
        oshiID: Oshi.ID,
        photosIn directory: URL
    ) {
        guard let background = sampleBackground(of: role, photosIn: directory) else {
            return
        }
        Task {
            _ = try? await appearance.replaceBackgroundPhoto(background.data, crop: background.crop, for: oshiID)
        }
    }

    /// 役どころ `role` の見本の推しの写真と、それを縦長の枠いっぱいに切り抜く範囲。読めなければ nil。
    private static func sampleBackground(of role: SampleData.Role, photosIn directory: URL) -> (data: Data, crop: PhotoCrop)? {
        let source = directory.appending(path: role.photoFileName, directoryHint: .notDirectory)
        guard let data = try? Data(contentsOf: source),
              let image = UIImage(data: data),
              let cgImage = image.cgImage else {
            return nil
        }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        return (data: data, crop: PhotoCrop(imageSize: size, aspectRatio: PhotoCrop.backgroundAspectRatio))
    }

    var body: some Scene {
        WindowGroup {
            switch container {
            case let .success(container):
                RootView()
                    .environment(router)
                    .modelContainer(container)
                    .refreshesWidgets()
                    .refreshesReminders(reminders)
                    .refreshesLiveActivities(liveActivities)
                    .providesPlusStatus(plus)
                    .environment(appearance)
                    .preferredColorScheme(LaunchOptions.forcedColorScheme)
            case .failure:
                StoreUnavailableView()
            }
        }
    }
}
