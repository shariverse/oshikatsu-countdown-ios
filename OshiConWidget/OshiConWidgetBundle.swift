//
//  OshiConWidgetBundle.swift
//  OshiConWidget
//

import SwiftUI
import WidgetKit

/// ホーム画面ウィジェットの一覧（カウントダウン・推しカウント・推しの写真）と、当日のライブアクティビティ。
@main
struct OshiConWidgetBundle: WidgetBundle {
    var body: some Widget {
        CountdownWidget()
        UpcomingWidget()
        PhotoWidget()
        EventLiveActivity()
    }
}
