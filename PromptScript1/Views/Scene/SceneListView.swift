import SwiftUI

// This view displays a list of all scenes in the current project.
// FIX: This version uses a safer ForEach loop to prevent runtime crashes.
struct SceneListView: View {
    @Binding var scenes: [VideoScene]
    let characters: [Character]
    let project: Project
    
    @State private var showingAddScene = false
    
    // The unsafe bindingForScene function has been removed.
    
    var body: some View {
        ZStack {
                TypewriterTheme.Colors.Scenes.background
                    .ignoresSafeArea()
                
                if scenes.isEmpty {
                    emptyStateView
                } else {
                    sceneListView
                }
            }
            .navigationTitle("SCENE LIST")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TypewriterTheme.Colors.Scenes.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SCENE LIST")
                        .font(.custom("Courier New", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(TypewriterTheme.Colors.Scenes.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddScene = true }) {
                        Image(systemName: TypewriterIcons.add)
                            .font(.title2)
                            .foregroundColor(TypewriterTheme.Colors.Scenes.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddScene) {
                AddSceneView(scenes: $scenes, characters: characters)
            }
    }
    
    private func deleteScenes(at offsets: IndexSet) {
        scenes.remove(atOffsets: offsets)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: TypewriterIcons.sceneEmpty)
                .font(.system(size: 60))
                .foregroundColor(TypewriterTheme.Colors.Scenes.primary)
            
            Text("No Scenes Yet")
                .typewriterTitle(size: 24)
            
            Text("Create compelling scenes\nfor your video production.")
                .typewriterText(size: 16, color: TypewriterTheme.Colors.typewriterGray)
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddScene = true }) {
                HStack {
                    Image(systemName: TypewriterIcons.add)
                    Text("Create First Scene")
                }
                .typewriterButton(color: TypewriterTheme.Colors.Scenes.primary)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(1.0)
            .animation(.typewriterBounce, value: showingAddScene)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var sceneListView: some View {
        List {
            ForEach(scenes.indices, id: \.self) { index in
                NavigationLink(destination: SceneDetailView(scene: $scenes[index], characters: characters, project: project)) {
                    SceneRowView(scene: scenes[index], characters: characters)
                }
                .listRowBackground(Color.white)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteScenes)
        }
        .listStyle(PlainListStyle())
    }
}


// MARK: - Scene Row Component
struct SceneRowView: View {
    let scene: VideoScene
    let characters: [Character]
    
    var body: some View {
        HStack(spacing: 15) {
            // Scene thumbnail or colorful placeholder
            if let imageData = scene.generatedImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: TypewriterTheme.CornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: TypewriterTheme.CornerRadius.medium)
                            .stroke(TypewriterTheme.Colors.Scenes.primary, lineWidth: 2)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: TypewriterTheme.CornerRadius.medium)
                        .fill(LinearGradient(
                            colors: [TypewriterTheme.Colors.Scenes.primary.opacity(0.8), 
                                   TypewriterTheme.Colors.Scenes.primary.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    Image(systemName: TypewriterIcons.scene)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
            }
            
            // Scene details
            VStack(alignment: .leading, spacing: 6) {
                Text(scene.title.isEmpty ? "Untitled Scene" : scene.title)
                    .typewriterText(size: 20, color: TypewriterTheme.Colors.inkBlack)
                    .fontWeight(.bold)
                
                let emotionText = scene.emotion == .custom ? scene.customEmotion : scene.emotion.rawValue
                if !emotionText.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "theatermasks")
                            .foregroundColor(TypewriterTheme.Colors.Scenes.secondary)
                            .font(.caption)
                        Text(emotionText)
                            .typewriterText(size: 15, color: TypewriterTheme.Colors.Scenes.secondary)
                    }
                }
                
                if !scene.selectedCharacters.isEmpty {
                    let characterNames = scene.selectedCharacters.compactMap { characterID in
                        characters.first { $0.id == characterID }?.basicInfo.name
                    }.joined(separator: ", ")
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .foregroundColor(TypewriterTheme.Colors.Scenes.accent)
                            .font(.caption)
                        Text(characterNames)
                            .typewriterText(size: 14, color: TypewriterTheme.Colors.Scenes.accent)
                            .lineLimit(2)
                    }
                }
                
                // Add a "SCENE" label
                HStack {
                    Text("SCENE \(scene.timeline.count) EVENTS")
                        .font(TypewriterTheme.Fonts.caption(10))
                        .foregroundColor(.white)
                        .padding(.horizontal, TypewriterTheme.Spacing.small)
                        .padding(.vertical, 2)
                        .background(TypewriterTheme.Colors.Scenes.primary)
                        .cornerRadius(TypewriterTheme.CornerRadius.small)
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, TypewriterTheme.Spacing.large)
        .padding(.vertical, TypewriterTheme.Spacing.medium)
        .background(Color.white)
        .cornerRadius(TypewriterTheme.CornerRadius.large)
        .shadow(color: TypewriterTheme.Shadows.light, radius: 1, x: 0, y: 1)
    }
}

