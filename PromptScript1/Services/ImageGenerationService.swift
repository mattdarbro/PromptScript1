//
//  ImageGenerationService.swift
//  PromptScript1
//
//  Created by Matt Darbro on 7/4/25.
//

import Foundation

/// A protocol that defines the requirements for a service that can generate an image from a text prompt.
protocol ImageGenerationService {
    
    /// Generates an image based on a descriptive text prompt.
    /// - Parameters:
    ///   - prompt: A detailed text description of the image to generate.
    ///   - apiKey: The API key required for the image generation service.
    ///   - completion: A closure that returns a `Result` containing either the image `Data` or an `Error`.
    func generateImage(
        from prompt: String,
        apiKey: String,
        completion: @escaping (Result<Data, Error>) -> Void
    )
}

//Step 1
// MARK: - OpenAI Implementation
class OpenAIImageGenerationService: ImageGenerationService {
    private let baseURL = "https://api.openai.com/v1/images/generations"
    
    func generateImage(from prompt: String, apiKey: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(ImageGenerationError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
            "response_format": "url"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(ImageGenerationError.encodingError(error)))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(ImageGenerationError.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(ImageGenerationError.noData))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataArray = json["data"] as? [[String: Any]],
                   let imageURL = dataArray.first?["url"] as? String {
                    
                    self.downloadImage(from: imageURL, completion: completion)
                } else {
                    completion(.failure(ImageGenerationError.decodingError(NSError(domain: "Parse error", code: 0))))
                }
            } catch {
                completion(.failure(ImageGenerationError.decodingError(error)))
            }
        }.resume()
    }
    
    private func downloadImage(from urlString: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(ImageGenerationError.invalidImageURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(ImageGenerationError.imageDownloadError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(ImageGenerationError.noImageData))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
}

// MARK: - Error Types
enum ImageGenerationError: Error, LocalizedError {
    case invalidURL
    case invalidImageURL
    case encodingError(Error)
    case decodingError(Error)
    case networkError(Error)
    case imageDownloadError(Error)
    case noData
    case noImageData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .invalidImageURL: return "Invalid image URL received"
        case .encodingError(let error): return "Request encoding error: \(error.localizedDescription)"
        case .decodingError(let error): return "Response decoding error: \(error.localizedDescription)"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .imageDownloadError(let error): return "Image download error: \(error.localizedDescription)"
        case .noData: return "No data received"
        case .noImageData: return "No image data received"
        }
    }
}
