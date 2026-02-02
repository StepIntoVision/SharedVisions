import SwiftUI

struct TimecodeView: View {
    @EnvironmentObject var videoModel: VideoPlayerModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Timecode display
            Text(videoModel.timecodeString)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            
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
            
            // Orb indicator
            if videoModel.showOrb {
                HStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("Orb Active")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
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
}

#Preview(windowStyle: .plain) {
    TimecodeView()
        .environmentObject(VideoPlayerModel())
}
