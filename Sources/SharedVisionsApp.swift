import SwiftUI

@main
struct SharedVisionsApp: App {
    @State private var immersionStyle: ImmersionStyle = .full
    @StateObject private var videoModel = VideoPlayerModel()
    
    var body: some Scene {
        // Main control window
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(videoModel)
        }
        .windowStyle(.plain)
        .defaultSize(CGSize(width: 900, height: 620))
        
        // Timecode overlay window
        WindowGroup(id: "timecode") {
            TimecodeView()
                .environmentObject(videoModel)
        }
        .windowStyle(.plain)
        .defaultSize(CGSize(width: 300, height: 140))
        
        // Immersive video space
        ImmersiveSpace(id: "ImmersiveVideo") {
            ImmersiveView()
                .environmentObject(videoModel)
        }
        .immersionStyle(selection: $immersionStyle, in: .full)
    }
}
