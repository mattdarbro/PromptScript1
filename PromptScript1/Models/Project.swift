import Foundation
import SwiftData

@Model
class Project {
    @Attribute(.unique) var id: UUID
    var name: String
    var projectDescription: String
    @Relationship(deleteRule: .cascade) var characters: [Character]
    @Relationship(deleteRule: .cascade) var scenes: [VideoScene]
    var createdDate: Date
    var lastModified: Date
    
    // NEW: The overall visual style for the entire project.
    var videoStyle: VideoStyle
    var customVideoStyle: String
    
    init(name: String, description: String = "") {
        self.id = UUID()
        self.name = name
        self.projectDescription = description
        self.characters = []
        self.scenes = []
        self.createdDate = Date()
        self.lastModified = Date()
        self.videoStyle = VideoStyle.cinematic
        self.customVideoStyle = ""
    }
    
    // Computed property for backward compatibility
    var description: String {
        get { projectDescription }
        set { projectDescription = newValue }
    }
}

