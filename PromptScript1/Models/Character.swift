import Foundation
import SwiftData

// Detailed Character model, now with nested structs for better organization.
// FIX: Added Hashable and Equatable conformance to all nested structs.
@Model
class Character {
    var id = UUID()
    var characterImageData: Data? = nil
    
    // MARK: - Nested Data Structures
    
    struct BasicInfo: Codable, Hashable, Equatable {
        var name: String = ""
        var age: String = ""
        var gender: String = ""
        var ethnicity: String = ""
    }
    
    struct FacialFeatures: Codable, Hashable, Equatable {
        var faceShape: String = ""
        var eyeColor: String = ""
        var eyeShape: String = ""
        var eyebrows: String = ""
        var noseShape: String = ""
        var lipShape: String = ""
        var skinTone: String = ""
        var facialHair: String = ""
        var distinctiveFeatures: String = ""
    }
    
    struct Hair: Codable, Hashable, Equatable {
        var color: String = ""
        var style: String = ""
        var length: String = ""
        var texture: String = ""
    }
    
    struct Body: Codable, Hashable, Equatable {
        var height: String = ""
        var build: String = ""
        var posture: String = ""
    }
    
    struct Clothing: Codable, Hashable, Equatable {
        var topWear: String = ""
        var bottomWear: String = ""
        var footwear: String = ""
        var accessories: String = ""
        var overallStyle: String = ""
    }
    
    struct Personality: Codable, Hashable, Equatable {
        var traits: String = ""
        var voiceDescription: String = ""
        var mannerisms: String = ""
    }
    
    // MARK: - Main Character Properties
    
    var basicInfo: BasicInfo = BasicInfo()
    var facialFeatures: FacialFeatures = FacialFeatures()
    var hair: Hair = Hair()
    var body: Body = Body()
    var clothing: Clothing = Clothing()
    var personality: Personality = Personality()
    var consistencyNotes: String = ""
    
    // Convenience properties for easier access in some views (read-only)
    var name: String { basicInfo.name }
    var age: String { basicInfo.age }
    var gender: String { basicInfo.gender }
    var hairColor: String { hair.color }
    var eyeColor: String { facialFeatures.eyeColor }
    var style: String { clothing.overallStyle }
    
    // Initializer to allow creating an empty character easily
    init() {}
    
    // MARK: - Character Description Utilities
    
    /// Generates a comprehensive character description for AI prompts
    func generateComprehensiveDescription() -> String {
        var description = basicInfo.name
        
        var physicalDetails: [String] = []
        
        // Basic demographics
        if !basicInfo.age.isEmpty { physicalDetails.append("\(basicInfo.age) year old") }
        if !basicInfo.gender.isEmpty { physicalDetails.append(basicInfo.gender) }
        if !basicInfo.ethnicity.isEmpty { physicalDetails.append(basicInfo.ethnicity) }
        
        // Physical build and height
        var buildDesc: [String] = []
        if !body.height.isEmpty { buildDesc.append(body.height) }
        if !body.build.isEmpty { buildDesc.append(body.build) }
        if !buildDesc.isEmpty { physicalDetails.append(buildDesc.joined(separator: ", ")) }
        
        // Hair description
        var hairDesc: [String] = []
        if !hair.color.isEmpty { hairDesc.append(hair.color) }
        if !hair.length.isEmpty { hairDesc.append(hair.length) }
        if !hair.style.isEmpty { hairDesc.append(hair.style) }
        if !hair.texture.isEmpty { hairDesc.append(hair.texture) }
        if !hairDesc.isEmpty {
            physicalDetails.append("\(hairDesc.joined(separator: " ")) hair")
        }
        
        // Facial features
        var faceDesc: [String] = []
        if !facialFeatures.eyeColor.isEmpty { faceDesc.append("\(facialFeatures.eyeColor) eyes") }
        if !facialFeatures.eyeShape.isEmpty { faceDesc.append("\(facialFeatures.eyeShape) eye shape") }
        if !facialFeatures.faceShape.isEmpty { faceDesc.append("\(facialFeatures.faceShape) face") }
        if !facialFeatures.skinTone.isEmpty { faceDesc.append("\(facialFeatures.skinTone) skin") }
        if !facialFeatures.facialHair.isEmpty { faceDesc.append(facialFeatures.facialHair) }
        if !faceDesc.isEmpty {
            physicalDetails.append(faceDesc.joined(separator: ", "))
        }
        
        // Distinctive features
        if !facialFeatures.distinctiveFeatures.isEmpty {
            physicalDetails.append(facialFeatures.distinctiveFeatures)
        }
        
        // Clothing and style
        var clothingDesc: [String] = []
        if !clothing.overallStyle.isEmpty { clothingDesc.append("\(clothing.overallStyle) style") }
        if !clothing.topWear.isEmpty { clothingDesc.append(clothing.topWear) }
        if !clothing.bottomWear.isEmpty { clothingDesc.append(clothing.bottomWear) }
        if !clothing.footwear.isEmpty { clothingDesc.append(clothing.footwear) }
        if !clothingDesc.isEmpty {
            physicalDetails.append("wearing \(clothingDesc.joined(separator: ", "))")
        }
        
        // Accessories
        if !clothing.accessories.isEmpty {
            physicalDetails.append("with \(clothing.accessories)")
        }
        
        // Body posture
        if !body.posture.isEmpty {
            physicalDetails.append("\(body.posture) posture")
        }
        
        // Personality traits that affect visual presentation
        if !personality.mannerisms.isEmpty {
            physicalDetails.append(personality.mannerisms)
        }
        
        // Consistency notes for AI
        if !consistencyNotes.isEmpty {
            physicalDetails.append(consistencyNotes)
        }
        
        // Combine everything
        if !physicalDetails.isEmpty {
            description += " (" + physicalDetails.joined(separator: "; ") + ")"
        }
        
        return description
    }
}

