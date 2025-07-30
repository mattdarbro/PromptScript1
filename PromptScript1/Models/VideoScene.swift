import Foundation

// NOTE: All 'enum' and helper 'struct' definitions have been removed from this file.
// They are now correctly centralized in 'SharedAITypesAndModels.swift'.

// MARK: - Updated VideoScene Model
struct VideoScene: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var generatedImageData: Data? = nil
    
    var title: String = ""
    var description: String = ""
    var emotion: EmotionalTone = .dramatic
    var customEmotion: String = ""
    var setting: String = ""
    var generatedPrompt: String = ""
    
    // These types are now correctly referenced from the shared models file.
    var shotMode: ShotMode = .single
    var establishingShot: EstablishingShot = .wideAngle
    var customEstablishingShot: String = ""
    
    var selectedCharacters: [UUID] = []
    
    var timeline: [TimelineEvent] = []
    
    var composition: Composition = Composition()
    
    // ADDED: Missing properties to resolve compiler errors.
    var lighting: String = ""
    var customLighting: String = ""
    
    var shotType: String = ""
    var customShotType: String = ""
    var cameraAngle: String = ""
    var customCameraAngle: String = ""
    var lensType: String = ""
    var customLensType: String = ""
    var focalLength: String = ""
    var cameraMovement: String = ""
    var customCameraMovement: String = ""
    var colorGrading: String = ""
    
    // MARK: - Enhanced Prompt Generation Method
    
    func generatePromptScript(characters: [Character], style: VideoStyle) -> String {
        var prompt = ""
        var characterFirstAppearance: Set<UUID> = []
        
        // HEADER SECTION
        prompt += "Style: \(style.rawValue)\n"
        prompt += "Setting: \(setting)\n"
        prompt += "Lighting: \(lighting.isEmpty ? "Natural" : lighting)\n"
        
        let establishingShotText = establishingShot == .custom ? customEstablishingShot : establishingShot.rawValue
        prompt += "Initial Camera Setup: \(establishingShotText), \(shotMode.rawValue)\n\n"
        
        // TIMELINE BODY
        for (index, event) in timeline.enumerated() {
            if index > 0 {
                let previousEvent = timeline[index - 1]
                if previousEvent.connectingWord != .none {
                    let connectingText = previousEvent.actualConnectingWord
                    if !connectingText.isEmpty {
                        prompt += "\(connectingText)\n\n"
                    }
                }
            }
            
            switch event.eventType {
            case .dialogue:
                if let characterID = event.characterID, let character = characters.first(where: { $0.id == characterID }) {
                    let isFirstAppearance = !characterFirstAppearance.contains(characterID)
                    let characterDescription = generateCharacterDescription(character, isFirstAppearance: isFirstAppearance)
                    let dialogueTypeText = event.dialogueType == .custom ? event.customDialogueType : event.dialogueType.rawValue
                    prompt += "\(characterDescription) \(dialogueTypeText) \"\(event.content)\"\n"
                    characterFirstAppearance.insert(characterID)
                }
            case .characterAction:
                if let characterID = event.characterID, let character = characters.first(where: { $0.id == characterID }) {
                    let isFirstAppearance = !characterFirstAppearance.contains(characterID)
                    let characterDescription = generateCharacterDescription(character, isFirstAppearance: isFirstAppearance)
                    prompt += "\(characterDescription) \(event.content)\n"
                    characterFirstAppearance.insert(characterID)
                }
            case .environmentAction:
                prompt += "\(event.content)\n"
            case .cameraAction:
                let cameraContent = event.content.lowercased().hasPrefix("camera") ? event.content : "Camera \(event.content)"
                prompt += "\(cameraContent)\n"
            case .actingNote:
                 if let characterID = event.characterID, let character = characters.first(where: { $0.id == characterID }) {
                    let isFirstAppearance = !characterFirstAppearance.contains(characterID)
                    let characterDescription = generateCharacterDescription(character, isFirstAppearance: isFirstAppearance)
                    prompt += "\(characterDescription): \(event.content)\n"
                    characterFirstAppearance.insert(characterID)
                }
            }
        }
        
        prompt += "\n(Keep character consistency)"
        
        return prompt
    }
    
    // MARK: - Enhanced Character Description Method
    
    private func generateCharacterDescription(_ character: Character, isFirstAppearance: Bool) -> String {
        let characterName = character.basicInfo.name
        
        if isFirstAppearance {
            // First appearance: Full description with name restated
            let fullDescription = character.generateComprehensiveDescription()
            return fullDescription
        } else {
            // Subsequent appearances: Just name with key descriptors
            var keyDescriptors: [String] = []
            
            // Add 1-2 most distinctive features
            if !character.basicInfo.age.isEmpty {
                keyDescriptors.append(character.basicInfo.age)
            }
            if !character.basicInfo.gender.isEmpty {
                keyDescriptors.append(character.basicInfo.gender)
            }
            
            if keyDescriptors.isEmpty {
                return characterName
            } else {
                return "\(characterName) (\(keyDescriptors.joined(separator: ", ")))"
            }
        }
    }
}

// MARK: - Helper Extensions
extension VideoScene {
    mutating func addTimelineEvent(_ event: TimelineEvent) {
        timeline.append(event)
        if let characterID = event.characterID, !selectedCharacters.contains(characterID) {
            selectedCharacters.append(characterID)
        }
    }
    
    mutating func removeTimelineEvent(id: UUID) {
        timeline.removeAll { $0.id == id }
    }
    
    mutating func moveTimelineEvent(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < timeline.count,
              destinationIndex >= 0, destinationIndex <= timeline.count else { return }
        
        let event = timeline.remove(at: sourceIndex)
        let adjustedDestination = destinationIndex > sourceIndex ? destinationIndex - 1 : destinationIndex
        timeline.insert(event, at: adjustedDestination)
    }
}

