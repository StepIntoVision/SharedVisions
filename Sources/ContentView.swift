import SwiftUI

struct ContentView: View {
    @EnvironmentObject var videoModel: VideoPlayerModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    @State private var isImmersed = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "visionpro")
                    .font(.system(size: 60))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("Shared Visions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Immersive Documentary Experience")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Status
            if videoModel.isPlaying {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                    Text("Playing")
                        .foregroundStyle(.green)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(videoModel.formattedTime)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            // Controls
            VStack(spacing: 16) {
                Button {
                    Task {
                        if isImmersed {
                            videoModel.pause()
                            await dismissImmersiveSpace()
                            dismissWindow(id: "timecode")
                            isImmersed = false
                        } else {
                            await openImmersiveSpace(id: "ImmersiveVideo")
                            openWindow(id: "timecode")
                            isImmersed = true
                        }
                    }
                } label: {
                    Label(
                        isImmersed ? "Exit Immersive" : "Enter Immersive",
                        systemImage: isImmersed ? "arrow.down.right.and.arrow.up.left" : "visionpro"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isImmersed ? .red : .blue)
                .controlSize(.extraLarge)
                
                if isImmersed {
                    HStack(spacing: 20) {
                        Button {
                            videoModel.seek(by: -10)
                        } label: {
                            Image(systemName: "gobackward.10")
                                .font(.title2)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            if videoModel.isPlaying {
                                videoModel.pause()
                            } else {
                                videoModel.play()
                            }
                        } label: {
                            Image(systemName: videoModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            videoModel.seek(by: 10)
                        } label: {
                            Image(systemName: "goforward.10")
                                .font(.title2)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Seek slider
                    VStack {
                        Slider(
                            value: Binding(
                                get: { videoModel.currentTime },
                                set: { videoModel.seek(to: $0) }
                            ),
                            in: 0...max(videoModel.duration, 1)
                        )
                        
                        HStack {
                            Text(videoModel.formattedTime)
                            Spacer()
                            Text(videoModel.formattedDuration)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environmentObject(VideoPlayerModel())
}
