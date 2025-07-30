import Foundation

// This protocol is needed for the formatter to conform to.
protocol PromptFormatter {
    func format(scene: VideoScene, characters: [Character], project: Project) -> String
}

/// A formatter that creates the new streamlined prompt format.
/// UPDATED: Now uses the new timeline model and generates the exact format requested.
struct DefaultPromptFormatter: PromptFormatter {
    
    // MARK: - New Methods for Full Export Capability
    
    /// Formats the entire project by formatting each scene and joining them.
    func format(project: Project) -> String {
        guard !project.scenes.isEmpty else {
            return "This project has no scenes to export."
        }
        
        let allScenePrompts = project.scenes.enumerated().map { (index, scene) -> String in
            // Get characters that are actually referenced in timeline events
            let timelineCharacterIDs = Set(scene.timeline.compactMap { $0.characterID })
            let sceneCharacters = project.characters.filter { timelineCharacterIDs.contains($0.id) }
            let scenePrompt = format(scene: scene, characters: sceneCharacters, project: project)
            return "--- SCENE \(index + 1): \(scene.title) ---\n\n" + scenePrompt
        }
        
        return allScenePrompts.joined(separator: "\n\n--------------------\n\n")
    }
    
    /// Creates a comprehensive character prompt for AI video generation.
    func format(character: Character, project: Project) -> String {
        let fullDescription = character.generateComprehensiveDescription()
        
        // Simple approach: if the description starts with the character name, remove it
        let characterName = character.basicInfo.name
        var detailsOnly = fullDescription
        
        // Check if description starts with "Name (" pattern
        if fullDescription.hasPrefix("\(characterName) (") {
            // Find the matching closing parenthesis at the end
            if fullDescription.hasSuffix(")") {
                // Remove "Name (" from start and ")" from end
                let startIndex = fullDescription.index(fullDescription.startIndex, offsetBy: characterName.count + 2)
                let endIndex = fullDescription.index(fullDescription.endIndex, offsetBy: -1)
                detailsOnly = String(fullDescription[startIndex..<endIndex])
            }
        }
        
        return "\(characterName): \(detailsOnly)"
    }
    
    // MARK: - Updated Scene Formatter - NEW CLEAN FORMAT
    
    /// Formats a single scene using the new streamlined format.
    func format(scene: VideoScene, characters: [Character], project: Project) -> String {
        // Use the new generatePromptScript method from VideoScene
        let styleText = project.videoStyle == .custom ? project.customVideoStyle : project.videoStyle.rawValue
        let style = VideoStyle(rawValue: styleText) ?? .cinematic
        
        return scene.generatePromptScript(characters: characters, style: style)
    }
    
    // MARK: - Alternative Detailed Format (if needed)
    
    /// Generates the old detailed format for comparison or backup use.
    func formatDetailed(scene: VideoScene, characters: [Character], project: Project) -> String {
        let styleText = project.videoStyle == .custom ? project.customVideoStyle : project.videoStyle.rawValue
        var prompt = "Visual Style: \(styleText).\n"
        
        let emotionText = scene.emotion == .custom ? scene.customEmotion : scene.emotion.rawValue
        prompt += "Emotional Tone: \(emotionText).\n"
        
        prompt += "Setting: \(scene.setting)\n"
        prompt += "Scene Description: \(scene.description)\n\n"
        
        // Characters with their timeline events
        if !characters.isEmpty {
            prompt += "Characters Present:\n"
            for character in characters {
                let eventsForCharacter = scene.timeline.filter { $0.characterID == character.id }
                
                if !eventsForCharacter.isEmpty {
                    prompt += "• \(character.basicInfo.name): A \(character.basicInfo.age) year old \(character.basicInfo.gender) \(character.basicInfo.ethnicity) with \(character.hair.color) \(character.hair.style) hair and \(character.facialFeatures.eyeColor) eyes. Build is \(character.body.build). Wearing \(character.clothing.overallStyle) style clothing: \(character.clothing.topWear) and \(character.clothing.bottomWear).\n"
                    
                    for event in eventsForCharacter {
                        switch event.eventType {
                        case .dialogue:
                            prompt += "  - Says: \"\(event.content)\".\n"
                        case .characterAction:
                            prompt += "  - Does: \(event.content).\n"
                        case .actingNote:
                            prompt += "  - Acting Note: \(event.content).\n"
                        case .environmentAction:
                            prompt += "  - Environment: \(event.content).\n"
                        case .cameraAction:
                            prompt += "  - Camera: \(event.content).\n"
                        }
                    }
                }
            }
            prompt += "\n"
        }
        
        // Cinematography details
        prompt += "Cinematography & Framing:\n"
        let shotText = scene.shotType == "Custom" ? scene.customShotType : scene.shotType
        if !shotText.isEmpty { prompt += "- Shot Type: \(shotText).\n" }
        
        let angleText = scene.cameraAngle == "Custom" ? scene.customCameraAngle : scene.cameraAngle
        if !angleText.isEmpty { prompt += "- Camera Angle: \(angleText).\n" }
        
        let lensText = scene.lensType == "Custom" ? scene.customLensType : scene.lensType
        if !lensText.isEmpty { prompt += "- Lens: \(lensText).\n" }
        
        if !scene.focalLength.isEmpty { prompt += "- Focal Length: \(scene.focalLength).\n" }
        
        let lightingText = scene.lighting == "Custom" ? scene.customLighting : scene.lighting
        if !lightingText.isEmpty { prompt += "- Lighting: \(lightingText).\n" }
        
        let movementText = scene.cameraMovement == "Custom" ? scene.customCameraMovement : scene.cameraMovement
        if !movementText.isEmpty { prompt += "- Camera Movement: \(movementText).\n" }
        
        if !scene.colorGrading.isEmpty { prompt += "- Color Grading: \(scene.colorGrading).\n" }
        
        prompt += "\nIMPORTANT: Maintain character consistency, especially facial features and clothing, as described above."
        
        return prompt
    }
}

// MARK: - Quick Format Extension

extension VideoScene {
    /// Quick method to get the new clean prompt format
    func toCleanPrompt(characters: [Character], style: VideoStyle) -> String {
        return generatePromptScript(characters: characters, style: style)
    }
}
