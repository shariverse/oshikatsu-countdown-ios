//
//  AppStoreSurfaceRenderingTests.swift
//  OshiConTests
//

import Foundation
@testable import OshiCon
import SwiftUI
import Testing
import UIKit

/// App Store 用スクリーンショットの、アプリの外の面（ホーム画面のウィジェット・ロック画面のアクセサリ）を、本物の View から PNG に描き出す。
///
/// ウィジェットの共有データはメモリ上のストアでは作られず、Simulator のホーム画面・ロック画面にウィジェットを置くこともできないので、
/// 出荷する View（`CountdownWidgetView`・`UpcomingWidgetView`・`PhotoWidgetView`・`CountdownAccessoryView`）を、
/// アプリの Preview と同じ枠（`WidgetPreview`）に入れて描き出す。描き出した画像は、UI テストで撮ったホーム画面・ロック画面に重ねる
/// （docs/app-store/screenshots/screenshots.html）。中身は UI テストと同じ見本の推しと予定（`SampleData`）。
///
/// ふだんのテストでは流さない。`scripts/app-store-screenshots.sh` が環境変数 `APP_STORE_SURFACES_DIR`（xcodebuild には
/// `TEST_RUNNER_APP_STORE_SURFACES_DIR` で渡す）に書き出し先を渡し、`-testLanguage` で言語を替えて流す
/// （ウィジェットの View は文言と日付を `Locale.app`、つまりアプリの言語で出すため）。
@MainActor
struct AppStoreSurfaceRenderingTests {
    /// 書き出し先。無ければこのテストは飛ばす。
    nonisolated private static let outputDirectory = ProcessInfo.processInfo.environment["APP_STORE_SURFACES_DIR"].flatMap { path in
        path.isEmpty ? nil : URL(fileURLWithPath: path, isDirectory: true)
    }

    /// 見本の推しの写真のディレクトリ（UI テストのバンドルに入れているものと同じ。リポジトリの中を読む）。
    nonisolated private static var samplePhotosDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "OshiConUITests/SampleOshiPhotos", directoryHint: .isDirectory)
    }

    /// 描き出す倍率。端末の倍率によらず 3 倍で描き、重ねるときに縮める。
    private static let scale: CGFloat = 3

    @Test("ホーム画面のウィジェットとロック画面のアクセサリを描き出す", .enabled(if: outputDirectory != nil))
    func renderSurfaces() throws {
        let directory = try #require(Self.outputDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let now = Date.now
        let calendar = Calendar.autoupdatingCurrent
        let today = CalendarDay(now, calendar: calendar)
        // UI テストの見本（`-sampleStreamStartsSoon`）と同じく、当日の配信は今から 40 分ほど先に始まる
        let sample = SampleData.make(today: today, now: now, locale: .app).startingStreamSoon(now: now, calendar: calendar)
        let events = sample.events
        let oshis = sample.oshis
        let roles = Dictionary(uniqueKeysWithValues: zip(SampleData.Role.allCases, oshis))
        let event = { (role: SampleData.Role, kind: EventKind) throws -> OshiEvent in
            let oshi = try #require(roles[role])
            return try #require(events.first { $0.oshiID == oshi.id && $0.kind == kind })
        }
        let dome = try event(.group, .live)
        let birthday = try event(.voiceActor, .birthday)
        let stage = try event(.stageActor, .live)
        let movie = try event(.character, .release)

        let countdown = { (event: OshiEvent) in
            CountdownWidgetContent(eventID: event.id, events: events, oshis: oshis, now: now, calendar: calendar)
        }
        let photoContent = { (event: OshiEvent) in
            PhotoWidgetContent(eventID: event.id, events: events, oshis: oshis, isPlusUnlocked: true, today: today)
        }

        // ホーム画面（無料）: カウントダウン（ピン留めのライブと誕生日）と推しカウント（これからの予定）
        try render(WidgetPreview.countdown(countdown(dome)), to: directory, name: "widget-countdown-small")
        try render(WidgetPreview.countdown(countdown(birthday)), to: directory, name: "widget-countdown-small-2")
        let upcoming = UpcomingWidgetContent(events: events, oshis: oshis, today: today, maxRows: UpcomingWidgetContent.maxRows)
        try render(WidgetPreview.upcoming(upcoming), to: directory, name: "widget-upcoming-medium")

        // ホーム画面（Plus）: 推しの写真
        try render(
            WidgetPreview.photo(photoContent(birthday), family: .systemSmall, photo: try photo(of: .voiceActor)),
            to: directory,
            name: "widget-photo-small"
        )
        try render(
            WidgetPreview.photo(photoContent(movie), family: .systemSmall, photo: try photo(of: .character)),
            to: directory,
            name: "widget-photo-small-2"
        )
        try render(
            WidgetPreview.photo(photoContent(stage), family: .systemMedium, photo: try photo(of: .stageActor)),
            to: directory,
            name: "widget-photo-medium"
        )

        // ロック画面: 時計の下に置く丸（ドームのライブの進み具合）と長方形（誕生日）。1 行は時計の上の日付と重なるので使わない
        try render(WidgetPreview.countdownLockScreen(countdown(dome), family: .circular), to: directory, name: "lock-circular")
        try render(WidgetPreview.countdownLockScreen(countdown(birthday), family: .rectangular), to: directory, name: "lock-rectangular")
    }

    /// 役どころ `role` の見本の推しの写真。
    private func photo(of role: SampleData.Role) throws -> CGImage {
        let url = Self.samplePhotosDirectory.appending(path: role.photoFileName, directoryHint: .notDirectory)
        let image = try #require(UIImage(contentsOfFile: url.path(percentEncoded: false)), "見本の推しの写真がありません: \(url.path())")
        return try #require(image.cgImage)
    }

    /// `view` を `<name>.png` に書き出す。透明な地は透明のまま残す（重ねる側で角の外を見せるため）。
    private func render(_ view: some View, to directory: URL, name: String) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = Self.scale
        renderer.isOpaque = false
        let image = try #require(renderer.uiImage, "\(name) を描けませんでした")
        let data = try #require(image.pngData())
        try data.write(to: directory.appending(path: "\(name).png", directoryHint: .notDirectory))
    }
}
