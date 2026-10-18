//
//  EventDetailCard.swift
//  OshiCon
//

import SwiftUI

/// 詳細の中身のカード。種類・推しの名前・タイトル、残り（または当日・終わった予定）、進み具合、日時・会場・くり返し。
struct EventDetailCard: View {
    let detail: EventDetailContent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                heading
                countdown
                if let progress = detail.countdown.progress,
                   let percentText = detail.progressPercentText,
                   let accessibilityLabel = detail.progressAccessibilityLabel {
                    progressBar(progress: progress, percentText: percentText, accessibilityLabel: accessibilityLabel)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
            Divider()
                .padding(.horizontal, 20)
            infoRow(systemImage: "clock", title: "日時", value: detail.dateText)
            if !detail.event.venue.isEmpty {
                infoRow(systemImage: "mappin.and.ellipse", title: "会場・場所", value: detail.event.venue)
            }
            if detail.event.repeatsYearly {
                infoRow(systemImage: "repeat", title: "くり返し", value: String(localized: "毎年この日を数えます"))
            }
        }
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppPalette.surface.color,
            in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
        )
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(detail.kindLabel)
                    .font(AppFont.text(.caption, weight: .bold))
                    .foregroundStyle(AppPalette.onSurface.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(detail.color.container.color, in: RoundedRectangle(cornerRadius: 8))
                Text(detail.oshiName)
                    .font(AppFont.text(.subheadline))
                    .foregroundStyle(AppPalette.onSurfaceVariant.color)
            }
            Text(detail.event.title)
                .font(AppFont.text(.title2, weight: .bold))
                .foregroundStyle(AppPalette.onSurface.color)
                .accessibilityAddTraits(.isHeader)
        }
    }

    @ViewBuilder private var countdown: some View {
        switch detail.countdown.status {
        case .upcoming:
            VStack(alignment: .leading, spacing: 4) {
                Text(detail.untilLabel)
                    .font(AppFont.text(.subheadline, weight: .bold))
                    .foregroundStyle(AppPalette.onSurfaceVariant.color)
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        let days = detail.remainingDaysParts
                        if !days.prefix.isEmpty {
                            Text(days.prefix)
                                .font(AppFont.text(.title3, weight: .bold))
                        }
                        Text(days.number)
                            .font(AppFont.countdownHero)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        if !days.suffix.isEmpty {
                            Text(days.suffix)
                                .font(AppFont.text(.title3, weight: .bold))
                        }
                    }
                    Text(detail.clockText)
                        .font(AppFont.countdownClock)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .foregroundStyle(detail.color.text.color)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(detail.countdownAccessibilityLabel)
        case .today:
            VStack(alignment: .leading, spacing: 4) {
                Text("今日は当日！")
                    .font(AppFont.text(.title, weight: .bold))
                    .foregroundStyle(detail.color.text.color)
                Text("楽しんできてね")
                    .font(AppFont.text(.body))
                    .foregroundStyle(AppPalette.onSurfaceVariant.color)
            }
            .accessibilityElement(children: .combine)
        case .ended:
            VStack(alignment: .leading, spacing: 4) {
                Text("終わった予定")
                    .font(AppFont.text(.subheadline, weight: .bold))
                    .foregroundStyle(AppPalette.onSurfaceVariant.color)
                Text(detail.daysAgoText)
                    .font(AppFont.text(.title, weight: .bold))
                    .foregroundStyle(AppPalette.onSurface.color)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func progressBar(progress: Double, percentText: String, accessibilityLabel: String) -> some View {
        VStack(spacing: 6) {
            ProgressView(value: progress)
                .tint(detail.color.text.color)
            HStack {
                Text(detail.progressStartText)
                Spacer()
                Text(percentText)
                    .fontWeight(.bold)
                Spacer()
                Text(detail.progressEndText)
            }
            .font(AppFont.text(.caption))
            .foregroundStyle(AppPalette.onSurfaceVariant.color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private func infoRow(systemImage: String, title: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Image(systemName: systemImage)
                .foregroundStyle(AppPalette.onSurfaceVariant.color)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.text(.caption))
                    .foregroundStyle(AppPalette.onSurfaceVariant.color)
                Text(value)
                    .font(AppFont.text(.body))
                    .foregroundStyle(AppPalette.onSurface.color)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
