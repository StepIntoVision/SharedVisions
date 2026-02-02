import SwiftUI
import RealityKit
import AVFoundation
import UIKit

struct ImmersiveView: View {
    @EnvironmentObject var videoModel: VideoPlayerModel
    @State private var skyboxEntity: Entity?
    
    // Animated primitives
    @State private var orbEntity: Entity?
    @State private var cubeEntity: Entity?
    @State private var torusEntity: Entity?
    @State private var pyramidEntity: Entity?
    
    var body: some View {
        RealityView { content in
            // Create and add skybox with video
            if let skybox = await createSkybox() {
                skyboxEntity = skybox
                content.add(skybox)
            }
            
            // Create all animated primitives (initially hidden)
            let orb = createRedOrb()
            orb.isEnabled = false
            orbEntity = orb
            content.add(orb)
            
            let cube = createBlueCube()
            cube.isEnabled = false
            cubeEntity = cube
            content.add(cube)
            
            let torus = createGreenTorus()
            torus.isEnabled = false
            torusEntity = torus
            content.add(torus)
            
            let pyramid = createPurplePyramid()
            pyramid.isEnabled = false
            pyramidEntity = pyramid
            content.add(pyramid)
            
        } update: { content in
            // Update Red Orb (10-20s): rises + approaches
            if let orb = orbEntity {
                orb.isEnabled = videoModel.showOrb
                if videoModel.showOrb {
                    let progress = Float(videoModel.orbProgress)
                    let y = -0.5 + progress * 2.0  // -0.5 to 1.5
                    let z = -3.0 + progress * 2.0  // -3 to -1
                    orb.position = SIMD3<Float>(0, y, z)
                    let pulse = 1.0 + 0.1 * sin(Float(videoModel.currentTime) * 3)
                    orb.scale = SIMD3<Float>(repeating: pulse * 0.3)
                }
                updateParticleEmission(for: orb, isPlaying: videoModel.isPlaying && videoModel.showOrb)
            }
            
            // Update Blue Cube (20-30s): spins + orbits around user
            if let cube = cubeEntity {
                cube.isEnabled = videoModel.showCube
                if videoModel.showCube {
                    let progress = Float(videoModel.cubeProgress)
                    let angle = progress * .pi * 4  // 2 full orbits
                    let radius: Float = 2.0
                    let x = sin(angle) * radius
                    let z = -cos(angle) * radius
                    let y: Float = 0.5 + 0.3 * sin(progress * .pi * 6)  // bobbing
                    cube.position = SIMD3<Float>(x, y, z)
                    cube.orientation = simd_quatf(angle: angle * 2, axis: SIMD3<Float>(1, 1, 0).normalized)
                }
                updateParticleEmission(for: cube, isPlaying: videoModel.isPlaying && videoModel.showCube)
            }
            
            // Update Green Torus (30-40s): pulses + bounces
            if let torus = torusEntity {
                torus.isEnabled = videoModel.showTorus
                if videoModel.showTorus {
                    let progress = Float(videoModel.torusProgress)
                    let bounceY = abs(sin(progress * .pi * 5)) * 1.5  // bouncing
                    torus.position = SIMD3<Float>(0, bounceY, -2.5)
                    let pulseScale = 0.4 + 0.15 * sin(progress * .pi * 8)
                    torus.scale = SIMD3<Float>(repeating: pulseScale)
                    torus.orientation = simd_quatf(angle: progress * .pi * 4, axis: [0, 1, 0])
                }
                updateParticleEmission(for: torus, isPlaying: videoModel.isPlaying && videoModel.showTorus)
            }
            
            // Update Purple Pyramid (40-50s): rotates + spirals inward
            // EXAMPLE: Animation with Hold Phase
            // ─────────────────────────────────────────────────────────────────
            // This primitive demonstrates the "animate then hold" pattern:
            //
            //   40-50s: Animation plays (pyramidProgress: 0 → 1)
            //   50-60s: Hold at final position (pyramidProgress locked at 1)
            //
            // During the hold phase:
            //   - showPyramid remains true (object stays visible)
            //   - pyramidHolding = true (signals we're in hold mode)
            //   - pyramidProgress = 1.0 (locked at final position)
            //   - Particles continue emitting (adds visual interest)
            //
            // This pattern is useful when you want viewers to have time
            // to appreciate an object after it finishes animating.
            // ─────────────────────────────────────────────────────────────────
            if let pyramid = pyramidEntity {
                pyramid.isEnabled = videoModel.showPyramid
                if videoModel.showPyramid {
                    let progress = Float(videoModel.pyramidProgress)
                    let spiralAngle = progress * .pi * 6  // 3 rotations
                    let radius = 3.0 - progress * 2.5  // spiral in from 3 to 0.5
                    let x = sin(spiralAngle) * radius
                    let z = -cos(spiralAngle) * radius
                    let y = 0.5 + progress * 1.0  // rise slightly
                    pyramid.position = SIMD3<Float>(x, y, z)
                    pyramid.orientation = simd_quatf(angle: progress * .pi * 8, axis: SIMD3<Float>(0, 1, 1).normalized)
                    
                    // During hold phase, particles keep emitting for visual interest
                    // You could also reduce birthRate here for a "settling" effect
                }
                updateParticleEmission(for: pyramid, isPlaying: videoModel.isPlaying && videoModel.showPyramid)
            }
        }
        .onAppear {
            videoModel.play()
        }
        .onDisappear {
            videoModel.pause()
        }
    }
    
    // MARK: - Skybox
    
    @MainActor
    private func createSkybox() async -> Entity? {
        guard let player = videoModel.player else {
            print("No video player available")
            return nil
        }
        
        let skyboxMesh = MeshResource.generateSphere(radius: 1000)
        let videoMaterial = VideoMaterial(avPlayer: player)
        let skyboxEntity = ModelEntity(mesh: skyboxMesh, materials: [videoMaterial])
        skyboxEntity.scale = SIMD3<Float>(x: -1, y: 1, z: 1)
        skyboxEntity.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 1, 0))
        
        return skyboxEntity
    }
    
    // MARK: - Red Orb (10-20s) - Fire particles
    
    private func createRedOrb() -> Entity {
        let container = Entity()
        container.name = "RedOrb"
        
        // Metallic red sphere
        let orbMesh = MeshResource.generateSphere(radius: 0.15)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0))
        material.metallic = .init(floatLiteral: 1.0)
        material.roughness = .init(floatLiteral: 0.2)
        material.emissiveColor = .init(color: .init(red: 1.0, green: 0.2, blue: 0.1, alpha: 1))
        material.emissiveIntensity = 0.8
        
        let orb = ModelEntity(mesh: orbMesh, materials: [material])
        container.addChild(orb)
        
        // Fire particles
        var particles = ParticleEmitterComponent()
        particles.emitterShape = .sphere
        particles.emitterShapeSize = [0.2, 0.2, 0.2]
        particles.birthLocation = .surface
        particles.birthDirection = .normal
        particles.speed = 0.15
        
        particles.mainEmitter.birthRate = 150
        particles.mainEmitter.lifeSpan = 0.8
        particles.mainEmitter.size = 0.03
        particles.mainEmitter.blendMode = .additive
        particles.mainEmitter.opacityCurve = .quickFadeInOut
        particles.mainEmitter.color = .evolving(
            start: .single(.init(Color(red: 1, green: 0.8, blue: 0.2))),
            end: .single(.init(Color(red: 1, green: 0.1, blue: 0).opacity(0)))
        )
        
        let particleEntity = Entity()
        particleEntity.components.set(particles)
        container.addChild(particleEntity)
        
        return container
    }
    
    // MARK: - Blue Cube (20-30s) - Ice sparkle particles
    
    private func createBlueCube() -> Entity {
        let container = Entity()
        container.name = "BlueCube"
        
        // Metallic blue cube
        let cubeMesh = MeshResource.generateBox(size: 0.25, cornerRadius: 0.02)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(red: 0.1, green: 0.4, blue: 0.9, alpha: 1.0))
        material.metallic = .init(floatLiteral: 0.9)
        material.roughness = .init(floatLiteral: 0.1)
        material.emissiveColor = .init(color: .init(red: 0.2, green: 0.5, blue: 1.0, alpha: 1))
        material.emissiveIntensity = 0.6
        
        let cube = ModelEntity(mesh: cubeMesh, materials: [material])
        container.addChild(cube)
        
        // Ice sparkle particles
        var particles = ParticleEmitterComponent()
        particles.emitterShape = .box
        particles.emitterShapeSize = [0.3, 0.3, 0.3]
        particles.birthLocation = .surface
        particles.speed = 0.05
        
        particles.mainEmitter.birthRate = 80
        particles.mainEmitter.lifeSpan = 1.2
        particles.mainEmitter.size = 0.015
        particles.mainEmitter.blendMode = .additive
        particles.mainEmitter.opacityCurve = .gradualFadeInOut
        particles.mainEmitter.color = .evolving(
            start: .single(.init(Color.white)),
            end: .single(.init(Color(red: 0.5, green: 0.8, blue: 1.0).opacity(0)))
        )
        
        let particleEntity = Entity()
        particleEntity.components.set(particles)
        container.addChild(particleEntity)
        
        return container
    }
    
    // MARK: - Green Torus (30-40s) - Spiral particles
    
    private func createGreenTorus() -> Entity {
        let container = Entity()
        container.name = "GreenTorus"
        
        // Glowing green torus
        let torusMesh = MeshResource.generateSphere(radius: 0.2) // Using sphere as torus approximation
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(red: 0.1, green: 0.8, blue: 0.3, alpha: 1.0))
        material.metallic = .init(floatLiteral: 0.7)
        material.roughness = .init(floatLiteral: 0.3)
        material.emissiveColor = .init(color: .init(red: 0.2, green: 1.0, blue: 0.4, alpha: 1))
        material.emissiveIntensity = 1.0
        
        let torus = ModelEntity(mesh: torusMesh, materials: [material])
        torus.scale = SIMD3<Float>(1.5, 0.5, 1.5) // Flatten to torus-like shape
        container.addChild(torus)
        
        // Spiral upward particles
        var particles = ParticleEmitterComponent()
        particles.emitterShape = .cylinder
        particles.emitterShapeSize = [0.4, 0.1, 0.4]
        particles.birthLocation = .surface
        particles.birthDirection = .normal
        particles.speed = 0.2
        particles.emissionDirection = [0, 1, 0]
        
        particles.mainEmitter.birthRate = 200
        particles.mainEmitter.lifeSpan = 1.5
        particles.mainEmitter.size = 0.02
        particles.mainEmitter.blendMode = .additive
        particles.mainEmitter.opacityCurve = .easeFadeOut
        particles.mainEmitter.acceleration = [0, 0.5, 0]
        particles.mainEmitter.color = .evolving(
            start: .single(.init(Color(red: 0.5, green: 1.0, blue: 0.5))),
            end: .single(.init(Color(red: 0, green: 0.5, blue: 0.2).opacity(0)))
        )
        
        let particleEntity = Entity()
        particleEntity.components.set(particles)
        container.addChild(particleEntity)
        
        return container
    }
    
    // MARK: - Purple Pyramid (40-50s) - Electric particles
    
    private func createPurplePyramid() -> Entity {
        let container = Entity()
        container.name = "PurplePyramid"
        
        // Glowing purple pyramid (using cone as approximation)
        let pyramidMesh = MeshResource.generateCone(height: 0.35, radius: 0.2)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(red: 0.6, green: 0.1, blue: 0.9, alpha: 1.0))
        material.metallic = .init(floatLiteral: 0.8)
        material.roughness = .init(floatLiteral: 0.15)
        material.emissiveColor = .init(color: .init(red: 0.8, green: 0.3, blue: 1.0, alpha: 1))
        material.emissiveIntensity = 1.2
        
        let pyramid = ModelEntity(mesh: pyramidMesh, materials: [material])
        container.addChild(pyramid)
        
        // Electric crackling particles
        var particles = ParticleEmitterComponent()
        particles.emitterShape = .cone
        particles.emitterShapeSize = [0.3, 0.4, 0.3]
        particles.birthLocation = .volume
        particles.speed = 0.3
        
        particles.mainEmitter.birthRate = 120
        particles.mainEmitter.lifeSpan = 0.4
        particles.mainEmitter.lifeSpanVariation = 0.2
        particles.mainEmitter.size = 0.025
        particles.mainEmitter.sizeVariation = 0.015
        particles.mainEmitter.blendMode = .additive
        particles.mainEmitter.opacityCurve = .quickFadeInOut
        particles.mainEmitter.color = .evolving(
            start: .single(.init(Color(red: 1, green: 0.5, blue: 1))),
            end: .single(.init(Color(red: 0.5, green: 0.2, blue: 1).opacity(0)))
        )
        
        // Spawned trail particles
        var spawned = ParticleEmitterComponent.ParticleEmitter()
        spawned.birthRate = 50
        spawned.lifeSpan = 0.3
        spawned.size = 0.01
        spawned.blendMode = .additive
        spawned.opacityCurve = .quickFadeInOut
        spawned.color = .constant(.single(.init(Color.white)))
        
        particles.spawnedEmitter = spawned
        particles.spawnOccasion = .onUpdate
        
        let particleEntity = Entity()
        particleEntity.components.set(particles)
        container.addChild(particleEntity)
        
        return container
    }
    
    // MARK: - Particle Control
    
    private func updateParticleEmission(for entity: Entity, isPlaying: Bool) {
        // Find particle emitter in children and pause/resume
        for child in entity.children {
            if var particles = child.components[ParticleEmitterComponent.self] {
                particles.isEmitting = isPlaying
                child.components[ParticleEmitterComponent.self] = particles
            }
        }
    }
}

// Helper extension for normalizing vectors
extension SIMD3 where Scalar == Float {
    var normalized: SIMD3<Float> {
        let length = sqrt(x*x + y*y + z*z)
        return length > 0 ? self / length : self
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environmentObject(VideoPlayerModel())
}
