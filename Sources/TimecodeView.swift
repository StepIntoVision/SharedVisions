import SwiftUI

struct TimecodeView: View {
    @EnvironmentObject var videoModel: VideoPlayerModel
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.dismissWindow) var dismissWindow
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        VStack(spacing: 12) {
            // Timecode display
            Text(videoModel.timecodeString)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            
            // Play/Pause button
            Button {
                if videoModel.isPlaying {
                    videoModel.pause()
                } else {
                    videoModel.play()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: videoModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                    Text(videoModel.isPlaying ? "Pause" : "Play")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(videoModel.isPlaying ? .orange : .green)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.blue)
                        .frame(
                            width: videoModel.duration > 0 
                                ? geometry.size.width * (videoModel.currentTime / videoModel.duration)
                                : 0,
                            height: 8
                        )
                }
            }
            .frame(height: 8)
            
            // Time labels
            HStack {
                Text(videoModel.formattedTime)
                Spacer()
                Text(videoModel.formattedDuration)
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
            
            // Active primitive indicator
            if let activePrimitive = activePrimitiveInfo {
                HStack {
                    Circle()
                        .fill(activePrimitive.color)
                        .frame(width: 8, height: 8)
                    Text(activePrimitive.name)
                        .font(.caption)
                        .foregroundStyle(activePrimitive.color)
                }
            }
            
            Divider()
                .background(.white.opacity(0.3))
            
            // Exit button
            Button {
                Task {
                    videoModel.pause()
                    videoModel.seek(to: 0)
                    await dismissImmersiveSpace()
                    dismissWindow(id: "timecode")
                    openWindow(id: "main")
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                    Text("Exit Experience")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(20)
        .frame(minWidth: 280)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var activePrimitiveInfo: (name: String, color: Color)? {
        if videoModel.showOrb {
            return ("Red Orb", .red)
        } else if videoModel.showCube {
            return ("Blue Cube", .blue)
        } else if videoModel.showTorus {
            return ("Green Torus", .green)
        } else if videoModel.showPyramid {
            // Show different label during hold phase
            if videoModel.pyramidHolding {
                return ("Purple Pyramid (Hold)", .purple)
            }
            return ("Purple Pyramid", .purple)
        }
        return nil
    }
}

#Preview(windowStyle: .plain) {
    TimecodeView()
        .environmentObject(VideoPlayerModel())
}
