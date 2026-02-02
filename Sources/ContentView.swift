import SwiftUI

struct ContentView: View {
    @EnvironmentObject var videoModel: VideoPlayerModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    @State private var isImmersed = false
    
    var body: some View {
        HStack(spacing: 24) {
            // MARK: - Left Side: Main Documentary
            mainDocumentarySection
            
            // MARK: - Right Side: Profiles
            profilesSection
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Main Documentary Section
    private var mainDocumentarySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Featured badge
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("FEATURED DOCUMENTARY")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(2)
            }
            .foregroundStyle(.secondary)
            
            // Hero image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 280)
                
                VStack(spacing: 16) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text("Shared Visions")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("An Immersive Journey")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Documentary info
            VStack(alignment: .leading, spacing: 12) {
                Text("Shared Visions: The Documentary")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 16) {
                    Label("1h 35m", systemImage: "clock")
                    Label("2024", systemImage: "calendar")
                    Label("Immersive", systemImage: "visionpro")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                Text("Experience the future of storytelling through the eyes of pioneering developers and creative visionaries. This groundbreaking documentary takes you inside the minds shaping spatial computing.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            
            Spacer()
            
            // Play button
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
                HStack(spacing: 12) {
                    Image(systemName: isImmersed ? "xmark.circle.fill" : "play.fill")
                        .font(.title2)
                    Text(isImmersed ? "Exit Experience" : "Begin Experience")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(isImmersed ? .red : .blue)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Profiles Section
    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("PROFILES")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    // View all action
                } label: {
                    Text("View All")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }
            
            // Profile cards
            ScrollView {
                VStack(spacing: 12) {
                    ProfileCard(
                        name: "Sarah Chen",
                        role: "Lead Developer",
                        company: "Spatial Labs",
                        imageName: "person.crop.circle.fill",
                        color: .blue
                    )
                    
                    ProfileCard(
                        name: "Marcus Webb",
                        role: "Creative Director", 
                        company: "Immersive Studios",
                        imageName: "person.crop.circle.fill",
                        color: .purple
                    )
                    
                    ProfileCard(
                        name: "Dr. Aisha Patel",
                        role: "XR Researcher",
                        company: "MIT Media Lab",
                        imageName: "person.crop.circle.fill",
                        color: .orange
                    )
                    
                    ProfileCard(
                        name: "James Liu",
                        role: "Hardware Engineer",
                        company: "Apple",
                        imageName: "person.crop.circle.fill",
                        color: .green
                    )
                    
                    ProfileCard(
                        name: "Coming Soon",
                        role: "More profiles",
                        company: "to be announced",
                        imageName: "plus.circle.fill",
                        color: .gray
                    )
                }
            }
        }
        .frame(width: 280)
    }
}

// MARK: - Profile Card Component
struct ProfileCard: View {
    let name: String
    let role: String
    let company: String
    let imageName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: imageName)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(role)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(company)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Play indicator
            Image(systemName: "play.circle")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environmentObject(VideoPlayerModel())
}
