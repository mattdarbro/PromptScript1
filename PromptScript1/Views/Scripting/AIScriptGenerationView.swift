import SwiftUI

// Enhanced AI Script Generation with rich story development tools
struct AIScriptGenerationView: View {
    var project: Project
    @ObservedObject var secureStorage: SecureStorage
    let onScenesGenerated: ([VideoScene]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    // Video Style (now editable in this view)
    @State private var selectedVideoStyle: VideoStyle
    @State private var customVideoStyleText: String
    
    // Story Development
    @State private var logline: String = ""
    @State private var selectedStoryStructure: StoryStructure = .saveTheCat
    @State private var primaryEmotion: EmotionalTone = .dramatic
    @State private var setting: String = ""
    @State private var selectedGenres: Set<String> = []
    @State private var cinematographyNotes: String = ""
    
    // Character selection
    @State private var selectedCharacterNames: Set<String> = []
    
    // Generation state
    @State private var isGenerating = false
    @State private var generationError = ""
    @State private var generatedScenes: [VideoScene] = []
    @State private var showingResults = false
    
    private let availableGenres = [
        "Action", "Adventure", "Comedy", "Drama", "Horror", "Romance",
        "Sci-Fi", "Fantasy", "Thriller", "Mystery", "Documentary",
        "Musical", "Western", "Crime", "Family", "Animation"
    ]
    
    // Use preferred provider from settings
    private var preferredProvider: AIProvider {
        secureStorage.preferredScriptGenerationProvider
    }
    
    init(project: Project, secureStorage: SecureStorage, onScenesGenerated: @escaping ([VideoScene]) -> Void) {
        self.project = project
        self.secureStorage = secureStorage
        self.onScenesGenerated = onScenesGenerated
        
        // Initialize with project's current video style
        self._selectedVideoStyle = State(initialValue: project.videoStyle)
        self._customVideoStyleText = State(initialValue: project.customVideoStyle)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    providerSection
                    videoStyleSection
                    storyDevelopmentSection
                    genreSelectionSection
                    settingAndAtmosphereSection
                    characterSelectionSection
                    cinematographySection
                    
                    if !generationError.isEmpty {
                        errorDisplay
                    }
                    
                    generateButton
                    Spacer()
                }
                .padding()
            }
            // ✨ NEW: Add keyboard dismissal functionality
            .scrollDismissesKeyboard(.interactively)  // Dismiss when scrolling
            .navigationTitle("Script Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Script Generator")
                        .font(.custom("Courier New", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(TypewriterTheme.Colors.Script.primary)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        dismiss() 
                    }
                    .font(.custom("Courier New", size: 16))
                    .foregroundColor(.primary)
                }
                // ✨ NEW: Add Done button for keyboard
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                }
            }
        }
        .sheet(isPresented: $showingResults) {
            ScriptGenerationResultsView(
                generatedScenes: $generatedScenes,
                project: project,
                onSaveToProject: { scenes in
                    updateProjectVideoStyle()
                    onScenesGenerated(scenes)
                    dismiss()
                }
            )
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Script Generator")
                .font(.custom("Courier New", size: 32))
                .fontWeight(.bold)
                .foregroundColor(TypewriterTheme.Colors.Script.primary)
            Text("Create a compelling 1-minute script with professional story structure")
                .font(.custom("Courier New", size: 16))
                .foregroundColor(.secondary)
        }
    }
    
    private var providerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(TypewriterTheme.Colors.Script.primary)
                Text("AI Provider: \(preferredProvider.rawValue)")
                    .font(.custom("Courier New", size: 18))
                    .fontWeight(.semibold)
                Spacer()
                if preferredProvider.isConfigured {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(TypewriterTheme.Colors.Script.primary)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }
            
            if !preferredProvider.isConfigured {
                Text("Configure \(preferredProvider.rawValue) API key in Settings to generate scripts")
                    .font(.custom("Courier New", size: 12))
                    .foregroundColor(.red)
            } else {
                Text("Using your preferred provider from Settings")
                    .font(.custom("Courier New", size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(TypewriterTheme.Colors.Script.cardBackground)
        .cornerRadius(12)
        .shadow(color: TypewriterTheme.Colors.Script.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var videoStyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Video Style")
                .font(.custom("Courier New", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(TypewriterTheme.Colors.Script.primary)
            
            Picker("Video Style", selection: $selectedVideoStyle) {
                ForEach(VideoStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .background(TypewriterTheme.Colors.Script.cardBackground)
            .cornerRadius(8)
            
            if selectedVideoStyle == .custom {
                TextField("Describe your custom video style...", text: $customVideoStyleText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(2...4)
            }
            
            Text("This will influence the AI's creative direction and will update your project settings")
                .font(.custom("Courier New", size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private var storyDevelopmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Story Development")
                .font(.custom("Courier New", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(TypewriterTheme.Colors.Script.primary)
            
            // Logline
            VStack(alignment: .leading, spacing: 8) {
                Text("Logline")
                    .font(.custom("Courier New", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(TypewriterTheme.Colors.Script.primary)
                TextField("A [character] must [objective] or else [stakes].", text: $logline, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(2...4)
                Text("One sentence that captures your story's essence")
                    .font(.custom("Courier New", size: 12))
                    .foregroundColor(.secondary)
            }
            
            // Primary Emotion
            VStack(alignment: .leading, spacing: 8) {
                Text("Primary Emotion")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Picker("Emotion", selection: $primaryEmotion) {
                    ForEach(EmotionalTone.allCases, id: \.self) { emotion in
                        Text(emotion.rawValue).tag(emotion)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                Text("The main emotional journey you want the audience to experience")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Story Structure
            VStack(alignment: .leading, spacing: 8) {
                Text("Story Structure")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Structure", selection: $selectedStoryStructure) {
                    ForEach(StoryStructure.allCases, id: \.self) { structure in
                        Text(structure.rawValue).tag(structure)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // This now needs to be implemented in your StoryStructure enum
                // Text(selectedStoryStructure.description)
                //     .font(.caption)
                //     .foregroundColor(.secondary)
                //     .padding(.horizontal, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedStoryStructure.beats, id: \.self) { beat in
                            Text(beat)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
    }
    
    private var genreSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Genres")
                .font(.headline)
            Text("Select genres to blend (1-3 recommended)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(availableGenres, id: \.self) { genre in
                    Button(action: {
                        if selectedGenres.contains(genre) {
                            selectedGenres.remove(genre)
                        } else {
                            selectedGenres.insert(genre)
                        }
                    }) {
                        Text(genre)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedGenres.contains(genre) ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedGenres.contains(genre) ? .white : .primary)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }
    
    private var settingAndAtmosphereSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Setting & Atmosphere")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Location & Time")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("e.g., A cozy coffee shop in downtown Seattle, late afternoon during winter", text: $setting, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(2...4)
                Text("Where and when does your story take place? Include time of day, season, mood.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var characterSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Characters")
                .font(.headline)
            
            if project.characters.isEmpty {
                VStack(spacing: 8) {
                    Text("No characters in this project")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Text("The AI will create characters for the script based on your story requirements")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text("Select existing characters to include (optional - AI can create new ones)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(project.characters) { character in
                    CharacterSelectionRow(character: character, selectedCharacterNames: $selectedCharacterNames)
                }
            }
        }
    }
    
    private var cinematographySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cinematography & Visual Style")
                .font(.headline)
            TextField("e.g., Warm lighting, intimate close-ups, handheld camera for energy, soft focus for romance", text: $cinematographyNotes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
            Text("Visual style, lighting, camera movements, and shot types to guide the AI")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var errorDisplay: some View {
        Text(generationError)
            .font(.caption)
            .foregroundColor(.red)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var generateButton: some View {
        Button(action: generateScript) {
            HStack {
                if isGenerating {
                    ProgressView().scaleEffect(0.8)
                    Text("Generating Script with \(preferredProvider.rawValue)...")
                } else {
                    Image(systemName: "wand.and.stars")
                    Text("Generate AI Script")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canGenerate ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canGenerate || isGenerating)
    }

    // MARK: - Logic
    
    private var canGenerate: Bool {
        !selectedGenres.isEmpty &&
        !setting.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !logline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        preferredProvider.isConfigured
    }
    
    private var selectedCharacters: [Character] {
        project.characters.filter { selectedCharacterNames.contains($0.basicInfo.name) }
    }
    
    private func updateProjectVideoStyle() {
        // This is a placeholder for your project update logic
        print("Video style would be updated to: \(selectedVideoStyle)")
    }
    
    private func generateScript() {
        guard canGenerate else { return }
        isGenerating = true
        generationError = ""
        
        // FINAL CORRECTION: Added the missing parameters to this initializer call.
        let enhancedInput = EnhancedScriptGenerationInput(
            logline: logline.trimmingCharacters(in: .whitespacesAndNewlines),
            duration: 60, // Default duration of 60 seconds
            sceneDuration: 8, // Default scene duration of 8 seconds
            videoStyle: selectedVideoStyle,
            customVideoStyle: selectedVideoStyle == .custom ? customVideoStyleText : nil,
            storyStructure: selectedStoryStructure,
            primaryEmotion: primaryEmotion,
            genres: Array(selectedGenres),
            setting: setting.trimmingCharacters(in: .whitespacesAndNewlines),
            cinematographyNotes: cinematographyNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            characters: selectedCharacters
        )
        
        let apiKey = getAPIKey(for: preferredProvider)
        let scriptService = MultiAIScriptGenerationService()
        
        scriptService.generateScript(
            input: enhancedInput,
            provider: preferredProvider,
            apiKey: apiKey
        ) { result in
            DispatchQueue.main.async {
                self.isGenerating = false
                switch result {
                case .success(let scenes):
                    self.generatedScenes = scenes
                    self.showingResults = true
                case .failure(let error):
                    print("Detailed Error: \(error)")
                    self.generationError = "Script generation failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
     private func getAPIKey(for provider: AIProvider) -> String {
     switch provider {
     case .openAI: return secureStorage.openAIKey
     case .claude: return secureStorage.claudeKey
     //case .gemini: return secureStorage.geminiKey
     }
     }
     }
     
