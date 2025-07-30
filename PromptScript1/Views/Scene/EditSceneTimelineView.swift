//
//  EditSceneTimelineView.swift
//  PromptScript1
//
//  Enhanced version supporting the new timeline features
//

import SwiftUI

/// A view for adding, editing, deleting, and reordering events in a scene's timeline.
struct EditSceneTimelineView: View {
    @Binding var scene: VideoScene
    let characters: [Character] // The full list of characters in the project
    
    @Environment(\.dismiss) private var dismiss
    
    // State for the "Add New Event" form
    @State private var newEventCharacterID: UUID?
    @State private var newEventType: EventType = .dialogue
    @State private var newEventContent: String = ""
    @State private var newEventConnectingWord: ConnectingWord = .then
    @State private var newCustomConnectingWord: String = ""
    @State private var newEventDialogueType: DialogueType = .says
    @State private var newCustomDialogueType: String = ""
    
    // State for presenting the editor for a single event
    @State private var eventToEdit: TimelineEvent?
    
    // State for preview
    @State private var showPromptPreview = false

    var body: some View {
        NavigationView {
            Form {
                // INFO SECTION
                Section {
                    Text("💡 All project characters are available below. Characters will be automatically added to this scene when you use them in timeline events.")
                        .font(.custom("Courier New", size: 12))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }
                
                // SHOT SETUP SECTION
                Section(header: Text("Shot Setup")
                    .font(.custom("Courier New", size: 16))
                    .foregroundColor(.green)
                    .fontWeight(.medium)) {
                    Picker("Shot Mode", selection: $scene.shotMode) {
                        ForEach(ShotMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("Establishing Shot", selection: $scene.establishingShot) {
                        ForEach(EstablishingShot.allCases, id: \.self) { shot in
                            Text(shot.rawValue).tag(shot)
                        }
                    }
                    
                    if scene.establishingShot == .custom {
                        TextField("Custom establishing shot", text: $scene.customEstablishingShot)
                    }
                }
                
                // TIMELINE EVENTS SECTION
                Section(header: HStack {
                    Text("Timeline Events")
                        .font(.custom("Courier New", size: 16))
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                    Spacer()
                    Button("Preview Prompt") {
                        showPromptPreview = true
                    }
                    .font(.custom("Courier New", size: 12))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
                }) {
                    if scene.timeline.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No events yet")
                                .font(.custom("Courier New", size: 16))
                                .foregroundColor(.secondary)
                            
                            Text("Add your first event below. All project characters are available - they'll be automatically added to this scene when you use them in the timeline.")
                                .font(.custom("Courier New", size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    } else {
                        List {
                            ForEach($scene.timeline) { $event in
                                Button(action: {
                                    self.eventToEdit = event
                                }) {
                                    EnhancedTimelineEventRowView(event: event, characters: characters)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .onMove(perform: moveEvent)
                            .onDelete(perform: deleteEvent)
                        }
                    }
                }
                
                // ADD NEW EVENT SECTION
                Section(header: Text("Add New Event")
                    .font(.custom("Courier New", size: 16))
                    .foregroundColor(.green)
                    .fontWeight(.medium)) {
                    // Event Type Picker (affects whether character is required)
                    Picker("Event Type", selection: $newEventType) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .onChange(of: newEventType) { newType in
                        // Reset character if switching to non-character event
                        if !newType.requiresCharacter {
                            newEventCharacterID = nil
                        }
                    }
                    
                    // Character Picker (only shown if event type requires character)
                    if newEventType.requiresCharacter {
                        Picker("Character", selection: $newEventCharacterID) {
                            Text("Select a Character").tag(nil as UUID?)
                            ForEach(charactersInScene) { character in
                                Text(character.basicInfo.name).tag(character.id as UUID?)
                            }
                        }
                    }
                    
                    // Dialogue Type Picker (only for dialogue events)
                    if newEventType == .dialogue {
                        Picker("Dialogue Type", selection: $newEventDialogueType) {
                            ForEach(DialogueType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        
                        if newEventDialogueType == .custom {
                            TextField("Custom dialogue type", text: $newCustomDialogueType)
                        }
                    }
                    
                    // Content Field
                    TextField(placeholderText, text: $newEventContent)
                    
                    // Connecting Word (except for last event)
                    if !scene.timeline.isEmpty {
                        Picker("Connecting Word", selection: $newEventConnectingWord) {
                            ForEach(ConnectingWord.allCases, id: \.self) { word in
                                Text(word.rawValue).tag(word)
                            }
                        }
                        
                        if newEventConnectingWord == .custom {
                            TextField("Custom connecting word (e.g., 'Suddenly', 'After a moment')", text: $newCustomConnectingWord)
                        }
                    }
                    
                    // Add Button
                    Button(action: addEvent) {
                        HStack {
                            Spacer()
                            Label("Add Event to Timeline", systemImage: "plus.circle.fill")
                                .font(.custom("Courier New", size: 16))
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(isNewEventValid ? Color.green : Color.gray)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .animation(.spring(), value: isNewEventValid)
                    .disabled(!isNewEventValid)
                }
            }
            // ✨ NEW: Add keyboard dismissal functionality
            .scrollDismissesKeyboard(.interactively)  // Dismiss when scrolling (this is safe)
            // REMOVED: .dismissKeyboardOnTap() - this was interfering with pickers
            .navigationTitle("EDIT TIMELINE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EDIT TIMELINE")
                        .font(.custom("Courier New", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.custom("Courier New", size: 14))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                        .font(.custom("Courier New", size: 14))
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                        .font(.custom("Courier New", size: 14))
                }
                // ✨ NEW: Add Done button for keyboard
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                    .font(.custom("Courier New", size: 14))
                }
            }
            .sheet(item: $eventToEdit) { event in
                if let index = scene.timeline.firstIndex(where: { $0.id == event.id }) {
                    EnhancedEditSingleEventView(
                        event: $scene.timeline[index],
                        characters: charactersInScene
                    )
                }
            }
            .sheet(isPresented: $showPromptPreview) {
                PromptPreviewView(scene: scene, characters: characters)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var charactersInScene: [Character] {
        // UPDATED: Make all project characters available in timeline
        // No need to pre-select characters for the scene
        return characters
    }
    
    private var isNewEventValid: Bool {
        let hasContent = !newEventContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasCharacterIfNeeded = !newEventType.requiresCharacter || newEventCharacterID != nil
        return hasContent && hasCharacterIfNeeded
    }
    
    private var placeholderText: String {
        switch newEventType {
        case .dialogue:
            return "What does the character say?"
        case .characterAction:
            return "What does the character do? (sits down, walks to door)"
        case .actingNote:
            return "Acting direction or emotion"
        case .environmentAction:
            return "What happens in the environment? (book falls to floor, door opens)"
        case .cameraAction:
            return "Camera movement (pans left, zooms in, tracks forward)"
        }
    }
    
    // MARK: - Actions
    
    private func addEvent() {
        let newEvent = TimelineEvent(
            characterID: newEventType.requiresCharacter ? newEventCharacterID : nil,
            eventType: newEventType,
            content: newEventContent,
            connectingWord: newEventConnectingWord,
            dialogueType: newEventDialogueType
        )
        
        // Set custom dialogue type and connecting word if needed
        var eventToAdd = newEvent
        if newEventDialogueType == .custom {
            eventToAdd.customDialogueType = newCustomDialogueType
        }
        if newEventConnectingWord == .custom {
            eventToAdd.customConnectingWord = newCustomConnectingWord
        }
        
        // UPDATED: Use the new helper method that automatically manages character selection
        scene.addTimelineEvent(eventToAdd)
        
        // Reset form
        newEventContent = ""
        newEventConnectingWord = .then
        newEventDialogueType = .says
        newCustomDialogueType = ""
    }
    
    private func deleteEvent(at offsets: IndexSet) {
        scene.timeline.remove(atOffsets: offsets)
    }
    
    private func moveEvent(from source: IndexSet, to destination: Int) {
        scene.timeline.move(fromOffsets: source, toOffset: destination)
    }
}

// MARK: - Enhanced Event Row View

struct EnhancedTimelineEventRowView: View {
    let event: TimelineEvent
    let characters: [Character]
    
    var characterName: String {
        guard let characterID = event.characterID,
              let character = characters.first(where: { $0.id == characterID }) else {
            return ""
        }
        return character.basicInfo.name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Event type icon
                Image(systemName: eventIcon)
                    .foregroundColor(eventColor)
                    .frame(width: 20)
                
                // Character name (if applicable)
                if !characterName.isEmpty {
                    Text(characterName)
                        .font(.custom("Courier New", size: 12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // Event type
                Text(event.eventType.displayName)
                    .font(.custom("Courier New", size: 10))
                    .foregroundColor(.secondary)
            }
            
            // Event content
            Text(event.content)
                .font(.custom("Courier New", size: 14))
            
            // Connecting word (if not none)
            if event.connectingWord != .none {
                HStack {
                    Spacer()
                    Text(event.connectingWord.promptText)
                        .font(.custom("Courier New", size: 10))
                        .italic()
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private var eventIcon: String {
        switch event.eventType {
        case .dialogue: return "bubble.left"
        case .characterAction: return "figure.walk"
        case .actingNote: return "theatermasks"
        case .environmentAction: return "leaf"
        case .cameraAction: return "camera"
        }
    }
    
    private var eventColor: Color {
        switch event.eventType {
        case .dialogue: return .blue
        case .characterAction: return .green
        case .actingNote: return .purple
        case .environmentAction: return .orange
        case .cameraAction: return .red
        }
    }
}

// MARK: - Enhanced Single Event Editor

struct EnhancedEditSingleEventView: View {
    @Binding var event: TimelineEvent
    let characters: [Character]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")
                    .font(.custom("Courier New", size: 16))
                    .foregroundColor(.green)
                    .fontWeight(.medium)) {
                    // Event type (read-only for now)
                    HStack {
                        Text("Event Type:")
                            .font(.custom("Courier New", size: 14))
                        Spacer()
                        Text(event.eventType.displayName)
                            .font(.custom("Courier New", size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    // Character selection (if applicable)
                    if event.eventType.requiresCharacter {
                        Picker("Character", selection: $event.characterID) {
                            Text("Select Character").tag(nil as UUID?)
                            ForEach(characters, id: \.id) { character in
                                Text(character.basicInfo.name).tag(character.id as UUID?)
                            }
                        }
                    }
                    
                    // Dialogue type (if dialogue event)
                    if event.eventType == .dialogue {
                        Picker("Dialogue Type", selection: $event.dialogueType) {
                            ForEach(DialogueType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        
                        if event.dialogueType == .custom {
                            TextField("Custom dialogue type", text: $event.customDialogueType)
                        }
                    }
                    
                    // Content editor
                    VStack(alignment: .leading) {
                        Text("Content:")
                            .font(.custom("Courier New", size: 16))
                            .foregroundColor(.green)
                        TextEditor(text: $event.content)
                            .frame(minHeight: 100)
                    }
                }
                
                Section(header: Text("Flow Control")
                    .font(.custom("Courier New", size: 16))
                    .foregroundColor(.green)
                    .fontWeight(.medium)) {
                    Picker("Connecting Word", selection: $event.connectingWord) {
                        ForEach(ConnectingWord.allCases, id: \.self) { word in
                            Text(word.rawValue).tag(word)
                        }
                    }
                    
                    if event.connectingWord == .custom {
                        TextField("Custom connecting word (e.g., 'Suddenly', 'After a moment')", text: $event.customConnectingWord)
                    }
                }
            }
            // ✨ NEW: Add keyboard dismissal to the single event editor
            .scrollDismissesKeyboard(.interactively)
            // REMOVED: .dismissKeyboardOnTap() - this was interfering with pickers
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
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
    }
}

// MARK: - Prompt Preview View

struct PromptPreviewView: View {
    let scene: VideoScene
    let characters: [Character]
    @Environment(\.dismiss) private var dismiss
    
    var promptText: String {
        // Use all characters that are referenced in timeline events
        let timelineCharacterIDs = Set(scene.timeline.compactMap { $0.characterID })
        let sceneCharacters = characters.filter { timelineCharacterIDs.contains($0.id) }
        
        // Debug info to help troubleshoot
        print("Timeline character IDs: \(timelineCharacterIDs)")
        print("Available characters: \(characters.map { $0.basicInfo.name })")
        print("Filtered scene characters: \(sceneCharacters.map { $0.basicInfo.name })")
        
        return scene.generatePromptScript(characters: sceneCharacters, style: .cinematic)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(promptText)
                    .font(.custom("Courier New", size: 14))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true) // Allow horizontal wrapping, preserve vertical size
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .textSelection(.enabled) // Allow text selection for copying
            }
            .navigationTitle("Prompt Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Copy") {
                        UIPasteboard.general.string = promptText
                    }
                }
            }
        }
    }
}
