import Foundation

// MARK: - Multi-AI Script Generation Coordinator
class MultiAIScriptGenerationService {
    func generateScript(
        input: EnhancedScriptGenerationInput,
        provider: AIProvider,
        apiKey: String,
        completion: @escaping (Result<[VideoScene], Error>) -> Void
    ) {
        let service = getService(for: provider)
        service.generateScript(input: input, apiKey: apiKey, completion: completion)
    }
    
    private func getService(for provider: AIProvider) -> ScriptGenerationService {
        switch provider {
        case .openAI: return OpenAIScriptGenerationImplementation()
        case .claude: return ClaudeScriptGenerationImplementation()
        //case .gemini: return GeminiScriptGenerationImplementation()
        }
    }
}

// MARK: - Base Implementation with Shared Logic
class BaseScriptGenerationImplementation {
    
    func buildEnhancedScriptPrompt(input: EnhancedScriptGenerationInput, numberOfScenes: Int) -> String {
        let styleText = input.videoStyle == .custom ? input.customVideoStyle ?? "Cinematic" : input.videoStyle.rawValue
        let genreText = input.genres.joined(separator: " mixed with ")
        let characterDescriptions = input.characters.map { "\($0.basicInfo.name) - \($0.basicInfo.age) year old \($0.basicInfo.gender), \($0.basicInfo.ethnicity)" }.joined(separator: "\n")
        let storyBeats = input.storyStructure.beats.joined(separator: " → ")
        
        return """
        Create a compelling \(input.duration)-second video script.

        CORE STORY:
        Logline: \(input.logline)
        
        STORY STRUCTURE: \(input.storyStructure.rawValue)
        Story Beats to Follow: \(storyBeats)
        
        EMOTIONAL JOURNEY: \(input.primaryEmotion.rawValue)
        The script should maintain this primary emotional tone while allowing for natural variation.

        PRODUCTION DETAILS:
        Style: \(styleText)
        Genre: \(genreText)
        Setting: \(input.setting)
        Cinematography: \(input.cinematographyNotes)

        CHARACTERS:
        \(characterDescriptions.isEmpty ? "Create compelling characters that serve the story" : characterDescriptions)

        TECHNICAL REQUIREMENTS:
        - Create exactly \(numberOfScenes) scenes.
        - Each scene should be approximately \(input.sceneDuration) seconds.
        - Follow the \(input.storyStructure.rawValue) structure.
        - Build an emotional arc from setup to resolution.
        - Ensure each scene advances the story and serves the logline.

        For each scene, provide:
        1. TITLE: Brief, compelling scene title
        2. DESCRIPTION: What happens in the scene (focus on story beats)
        3. EMOTION: Choose from (Tense, Joyful, Melancholy, Mysterious, Romantic, Action, Peaceful, Dramatic, Comedy)
        4. ESTABLISHING_SHOT: Choose from (Wide Angle, Close Up, Medium Shot, Zoom In, Zoom Out, Handheld, Tracking Shot)
        5. TIMELINE_EVENTS: An ordered sequence of actions and dialogue.

        TIMELINE EVENT TYPES:
        - CHARACTER_DIALOGUE: [character name]: "[what they say]"
        - CHARACTER_ACTION: [character name]: [what they do]
        - ENVIRONMENT_ACTION: [something that happens in the scene]
        - CAMERA_ACTION: [camera movement or shot]
        - ACTING_NOTE: [character name]: [how they should act/feel]

        Format each scene like this, starting a new line for each element:
        SCENE [number]:
        TITLE: [title]
        DESCRIPTION: [description]
        EMOTION: [emotion]
        ESTABLISHING_SHOT: [establishing shot]
        TIMELINE_EVENTS:
        CHARACTER_DIALOGUE: [character name]: "[dialogue]"
        CHARACTER_ACTION: [character name]: [action]
        """
    }
    
    func parseScriptIntoScenes(scriptText: String, input: EnhancedScriptGenerationInput) -> [VideoScene] {
        var scenes: [VideoScene] = []
        let sceneBlocks = scriptText.components(separatedBy: "SCENE ").dropFirst()
        
        for sceneBlock in sceneBlocks {
            var scene = VideoScene()
            let lines = sceneBlock.components(separatedBy: "\n")
            var isParsingTimeline = false
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if trimmedLine.hasPrefix("TITLE:") {
                    isParsingTimeline = false
                    scene.title = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                } else if trimmedLine.hasPrefix("DESCRIPTION:") {
                    isParsingTimeline = false
                    scene.description = String(trimmedLine.dropFirst(12)).trimmingCharacters(in: .whitespaces)
                } else if trimmedLine.hasPrefix("EMOTION:") {
                    isParsingTimeline = false
                    let emotionText = String(trimmedLine.dropFirst(8)).trimmingCharacters(in: .whitespaces)
                    scene.emotion = EmotionalTone(rawValue: emotionText) ?? .dramatic
                } else if trimmedLine.hasPrefix("ESTABLISHING_SHOT:") {
                    isParsingTimeline = false
                    let shotText = String(trimmedLine.dropFirst(18)).trimmingCharacters(in: .whitespaces)
                    scene.establishingShot = EstablishingShot(rawValue: shotText) ?? .wideAngle
                } else if trimmedLine.hasPrefix("TIMELINE_EVENTS:") {
                    isParsingTimeline = true
                } else if isParsingTimeline, !trimmedLine.isEmpty, let event = parseTimelineEvent(line: trimmedLine, characters: input.characters) {
                    scene.timeline.append(event)
                }
            }
            scene.setting = input.setting
            scene.selectedCharacters = input.characters.map { $0.id }
            scenes.append(scene)
        }
        return scenes
    }

    // FINAL CORRECTION 2: This function is now fully implemented.
        private func parseTimelineEvent(line: String, characters: [Character]) -> TimelineEvent? {
            let eventTypes: [(String, EventType)] = [
                ("CHARACTER_DIALOGUE:", .dialogue),
                ("CHARACTER_ACTION:", .characterAction),
                ("ACTING_NOTE:", .actingNote),
                ("ENVIRONMENT_ACTION:", .environmentAction),
                ("CAMERA_ACTION:", .cameraAction)
            ]

            for (prefix, eventType) in eventTypes {
                if line.hasPrefix(prefix) {
                    var content = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                    var characterID: UUID? = nil

                    if [.dialogue, .characterAction, .actingNote].contains(eventType) {
                        if let colonIndex = content.firstIndex(of: ":") {
                            let name = String(content[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                            content = String(content[content.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                            characterID = characters.first { $0.basicInfo.name == name }?.id
                        }
                    }
                    
                    if eventType == .dialogue {
                        content = content.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    }
                    
                    return TimelineEvent(characterID: characterID, eventType: eventType, content: content)
                }
            }
            return nil
        }
    }



// MARK: - OpenAI Implementation
class OpenAIScriptGenerationImplementation: BaseScriptGenerationImplementation, ScriptGenerationService {
    func generateScript(input: EnhancedScriptGenerationInput, apiKey: String, completion: @escaping (Result<[VideoScene], Error>) -> Void) {
        let numberOfScenes = input.duration / input.sceneDuration
        let prompt = buildEnhancedScriptPrompt(input: input, numberOfScenes: numberOfScenes)
        
        generateScriptText(prompt: prompt, apiKey: apiKey) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let scriptText):
                    let scenes = self.parseScriptIntoScenes(scriptText: scriptText, input: input)
                    completion(.success(scenes))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func generateScriptText(prompt: String, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(ScriptGenerationError.invalidURL)); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = ["model": "gpt-4o", "messages": [["role": "user", "content": prompt]], "max_tokens": 4096, "temperature": 0.8]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(ScriptGenerationError.encodingError(error))); return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(.failure(ScriptGenerationError.networkError(error))); return }
            guard let data = data else { completion(.failure(ScriptGenerationError.noData)); return }
            
            do {
                let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let content = response.choices.first?.message.content {
                    completion(.success(content))
                } else {
                    let errorResponse = try JSONDecoder().decode(OpenAIErrorResponse.self, from: data)
                    completion(.failure(ScriptGenerationError.apiError(errorResponse.error.message)))
                }
            } catch {
                do {
                    let errorResponse = try JSONDecoder().decode(OpenAIErrorResponse.self, from: data)
                    completion(.failure(ScriptGenerationError.apiError(errorResponse.error.message)))
                } catch {
                    completion(.failure(ScriptGenerationError.decodingError(error)))
                }
            }
        }.resume()
    }
}

// Update your ClaudeScriptGenerationImplementation with the correct model name

class ClaudeScriptGenerationImplementation: BaseScriptGenerationImplementation, ScriptGenerationService {
    func generateScript(input: EnhancedScriptGenerationInput, apiKey: String, completion: @escaping (Result<[VideoScene], Error>) -> Void) {
        print("🔵 Claude: Starting script generation")
        print("🔵 Claude: API Key present: \(!apiKey.isEmpty)")
        
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            print("❌ Claude: Invalid URL")
            completion(.failure(ScriptGenerationError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let prompt = buildEnhancedScriptPrompt(input: input, numberOfScenes: input.duration / input.sceneDuration)
        print("🔵 Claude: Prompt length: \(prompt.count) characters")
        
        // FIXED: Use the correct Claude model name
        let requestBody: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",  // Changed from claude-3-opus-20240229
            "max_tokens": 4096,
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.8
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("🔵 Claude: Request body created successfully")
        } catch {
            print("❌ Claude: Encoding error: \(error)")
            completion(.failure(ScriptGenerationError.encodingError(error)))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Claude: Network error: \(error)")
                    completion(.failure(ScriptGenerationError.networkError(error)))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔵 Claude: HTTP Status: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    print("❌ Claude: No data received")
                    completion(.failure(ScriptGenerationError.noData))
                    return
                }
                
                print("🔵 Claude: Received data: \(data.count) bytes")
                
                // Print raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔵 Claude: Raw response: \(responseString.prefix(800))...")
                }
                
                do {
                    let response = try JSONDecoder().decode(ClaudeVisionResponse.self, from: data)
                    guard let content = response.content.first?.text else {
                        print("❌ Claude: No content in response")
                        completion(.failure(ScriptGenerationError.parseError))
                        return
                    }
                    print("✅ Claude: Content received: \(content.prefix(200))...")
                    let scenes = self.parseScriptIntoScenes(scriptText: content, input: input)
                    print("✅ Claude: Parsed \(scenes.count) scenes")
                    completion(.success(scenes))
                } catch {
                    print("❌ Claude: Decoding error: \(error)")
                    do {
                        let errorResponse = try JSONDecoder().decode(ClaudeErrorResponse.self, from: data)
                        let errorMessage = errorResponse.error.message
                        print("❌ Claude: API Error: \(errorMessage)")
                        completion(.failure(ScriptGenerationError.apiError(errorMessage)))
                    } catch {
                        print("❌ Claude: Failed to decode error response: \(error)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("❌ Claude: Full error response: \(responseString)")
                        }
                        completion(.failure(ScriptGenerationError.decodingError(error)))
                    }
                }
            }
        }.resume()
    }
}

/*
// MARK: - Gemini Implementation
class GeminiScriptGenerationImplementation: BaseScriptGenerationImplementation, ScriptGenerationService {
    func generateScript(input: EnhancedScriptGenerationInput, apiKey: String, completion: @escaping (Result<[VideoScene], Error>) -> Void) {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent?key=\(apiKey)") else {
            completion(.failure(ScriptGenerationError.invalidURL)); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let prompt = buildEnhancedScriptPrompt(input: input, numberOfScenes: input.duration / input.sceneDuration)
        let requestBody: [String: Any] = ["contents": [["parts": [["text": prompt]]]], "generationConfig": ["temperature": 0.8]]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(ScriptGenerationError.encodingError(error))); return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(ScriptGenerationError.networkError(error))); return }
                guard let data = data else { completion(.failure(ScriptGenerationError.noData)); return }
                
                do {
                    let response = try JSONDecoder().decode(GeminiVisionResponse.self, from: data)
                    guard let content = response.candidates.first?.content.parts.first?.text else {
                        completion(.failure(ScriptGenerationError.parseError)); return
                    }
                    let scenes = self.parseScriptIntoScenes(scriptText: content, input: input)
                    completion(.success(scenes))
                } catch {
                    do {
                        let errorResponse = try JSONDecoder().decode(GoogleCloudErrorResponse.self, from: data)
                        let errorMessage = errorResponse.error.message
                        completion(.failure(ScriptGenerationError.apiError(errorMessage)))
                    } catch {
                        completion(.failure(ScriptGenerationError.decodingError(error)))
                    }
                }
            }
        }.resume()
    }
}

*/
