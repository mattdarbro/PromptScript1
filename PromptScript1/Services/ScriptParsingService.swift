/*
import Foundation

/// The public data container for the result of any parsing service.
/// Any part of the app that calls a parser will expect to receive this struct.
struct ScriptParseResult {
    var characters: [Character]
    var scenes: [VideoScene]
}

/// The protocol that all parsing services (OpenAI, Gemini, Claude, etc.) must conform to.
/// It defines the standard function that our app will call to parse a script.
protocol ScriptParsingService {
    
    /// Parses the provided script text and returns characters and scenes.
    /// - Parameters:
    ///   - scriptText: The raw script text to be analyzed.
    ///   - apiKey: The API key required for the service.
    ///   - completion: A closure that returns a `Result` containing either the `ScriptParseResult` or an `Error`.
    func parseScript(
        _ scriptText: String,
        apiKey: String,
        completion: @escaping (Result<ScriptParseResult, Error>) -> Void
    )
}

*/
