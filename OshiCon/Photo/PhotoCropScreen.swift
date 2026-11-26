//
//  PhotoCropScreen.swift
//  OshiCon
//

import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/// 写真の調整画面。選んだ写真を拡大・縮小・移動・回転して、枠に写す範囲を決める（iOS の連絡先の写真の調整に寄せる）。
/// 枠の縦横比は `initialCrop.aspectRatio`（推しの丸は正方形、背景の写真は約 9:19.5 の縦長）、枠の形は `shape`（推しは丸、背景は角の丸い長方形）。
///
/// 黒い地に写真を置き、枠の外を暗くする。上に「やめる」「完了」を置く。
/// ピンチ・ドラッグ・2 本指のひねりを同時に効かせる。操作の途中は枠の隅が一時的に空いてもよく、
/// 指を離したとき（ジェスチャーが中断されたときも）に、枠の隅が空かないよう `PhotoCrop.clamped()` に寄せる。
/// VoiceOver などジェスチャーを使えない人向けに、上下のスワイプ（adjustable）で拡大・縮小、カスタムアクションで回転と元に戻す操作を置く。
///
/// 範囲は表示したときの `initialCrop` から始める（`@State`）。別の写真を調整するときは `.id(_:)` を変えるなどして作り直す。
/// シートで出すときは `.interactiveDismissDisabled()` を付け、「やめる」「完了」でだけ閉じる。
struct PhotoCropScreen: View {
    /// 表示用に縮めた写真（向きを反映した後の画像）。
    let image: CGImage
    /// 範囲の初期値。`imageSize` は取り込む写真の元の大きさ（表示用に縮める前）にする。枠の縦横比もこれで決まる。
    let initialCrop: PhotoCrop
    /// 枠の形（枠の外を暗くする形と枠の線）。
    let shape: PhotoCropShape
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

    init(
        image: CGImage,
        initialCrop: PhotoCrop,
        shape: PhotoCropShape = .circle,
        onCancel: @escaping () -> Void,
        onDone: @escaping (PhotoCrop) -> Void
    ) {
        self.image = image
        self.initialCrop = initialCrop
        self.shape = shape
        self.onCancel = onCancel
        self.onDone = onDone
        _crop = State(initialValue: initialCrop.clamped())
    }

    var body: some View {
        GeometryReader { geometry in
            let frameSize = PhotoCropLayout.frameSize(in: geometry.size, aspectRatio: crop.aspectRatio)
            ZStack {
                photo(frameSize: frameSize)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                dimmingMask(frameSize: frameSize, in: geometry.size)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(gestures(frameSize: frameSize))
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

    private func photo(frameSize: CGSize) -> some View {
        let layout = crop.layout(frameSize: frameSize)
        return Image(decorative: image, scale: 1)
            .resizable()
            .interpolation(.high)
            .frame(width: crop.imageSize.width * layout.scale, height: crop.imageSize.height * layout.scale)
            .rotationEffect(crop.rotation)
            .offset(layout.offset)
            .accessibilityHidden(true)
    }

    /// 枠（推しは丸、背景は角の丸い長方形）の外を暗くする。枠の線も引く。
    private func dimmingMask(frameSize: CGSize, in size: CGSize) -> some View {
        let frame = CGRect(
            x: (size.width - frameSize.width) / 2,
            y: (size.height - frameSize.height) / 2,
            width: frameSize.width,
            height: frameSize.height
        )
        return ZStack {
            Path { path in
                // 上のバーの下や画面の外まで覆う
                path.addRect(CGRect(origin: .zero, size: size).insetBy(dx: -size.width, dy: -size.height))
                path.addPath(shape.path(in: frame))
            }
            .fill(Color.black.opacity(0.6), style: FillStyle(eoFill: true))
            shape.path(in: frame)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
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
        .accessibilityIdentifier("photoCrop.cancel")
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
        .accessibilityIdentifier("photoCrop.done")
        .font(theme.typography.text(.body, weight: .bold))
        .foregroundStyle(theme.palette.brand.color)
        .fixedSize(horizontal: !wraps, vertical: true)
    }

    // MARK: - 操作

    /// 移動・拡大・回転を同時に効かせる。値は始めたときからの量なので、始めたときの範囲（`gestureBase`）に当てて求める。
    private func gestures(frameSize: CGSize) -> some Gesture {
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
                    frameSize: frameSize
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
    /// 拡大率はジェスチャーの途中の制限（`PhotoCropLayout.limitedWhileGesturing`）に収める。枠の幅が 0 なら移動しない。
    static func apply(
        to base: PhotoCrop,
        translation: CGSize,
        magnification: CGFloat,
        rotation: Angle,
        frameSize: CGSize
    ) -> PhotoCrop {
        let factor = magnification.isFinite && magnification > 0 ? magnification : 1
        var result = PhotoCropLayout.limitedWhileGesturing(base.zoomed(by: factor)).rotated(by: rotation)
        if frameSize.width > 0 {
            result = result.dragged(by: translation, frameSize: frameSize)
        }
        return result
    }

    /// 正方形の枠（一辺 `frameSide` pt）で、ジェスチャーの量を当てた範囲。
    static func apply(
        to base: PhotoCrop,
        translation: CGSize,
        magnification: CGFloat,
        rotation: Angle,
        frameSide: CGFloat
    ) -> PhotoCrop {
        apply(
            to: base,
            translation: translation,
            magnification: magnification,
            rotation: rotation,
            frameSize: CGSize(width: frameSide, height: frameSide)
        )
    }
}

/// 調整画面の枠の大きさと、ジェスチャーの途中の制限。
nonisolated enum PhotoCropLayout {
    /// 枠と画面の端の間（pt）。
    static let margin: CGFloat = 16
    /// 枠の短い辺（正方形では一辺）の上限（pt）。iPad の大きな画面で写真が広がりすぎないようにする。
    static let maximumFrameSide: CGFloat = 560

    /// 写真を置く範囲の大きさから決めた、丸の枠の一辺（pt）。短い辺から余白を引き、上限で抑える。
    static func frameSide(in size: CGSize) -> CGFloat {
        frameSize(in: size, aspectRatio: 1).width
    }

    /// 写真を置く範囲の大きさから決めた、縦横比 `aspectRatio`（幅 ÷ 高さ）の枠の大きさ（pt）。
    /// 四方の余白を引いた範囲に収まる最大の長方形にし、短い辺が `maximumFrameSide` を超えれば縦横比のまま縮める。
    static func frameSize(in size: CGSize, aspectRatio: CGFloat) -> CGSize {
        let ratio = aspectRatio.isFinite && aspectRatio > 0 ? aspectRatio : 1
        let width = max(size.width - margin * 2, 0)
        let height = max(size.height - margin * 2, 0)
        let fitted = width > height * ratio
            ? CGSize(width: height * ratio, height: height)
            : CGSize(width: width, height: width / ratio)
        guard min(fitted.width, fitted.height) > maximumFrameSide else {
            return fitted
        }
        // 短い辺をちょうど上限にし、長い辺は縦横比から求める
        return ratio <= 1
            ? CGSize(width: maximumFrameSide, height: maximumFrameSide / ratio)
            : CGSize(width: maximumFrameSide * ratio, height: maximumFrameSide)
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

#Preview("背景の写真（縦長の枠）") {
    PhotoCropScreen(
        image: PhotoCropPreviewImage.make(),
        initialCrop: PhotoCrop(imageSize: CGSize(width: 1_600, height: 1_200), aspectRatio: PhotoCrop.backgroundAspectRatio),
        shape: .roundedRectangle,
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

    /// `make()` の画像を PNG で書き出したデータ（UI テストで、写真ライブラリから選んだ写真の代わりに使う）。書き出せなければ nil。
    static func pngData() -> Data? {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, make(), nil)
        return CGImageDestinationFinalize(destination) ? output as Data : nil
    }
}
