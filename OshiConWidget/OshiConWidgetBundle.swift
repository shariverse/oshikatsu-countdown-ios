//
//  OshiConWidgetBundle.swift
//  OshiConWidget
//

import SwiftUI
import WidgetKit

/// ホーム画面ウィジェットの一覧。カウントダウンと推しカウント。
@main
struct OshiConWidgetBundle: WidgetBundle {
    var body: some Widget {
        CountdownWidget()
        UpcomingWidget()
    }
}
