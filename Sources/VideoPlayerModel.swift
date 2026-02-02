import SwiftUI
import AVFoundation
import Combine

@MainActor
class VideoPlayerModel: ObservableObject {
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isPlaying: Bool = false
    @Published var isLoaded: Bool = false
    
    // Orb state (visible between 10-20 seconds)
    @Published var showOrb: Bool = false
    @Published var orbProgress: Double = 0 // 0 to 1 over 10 seconds
    
    private(set) var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    
    var formattedTime: String {
        formatTime(currentTime)
    }
    
    var formattedDuration: String {
        formatTime(duration)
    }
    
    var timecodeString: String {
        let hours = Int(currentTime) / 3600
        let minutes = (Int(currentTime) % 3600) / 60
        let seconds = Int(currentTime) % 60
        let frames = Int((currentTime.truncatingRemainder(dividingBy: 1)) * 30) // Assuming 30fps
        return String(format: "%02d:%02d:%02d:%02d", hours, minutes, seconds, frames)
    }
    
    init() {
        setupPlayer()
    }
    
    private func setupPlayer() {
        // Try to load video in order of preference
        let extensions = ["aivu", "mov", "mp4", "m4v"]
        
        // 1. Check bundle first
        for ext in extensions {
            if let url = Bundle.main.url(forResource: "test", withExtension: ext) {
                print("Loading video from bundle: \(url)")
                loadVideo(from: url)
                return
            }
        }
        
        // 2. Check documents directory (for sideloaded content)
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            for ext in extensions {
                let docURL = documentsPath.appendingPathComponent("test.\(ext)")
                if FileManager.default.fileExists(atPath: docURL.path) {
                    print("Loading video from documents: \(docURL)")
                    loadVideo(from: docURL)
                    return
                }
            }
        }
        
        // 3. Use Apple's sample 360 video for testing
        // This is a publicly available sample immersive video
        if let sampleURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/historic_planet_content_2024-02-28/main.m3u8") {
            print("Loading sample HLS video for testing")
            loadVideo(from: sampleURL)
            return
        }
        
        print("No video found to load")
    }
    
    func loadVideo(from url: URL) {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        player = AVPlayer(playerItem: playerItem)
        
        // Observe player status
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                if item.status == .readyToPlay {
                    self?.isLoaded = true
                    self?.duration = item.duration.seconds.isNaN ? 0 : item.duration.seconds
                }
            }
        }
        
        // Time observer for current time updates
        let interval = CMTime(seconds: 1.0/30.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.updateTime(time.seconds)
            }
        }
    }
    
    private func updateTime(_ time: Double) {
        currentTime = time
        
        // Orb logic: show between 10-20 seconds
        if time >= 10 && time < 20 {
            showOrb = true
            orbProgress = (time - 10) / 10.0 // 0 to 1 over 10 seconds
        } else {
            showOrb = false
            orbProgress = 0
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func seek(by delta: Double) {
        let newTime = max(0, min(duration, currentTime + delta))
        seek(to: newTime)
    }
    
    private func formatTime(_ time: Double) -> String {
        guard !time.isNaN && !time.isInfinite else { return "00:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
    }
}
