//
//  OshiConWidgetBundle.swift
//  OshiConWidget
//

import SwiftUI
import WidgetKit

/// ホーム画面ウィジェットの一覧（カウントダウンと推しカウント）と、当日のライブアクティビティ。
@main
struct OshiConWidgetBundle: WidgetBundle {
    var body: some Widget {
        CountdownWidget()
        UpcomingWidget()
        EventLiveActivity()
    }
}
