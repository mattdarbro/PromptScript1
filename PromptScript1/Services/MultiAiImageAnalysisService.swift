import Foundation

// Protocol for image analysis services
// Shared types are imported from SharedAITypes.swift
protocol ImageAnalysisService {
    func analyzeSetting(
        imageData: Data,
        apiKey: String,
        completion: @escaping (Result<String, Error>) -> Void
    )
}

// MARK: - Multi-AI Image Analysis Coordinator
class MultiAIImageAnalysisService {
    
    func analyzeSetting(
        imageData: Data,
        provider: AIProvider,
        apiKey: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let service = getService(for: provider)
        service.analyzeSetting(imageData: imageData, apiKey: apiKey, completion: completion)
    }
    
    private func getService(for provider: AIProvider) -> ImageAnalysisService {
        switch provider {
        case .openAI: return OpenAIImageAnalysisImplementation()
        case .claude: return ClaudeImageAnalysisImplementation()
        //case .gemini: return GeminiImageAnalysisImplementation()
        }
    }
    
    // Smart analysis with fallback
    func analyzeSettingWithFallback(
        imageData: Data,
        primaryProvider: AIProvider,
        apiKeys: [AIProvider: String],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let primaryKey = apiKeys[primaryProvider] else {
            completion(.failure(ImageAnalysisError.missingAPIKey))
            return
        }
        
        analyzeSetting(imageData: imageData, provider: primaryProvider, apiKey: primaryKey) { result in
            switch result {
            case .success(let setting):
                completion(.success(setting))
            case .failure(let error):
                // Try fallback providers
                self.tryFallbackProviders(
                    imageData: imageData,
                    excludingProvider: primaryProvider,
                    apiKeys: apiKeys,
                    primaryError: error,
                    completion: completion
                )
            }
        }
    }
    
    private func tryFallbackProviders(
        imageData: Data,
        excludingProvider: AIProvider,
        apiKeys: [AIProvider: String],
        primaryError: Error,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let fallbackProviders = AIProvider.allCases.filter { $0 != excludingProvider }
        
        guard !fallbackProviders.isEmpty else {
            completion(.failure(primaryError))
            return
        }
        
        let nextProvider = fallbackProviders[0]
        guard let apiKey = apiKeys[nextProvider] else {
            completion(.failure(primaryError))
            return
        }
        
        analyzeSetting(imageData: imageData, provider: nextProvider, apiKey: apiKey) { result in
            switch result {
            case .success(let setting):
                completion(.success(setting))
            case .failure:
                completion(.failure(primaryError))
            }
        }
    }
}

// MARK: - OpenAI Implementation
class OpenAIImageAnalysisImplementation: ImageAnalysisService {
    
    func analyzeSetting(
        imageData: Data,
        apiKey: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let prompt = """
        Analyze this image and describe the location as a concise scene setting for a movie script. 
        
        Provide a detailed but focused description that includes:
        - Primary environment/location type
        - Time of day and lighting conditions
        - Overall mood and atmosphere
        - Key visual elements that establish the setting
        
        Limit the description to 2-3 sentences. Focus on creating a vivid setting description that would help an AI video generator understand the scene.
        
        Example format: "A bustling downtown coffee shop during morning rush hour, filled with warm golden light streaming through large windows. The atmosphere is energetic yet cozy, with the sounds of espresso machines and quiet conversations creating an urban sanctuary."
        """
        
        callVisionAPI(prompt: prompt, imageData: imageData, apiKey: apiKey, completion: completion)
    }
    
    private func callVisionAPI(
        prompt: String,
        imageData: Data,
        apiKey: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(ImageAnalysisError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let base64Image = imageData.base64EncodedString()
        
        let payload: [String: Any] = [
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
            "max_tokens": 200
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(ImageAnalysisError.encodingError))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(ImageAnalysisError.noData))
                return
            }
            
            do {
                let openAIResponse = try JSONDecoder().decode(OpenAIVisionResponse.self, from: data)
                if let content = openAIResponse.choices.first?.message.content {
                    completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else {
                    completion(.failure(ImageAnalysisError.noContent))
                }
            } catch {
                completion(.failure(ImageAnalysisError.decodingError(error)))
            }
        }.resume()
    }
}

// MARK: - Claude Implementation (Complete)
class ClaudeImageAnalysisImplementation: ImageAnalysisService {
    
    func analyzeSetting(
        imageData: Data,
        apiKey: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("🔵 Claude: Starting setting image analysis")
        print("🔵 Claude: Image data size: \(imageData.count) bytes")
        print("🔵 Claude: API Key present: \(!apiKey.isEmpty)")
        
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            print("❌ Claude: Invalid URL")
            completion(.failure(ImageAnalysisError.invalidURL))
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        let imageType = getImageType(from: imageData)
        
        let prompt = """
        Analyze this image and describe the location as a concise scene setting for a movie script.
        
        Provide a detailed but focused description that includes:
        - Primary environment/location type
        - Time of day and lighting conditions  
        - Overall mood and atmosphere
        - Key visual elements that establish the setting
        
        Limit the description to 2-3 sentences. Focus on creating a vivid setting description that would help an AI video generator understand the scene.
        
        Example format: "A bustling downtown coffee shop during morning rush hour, filled with warm golden light streaming through large windows. The atmosphere is energetic yet cozy, with the sounds of espresso machines and quiet conversations creating an urban sanctuary."
        
        Respond with ONLY the setting description, no additional text or formatting.
        """
        
        let requestBody: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 300,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": imageType,
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
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
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("🔵 Claude: Request body created successfully")
        } catch {
            print("❌ Claude: Encoding error: \(error)")
            completion(.failure(ImageAnalysisError.encodingError))
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
                    completion(.failure(ImageAnalysisError.noData))
                    return
                }
                
                print("🔵 Claude: Received data: \(data.count) bytes")
                
                // Print raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔵 Claude: Raw response: \(responseString.prefix(500))...")
                }
                
                do {
                    let response = try JSONDecoder().decode(ClaudeVisionResponse.self, from: data)
                    guard let content = response.content.first?.text else {
                        print("❌ Claude: No content in response")
                        completion(.failure(ImageAnalysisError.noContent))
                        return
                    }
                    
                    print("✅ Claude: Setting description received: \(content.prefix(150))...")
                    
                    // Clean up the response
                    let cleanedContent = content
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "\"", with: "") // Remove quotes if present
                    
                    completion(.success(cleanedContent))
                    
                } catch {
                    print("❌ Claude: Decoding error: \(error)")
                    
                    // Try to decode error response
                    do {
                        let errorResponse = try JSONDecoder().decode(ClaudeErrorResponse.self, from: data)
                        let errorMessage = errorResponse.error.message
                        print("❌ Claude: API Error: \(errorMessage)")
                        completion(.failure(ImageAnalysisError.decodingError(NSError(domain: "ClaudeAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))))
                    } catch {
                        print("❌ Claude: Failed to decode error response: \(error)")
                        completion(.failure(ImageAnalysisError.decodingError(error)))
                    }
                }
            }
        }.resume()
    }
    
    private func getImageType(from data: Data) -> String {
        guard data.count > 4 else { return "image/jpeg" }
        
        let bytes = data.prefix(4)
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "image/jpeg"
        } else if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "image/png"
        } else if bytes.starts(with: [0x47, 0x49, 0x46]) {
            return "image/gif"
        } else if bytes.starts(with: [0x52, 0x49, 0x46, 0x46]) {
            return "image/webp"
        } else {
            return "image/jpeg" // Default fallback
        }
    }
}
/*
// MARK: - Gemini Implementation (Stub)
class GeminiImageAnalysisImplementation: ImageAnalysisService {
    func analyzeSetting(imageData: Data, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        // TODO: Implement Gemini image analysis
        completion(.failure(ImageAnalysisError.serviceNotImplemented("Gemini")))
    }
}
*/
