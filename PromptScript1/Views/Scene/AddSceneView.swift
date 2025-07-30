import SwiftUI
import PhotosUI

// This view is a sheet for creating a new scene from scratch.
// Updated to use settings-based AI provider selection (no manual picker)
struct AddSceneView: View {
    @Binding var scenes: [VideoScene]
    let characters: [Character]
    @Environment(\.dismiss) private var dismiss
    
    @State private var newScene = VideoScene()
    @State private var selectedCharacterIDs: Set<UUID> = []
    
    // State variables for the photo picker and analysis
    @State private var selectedSettingPhoto: PhotosPickerItem?
    @State private var selectedSettingImageData: Data?
    @State private var isAnalyzingSetting = false
    @State private var settingAnalysisError = ""
    
    // State for the "Add New Event" form
    @State private var newEventCharacterID: UUID?
    @State private var newEventType: EventType = .dialogue
    @State private var newEventContent: String = ""
    @State private var newEventConnectingWord: ConnectingWord = .then
    @State private var newCustomConnectingWord: String = ""
    @State private var newEventDialogueType: DialogueType = .says
    @State private var newCustomDialogueType: String = ""
    
    @StateObject private var secureStorage = SecureStorage.shared
    private let imageAnalysisService = MultiAIImageAnalysisService()
    
    // Use preferred provider from settings
    private var preferredProvider: AIProvider {
        secureStorage.preferredCharacterAnalysisProvider
    }
    
    var body: some View {
        NavigationView {
            Form {
                photoAnalysisSection
                sceneInfoSection
                charactersSection
                timelineEventsSection
                
                // ADD NEW EVENT SECTION
                Section(header: Text("Add New Event")
                    .font(.custom("Courier New", size: 16))
                    .foregroundColor(.green)) {
                    // Event Type Picker
                    Picker("Event Type", selection: $newEventType) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                                .font(.custom("Courier New", size: 14))
                                .tag(type)
                        }
                    }
                    .font(.custom("Courier New", size: 14))
                    .onChange(of: newEventType) { _, newType in
                        // Reset character if switching to non-character event
                        if !newType.requiresCharacter {
                            newEventCharacterID = nil
                        }
                    }
                    
                    // Character Picker (only if event type requires a character)
                    if newEventType.requiresCharacter {
                        Picker("Character", selection: $newEventCharacterID) {
                            Text("Select a Character")
                                .font(.custom("Courier New", size: 14))
                                .tag(nil as UUID?)
                            ForEach(characters) { character in
                                Text(character.basicInfo.name)
                                    .font(.custom("Courier New", size: 14))
                                    .tag(character.id as UUID?)
                            }
                        }
                        .font(.custom("Courier New", size: 14))
                    }
                    
                    // Content Field
                    TextField("Event Content", text: $newEventContent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2, reservesSpace: true)
                        .font(.custom("Courier New", size: 12))
                    
                    // Connecting Word
                    Picker("Connecting Word", selection: $newEventConnectingWord) {
                        ForEach(ConnectingWord.allCases, id: \.self) { word in
                            Text(word.rawValue)
                                .font(.custom("Courier New", size: 14))
                                .tag(word)
                        }
                    }
                    .font(.custom("Courier New", size: 14))
                    
                    if newEventConnectingWord == .custom {
                        TextField("Custom connecting word (e.g., 'Suddenly', 'After a moment')", text: $newCustomConnectingWord)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.custom("Courier New", size: 12))
                    }
                    
                    // Add Event Button
                    addEventButton
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.custom("Courier New", size: 14))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveScene()
                        dismiss()
                    }
                    .font(.custom("Courier New", size: 14))
                    .disabled(newScene.title.isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                    .font(.custom("Courier New", size: 14))
                }
            }
            .onChange(of: selectedSettingPhoto) { _, newPhoto in
                Task {
                    guard let photoItem = newPhoto else { return }
                    if let data = try? await photoItem.loadTransferable(type: Data.self) {
                        selectedSettingImageData = data
                        analyzeSettingImage(imageData: data)
                    }
                }
            }
        }
    }
    
    private func analyzeSettingImage(imageData: Data) {
        let provider = preferredProvider
        
        guard provider.isConfigured else {
            settingAnalysisError = "\(provider.rawValue) API Key is not configured. Check Settings."
            return
        }
        
        isAnalyzingSetting = true
        settingAnalysisError = ""
        
        let apiKey = secureStorage.getAPIKey(for: provider)
        
        imageAnalysisService.analyzeSetting(
            imageData: imageData,
            provider: provider,
            apiKey: apiKey
        ) { result in
            DispatchQueue.main.async {
                isAnalyzingSetting = false
                switch result {
                case .success(let description):
                    newScene.setting = description
                case .failure(let error):
                    settingAnalysisError = "Analysis failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func addTimelineEvent() {
        let newEvent = TimelineEvent(
            characterID: newEventType.requiresCharacter ? newEventCharacterID : nil,
            eventType: newEventType,
            content: newEventContent,
            connectingWord: newEventConnectingWord,
            dialogueType: newEventDialogueType
        )
        
        // Set custom dialogue type if needed
        var eventToAdd = newEvent
        if newEventDialogueType == .custom {
            eventToAdd.customDialogueType = newCustomDialogueType
        }
        if newEventConnectingWord == .custom {
            eventToAdd.customConnectingWord = newCustomConnectingWord
        }
        
        // Add the event to the scene
        newScene.addTimelineEvent(eventToAdd)
        
        // Reset form
        newEventContent = ""
        newEventConnectingWord = .then
        newEventDialogueType = .says
        newCustomDialogueType = ""
        newCustomConnectingWord = ""
    }
    
    private func saveScene() {
        newScene.selectedCharacters = Array(selectedCharacterIDs)
        newScene.generatedImageData = selectedSettingImageData
        scenes.append(newScene)
    }
    
    private var isNewEventValid: Bool {
        let hasContent = !newEventContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasCharacterIfNeeded = !newEventType.requiresCharacter || newEventCharacterID != nil
        return hasContent && hasCharacterIfNeeded
    }
    
    private func deleteTimelineEvent(at offsets: IndexSet) {
        newScene.timeline.remove(atOffsets: offsets)
    }
    
    private func moveTimelineEvent(from source: IndexSet, to destination: Int) {
        newScene.timeline.move(fromOffsets: source, toOffset: destination)
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Event Type Styling Helpers
    
    private func iconForEventType(_ eventType: EventType) -> String {
        switch eventType {
        case .dialogue:
            return "bubble.left.fill"
        case .characterAction:
            return "figure.walk"
        case .actingNote:
            return "theatermasks.fill"
        case .environmentAction:
            return "leaf.fill"
        case .cameraAction:
            return "video.fill"
        }
    }
    
    private func colorForEventType(_ eventType: EventType) -> Color {
        switch eventType {
        case .dialogue, .characterAction:
            return .blue
        case .actingNote, .environmentAction:
            return .green
        case .cameraAction:
            return .orange
        }
    }
    
    // MARK: - View Builders to avoid compiler timeout
    
    @ViewBuilder
    private var addEventButton: some View {
        Button(action: addTimelineEvent) {
            HStack {
                Spacer()
                Text("Add Event")
                    .font(.custom("Courier New", size: 16))
                Spacer()
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(isNewEventValid ? Color.green : Color.gray)
        .cornerRadius(8)
        .shadow(radius: 2)
        .disabled(!isNewEventValid)
    }
    
    @ViewBuilder
    private func characterSelectionRow(for character: Character) -> some View {
        Button(action: {
            if selectedCharacterIDs.contains(character.id) {
                selectedCharacterIDs.remove(character.id)
            } else {
                selectedCharacterIDs.insert(character.id)
            }
        }) {
            HStack {
                // Show character thumbnail if available
                if let imageData = character.characterImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "person")
                                .font(.custom("Courier New", size: 14))
                                .foregroundColor(.gray)
                        )
                }
                
                Text(character.basicInfo.name.isEmpty ? "Unnamed Character" : character.basicInfo.name)
                    .font(.custom("Courier New", size: 14))
                Spacer()
                if selectedCharacterIDs.contains(character.id) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            }
        }
        .foregroundColor(.primary)
    }
    
    @ViewBuilder
    private var photoAnalysisSection: some View {
        Section("AI Photo Analysis (Optional)") {
            PhotosPicker(selection: $selectedSettingPhoto, matching: .images, photoLibrary: .shared()) {
                HStack {
                    Image(systemName: "camera.viewfinder")
                        .foregroundColor(preferredProvider.isConfigured ? .green : .gray)
                    Text("Analyze Setting from Photo")
                        .font(.custom("Courier New", size: 14))
                        .foregroundColor(preferredProvider.isConfigured ? .green : .gray)
                }
            }
            .disabled(!preferredProvider.isConfigured)
            
            // Show provider status
            if preferredProvider.isConfigured {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Using \(preferredProvider.rawValue) from settings")
                        .font(.custom("Courier New", size: 12))
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("Configure \(preferredProvider.rawValue) API key in Settings to analyze photos")
                        .font(.custom("Courier New", size: 12))
                        .foregroundColor(.orange)
                }
            }
            
            if let selectedSettingImageData, let uiImage = UIImage(data: selectedSettingImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                    .frame(maxHeight: 150)
            }
            
            if isAnalyzingSetting {
                ProgressView("Analyzing setting...")
                    .font(.custom("Courier New", size: 14))
            } else if !settingAnalysisError.isEmpty {
                Text(settingAnalysisError)
                    .font(.custom("Courier New", size: 12))
                    .foregroundColor(.red)
            }
        }
    }
    
    @ViewBuilder
    private var sceneInfoSection: some View {
        Section("Scene Info") {
            TextField("Title*", text: $newScene.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.custom("Courier New", size: 16))
                .padding(4)
                .foregroundColor(.primary)
            
            TextField("Description", text: $newScene.description, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3, reservesSpace: true)
                .font(.custom("Courier New", size: 12))
                .padding(4)
            
            TextField("Setting", text: $newScene.setting, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3, reservesSpace: true)
                .font(.custom("Courier New", size: 12))
                .padding(4)
            
            Picker("Emotional Tone", selection: $newScene.emotion) {
                ForEach(EmotionalTone.allCases, id: \.self) { emotion in
                    Text(emotion.rawValue)
                        .font(.custom("Courier New", size: 14))
                        .tag(emotion)
                }
            }
            .font(.custom("Courier New", size: 14))
            
            Picker("Establishing Shot", selection: $newScene.establishingShot) {
                ForEach(EstablishingShot.allCases, id: \.self) { shot in
                    Text(shot.rawValue)
                        .font(.custom("Courier New", size: 14))
                        .tag(shot)
                }
            }
            .font(.custom("Courier New", size: 14))
        }
    }
    
    @ViewBuilder
    private var charactersSection: some View {
        Section("Characters in Scene") {
            if characters.isEmpty {
                Text("No characters exist yet. Add them in the Characters tab.")
                    .font(.custom("Courier New", size: 12))
                    .foregroundColor(.secondary)
            } else {
                ForEach(characters) { character in
                    characterSelectionRow(for: character)
                }
            }
        }
    }
    
    @ViewBuilder
    private var timelineEventsSection: some View {
        Section(header: HStack {
            Text("Timeline Events")
                .font(.custom("Courier New", size: 16))
                .foregroundColor(.green)
            Spacer()
            Button("Preview Prompt") {
                // Functionality to preview prompt
            }
            .font(.custom("Courier New", size: 12))
            .foregroundColor(.green)
            .padding(4)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }) {
            if newScene.timeline.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No events yet")
                        .font(.custom("Courier New", size: 16))
                        .foregroundColor(.secondary)
                    
                    Text("Add your first event below. All project characters are available - they'll be automatically added to this scene when you use them in the timeline.")
                        .font(.custom("Courier New", size: 14))
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .shadow(radius: 2)
            } else {
                List {
                    ForEach($newScene.timeline, id: \.id) { $event in
                        let index = newScene.timeline.firstIndex(where: { $0.id == event.id }) ?? 0
                        VStack(alignment: .leading, spacing: 4) {
                            // Event details with colored icon
                            HStack {
                                // Colored icon based on event type
                                Image(systemName: iconForEventType(event.eventType))
                                    .foregroundColor(colorForEventType(event.eventType))
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 20, height: 20)
                                
                                Text("Event \(index + 1): \(event.eventType.rawValue)")
                                    .font(.custom("Courier New", size: 12))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Delete") {
                                    if let idx = newScene.timeline.firstIndex(where: { $0.id == event.id }) {
                                        newScene.timeline.remove(at: idx)
                                    }
                                }
                                .font(.custom("Courier New", size: 12))
                                .foregroundColor(.red)
                            }
                            
                            HStack {
                                // Spacer to align content with text above
                                Spacer()
                                    .frame(width: 20)
                                
                                TextField("Content", text: $event.content, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(2, reservesSpace: true)
                                    .font(.custom("Courier New", size: 12))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove(perform: moveTimelineEvent)
                    .onDelete(perform: deleteTimelineEvent)
                }
            }
        }
    }
}
