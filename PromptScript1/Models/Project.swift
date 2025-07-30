import Foundation

struct Project: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String = ""
    var characters: [Character] = []
    var scenes: [VideoScene] = []
    var createdDate: Date = Date()
    var lastModified: Date = Date()
    
    // NEW: The overall visual style for the entire project.
    var videoStyle: VideoStyle = .cinematic
    var customVideoStyle: String = ""
}

