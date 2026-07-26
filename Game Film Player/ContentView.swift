import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var model = PlayerModel()
    @State private var isPickerPresented = false

    // Zoom / pan
    @State private var zoomScale: CGFloat = 1
    @State private var lastZoomScale: CGFloat = 1
    @State private var panOffset: CGSize = .zero
    @State private var lastPanOffset: CGSize = .zero
    @State private var cursorInVideo: CGPoint = .zero
    @State private var isHoveringVideo = false
    /// Locked for the duration of a pinch so zoom stays stable mid-gesture.
    @State private var zoomGestureAnchor: CGPoint?

    // Scrubber draft value while dragging
    @State private var scrubTime: Double = 0

    // Skip feedback flash
    @State private var skipFlash: SkipFlash?

    private let minZoom: CGFloat = 1
    private let maxZoom: CGFloat = 5

    var body: some View {
        VStack(spacing: 0) {
            videoArea
            controls
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .fileImporter(
            isPresented: $isPickerPresented,
            allowedContentTypes: [.movie, .video, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                resetViewport()
                model.open(url: url)
            case .failure(let error):
                print("Error opening file: \(error.localizedDescription)")
            }
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.space) {
            model.togglePlayPause()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            performSkip(-5)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            performSkip(5)
            return .handled
        }
        .onDisappear {
            model.close()
        }
    }

    // MARK: - Video

    private var videoArea: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                if model.hasVideo {
                    PlayerLayerView(player: model.player)
                        .scaleEffect(zoomScale)
                        .offset(panOffset)
                        .allowsHitTesting(false)

                    // Gesture surface above the video
                    Color.clear
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                cursorInVideo = location
                                isHoveringVideo = true
                            case .ended:
                                isHoveringVideo = false
                            }
                        }
                        .highPriorityGesture(doubleTapSkipGesture(in: geo.size))
                        .onLongPressGesture(
                            minimumDuration: 0.28,
                            maximumDistance: 18,
                            pressing: { pressing in
                                // Boost starts in `perform` (after the hold delay);
                                // release always restores the base rate.
                                if !pressing {
                                    model.endBoost()
                                }
                            },
                            perform: {
                                model.beginBoost()
                            }
                        )
                        .simultaneousGesture(magnificationGesture(in: geo.size))
                        .simultaneousGesture(panGesture(in: geo.size))

                    if model.isBoosting {
                        boostOverlay
                    }

                    if let skipFlash {
                        skipOverlay(skipFlash)
                    }
                } else {
                    emptyState
                }
            }
            .clipped()
        }
        .frame(minHeight: 320)
    }

    private var emptyState: some View {
        Button {
            isPickerPresented = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "film")
                    .font(.system(size: 40))
                Text("Open Video File")
                    .font(.headline)
                Text("Pinch to zoom · hold to speed up · double-click sides to skip")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }

    private var boostOverlay: some View {
        Text(String(format: "%.1fx", model.effectiveRate))
            .font(.system(size: 42, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
            .allowsHitTesting(false)
    }

    private func skipOverlay(_ flash: SkipFlash) -> some View {
        HStack {
            if flash.direction < 0 {
                skipBadge(seconds: flash.seconds, leading: true)
                Spacer()
            } else {
                Spacer()
                skipBadge(seconds: flash.seconds, leading: false)
            }
        }
        .padding(.horizontal, 28)
        .allowsHitTesting(false)
    }

    private func skipBadge(seconds: Double, leading: Bool) -> some View {
        Label(
            String(format: "%g s", abs(seconds)),
            systemImage: leading ? "gobackward" : "goforward"
        )
        .font(.title2.weight(.semibold))
        .foregroundStyle(.white)
        .padding(14)
        .background(.black.opacity(0.45), in: Circle())
    }

    // MARK: - Gestures

    private func magnificationGesture(in size: CGSize) -> some Gesture {
        // MagnifyGesture exposes the pinch start location; we prefer the live
        // cursor so zoom behaves like Maps / Preview (anchor under the pointer).
        MagnifyGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                if zoomGestureAnchor == nil {
                    if isHoveringVideo {
                        zoomGestureAnchor = cursorInVideo
                    } else {
                        zoomGestureAnchor = value.startLocation
                    }
                }

                let anchor = zoomGestureAnchor
                    ?? CGPoint(x: size.width / 2, y: size.height / 2)
                let newScale = clampZoom(lastZoomScale * value.magnification)
                zoomScale = newScale
                panOffset = clampPan(
                    anchoredOffset(
                        from: lastPanOffset,
                        oldScale: lastZoomScale,
                        newScale: newScale,
                        anchor: anchor,
                        in: size
                    ),
                    in: size,
                    scale: newScale
                )
            }
            .onEnded { _ in
                zoomGestureAnchor = nil
                lastZoomScale = zoomScale
                if zoomScale <= minZoom + 0.01 {
                    withAnimation(.easeOut(duration: 0.15)) {
                        zoomScale = minZoom
                        lastZoomScale = minZoom
                        panOffset = .zero
                        lastPanOffset = .zero
                    }
                } else {
                    lastPanOffset = panOffset
                }
            }
    }

    /// Keeps the content point under `anchor` fixed on screen while scale changes.
    private func anchoredOffset(
        from startOffset: CGSize,
        oldScale: CGFloat,
        newScale: CGFloat,
        anchor: CGPoint,
        in size: CGSize
    ) -> CGSize {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let contentX = (anchor.x - center.x - startOffset.width) / oldScale
        let contentY = (anchor.y - center.y - startOffset.height) / oldScale
        return CGSize(
            width: anchor.x - center.x - contentX * newScale,
            height: anchor.y - center.y - contentY * newScale
        )
    }

    private func panGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard zoomScale > minZoom + 0.01 else { return }
                // Don't fight hold-to-boost while panning.
                model.endBoost()
                let proposed = CGSize(
                    width: lastPanOffset.width + value.translation.width,
                    height: lastPanOffset.height + value.translation.height
                )
                panOffset = clampPan(proposed, in: size, scale: zoomScale)
            }
            .onEnded { _ in
                lastPanOffset = panOffset
            }
    }

    private func doubleTapSkipGesture(in size: CGSize) -> some Gesture {
        SpatialTapGesture(count: 2, coordinateSpace: .local)
            .onEnded { event in
                guard model.hasVideo else { return }
                if event.location.x < size.width * 0.5 {
                    performSkip(-5)
                } else {
                    performSkip(5)
                }
            }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 12) {
            scrubber

            HStack(spacing: 16) {
                Button {
                    isPickerPresented = true
                } label: {
                    Label("Open", systemImage: "folder")
                }

                Spacer(minLength: 8)

                Button {
                    performSkip(-5)
                } label: {
                    Image(systemName: "gobackward.5")
                        .font(.title2)
                }
                .disabled(!model.hasVideo)
                .help("Skip back 5 seconds (←)")

                Button {
                    model.togglePlayPause()
                } label: {
                    Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .frame(width: 36)
                }
                .disabled(!model.hasVideo)
                .help("Play / Pause (Space)")

                Button {
                    performSkip(5)
                } label: {
                    Image(systemName: "goforward.5")
                        .font(.title2)
                }
                .disabled(!model.hasVideo)
                .help("Skip forward 5 seconds (→)")

                Spacer(minLength: 8)

                speedControl
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .buttonStyle(.borderless)
    }

    private var scrubber: some View {
        HStack(spacing: 10) {
            Text(timeString(from: model.isScrubbing ? scrubTime : model.currentTime))
                .font(.caption.monospacedDigit())
                .frame(width: 64, alignment: .leading)

            Slider(
                value: Binding(
                    get: { model.isScrubbing ? scrubTime : model.currentTime },
                    set: { newValue in
                        scrubTime = newValue
                        if model.isScrubbing {
                            model.updateScrubbing(to: newValue)
                        }
                    }
                ),
                in: 0...(model.duration > 0 ? model.duration : 1),
                onEditingChanged: { editing in
                    if editing {
                        scrubTime = model.currentTime
                        model.beginScrubbing()
                    } else {
                        model.endScrubbing(at: scrubTime)
                    }
                }
            )
            .disabled(!model.hasVideo)

            Text(timeString(from: model.duration))
                .font(.caption.monospacedDigit())
                .frame(width: 64, alignment: .trailing)
        }
    }

    private var speedControl: some View {
        HStack(spacing: 8) {
            Text("Speed")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(
                value: Binding(
                    get: { Double(model.baseRate) },
                    set: { model.setBaseRate(Float($0)) }
                ),
                in: 0.1...3.0,
                step: 0.1
            )
            .frame(width: 140)
            .disabled(!model.hasVideo)

            Text(String(format: "%.1fx", model.isBoosting ? model.effectiveRate : model.baseRate))
                .font(.caption.monospacedDigit().weight(model.isBoosting ? .bold : .regular))
                .frame(width: 42, alignment: .leading)
                .foregroundStyle(model.isBoosting ? Color.orange : Color.primary)
        }
        .help("Base speed 0.1×–3×. Click and hold the video to boost temporarily.")
    }

    // MARK: - Helpers

    private func performSkip(_ seconds: Double) {
        guard model.hasVideo else { return }
        model.skip(by: seconds)
        let flash = SkipFlash(direction: seconds < 0 ? -1 : 1, seconds: seconds)
        withAnimation(.easeOut(duration: 0.12)) {
            skipFlash = flash
        }
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            if skipFlash == flash {
                withAnimation(.easeIn(duration: 0.2)) {
                    skipFlash = nil
                }
            }
        }
    }

    private func resetViewport() {
        zoomScale = 1
        lastZoomScale = 1
        panOffset = .zero
        lastPanOffset = .zero
        zoomGestureAnchor = nil
        skipFlash = nil
    }

    private func clampZoom(_ value: CGFloat) -> CGFloat {
        min(max(value, minZoom), maxZoom)
    }

    private func clampPan(_ offset: CGSize, in size: CGSize, scale: CGFloat) -> CGSize {
        guard scale > 1 else { return .zero }
        let maxX = (size.width * (scale - 1)) / 2
        let maxY = (size.height * (scale - 1)) / 2
        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }

    private func timeString(from seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "00:00" }
        let total = Int(seconds.rounded(.down))
        let s = total % 60
        let m = (total / 60) % 60
        let h = total / 3600
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

private struct SkipFlash: Equatable {
    let direction: Int
    let seconds: Double
}

#Preview {
    ContentView()
        .frame(width: 900, height: 600)
}
