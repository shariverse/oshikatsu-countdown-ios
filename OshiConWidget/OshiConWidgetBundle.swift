//
//  OshiConWidgetBundle.swift
//  OshiConWidget
//

import SwiftUI
import WidgetKit

/// ホーム画面ウィジェットの一覧。カウントダウンと推しカウント（タスク 17）をここに並べる。
@main
struct OshiConWidgetBundle: WidgetBundle {
    var body: some Widget {
        CountdownWidget()
    }
}
