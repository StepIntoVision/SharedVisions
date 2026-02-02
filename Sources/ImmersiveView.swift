import SwiftUI
import RealityKit
import AVFoundation
import UIKit

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
                    // Also move from z = -3 towards z = -1 (closer to user)
                    let startY: Float = -0.5
                    let endY: Float = 1.5
                    let startZ: Float = -3.0
                    let endZ: Float = -1.0
                    let progress = Float(videoModel.orbProgress)
                    let currentY = startY + progress * (endY - startY)
                    let currentZ = startZ + progress * (endZ - startZ)
                    orb.position = SIMD3<Float>(0, currentY, currentZ)
                    
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
        
        // Rotate 90 degrees to correct video orientation on device
        skyboxEntity.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 1, 0))
        
        return skyboxEntity
    }
    
    private func createRedOrb() -> ModelEntity {
        // Create a 3D metallic red sphere
        let orbMesh = MeshResource.generateSphere(radius: 0.15)
        
        // Create metallic red material
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0))
        material.metallic = .init(floatLiteral: 1.0)
        material.roughness = .init(floatLiteral: 0.2)
        material.emissiveColor = .init(color: .init(red: 0.5, green: 0.05, blue: 0.05, alpha: 1))
        material.emissiveIntensity = 0.5
        
        let orb = ModelEntity(mesh: orbMesh, materials: [material])
        orb.name = "RedOrb"
        orb.scale = SIMD3<Float>(repeating: 0.3)
        
        // Add some visual interest with a slight rotation component
        orb.components.set(SpinComponent())
        
        return orb
    }
}

// Component to make the orb spin
struct SpinComponent: Component {
    var speed: Float = 1.0
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environmentObject(VideoPlayerModel())
}
