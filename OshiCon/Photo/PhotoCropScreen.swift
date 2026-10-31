//
//  PhotoCropScreen.swift
//  OshiCon
//

import SwiftUI

/// 写真の調整画面。選んだ写真を拡大・縮小・移動・回転して、丸の枠に写す範囲を決める（iOS の連絡先の写真の調整に寄せる）。
///
/// 黒い地に写真を置き、丸の枠の外を暗くする。上に「やめる」「完了」を置く。
/// ピンチ・ドラッグ・2 本指のひねりを同時に効かせ、指を離したら枠の隅が空かないよう `PhotoCrop.clamped()` に寄せる。
/// VoiceOver などジェスチャーを使えない人向けに、上下のスワイプ（adjustable）で拡大・縮小、カスタムアクションで回転と元に戻す操作を置く。
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
    /// 進行中のジェスチャーで、前回までに反映した量。
    @State private var lastTranslation: CGSize = .zero
    @State private var lastMagnification: CGFloat = 1
    @State private var lastRotation: Angle = .zero
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
                adjust(PhotoCropAccessibility.rotated(crop, clockwise: false))
            }
            .accessibilityAction(named: Text("右に回す")) {
                adjust(PhotoCropAccessibility.rotated(crop, clockwise: true))
            }
            .accessibilityAction(named: Text("元に戻す")) {
                adjust(initialCrop.clamped())
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            topBar
        }
        .background(Color.black.ignoresSafeArea())
        // 写真が見やすいよう、地は外観によらず黒。文字はテーマのダークの色で書く
        .environment(\.colorScheme, .dark)
        .statusBarHidden()
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
            HStack(spacing: 12) {
                cancelButton
                Spacer(minLength: 8)
                title
                Spacer(minLength: 8)
                doneButton
            }
            // 文字が大きくて 1 行に収まらないときは、見出しをボタンの下に置く
            VStack(spacing: 8) {
                HStack {
                    cancelButton
                    Spacer(minLength: 8)
                    doneButton
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

    private var cancelButton: some View {
        Button("やめる", action: onCancel)
            .font(theme.typography.text(.body))
            .foregroundStyle(theme.palette.onSurface.color)
            .fixedSize()
    }

    private var doneButton: some View {
        Button("完了") {
            onDone(crop.clamped())
        }
        .font(theme.typography.text(.body, weight: .bold))
        .foregroundStyle(theme.palette.brand.color)
        .fixedSize()
    }

    // MARK: - 操作

    private func gestures(frameSide: CGFloat) -> some Gesture {
        let drag = DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard frameSide > 0 else {
                    return
                }
                let delta = CGSize(
                    width: value.translation.width - lastTranslation.width,
                    height: value.translation.height - lastTranslation.height
                )
                lastTranslation = value.translation
                crop = crop.dragged(by: delta, frameSide: frameSide)
            }
            .onEnded { _ in
                lastTranslation = .zero
                settle()
            }
        let magnify = MagnifyGesture()
            .onChanged { value in
                let factor = value.magnification / max(lastMagnification, .leastNonzeroMagnitude)
                lastMagnification = value.magnification
                crop = PhotoCropLayout.limitedWhileGesturing(crop.zoomed(by: factor))
            }
            .onEnded { _ in
                lastMagnification = 1
                settle()
            }
        let rotate = RotateGesture()
            .onChanged { value in
                let delta = value.rotation - lastRotation
                lastRotation = value.rotation
                crop = crop.rotated(by: delta)
            }
            .onEnded { _ in
                lastRotation = .zero
                settle()
            }
        return drag.simultaneously(with: magnify).simultaneously(with: rotate)
    }

    /// 指を離したら、枠の隅が空かない範囲に寄せる（「視差効果を減らす」ではアニメーションなし）。
    private func settle() {
        adjust(crop.clamped())
    }

    private func adjust(_ newCrop: PhotoCrop) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            crop = newCrop
        }
    }
}

// MARK: - 画面から切り離した決まり

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
