import Foundation

// This file contains API-specific models that are NOT duplicated in SharedAITypesAndModels.swift
// All shared types (OpenAI responses, ParsedScript models) are now in SharedAITypesAndModels.swift

// MARK: - Character Analysis Models (Unique to this file)

/// Used to decode the JSON response from the character vision analysis.
struct AnalyzedCharacterDetails: Codable {
    var age: String?
    var gender: String?
    var ethnicity: String?
    var faceShape: String?
    var eyeColor: String?
    var skinTone: String?
    var facialHair: String?
    var hairColor: String?
    var hairStyle: String?
    var height: String?
    var build: String?
    var topWear: String?
    var bottomWear: String?
    var overallStyle: String?
    var accessories: String?
}
/*
// MARK: - Legacy Support (if needed)
// If other parts of your code are still using the old naming convention,
// you can create typealiases to maintain compatibility:

typealias Choice = OpenAIChoice
typealias Message = OpenAIMessage

// Note: All other models (OpenAIResponse, ParsedScript, etc.) are now
// imported from SharedAITypesAndModels.swift automatically
*/
