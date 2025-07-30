/*
import Foundation

/// A protocol that defines the requirements for a service that can analyze an image
/// for visual information.
protocol ImageAnalysisService {
    
    /// Analyzes an image of a person and returns a `Character` object.
    /// - Parameters:
    ///   - imageData: The raw data of the image to be analyzed.
    ///   - apiKey: The API key required for the service.
    ///   - completion: A closure that returns a `Result` containing either the analyzed `Character` or an `Error`.
    func analyzeImage(
        _ imageData: Data,
        apiKey: String,
        completion: @escaping (Result<Character, Error>) -> Void
    )
    
    /// NEW: Analyzes an image of a location and returns a descriptive string.
    /// - Parameters:
    ///   - imageData: The raw data of the image to be analyzed.
    ///   - apiKey: The API key required for the service.
    ///   - completion: A closure that returns a `Result` containing either the setting description `String` or an `Error`.
    func analyzeSetting(
        _ imageData: Data,
        apiKey: String,
        completion: @escaping (Result<String, Error>) -> Void
    )
}
*/
