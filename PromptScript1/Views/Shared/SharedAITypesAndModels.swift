import Foundation

// MARK: - Core Protocols
protocol CharacterAnalysisService {
    func analyzeCharacter(imageData: Data, apiKey: String, completion: @escaping (Result<Character, Error>) -> Void)
}

protocol ScriptParsingService {
    func parseScript(_ scriptText: String, apiKey: String, completion: @escaping (Result<ScriptParseResult, Error>) -> Void)
}

protocol ScriptGenerationService {
    func generateScript(input: EnhancedScriptGenerationInput, apiKey: String, completion: @escaping (Result<[VideoScene], Error>) -> Void)
}


// MARK: - Core Input & Result Types
struct ScriptParseResult {
    let characters: [Character]
    let scenes: [VideoScene]
}

struct EnhancedScriptGenerationInput {
    var logline: String
    var duration: Int
    var sceneDuration: Int
    var videoStyle: VideoStyle
    var customVideoStyle: String?
    var storyStructure: StoryStructure
    var primaryEmotion: EmotionalTone
    var genres: [String]
    var setting: String
    var cinematographyNotes: String
    var characters: [Character]
}


// MARK: - Shared Enums (The Single Source of Truth)
enum AIProvider: String, CaseIterable, Codable {
    case openAI = "OpenAI"
    case claude = "Claude (Anthropic)"
    //case gemini = "Gemini (Google)"
    
    var isConfigured: Bool {
        switch self {
        case .openAI: return !SecureStorage.shared.openAIKey.isEmpty
        case .claude: return !SecureStorage.shared.claudeKey.isEmpty
        //case .gemini: return !SecureStorage.shared.geminiKey.isEmpty
        }
    }
}

enum AITaskType: String, CaseIterable, Codable {
    case scriptGeneration = "Script Generation"
    case scriptParsing = "Script Parsing"
    case characterAnalysis = "Character Analysis"
    case imageGeneration = "Image Generation"
    case sceneGeneration = "Scene Generation"
    case imageAnalysis = "Image Analysis"
    
    var recommendedProvider: AIProvider {
        switch self {
        case .scriptGeneration, .characterAnalysis, .sceneGeneration: return .claude
        case .scriptParsing: return .claude
        case .imageGeneration, .imageAnalysis: return .openAI
        }
    }
}

enum StoryStructure: String, CaseIterable, Codable {
    case saveTheCat = "Save the Cat"
    case threeAct = "Three-Act Structure"
    case heroesJourney = "Hero's Journey"
    case freytag = "Freytag's Pyramid"
    case simo = "SIMO"
    
    // ADDED THIS BACK IN: The missing description property
    var description: String {
        switch self {
        case .saveTheCat:
            return "Opening Image → Setup → Inciting Incident → Debate → Break into 2 → B Story → Midpoint → Bad Guys Close In → Dark Night → Break into 3 → Finale → Final Image"
        case .threeAct:
            return "Act 1: Setup (25%) → Act 2: Confrontation (50%) → Act 3: Resolution (25%)"
        case .heroesJourney:
            return "Ordinary World → Call to Adventure → Refusal → Meeting Mentor → Crossing Threshold → Tests → Revelation → Transformation → Return"
        case .freytag:
            return "Exposition → Rising Action → Climax → Falling Action → Resolution"
        case .simo:
            return "Setup character/world → Inciting incident disrupts → Midpoint revelation → Outcome/resolution"
        }
    }
    
    var beats: [String] {
        switch self {
        case .saveTheCat: return ["Opening Image", "Setup", "Inciting Incident", "Debate", "Break into 2", "Midpoint", "Dark Night", "Finale"]
        case .threeAct: return ["Setup", "Plot Point 1", "Midpoint", "Plot Point 2", "Climax", "Resolution"]
        case .heroesJourney: return ["Ordinary World", "Call to Adventure", "Meeting Mentor", "Crossing Threshold", "Tests/Trials", "Revelation", "Transformation", "Return"]
        case .freytag: return ["Exposition", "Rising Action", "Climax", "Falling Action", "Resolution"]
        case .simo: return ["Setup", "Inciting Incident", "Midpoint", "Outcome"]
        }
    }
}

enum EmotionalTone: String, CaseIterable, Codable, Hashable, Equatable {
    case tense = "Tense"
    case joyful = "Joyful"
    case melancholy = "Melancholy"
    case mysterious = "Mysterious"
    case romantic = "Romantic"
    case action = "Action"
    case peaceful = "Peaceful"
    case dramatic = "Dramatic"
    case comedy = "Comedy"
    case custom = "Custom"
}

enum EstablishingShot: String, CaseIterable, Codable, Hashable, Equatable {
    case wideAngle = "Wide Angle"
    case closeUp = "Close Up"
    case mediumShot = "Medium Shot"
    case zoomIn = "Zoom In"
    case zoomOut = "Zoom Out"
    case handheld = "Handheld"
    case tracking = "Tracking Shot"
    case overhead = "Overhead Shot"
    case lowAngle = "Low Angle"
    case highAngle = "High Angle"
    case custom = "Custom"
}

enum VideoStyle: String, CaseIterable, Codable, Hashable, Equatable {
    case cinematic = "Cinematic"
    case anime = "Anime"
    case documentary = "Documentary"
    case oldFilm = "Old Film (8mm/16mm)"
    case youTubeVlog = "YouTube Vlog"
    case hyperrealistic = "Hyperrealistic"
    case fantasy = "Fantasy"
    case custom = "Custom"
}

enum EventType: String, CaseIterable, Codable, Hashable, Equatable {
    case dialogue = "Dialogue"
    case characterAction = "Character Action"
    case actingNote = "Acting Note"
    case environmentAction = "Environment Action"
    case cameraAction = "Camera Action"
    
    // ADDED THIS BACK IN: The missing helper properties
    var requiresCharacter: Bool {
        switch self {
        case .dialogue, .characterAction, .actingNote:
            return true
        case .environmentAction, .cameraAction:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .dialogue: return "Character Dialogue"
        case .characterAction: return "Character Action"
        case .environmentAction: return "Environment Action"
        case .cameraAction: return "Camera Action"
        case .actingNote: return "Acting Note"
        }
    }
}

enum ShotMode: String, CaseIterable, Codable, Hashable, Equatable {
    case single = "Single Shot"
    case multishot = "Multi-shot"
}

enum RuleOfThirds: String, CaseIterable, Codable, Hashable, Equatable {
    case notSet = "Not Set", center = "Center Frame", leftThird = "On Left Third-Line", rightThird = "On Right Third-Line", topThird = "On Top Third-Line", bottomThird = "On Bottom Third-Line"
}

enum SubjectPlacement: String, CaseIterable, Codable, Hashable, Equatable {
    case notSet = "Not Set", foreground = "In Foreground", midground = "In Midground", background = "In Background"
}

enum EyeLine: String, CaseIterable, Codable, Hashable, Equatable {
    case notSet = "Not Set", atCamera = "Looking at Camera", offScreenLeft = "Looking Off-Screen Left", offScreenRight = "Looking Off-Screen Right", atAnotherCharacter = "Looking at Another Character"
}

enum ConnectingWord: String, CaseIterable, Codable, Hashable, Equatable {
    case then = "Then", whileAction = "While", cutTo = "Cut to", pause = "Pause", meanwhile = "Meanwhile", suddenly = "Suddenly", slowly = "Slowly", fadeIn = "Fade in", fadeOut = "Fade out", custom = "Custom", none = "None"
    
    var promptText: String {
        return self == .none ? "" : self.rawValue
    }
}

enum DialogueType: String, CaseIterable, Codable, Hashable, Equatable {
    case says, shouts, whispers, screams, mutters, laughs, cries, sighs, gasps, custom
    
    var displayName: String {
        return self == .custom ? "Custom" : self.rawValue.capitalized
    }
}

// MARK: - Shared Structs
struct Composition: Codable, Hashable, Equatable {
    var ruleOfThirds: RuleOfThirds = .notSet
    var subjectPlacement: SubjectPlacement = .notSet
    var eyeLine: EyeLine = .notSet
}

struct TimelineEvent: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var characterID: UUID?
    var eventType: EventType
    var content: String
    var connectingWord: ConnectingWord = .then
    var customConnectingWord: String = ""
    var dialogueType: DialogueType = .says
    var customDialogueType: String = ""

    init(id: UUID = UUID(), characterID: UUID? = nil, eventType: EventType, content: String, connectingWord: ConnectingWord = .then, dialogueType: DialogueType = .says) {
        self.id = id
        self.characterID = characterID
        self.eventType = eventType
        self.content = content
        self.connectingWord = connectingWord
        self.dialogueType = dialogueType
    }

    var actualConnectingWord: String {
        return connectingWord == .custom ? customConnectingWord : connectingWord.promptText
    }
}

// MARK: - API & Parsed Data Models
struct OpenAIResponse: Codable { let choices: [OpenAIChoice] }
struct OpenAIChoice: Codable { let message: OpenAIMessage }
struct OpenAIMessage: Codable { let content: String }
struct OpenAIVisionResponse: Decodable { let choices: [OpenAIVisionChoice] }
struct OpenAIVisionChoice: Decodable { let message: OpenAIVisionMessage }
struct OpenAIVisionMessage: Decodable { let content: String }
struct GeminiVisionResponse: Decodable { let candidates: [GeminiCandidate] }
struct GeminiCandidate: Decodable { let content: GeminiContent }
struct GeminiContent: Decodable { let parts: [GeminiPart] }
struct GeminiPart: Decodable { let text: String }
struct ClaudeVisionResponse: Decodable { let content: [ClaudeContent] }
struct ClaudeContent: Decodable { let text: String? }

// FINAL CORRECTION: Fully implemented the ParsedScript and CharacterAnalysisResult structs.
struct ParsedScript: Codable {
    let characters: [ParsedCharacter]
    let scenes: [ParsedScene]
}

struct ParsedCharacter: Codable {
    let name: String?
    let age: String?
    let gender: String?
    let ethnicity: String?
    let description: String?
}

struct ParsedScene: Codable {
    let title: String?
    let description: String?
    let setting: String?
    let emotion: String?
    let establishing_shot: String?
    let timeline_events: [ParsedTimelineEvent]?
}

struct ParsedTimelineEvent: Codable {
    let character_name: String
    let event_type: String
    let content: String
}

// In SharedAITypesAndModels.swift, replace the existing CharacterAnalysisResult struct with this one.

struct CharacterAnalysisResult: Codable {
    let basicInfo: BasicInfoResult
    let facialFeatures: FacialFeaturesResult
    let hair: HairResult
    let body: BodyResult
    let clothing: ClothingResult
    let personality: PersonalityResult?
    let consistencyNotes: String?
    
    // THIS FUNCTION IS NOW FULLY IMPLEMENTED
    // In your existing CharacterAnalysisResult struct,
    // find the toCharacter() method and replace JUST that method with this:

    func toCharacter() -> Character {
        var character = Character()
        
        // Basic Info
        character.basicInfo.age = basicInfo.age ?? ""
        character.basicInfo.gender = basicInfo.gender ?? ""
        character.basicInfo.ethnicity = basicInfo.ethnicity ?? ""
        
        // Facial Features
        character.facialFeatures.faceShape = facialFeatures.faceShape ?? ""
        character.facialFeatures.eyeColor = facialFeatures.eyeColor ?? ""
        character.facialFeatures.eyeShape = facialFeatures.eyeShape ?? ""
        character.facialFeatures.eyebrows = facialFeatures.eyebrows ?? ""
        character.facialFeatures.noseShape = facialFeatures.noseShape ?? ""
        character.facialFeatures.lipShape = facialFeatures.lipShape ?? ""
        character.facialFeatures.skinTone = facialFeatures.skinTone ?? ""
        character.facialFeatures.facialHair = facialFeatures.facialHair ?? ""
        character.facialFeatures.distinctiveFeatures = facialFeatures.distinctiveFeatures ?? ""
        
        // Hair
        character.hair.color = hair.color ?? ""
        character.hair.style = hair.style ?? ""
        character.hair.length = hair.length ?? ""
        character.hair.texture = hair.texture ?? ""
        
        // Body
        character.body.height = body.height ?? ""
        character.body.build = body.build ?? ""
        character.body.posture = body.posture ?? ""
        
        // Clothing
        character.clothing.topWear = clothing.topWear ?? ""
        character.clothing.bottomWear = clothing.bottomWear ?? ""
        character.clothing.footwear = clothing.footwear ?? ""
        character.clothing.accessories = clothing.accessories ?? ""
        character.clothing.overallStyle = clothing.overallStyle ?? ""
        
        // Personality & Notes
        character.personality.mannerisms = personality?.mannerisms ?? ""
        character.consistencyNotes = consistencyNotes ?? ""
        
        return character
    }
}

struct BasicInfoResult: Codable { let age: String?, gender: String?, ethnicity: String? }
struct FacialFeaturesResult: Codable { let faceShape: String?, eyeColor: String?, eyeShape: String?, eyebrows: String?, noseShape: String?, lipShape: String?, skinTone: String?, facialHair: String?, distinctiveFeatures: String? }
struct HairResult: Codable { let color: String?, style: String?, length: String?, texture: String? }
struct BodyResult: Codable { let height: String?, build: String?, posture: String? }
struct ClothingResult: Codable { let topWear: String?, bottomWear: String?, footwear: String?, accessories: String?, overallStyle: String? }
struct PersonalityResult: Codable { let mannerisms: String? }

// MARK: - Shared Error Types
enum CharacterAnalysisError: Error, LocalizedError {
    case invalidURL, encodingError, noData, parseError, invalidJSONFormat, missingAPIKey
    case decodingError(Error), serviceNotImplemented(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError:
            return "Failed to encode request data"
        case .noData:
            return "No data received from API"
        case .parseError:
            return "Failed to parse API response"
        case .invalidJSONFormat:
            return "Invalid JSON format in response"
        case .missingAPIKey:
            return "API key is missing or invalid"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serviceNotImplemented(let service):
            return "\(service) service is not yet implemented"
        }
    }
}

enum ScriptParsingError: Error, LocalizedError {
    case invalidURL, encodingError, noData, parseError, missingAPIKey
    case decodingError(Error), serviceNotImplemented(String), apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError:
            return "Failed to encode request data"
        case .noData:
            return "No data received from API"
        case .parseError:
            return "Failed to parse API response"
        case .missingAPIKey:
            return "API key is missing or invalid"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serviceNotImplemented(let service):
            return "\(service) service is not yet implemented"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

enum ImageAnalysisError: Error, LocalizedError {
    case invalidURL, encodingError, noData, noContent, missingAPIKey
    case decodingError(Error), serviceNotImplemented(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError:
            return "Failed to encode request data"
        case .noData:
            return "No data received from API"
        case .noContent:
            return "No content found in API response"
        case .missingAPIKey:
            return "API key is missing or invalid"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serviceNotImplemented(let service):
            return "\(service) service is not yet implemented"
        }
    }
}

enum ScriptGenerationError: Error, LocalizedError {
    case invalidURL
    case encodingError(Error)
    case decodingError(Error)
    case networkError(Error)
    case noData
    case parseError
    case missingAPIKey
    case serviceNotImplemented(String)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noData:
            return "No data received from API"
        case .parseError:
            return "Failed to parse API response"
        case .missingAPIKey:
            return "API key is missing or invalid"
        case .serviceNotImplemented(let service):
            return "\(service) service is not yet implemented"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

struct GoogleCloudErrorResponse: Decodable {
    let error: GoogleCloudError
}

struct GoogleCloudError: Decodable, LocalizedError {
    let code: Int
    let message: String
    let status: String

    var errorDescription: String? {
        return message
    }
}

// Add this to SharedAITypesAndModels.swift
struct ClaudeErrorResponse: Decodable {
    let type: String
    let error: ClaudeError
}

struct ClaudeError: Decodable {
    let type: String
    let message: String
}

// Add this to SharedAITypesAndModels.swift
struct OpenAIErrorResponse: Decodable {
    let error: OpenAIError
}

struct OpenAIError: Decodable {
    let message: String
    let type: String?
}

// Add this to your SharedAITypesAndModels.swift if you want cleaner API key access:

extension AIProvider {
    /// Get the API key for this provider from SecureStorage
    var apiKey: String {
        return SecureStorage.shared.getAPIKey(for: self)
    }
    
    /// Get a user-friendly display name for the provider
    var displayName: String {
        switch self {
        case .openAI:
            return "OpenAI (GPT-4)"
        case .claude:
            return "Claude (Anthropic)"
        // Add gemini back if you re-enable it:
        // case .gemini:
        //     return "Gemini (Google)"
        }
    }
}
