import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class PlayerModel {
    let player = AVPlayer()

    var hasVideo = false
    var isPlaying = false
    var isScrubbing = false
    var isBoosting = false

    /// Lasting playback rate chosen by the user (0.1…3.0).
    var baseRate: Float = 1.0

    var currentTime: Double = 0
    var duration: Double = 0

    private var securityScopedURL: URL?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?

    private static let minRate: Float = 0.1
    private static let maxRate: Float = 3.0
    private static let skipSeconds: Double = 5

    var effectiveRate: Float {
        isBoosting ? boostRate(for: baseRate) : baseRate
    }

    func open(url: URL) {
        close()

        let accessed = url.startAccessingSecurityScopedResource()
        if accessed {
            securityScopedURL = url
        }

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        hasVideo = true
        currentTime = 0
        duration = 0
        isPlaying = false
        isBoosting = false

        attachObservers(for: item)

        Task { [weak self] in
            guard let self else { return }
            do {
                let loaded = try await item.asset.load(.duration)
                let seconds = loaded.seconds
                if seconds.isFinite, seconds > 0 {
                    self.duration = seconds
                }
            } catch {
                // Duration may still arrive via the periodic observer.
            }
            self.play()
        }
    }

    func close() {
        detachObservers()
        player.pause()
        player.replaceCurrentItem(with: nil)
        if let securityScopedURL {
            securityScopedURL.stopAccessingSecurityScopedResource()
            self.securityScopedURL = nil
        }
        hasVideo = false
        isPlaying = false
        isBoosting = false
        isScrubbing = false
        currentTime = 0
        duration = 0
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard hasVideo else { return }
        isBoosting = false
        player.playImmediately(atRate: baseRate)
        isPlaying = true
    }

    func pause() {
        isBoosting = false
        player.pause()
        isPlaying = false
    }

    func skipBackward() {
        skip(by: -Self.skipSeconds)
    }

    func skipForward() {
        skip(by: Self.skipSeconds)
    }

    func skip(by seconds: Double) {
        guard hasVideo else { return }
        seek(to: currentTime + seconds)
    }

    func seek(to seconds: Double) {
        guard hasVideo else { return }
        let upper = duration > 0 ? duration : seconds
        let clamped = min(max(0, seconds), upper)
        let time = CMTime(seconds: clamped, preferredTimescale: 600)
        currentTime = clamped

        let wasPlaying = isPlaying
        let rate = effectiveRate
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            Task { @MainActor in
                guard let self, finished else { return }
                if wasPlaying, !self.isScrubbing {
                    self.player.playImmediately(atRate: rate)
                    self.isPlaying = true
                }
            }
        }
    }

    func beginScrubbing() {
        isScrubbing = true
        player.pause()
    }

    func updateScrubbing(to seconds: Double) {
        currentTime = seconds
    }

    func endScrubbing(at seconds: Double) {
        isScrubbing = false
        seek(to: seconds)
    }

    func beginBoost() {
        guard hasVideo, isPlaying, !isBoosting else { return }
        isBoosting = true
        player.rate = boostRate(for: baseRate)
    }

    func endBoost() {
        guard isBoosting else { return }
        isBoosting = false
        if isPlaying {
            player.rate = baseRate
        }
    }

    func setBaseRate(_ rate: Float) {
        baseRate = Self.clampRate(rate)
        guard !isBoosting else { return }
        if isPlaying {
            player.rate = baseRate
        }
    }

    deinit {
        player.pause()
        player.replaceCurrentItem(with: nil)
    }

    private func boostRate(for base: Float) -> Float {
        if base < 2.0 { return 2.0 }
        return Self.maxRate
    }

    private static func clampRate(_ rate: Float) -> Float {
        min(max(rate, minRate), maxRate)
    }

    private func attachObservers(for item: AVPlayerItem) {
        detachObservers()

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.05, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self, !self.isScrubbing else { return }
                let seconds = time.seconds
                if seconds.isFinite {
                    self.currentTime = seconds
                }
                if let itemDuration = self.player.currentItem?.duration.seconds,
                   itemDuration.isFinite,
                   itemDuration > 0 {
                    self.duration = itemDuration
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isPlaying = false
                self.isBoosting = false
                self.player.seek(to: .zero)
                self.currentTime = 0
            }
        }

        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self else { return }
                if item.status == .failed {
                    self.pause()
                }
            }
        }
    }

    private func detachObservers() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
    }
}
