import SwiftUI

// This view displays the detailed information for a single scene.
// Fixed with proper safe area handling, using existing InfoViews components.
struct SceneDetailViewNew: View {
    @Binding var scene: VideoScene
    let characters: [Character] // The full list of characters in the project
    let project: Project
    
    @State private var showingEditScene = false
    
    private var typewriterFont: Font = .custom("Courier New", size: 16)

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                
                // Simple header - no image to avoid clipping
                headerSection
                
                InfoSection(title: "Scene Overview") {
                    if !scene.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description:")
                                .font(typewriterFont)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                            Text(scene.description)
                                .font(typewriterFont)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    InfoRow(label: "Setting", value: scene.setting)
                    let emotionText = scene.emotion == .custom ? scene.customEmotion : scene.emotion.rawValue
                    InfoRow(label: "Emotion", value: emotionText)
                    InfoRow(label: "Shot Mode", value: scene.shotMode.rawValue)
                    let establishingShotText = scene.establishingShot == .custom ? scene.customEstablishingShot : scene.establishingShot.rawValue
                    InfoRow(label: "Establishing Shot", value: establishingShotText)
                }
                
                InfoSection(title: "Timeline") {
                    if scene.timeline.isEmpty {
                        Text("No events in this scene yet. Tap the edit icon to add dialogue and actions.")
                            .font(typewriterFont)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    } else {
                        ForEach(scene.timeline) { event in
                            EnhancedTimelineEventRowView(event: event, characters: characters)
                                .padding(.bottom, 8)
                        }
                    }
                }
                
                // Bottom spacer for safe scrolling
                Color.clear.frame(height: 60)
            }
            .padding(.horizontal, 16) // Proper horizontal padding
            .padding(.top, 8)
        }
        .navigationTitle(scene.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditScene = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
        }
        .sheet(isPresented: $showingEditScene) {
            EditSceneTimelineView(scene: $scene, characters: characters)
        }
    }
    
    // MARK: - Simple Header Section (No image to avoid clipping)
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scene Details")
                .font(.custom("Courier New", size: 20))
                .foregroundColor(.green)
                .fontWeight(.bold)
            
            if scene.generatedImageData != nil {
                HStack(spacing: 6) {
                    Image(systemName: "photo.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Reference image available")
                        .font(.custom("Courier New", size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .shadow(color: .green.opacity(0.2), radius: 4, x: 0, y: 2)
        .cornerRadius(12)
    }
}
