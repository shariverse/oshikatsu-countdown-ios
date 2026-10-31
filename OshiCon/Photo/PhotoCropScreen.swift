//
//  PhotoCropScreen.swift
//  OshiCon
//

import SwiftUI

/// 写真の調整画面。選んだ写真を拡大・縮小・移動・回転して、丸の枠に写す範囲を決める（iOS の連絡先の写真の調整に寄せる）。
///
/// 黒い地に写真を置き、丸の枠の外を暗くする。上に「やめる」「完了」を置く。
/// ピンチ・ドラッグ・2 本指のひねりを同時に効かせる。操作の途中は枠の隅が一時的に空いてもよく、
/// 指を離したとき（ジェスチャーが中断されたときも）に、枠の隅が空かないよう `PhotoCrop.clamped()` に寄せる。
/// VoiceOver などジェスチャーを使えない人向けに、上下のスワイプ（adjustable）で拡大・縮小、カスタムアクションで回転と元に戻す操作を置く。
///
/// 範囲は表示したときの `initialCrop` から始める（`@State`）。別の写真を調整するときは `.id(_:)` を変えるなどして作り直す。
/// シートで出すときは `.interactiveDismissDisabled()` を付け、「やめる」「完了」でだけ閉じる。
struct PhotoCropScreen: View {
    /// 表示用に縮めた写真（向きを反映した後の画像）。
    let image: CGImage
    /// 範囲の初期値。`imageSize` は取り込む写真の元の大きさ（表示用に縮める前）にする。
    let initialCrop: PhotoCrop
    /// 「やめる」。何も変えずに閉じる。
    let onCancel: () -> Void
    /// 「完了」。決めた範囲（補正済み）を返す。
    let onDone: (PhotoCrop) -> Void

    @State private var crop: PhotoCrop
    /// 進行中のジェスチャーを始めたときの範囲。ジェスチャーをしていなければ nil。
    @State private var gestureBase: PhotoCrop?
    /// 進行中のジェスチャーで最後に受け取った量。片方の指を先に離して拡大・回転の値が来なくなっても、最後の量を保つ。
    @State private var gestureAmount = PhotoCropGesture.Amount()
    /// ジェスチャーの最中か。中断されたときも false に戻る（`onEnded` は中断では呼ばれない）。
    @GestureState private var isGesturing = false
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(image: CGImage, initialCrop: PhotoCrop, onCancel: @escaping () -> Void, onDone: @escaping (PhotoCrop) -> Void) {
        self.image = image
        self.initialCrop = initialCrop
        self.onCancel = onCancel
        self.onDone = onDone
        _crop = State(initialValue: initialCrop.clamped())
    }

    var body: some View {
        GeometryReader { geometry in
            let frameSide = PhotoCropLayout.frameSide(in: geometry.size)
            ZStack {
                photo(frameSide: frameSide)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                dimmingMask(frameSide: frameSide, in: geometry.size)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(gestures(frameSide: frameSide))
            .accessibilityElement()
            .accessibilityLabel(Text("調整中の写真"))
            .accessibilityValue(Text(PhotoCropAccessibility.value(of: crop)))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    adjust(PhotoCropAccessibility.zoomedIn(crop))
                case .decrement:
                    adjust(PhotoCropAccessibility.zoomedOut(crop))
                @unknown default:
                    break
                }
            }
            .accessibilityAction(named: Text("左に回す")) {
                adjust(PhotoCropAccessibility.rotated(crop, clockwise: false), announces: true)
            }
            .accessibilityAction(named: Text("右に回す")) {
                adjust(PhotoCropAccessibility.rotated(crop, clockwise: true), announces: true)
            }
            .accessibilityAction(named: Text("元に戻す")) {
                adjust(PhotoCropGesture.reset(crop, to: initialCrop), announces: true)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            topBar
        }
        .background(Color.black.ignoresSafeArea())
        // 写真が見やすいよう、地は外観によらず黒。文字はテーマのダークの色で書く
        .environment(\.colorScheme, .dark)
        .statusBarHidden()
        .onChange(of: isGesturing) { _, gesturing in
            // 指を離したときと、ジェスチャーが中断されたときの両方で補正する
            if !gesturing {
                gestureBase = nil
                gestureAmount = PhotoCropGesture.Amount()
                settle()
            }
        }
    }

    // MARK: - 写真と枠

    private func photo(frameSide: CGFloat) -> some View {
        let layout = crop.layout(frameSide: frameSide)
        return Image(decorative: image, scale: 1)
            .resizable()
            .interpolation(.high)
            .frame(width: crop.imageSize.width * layout.scale, height: crop.imageSize.height * layout.scale)
            .rotationEffect(crop.rotation)
            .offset(layout.offset)
            .accessibilityHidden(true)
    }

    /// 丸の枠の外を暗くする。枠の線も引く。
    private func dimmingMask(frameSide: CGFloat, in size: CGSize) -> some View {
        let circle = CGRect(
            x: (size.width - frameSide) / 2,
            y: (size.height - frameSide) / 2,
            width: frameSide,
            height: frameSide
        )
        return ZStack {
            Path { path in
                // 上のバーの下や画面の外まで覆う
                path.addRect(CGRect(origin: .zero, size: size).insetBy(dx: -size.width, dy: -size.height))
                path.addEllipse(in: circle)
            }
            .fill(Color.black.opacity(0.6), style: FillStyle(eoFill: true))
            Circle()
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                .frame(width: circle.width, height: circle.height)
                .position(x: circle.midX, y: circle.midY)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - 上のバー

    private var topBar: some View {
        ViewThatFits(in: .horizontal) {
            // 見出しを画面の中央に置くため、両側のボタンに同じ幅を割り当てる
            HStack(spacing: 12) {
                cancelButton(wraps: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
                // 見出しは折り返さない（収まらなければ次の案に回す）
                title
                    .fixedSize()
                doneButton(wraps: false)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            // 1 行に収まらないときは、見出しをボタンの下に置く
            VStack(spacing: 8) {
                HStack {
                    cancelButton(wraps: false)
                    Spacer(minLength: 8)
                    doneButton(wraps: false)
                }
                title
            }
            // それでも収まらない（アクセシビリティサイズの文字など）ときは、ボタンの文字を折り返す
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    cancelButton(wraps: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    doneButton(wraps: true)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                title
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black)
    }

    private var title: some View {
        Text("移動と拡大・縮小")
            .font(theme.typography.text(.headline, weight: .bold))
            .foregroundStyle(theme.palette.onSurface.color)
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
    }

    private func cancelButton(wraps: Bool) -> some View {
        Button(action: onCancel) {
            Text("やめる")
                .multilineTextAlignment(.leading)
        }
        .font(theme.typography.text(.body))
        .foregroundStyle(theme.palette.onSurface.color)
        .fixedSize(horizontal: !wraps, vertical: true)
    }

    private func doneButton(wraps: Bool) -> some View {
        Button {
            var result = crop.clamped()
            result.rotation = PhotoCrop.normalized(result.rotation)
            onDone(result)
        } label: {
            Text("完了")
                .multilineTextAlignment(.trailing)
        }
        .font(theme.typography.text(.body, weight: .bold))
        .foregroundStyle(theme.palette.brand.color)
        .fixedSize(horizontal: !wraps, vertical: true)
    }

    // MARK: - 操作

    /// 移動・拡大・回転を同時に効かせる。値は始めたときからの量なので、始めたときの範囲（`gestureBase`）に当てて求める。
    private func gestures(frameSide: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .simultaneously(with: MagnifyGesture())
            .simultaneously(with: RotateGesture())
            .updating($isGesturing) { _, state, _ in
                state = true
            }
            .onChanged { value in
                let base = gestureBase ?? crop
                gestureBase = base
                gestureAmount.update(
                    translation: value.first?.first?.translation,
                    magnification: value.first?.second?.magnification,
                    rotation: value.second?.rotation
                )
                crop = PhotoCropGesture.apply(
                    to: base,
                    translation: gestureAmount.translation,
                    magnification: gestureAmount.magnification,
                    rotation: gestureAmount.rotation,
                    frameSide: frameSide
                )
            }
    }

    /// 枠の隅が空かない範囲に寄せる（「視差効果を減らす」ではアニメーションなし）。
    /// 回転角はそろえない（そろえると 180° をまたいだときに補正のアニメーションで 1 周回るため）。
    /// −180°〜180° にそろえるのは「完了」で返すときだけ（「元に戻す」は今の角度に近い、同じ見た目の角度に戻す）。
    private func settle() {
        adjust(crop.clamped())
    }

    /// 範囲を変える。読み上げの操作では、変えた後の状態を読み上げる（カスタムアクションでは値が読み直されないことがあるため）。
    private func adjust(_ newCrop: PhotoCrop, announces: Bool = false) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            crop = newCrop
        }
        if announces {
            AccessibilityNotification.Announcement(PhotoCropAccessibility.value(of: newCrop)).post()
        }
    }
}

// MARK: - 画面から切り離した決まり

/// ジェスチャーの量を範囲に当てる。
nonisolated enum PhotoCropGesture {
    /// 進行中のジェスチャーの、始めたときからの量。来なくなった値（先に終わったジェスチャー）は最後の値を保つ。
    struct Amount: Equatable {
        var translation: CGSize = .zero
        var magnification: CGFloat = 1
        var rotation: Angle = .zero

        mutating func update(translation: CGSize?, magnification: CGFloat?, rotation: Angle?) {
            if let translation {
                self.translation = translation
            }
            if let magnification {
                self.magnification = magnification
            }
            if let rotation {
                self.rotation = rotation
            }
        }
    }

    /// 「元に戻す」の行き先。回転角は今の角度に最も近い同じ見た目の角度にし、戻すアニメーションで何周も回らないようにする。
    static func reset(_ current: PhotoCrop, to initial: PhotoCrop) -> PhotoCrop {
        var result = initial.clamped()
        let turns = ((current.rotation.radians - result.rotation.radians) / (2 * .pi)).rounded()
        result.rotation = .radians(result.rotation.radians + turns * 2 * .pi)
        return result
    }

    /// 始めたときの範囲 `base` に、始めたときからの拡大・回転（枠の中心を軸）と移動を当てた範囲。補正はしない。
    /// 拡大率はジェスチャーの途中の制限（`PhotoCropLayout.limitedWhileGesturing`）に収める。枠の大きさが 0 なら移動しない。
    static func apply(
        to base: PhotoCrop,
        translation: CGSize,
        magnification: CGFloat,
        rotation: Angle,
        frameSide: CGFloat
    ) -> PhotoCrop {
        let factor = magnification.isFinite && magnification > 0 ? magnification : 1
        var result = PhotoCropLayout.limitedWhileGesturing(base.zoomed(by: factor)).rotated(by: rotation)
        if frameSide > 0 {
            result = result.dragged(by: translation, frameSide: frameSide)
        }
        return result
    }
}

/// 調整画面の枠の大きさと、ジェスチャーの途中の制限。
nonisolated enum PhotoCropLayout {
    /// 枠と画面の端の間（pt）。
    static let margin: CGFloat = 16
    /// 枠の一辺の上限（pt）。iPad の大きな画面で写真が広がりすぎないようにする。
    static let maximumFrameSide: CGFloat = 560

    /// 写真を置く範囲の大きさから決めた、丸の枠の一辺（pt）。短い辺から余白を引き、上限で抑える。
    static func frameSide(in size: CGSize) -> CGFloat {
        max(min(min(size.width, size.height) - margin * 2, maximumFrameSide), 0)
    }

    /// ジェスチャーの途中は、上限・下限を少し越えるところまで拡大・縮小させる（指を離すと戻す）。
    static func limitedWhileGesturing(_ crop: PhotoCrop) -> PhotoCrop {
        var result = crop
        result.zoom = min(max(crop.zoom, crop.minimumZoom * 0.5), crop.maximumZoom * 2)
        return result
    }
}

/// VoiceOver などジェスチャーを使えない人向けの操作と読み上げ。
nonisolated enum PhotoCropAccessibility {
    /// 1 回の拡大・縮小の倍率。
    static let zoomStep: CGFloat = 1.25
    /// 1 回の回転の角度。
    static let rotationStep: Angle = .degrees(5)

    static func zoomedIn(_ crop: PhotoCrop) -> PhotoCrop {
        crop.zoomed(by: zoomStep).clamped()
    }

    static func zoomedOut(_ crop: PhotoCrop) -> PhotoCrop {
        crop.zoomed(by: 1 / zoomStep).clamped()
    }

    /// 回して、枠の隅が空かないよう拡大率と位置を補正する。
    static func rotated(_ crop: PhotoCrop, clockwise: Bool) -> PhotoCrop {
        crop.rotated(by: clockwise ? rotationStep : -rotationStep).clamped()
    }

    /// 読み上げる今の状態（拡大率と回転の角度）。
    static func value(of crop: PhotoCrop, locale: Locale = .app) -> String {
        let zoom = Double(crop.zoom).formatted(.number.precision(.fractionLength(1)).locale(locale))
        let degrees = Int(PhotoCrop.normalized(crop.rotation).degrees.rounded())
        return String(localized: LocalizedStringResource("拡大 \(zoom) 倍、回転 \(degrees) 度", locale: locale))
    }
}

#Preview("調整画面") {
    PhotoCropScreen(
        image: PhotoCropPreviewImage.make(),
        initialCrop: PhotoCrop(imageSize: CGSize(width: 1_600, height: 1_200)),
        onCancel: {},
        onDone: { _ in }
    )
}

#Preview("回転・拡大した状態") {
    PhotoCropScreen(
        image: PhotoCropPreviewImage.make(),
        initialCrop: PhotoCrop(
            imageSize: CGSize(width: 1_600, height: 1_200),
            zoom: 1.8,
            rotation: .degrees(12),
            center: CGPoint(x: 600, y: 500)
        ),
        onCancel: {},
        onDone: { _ in }
    )
}

/// Preview と画面の確かめに使う、色と図形の画像（実在の写真を使わない）。
nonisolated enum PhotoCropPreviewImage {
    /// 4 つの象限を色分けし、中央に白い丸、四隅に目印を置いた 1600×1200 の画像。
    static func make(width: Int = 1_600, height: Int = 1_200) -> CGImage {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
        guard let context else {
            preconditionFailure("画像を作れない")
        }
        let halfWidth = CGFloat(width) / 2
        let halfHeight = CGFloat(height) / 2
        let pink = CGColor(red: 0.95, green: 0.45, blue: 0.65, alpha: 1)
        let blue = CGColor(red: 0.45, green: 0.75, blue: 0.95, alpha: 1)
        let green = CGColor(red: 0.55, green: 0.85, blue: 0.55, alpha: 1)
        let yellow = CGColor(red: 0.98, green: 0.85, blue: 0.4, alpha: 1)
        // CGContext は y が上向きなので、見たときの上の象限は y が大きいほう
        let colors: [(CGRect, CGColor)] = [
            (CGRect(x: 0, y: halfHeight, width: halfWidth, height: halfHeight), pink),
            (CGRect(x: halfWidth, y: halfHeight, width: halfWidth, height: halfHeight), blue),
            (CGRect(x: 0, y: 0, width: halfWidth, height: halfHeight), green),
            (CGRect(x: halfWidth, y: 0, width: halfWidth, height: halfHeight), yellow)
        ]
        for (rect, color) in colors {
            context.setFillColor(color)
            context.fill(rect)
        }
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        let radius = CGFloat(min(width, height)) / 5
        context.fillEllipse(in: CGRect(x: halfWidth - radius, y: halfHeight - radius, width: radius * 2, height: radius * 2))
        context.setFillColor(CGColor(red: 0.2, green: 0.1, blue: 0.3, alpha: 1))
        let mark = CGFloat(min(width, height)) / 10
        let corners = [
            CGPoint.zero,
            CGPoint(x: CGFloat(width) - mark, y: 0),
            CGPoint(x: 0, y: CGFloat(height) - mark),
            CGPoint(x: CGFloat(width) - mark, y: CGFloat(height) - mark)
        ]
        for origin in corners {
            context.fill(CGRect(origin: origin, size: CGSize(width: mark, height: mark)))
        }
        guard let image = context.makeImage() else {
            preconditionFailure("画像を作れない")
        }
        return image
    }
}
