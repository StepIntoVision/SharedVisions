import SwiftUI
import RealityKit
import AVFoundation

struct ImmersiveView: View {
    @EnvironmentObject var videoModel: VideoPlayerModel
    @State private var orbEntity: ModelEntity?
    @State private var skyboxEntity: Entity?
    
    var body: some View {
        RealityView { content in
            // Create and add skybox with video
            if let skybox = await createSkybox() {
                skyboxEntity = skybox
                content.add(skybox)
            }
            
            // Create red orb (initially hidden)
            let orb = createRedOrb()
            orb.isEnabled = false
            orbEntity = orb
            content.add(orb)
            
        } update: { content in
            // Update orb visibility and position based on video time
            if let orb = orbEntity {
                orb.isEnabled = videoModel.showOrb
                
                if videoModel.showOrb {
                    // Start at y = -0.5, move up to y = 1.5 over 10 seconds
                    // Position in front of user at z = -3
                    let startY: Float = -0.5
                    let endY: Float = 1.5
                    let currentY = startY + Float(videoModel.orbProgress) * (endY - startY)
                    orb.position = SIMD3<Float>(0, currentY, -3)
                    
                    // Also pulse the orb slightly
                    let pulse = 1.0 + 0.1 * sin(Float(videoModel.currentTime) * 3)
                    orb.scale = SIMD3<Float>(repeating: pulse * 0.3)
                }
            }
        }
        .onAppear {
            videoModel.play()
        }
        .onDisappear {
            videoModel.pause()
        }
    }
    
    @MainActor
    private func createSkybox() async -> Entity? {
        guard let player = videoModel.player else {
            print("No video player available")
            return nil
        }
        
        // Create a large sphere for the skybox
        let skyboxMesh = MeshResource.generateSphere(radius: 1000)
        
        // Create video material from AVPlayer
        let videoMaterial = VideoMaterial(avPlayer: player)
        
        // Create the skybox entity
        let skyboxEntity = ModelEntity(mesh: skyboxMesh, materials: [videoMaterial])
        
        // Flip inside-out so video displays on inner surface
        skyboxEntity.scale = SIMD3<Float>(x: -1, y: 1, z: 1)
        
        return skyboxEntity
    }
    
    private func createRedOrb() -> ModelEntity {
        // Create a glowing red sphere
        let orbMesh = MeshResource.generateSphere(radius: 0.15)
        
        // Create emissive red material
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .red)
        material.emissiveColor = .init(color: .init(red: 1, green: 0.2, blue: 0.1, alpha: 1))
        material.emissiveIntensity = 2.0
        
        let orb = ModelEntity(mesh: orbMesh, materials: [material])
        orb.name = "RedOrb"
        orb.scale = SIMD3<Float>(repeating: 0.3)
        
        return orb
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environmentObject(VideoPlayerModel())
}
