import SwiftUI

// This view displays the detailed information for a single character.
// Fixed with proper safe area handling, using existing InfoViews components.
struct CharacterDetailView: View {
    @Binding var character: Character
    let videoStyle: String
    @State private var showingEditCharacter = false
    
    // This computed property generates the text for the ShareLink on the fly.
    private var characterExportText: String {
        var text = "CHARACTER PROFILE: \(character.basicInfo.name)\n"
        text += "----------------------------------------\n"
        text += "Basic Info: \(character.basicInfo.age) year old \(character.basicInfo.gender) \(character.basicInfo.ethnicity).\n"
        text += "Appearance: \(character.body.height) with a \(character.body.build) build. Has \(character.hair.color) \(character.hair.style) hair and \(character.facialFeatures.eyeColor) eyes.\n"
        text += "Style: Wears \(character.clothing.overallStyle) clothing, typically a \(character.clothing.topWear) and \(character.clothing.bottomWear).\n"
        if !character.clothing.accessories.isEmpty {
            text += "Accessories: \(character.clothing.accessories).\n"
        }
        if !character.personality.traits.isEmpty {
            text += "Personality: \(character.personality.traits).\n"
        }
        if !character.consistencyNotes.isEmpty {
            text += "AI Consistency Notes: \(character.consistencyNotes)\n"
        }
        return text
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: TypewriterTheme.Spacing.extraLarge) {
                
                // Simple header - no reference image to avoid clipping
                headerSection
                
                CharacterInfoSection(title: "BASIC INFORMATION") {
                    CharacterInfoRow(label: "AGE", value: character.basicInfo.age)
                    CharacterInfoRow(label: "GENDER", value: character.basicInfo.gender)
                    CharacterInfoRow(label: "ETHNICITY", value: character.basicInfo.ethnicity)
                }
                
                CharacterInfoSection(title: "DETAILED FACIAL FEATURES") {
                    CharacterInfoRow(label: "FACE SHAPE", value: character.facialFeatures.faceShape)
                    CharacterInfoRow(label: "EYE COLOR", value: character.facialFeatures.eyeColor)
                    CharacterInfoRow(label: "EYE SHAPE", value: character.facialFeatures.eyeShape)
                    CharacterInfoRow(label: "EYEBROWS", value: character.facialFeatures.eyebrows)
                    CharacterInfoRow(label: "NOSE SHAPE", value: character.facialFeatures.noseShape)
                    CharacterInfoRow(label: "LIP SHAPE", value: character.facialFeatures.lipShape)
                    CharacterInfoRow(label: "SKIN TONE", value: character.facialFeatures.skinTone)
                    CharacterInfoRow(label: "FACIAL HAIR", value: character.facialFeatures.facialHair)
                    CharacterInfoRow(label: "DISTINCTIVE FEATURES", value: character.facialFeatures.distinctiveFeatures)
                }
                
                CharacterInfoSection(title: "HAIR DETAILS") {
                    CharacterInfoRow(label: "COLOR", value: character.hair.color)
                    CharacterInfoRow(label: "STYLE", value: character.hair.style)
                    CharacterInfoRow(label: "LENGTH", value: character.hair.length)
                    CharacterInfoRow(label: "TEXTURE", value: character.hair.texture)
                }
                
                CharacterInfoSection(title: "BODY & PHYSICAL PRESENCE") {
                    CharacterInfoRow(label: "HEIGHT", value: character.body.height)
                    CharacterInfoRow(label: "BUILD", value: character.body.build)
                    CharacterInfoRow(label: "POSTURE", value: character.body.posture)
                }
                
                CharacterInfoSection(title: "CLOTHING & ACCESSORIES") {
                    CharacterInfoRow(label: "OVERALL STYLE", value: character.clothing.overallStyle)
                    CharacterInfoRow(label: "TOP WEAR", value: character.clothing.topWear)
                    CharacterInfoRow(label: "BOTTOM WEAR", value: character.clothing.bottomWear)
                    CharacterInfoRow(label: "FOOTWEAR", value: character.clothing.footwear)
                    CharacterInfoRow(label: "ACCESSORIES", value: character.clothing.accessories)
                }
                
                if !character.personality.traits.isEmpty || !character.personality.voiceDescription.isEmpty || !character.personality.mannerisms.isEmpty {
                    CharacterInfoSection(title: "PERSONALITY & MANNERISMS") {
                        CharacterInfoRow(label: "TRAITS", value: character.personality.traits)
                        CharacterInfoRow(label: "VOICE DESCRIPTION", value: character.personality.voiceDescription)
                        CharacterInfoRow(label: "MANNERISMS", value: character.personality.mannerisms)
                    }
                }
                
                if !character.consistencyNotes.isEmpty {
                    CharacterInfoSection(title: "AI CONSISTENCY NOTES") {
                        Text(character.consistencyNotes)
                            .typewriterText(size: 14)
                            .padding(TypewriterTheme.Spacing.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(TypewriterTheme.Colors.Characters.primary.opacity(0.1))
                            .cornerRadius(TypewriterTheme.CornerRadius.medium)
                            .fixedSize(horizontal: false, vertical: true)
                            .overlay(
                                RoundedRectangle(cornerRadius: TypewriterTheme.CornerRadius.medium)
                                    .stroke(TypewriterTheme.Colors.Characters.primary.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                // Bottom spacer for safe scrolling
                Color.clear.frame(height: 60)
            }
            .padding(.horizontal, TypewriterTheme.Spacing.large)
            .padding(.top, TypewriterTheme.Spacing.small)
        }
        .background(TypewriterTheme.Colors.Characters.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TypewriterTheme.Colors.Characters.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(character.basicInfo.name.isEmpty ? "UNNAMED CHARACTER" : character.basicInfo.name.uppercased())
                    .font(.custom("Courier New", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { /* Share functionality */ }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(TypewriterTheme.Colors.Characters.primary)
                }
                Button(action: { showingEditCharacter = true }) {
                    Image(systemName: TypewriterIcons.edit)
                        .foregroundColor(TypewriterTheme.Colors.Characters.primary)
                }
            }
        }
        .sheet(isPresented: $showingEditCharacter) {
            EditCharacterSheet(character: $character)
        }
    }
    
    // MARK: - Character Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: TypewriterTheme.Spacing.medium) {
            HStack {
                Image(systemName: TypewriterIcons.character)
                    .font(.title)
                    .foregroundColor(TypewriterTheme.Colors.Characters.primary)
                
                Text("CHARACTER PROFILE")
                    .typewriterTitle(size: 20)
                    .foregroundColor(TypewriterTheme.Colors.inkBlack)
            }
            
            if character.characterImageData != nil {
                HStack(spacing: 6) {
                    Image(systemName: "photo.circle.fill")
                        .font(.caption)
                        .foregroundColor(TypewriterTheme.Colors.Characters.secondary)
                    Text("Generated from reference photo")
                        .typewriterText(size: 12, color: TypewriterTheme.Colors.Characters.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TypewriterTheme.Spacing.large)
        .typewriterCard()
    }
}

// MARK: - Character-Specific Info Components
struct CharacterInfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: TypewriterTheme.Spacing.medium) {
            HStack {
                Text(title)
                    .typewriterTitle(size: 16)
                    .foregroundColor(TypewriterTheme.Colors.Characters.primary)
                Spacer()
                Rectangle()
                    .fill(TypewriterTheme.Colors.Characters.primary)
                    .frame(height: 1)
                    .frame(maxWidth: 100)
            }
            
            VStack(alignment: .leading, spacing: TypewriterTheme.Spacing.small) {
                content
            }
        }
        .padding(TypewriterTheme.Spacing.large)
        .typewriterCard()
    }
}

struct CharacterInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        if !value.isEmpty {
            HStack(alignment: .top) {
                Text("\(label):")
                    .typewriterText(size: 14, color: TypewriterTheme.Colors.Characters.secondary)
                    .fontWeight(.semibold)
                    .frame(minWidth: 100, alignment: .leading)
                
                Text(value)
                    .typewriterText(size: 14, color: TypewriterTheme.Colors.inkBlack)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.vertical, 2)
        }
    }
}
