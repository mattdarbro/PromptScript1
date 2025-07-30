import Foundation


// This class acts as a coordinator, delegating the analysis task to the
// appropriate service based on the user's selected provider.
class MultiAICharacterAnalysisService {
    
    func analyzeCharacter(
        imageData: Data,
        provider: AIProvider,
        apiKey: String,
        completion: @escaping (Result<Character, Error>) -> Void
    ) {
        let service = getService(for: provider)
        service.analyzeCharacter(imageData: imageData, apiKey: apiKey, completion: completion)
    }
    
    // Returns the concrete service implementation for a given AI provider.
    private func getService(for provider: AIProvider) -> CharacterAnalysisService {
        switch provider {
        case .openAI: return OpenAICharacterAnalysisService()
        case .claude: return ClaudeCharacterAnalysisService()
        //case .gemini: return GeminiCharacterAnalysisService()
        }
    }
}


// MARK: - OpenAI Character Analysis Service
class OpenAICharacterAnalysisService: CharacterAnalysisService {
    
    func analyzeCharacter(
        imageData: Data,
        apiKey: String,
        completion: @escaping (Result<Character, Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(CharacterAnalysisError.invalidURL))
            return
        }
        
        // Convert image to base64 for the JSON payload.
        let base64Image = imageData.base64EncodedString()
        let prompt = createEnhancedCharacterAnalysisPrompt()
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                    ]
                ]
            ],
            "max_tokens": 1500
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(CharacterAnalysisError.encodingError))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(CharacterAnalysisError.noData))
                return
            }
            
            do {
                // CORRECTED: Decodes using the shared OpenAIVisionResponse struct
                let response = try JSONDecoder().decode(OpenAIVisionResponse.self, from: data)
                guard let content = response.choices.first?.message.content else {
                    completion(.failure(CharacterAnalysisError.parseError))
                    return
                }
                
                let character = try parseCharacterFromContent(content)
                completion(.success(character))
                
            } catch {
                completion(.failure(CharacterAnalysisError.decodingError(error)))
            }
        }.resume()
    }
}

// Updated Claude Character Analysis Service that matches your Character model

class ClaudeCharacterAnalysisService: CharacterAnalysisService {
    func analyzeCharacter(imageData: Data, apiKey: String, completion: @escaping (Result<Character, Error>) -> Void) {
        print("🔵 Claude: Starting character analysis")
        print("🔵 Claude: Image data size: \(imageData.count) bytes")
        print("🔵 Claude: API Key present: \(!apiKey.isEmpty)")
        
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            print("❌ Claude: Invalid URL")
            completion(.failure(CharacterAnalysisError.invalidURL))
            return
        }

        let base64Image = imageData.base64EncodedString()
        let prompt = createEnhancedCharacterAnalysisPrompt()

        // FIXED: Use the correct Claude model name
        let requestBody: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",  // Changed from claude-3-opus-20240229
            "max_tokens": 1500,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "image", "source": ["type": "base64", "media_type": "image/jpeg", "data": base64Image]],
                        ["type": "text", "text": prompt]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            print("🔵 Claude: Request body created successfully")
        } catch {
            print("❌ Claude: Encoding error: \(error)")
            completion(.failure(CharacterAnalysisError.encodingError))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Claude: Network error: \(error)")
                    completion(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔵 Claude: HTTP Status: \(httpResponse.statusCode)")
                }

                guard let data = data else {
                    print("❌ Claude: No data received")
                    completion(.failure(CharacterAnalysisError.noData))
                    return
                }
                
                print("🔵 Claude: Received data: \(data.count) bytes")
                
                // Print raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔵 Claude: Raw response: \(responseString.prefix(1000))...")
                }

                do {
                    let response = try JSONDecoder().decode(ClaudeVisionResponse.self, from: data)
                    guard let content = response.content.first?.text else {
                        print("❌ Claude: No content in response")
                        completion(.failure(CharacterAnalysisError.parseError))
                        return
                    }
                    
                    print("✅ Claude: Content received: \(content.prefix(300))...")
                    
                    let character = try parseCharacterFromContent(content)
                    
                    // FIXED: Set the original image data in the character
                    var finalCharacter = character
                    finalCharacter.characterImageData = imageData
                    
                    completion(.success(finalCharacter))
                } catch {
                    print("❌ Claude: Decoding error: \(error)")
                    
                    // Try to decode error response
                    do {
                        let errorResponse = try JSONDecoder().decode(ClaudeErrorResponse.self, from: data)
                        let errorMessage = errorResponse.error.message
                        print("❌ Claude: API Error: \(errorMessage)")
                        completion(.failure(CharacterAnalysisError.parseError))
                    } catch {
                        print("❌ Claude: Failed to decode error response: \(error)")
                        completion(.failure(CharacterAnalysisError.decodingError(error)))
                    }
                }
            }
        }.resume()
    }
}
/*
// MARK: - Gemini Character Analysis Service
class GeminiCharacterAnalysisService: CharacterAnalysisService {
    func analyzeCharacter(imageData: Data, apiKey: String, completion: @escaping (Result<Character, Error>) -> Void) {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=\(apiKey)") else {
            completion(.failure(CharacterAnalysisError.invalidURL))
            return
        }

        let base64Image = imageData.base64EncodedString()
        let prompt = createEnhancedCharacterAnalysisPrompt()

        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": base64Image]]
                ]]
            ],
            "generationConfig": ["response_mime_type": "application/json"]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(CharacterAnalysisError.encodingError))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(CharacterAnalysisError.noData))
                return
            }

            do {
                // CORRECTED: Decodes using the shared GeminiVisionResponse struct
                let response = try JSONDecoder().decode(GeminiVisionResponse.self, from: data)
                guard let content = response.candidates.first?.content.parts.first?.text else {
                    completion(.failure(CharacterAnalysisError.parseError))
                    return
                }
                let character = try parseCharacterFromContent(content)
                completion(.success(character))
            } catch {
                completion(.failure(CharacterAnalysisError.decodingError(error)))
            }
        }.resume()
    }
}
*/

// MARK: - Shared Helper Functions

// Creates a standardized, detailed prompt for any AI vision model.
fileprivate func createEnhancedCharacterAnalysisPrompt() -> String {
    return """
    Analyze this person's appearance and return ONLY valid JSON with comprehensive character details.
    Use this EXACT structure - fill in all available details or use empty strings:
    {
      "basicInfo": { "age": "estimated age (e.g., '30s', '45 year old')", "gender": "apparent gender", "ethnicity": "apparent ethnicity" },
      "facialFeatures": { "faceShape": "face shape", "eyeColor": "eye color", "eyeShape": "eye shape description", "eyebrows": "eyebrow description", "noseShape": "nose shape", "lipShape": "lip shape", "skinTone": "skin tone", "facialHair": "facial hair description", "distinctiveFeatures": "scars, marks, unique features" },
      "hair": { "color": "hair color", "style": "hair style", "length": "hair length", "texture": "hair texture" },
      "body": { "height": "apparent height", "build": "body build", "posture": "posture description" },
      "clothing": { "topWear": "top clothing", "bottomWear": "bottom clothing", "footwear": "shoes/footwear", "accessories": "glasses, jewelry, etc", "overallStyle": "overall style" },
      "personality": { "mannerisms": "visible mannerisms or expressions" },
      "consistencyNotes": "key identifying features for AI consistency"
    }
    Return ONLY the JSON object, no other text or markdown formatting.
    """
}

// Parses the string response from an AI into a Character object.
fileprivate func parseCharacterFromContent(_ content: String) throws -> Character {
    guard let jsonData = extractJSON(from: content) else {
        throw CharacterAnalysisError.invalidJSONFormat
    }
    
    do {
        let characterData = try JSONDecoder().decode(CharacterAnalysisResult.self, from: jsonData)
        return characterData.toCharacter()
    } catch {
        throw CharacterAnalysisError.decodingError(error)
    }
}

// Extracts a JSON string from a larger string, cleaning up markdown fences if present.
fileprivate func extractJSON(from text: String) -> Data? {
    if let range = text.range(of: "```json\\s*([\\s\\S]*?)\\s*```", options: .regularExpression) {
        let jsonContent = String(text[range])
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return jsonContent.data(using: .utf8)
    }
    
    if let firstBrace = text.firstIndex(of: "{"), let lastBrace = text.lastIndex(of: "}") {
        let jsonString = String(text[firstBrace...lastBrace])
        return jsonString.data(using: .utf8)
    }
    
    return text.data(using: .utf8)
}

// NOTE: The local API Response Data Models have been removed from this file.
// They are now correctly centralized in SharedAITypesAndModels.swift

