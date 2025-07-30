import Foundation

// MARK: - Helper Functions (Must be at top for access)

fileprivate func createEnhancedParsingPrompt(from scriptText: String) -> String {
    return """
    Analyze this script and extract character and scene information. Return ONLY valid JSON that strictly follows this structure. Do not include any explanatory text or markdown formatting.

    {
      "characters": [
        { "name": "Character Name", "age": "estimated age", "gender": "gender", "ethnicity": "ethnicity if apparent", "description": "comprehensive physical description" }
      ],
      "scenes": [
        {
          "title": "Scene title/location",
          "description": "what happens in this scene",
          "setting": "location/setting description",
          "emotion": "dominant emotion (e.g., Tense, Joyful, Melancholy)",
          "establishing_shot": "suggested establishing shot (e.g., Wide Angle, Close Up)",
          "timeline_events": [
            { "character_name": "Character Name", "event_type": "Character Action", "content": "what they do" },
            { "character_name": "Character Name", "event_type": "Dialogue", "content": "what they say" },
            { "character_name": "Character Name", "event_type": "Acting Note", "content": "how they should act" },
            { "character_name": "N/A", "event_type": "Environment Action", "content": "environmental events" },
            { "character_name": "N/A", "event_type": "Camera Action", "content": "camera movements" }
          ]
        }
      ]
    }
    
    Script to analyze:
    \(scriptText)
    """
}

fileprivate func extractJSON(from text: String) -> Data? {
    // Multiple strategies to extract JSON from AI responses
    let patterns = [
        "```json\\s*([\\s\\S]*?)\\s*```",  // JSON in code blocks
        "```\\s*([\\s\\S]*?)\\s*```",      // Generic code blocks
        "\\{[\\s\\S]*\\}"                  // Any JSON object
    ]
    
    for pattern in patterns {
        if let range = text.range(of: pattern, options: .regularExpression) {
            var jsonContent = String(text[range])
            jsonContent = jsonContent.replacingOccurrences(of: "```json", with: "")
            jsonContent = jsonContent.replacingOccurrences(of: "```", with: "")
            jsonContent = jsonContent.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let data = jsonContent.data(using: .utf8) {
                // Validate it's actually JSON
                do {
                    _ = try JSONSerialization.jsonObject(with: data)
                    return data
                } catch {
                    continue
                }
            }
        }
    }
    
    // Final fallback: try the entire text as JSON
    if let data = text.data(using: .utf8) {
        do {
            _ = try JSONSerialization.jsonObject(with: data)
            return data
        } catch {
            // Not valid JSON
        }
    }
    
    return nil
}

fileprivate func convertToScriptParseResult(_ parsed: ParsedScript) throws -> ScriptParseResult {
    let characters = parsed.characters.map { parsedChar -> Character in
        var newCharacter = Character()
        newCharacter.basicInfo.name = parsedChar.name ?? "Unknown"
        newCharacter.basicInfo.age = parsedChar.age ?? ""
        newCharacter.basicInfo.gender = parsedChar.gender ?? ""
        newCharacter.basicInfo.ethnicity = parsedChar.ethnicity ?? ""
        newCharacter.facialFeatures.distinctiveFeatures = parsedChar.description ?? ""
        return newCharacter
    }
    
    let scenes = parsed.scenes.enumerated().map { (index, parsedScene) -> VideoScene in
        var newScene = VideoScene()
        newScene.title = parsedScene.title ?? "Scene \(index + 1)"
        newScene.description = parsedScene.description ?? ""
        newScene.setting = parsedScene.setting ?? ""
        
        if let emotionText = parsedScene.emotion {
            newScene.emotion = EmotionalTone(rawValue: emotionText) ?? .dramatic
        }
        
        if let shotText = parsedScene.establishing_shot {
            newScene.establishingShot = EstablishingShot(rawValue: shotText) ?? .wideAngle
        }
        
        if let parsedEvents = parsedScene.timeline_events {
            newScene.timeline = parsedEvents.compactMap { parsedEvent -> TimelineEvent? in
                let characterID = characters.first(where: { $0.basicInfo.name == parsedEvent.character_name })?.id
                
                let eventType: EventType
                switch parsedEvent.event_type.lowercased().replacingOccurrences(of: " ", with: "") {
                case "dialogue": eventType = .dialogue
                case "characteraction": eventType = .characterAction
                case "actingnote": eventType = .actingNote
                case "environmentaction": eventType = .environmentAction
                case "cameraaction": eventType = .cameraAction
                default: eventType = .characterAction
                }
                
                return TimelineEvent(characterID: characterID, eventType: eventType, content: parsedEvent.content)
            }
        }
        
        newScene.selectedCharacters = Array(Set(newScene.timeline.compactMap { $0.characterID }))
        return newScene
    }
    
    return ScriptParseResult(characters: characters, scenes: scenes)
}

// MARK: - Multi-AI Script Parsing Coordinator
class MultiAIScriptParsingService {
    
    func parseScript(
        _ scriptText: String,
        provider: AIProvider,
        apiKey: String,
        completion: @escaping (Result<ScriptParseResult, Error>) -> Void
    ) {
        let service = getService(for: provider)
        service.parseScript(scriptText, apiKey: apiKey, completion: completion)
    }
    
    private func getService(for provider: AIProvider) -> ScriptParsingService {
        switch provider {
        case .openAI: return OpenAIScriptParsingImplementation()
        case .claude: return ClaudeScriptParsingImplementation()
        //case .gemini: return GeminiScriptParsingImplementation()
        }
    }
}

// MARK: - OpenAI Implementation (Working)
class OpenAIScriptParsingImplementation: ScriptParsingService {
    
    func parseScript(
        _ scriptText: String,
        apiKey: String,
        completion: @escaping (Result<ScriptParseResult, Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(ScriptParsingError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = createEnhancedParsingPrompt(from: scriptText)
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "response_format": ["type": "json_object"],
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 4096
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(ScriptParsingError.encodingError))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(ScriptParsingError.noData)); return }
            
            do {
                let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                guard let content = apiResponse.choices.first?.message.content,
                      let jsonData = content.data(using: .utf8) else {
                    throw ScriptParsingError.parseError
                }
                let parsedScript = try JSONDecoder().decode(ParsedScript.self, from: jsonData)
                let result = try convertToScriptParseResult(parsedScript)
                completion(.success(result))
            } catch {
                completion(.failure(ScriptParsingError.decodingError(error)))
            }
        }.resume()
    }
}

// MARK: - Fixed Claude Implementation
class ClaudeScriptParsingImplementation: ScriptParsingService {
    func parseScript(_ scriptText: String, apiKey: String, completion: @escaping (Result<ScriptParseResult, Error>) -> Void) {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            completion(.failure(ScriptParsingError.invalidURL)); return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let prompt = """
        You must respond with ONLY valid JSON. No explanations, no markdown, just JSON that follows this exact structure:

        \(createEnhancedParsingPrompt(from: scriptText))
        """
        
        let requestBody: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 4096,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(ScriptParsingError.encodingError)); return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error)); return
            }
            
            guard let data = data else {
                completion(.failure(ScriptParsingError.noData)); return
            }
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    // Try to parse Claude error response
                    if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                        completion(.failure(ScriptParsingError.apiError(errorResponse.error.message)))
                    } else {
                        let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown Claude API error"
                        completion(.failure(ScriptParsingError.apiError(errorMessage)))
                    }
                    return
                }
            }
            
            do {
                // Use the existing ClaudeVisionResponse structure from shared file
                let apiResponse = try JSONDecoder().decode(ClaudeVisionResponse.self, from: data)
                guard let content = apiResponse.content.first?.text else {
                    throw ScriptParsingError.parseError
                }
                
                // Extract JSON from Claude's response
                guard let jsonData = extractJSON(from: content) else {
                    print("Claude response content: \(content)")
                    throw ScriptParsingError.parseError
                }
                
                let parsedScript = try JSONDecoder().decode(ParsedScript.self, from: jsonData)
                let result = try convertToScriptParseResult(parsedScript)
                completion(.success(result))
            } catch {
                print("Claude parsing error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Claude raw response: \(responseString)")
                }
                completion(.failure(ScriptParsingError.decodingError(error)))
            }
        }.resume()
    }
}

// MARK: - Fixed Gemini Implementation with Rate Limiting
class GeminiScriptParsingImplementation: ScriptParsingService {
    func parseScript(_ scriptText: String, apiKey: String, completion: @escaping (Result<ScriptParseResult, Error>) -> Void) {
        performRequestWithRetry(scriptText: scriptText, apiKey: apiKey, attempt: 1, completion: completion)
    }
    
    private func performRequestWithRetry(scriptText: String, apiKey: String, attempt: Int, completion: @escaping (Result<ScriptParseResult, Error>) -> Void) {
    //private func performRequestWithRetry(scriptText: String, apiKey: String, attempt: Int, completion: @escaping (Result<ScriptParseResult, Error>) -> Void) {
        
        // Maximum 3 retry attempts
        guard attempt <= 3 else {
            completion(.failure(ScriptParsingError.apiError("Maximum retry attempts exceeded")))
            return
        }
        
        // Updated to use the correct Gemini API endpoint
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=\(apiKey)") else {
            completion(.failure(ScriptParsingError.invalidURL)); return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0
        
        if attempt > 1 {
            print("🔄 Gemini retry attempt \(attempt)/3")
        }

        let prompt = """
        You must respond with valid JSON only. No explanations or markdown. Use this exact structure:

        \(createEnhancedParsingPrompt(from: scriptText))
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": prompt
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "topP": 0.8,
                "topK": 40,
                "maxOutputTokens": 4096
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(ScriptParsingError.encodingError)); return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(ScriptParsingError.apiError("Network error: \(error.localizedDescription)")))
                return
            }
            
            guard let data = data else {
                completion(.failure(ScriptParsingError.noData))
                return
            }
            
            // Check for rate limiting (429) and retry with exponential backoff
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    let delaySeconds = pow(2.0, Double(attempt)) // 2, 4, 8 seconds
                    print("⏱️ Rate limited. Retrying in \(delaySeconds) seconds...")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
                        self?.performRequestWithRetry(
                            scriptText: scriptText,
                            apiKey: apiKey,
                            attempt: attempt + 1,
                            completion: completion
                        )
                    }
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    if let errorResponse = try? JSONDecoder().decode(GoogleCloudErrorResponse.self, from: data) {
                        completion(.failure(ScriptParsingError.apiError(errorResponse.error.message)))
                    } else {
                        let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown Gemini API error"
                        completion(.failure(ScriptParsingError.apiError(errorMessage)))
                    }
                    return
                }
            }
            
            do {
                let apiResponse = try JSONDecoder().decode(GeminiVisionResponse.self, from: data)
                guard let content = apiResponse.candidates.first?.content.parts.first?.text else {
                    throw ScriptParsingError.parseError
                }
                
                guard let jsonData = extractJSON(from: content) else {
                    throw ScriptParsingError.parseError
                }
                
                let parsedScript = try JSONDecoder().decode(ParsedScript.self, from: jsonData)
                let result = try convertToScriptParseResult(parsedScript)
                print("✅ Gemini: Successfully parsed script with \(result.characters.count) characters and \(result.scenes.count) scenes")
                completion(.success(result))
            } catch {
                print("❌ Gemini parsing error: \(error)")
                completion(.failure(ScriptParsingError.decodingError(error)))
            }
        }.resume()
    }
}

