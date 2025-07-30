import SwiftUI
import PhotosUI

// Enhanced character creation sheet with comprehensive character capture
struct AddCharacterSheet: View {
    @Binding var characters: [Character]
    @Environment(\.dismiss) private var dismiss
    
    // A single state variable to hold the new character data.
    @State private var newCharacter = Character()
    
    // State variables for the photo picker and analysis
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isAnalyzing = false
    @State private var analysisError = ""
    
    // Use SecureStorage to get the API key and the user's preferred provider.
    @StateObject private var secureStorage = SecureStorage.shared
    private let analysisService = MultiAICharacterAnalysisService()
    
    var body: some View {
        NavigationView {
            Form {
                // Section for selecting a photo and triggering AI analysis.
                Section("AI Photo Analysis") {
                    
                    // --- REMOVED: The redundant Picker for AI Provider has been removed. ---
                    // The view will now automatically use the preference from Settings.
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                            Text("Select Photo to Analyze")
                        }
                    }
                    
                    // Show the selected image.
                    if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                            .frame(maxHeight: 200)
                    }
                    
                    // Show a progress view during analysis or an error message on failure.
                    if isAnalyzing {
                        // CHANGED: The progress message now reflects the centrally-configured provider.
                        ProgressView("Analyzing with \(secureStorage.preferredCharacterAnalysisProvider.rawValue)...")
                    } else if !analysisError.isEmpty {
                        Text(analysisError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Text("💡 AI will auto-fill character details from the photo based on your preferences in Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Basic Information") {
                    FormField(label: "Name*", placeholder: "Enter character name", value: $newCharacter.basicInfo.name)
                    FormField(label: "Age", placeholder: "e.g., 30s, 25 year old", value: $newCharacter.basicInfo.age)
                    FormField(label: "Gender", placeholder: "e.g., Male, Female, Non-binary", value: $newCharacter.basicInfo.gender)
                    FormField(label: "Ethnicity", placeholder: "e.g., Caucasian, East Asian, Hispanic", value: $newCharacter.basicInfo.ethnicity)
                }
                
                Section("Detailed Facial Features") {
                    FormField(label: "Face Shape", placeholder: "e.g., oval, round, square, angular", value: $newCharacter.facialFeatures.faceShape)
                    FormField(label: "Eye Color", placeholder: "e.g., piercing blue, warm brown", value: $newCharacter.facialFeatures.eyeColor)
                    FormField(label: "Eye Shape", placeholder: "e.g., almond-shaped, wide-set", value: $newCharacter.facialFeatures.eyeShape)
                    FormField(label: "Eyebrows", placeholder: "e.g., thick, bushy, well-groomed", value: $newCharacter.facialFeatures.eyebrows)
                    FormField(label: "Nose Shape", placeholder: "e.g., straight, aquiline, button", value: $newCharacter.facialFeatures.noseShape)
                    FormField(label: "Lip Shape", placeholder: "e.g., full, thin, cupid's bow", value: $newCharacter.facialFeatures.lipShape)
                    FormField(label: "Skin Tone", placeholder: "e.g., fair, olive, dark", value: $newCharacter.facialFeatures.skinTone)
                    FormField(label: "Facial Hair", placeholder: "e.g., full beard, mustache, clean-shaven", value: $newCharacter.facialFeatures.facialHair)
                    FormField(label: "Distinctive Features", placeholder: "e.g., scar over left eye, dimples, freckles", value: $newCharacter.facialFeatures.distinctiveFeatures, isMultiline: true)
                }
                
                Section("Hair Details") {
                    FormField(label: "Hair Color", placeholder: "e.g., salt-and-pepper, auburn, jet black", value: $newCharacter.hair.color)
                    FormField(label: "Hair Style", placeholder: "e.g., short and spiky, long ponytail, buzz cut", value: $newCharacter.hair.style)
                    FormField(label: "Hair Length", placeholder: "e.g., short, shoulder-length, long", value: $newCharacter.hair.length)
                    FormField(label: "Hair Texture", placeholder: "e.g., curly, straight, wavy, coarse", value: $newCharacter.hair.texture)
                }
                
                Section("Body & Physical Presence") {
                    FormField(label: "Height", placeholder: "e.g., tall, average, 5'10\", towering", value: $newCharacter.body.height)
                    FormField(label: "Build", placeholder: "e.g., athletic, slim, stocky, muscular", value: $newCharacter.body.build)
                    FormField(label: "Posture", placeholder: "e.g., confident stance, slouched, military bearing", value: $newCharacter.body.posture)
                }
                
                Section("Clothing & Accessories") {
                    FormField(label: "Overall Style", placeholder: "e.g., business casual, bohemian, grunge", value: $newCharacter.clothing.overallStyle)
                    FormField(label: "Top Wear", placeholder: "e.g., crisp white shirt, leather jacket", value: $newCharacter.clothing.topWear)
                    FormField(label: "Bottom Wear", placeholder: "e.g., dark tailored pants, ripped jeans", value: $newCharacter.clothing.bottomWear)
                    FormField(label: "Footwear", placeholder: "e.g., polished oxfords, combat boots, sneakers", value: $newCharacter.clothing.footwear)
                    FormField(label: "Accessories", placeholder: "e.g., wire-rim glasses, silver watch, gold chain", value: $newCharacter.clothing.accessories)
                }
                
                Section("Personality & Mannerisms") {
                    FormField(label: "Personality Traits", placeholder: "e.g., witty, cynical, optimistic, brooding", value: $newCharacter.personality.traits, isMultiline: true)
                    FormField(label: "Voice Description", placeholder: "e.g., deep and gravelly, soft-spoken, commanding", value: $newCharacter.personality.voiceDescription)
                    FormField(label: "Physical Mannerisms", placeholder: "e.g., adjusts glasses when thinking, slight limp", value: $newCharacter.personality.mannerisms)
                }
                
                Section("AI Consistency Notes") {
                    FormField(label: "Special Details for AI Video", placeholder: "e.g., never removes wedding ring, always maintains eye contact, has nervous tic", value: $newCharacter.consistencyNotes, isMultiline: true)
                    
                    Text("💡 These notes help maintain character consistency across multiple video generations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Character Preview") {
                    if !newCharacter.basicInfo.name.isEmpty {
                        let previewDescription = generateCharacterPreview(newCharacter)
                        Text("Final AI Prompt Description:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(previewDescription)
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true) // Allow horizontal wrapping, preserve vertical size
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                            .textSelection(.enabled) // Allow text selection for copying
                    } else {
                        Text("Enter character name to see AI prompt preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            // ✨ NEW: Add keyboard dismissal functionality
            .scrollDismissesKeyboard(.interactively)  // Dismiss when scrolling
            // REMOVED: .dismissKeyboardOnTap() - this interferes with pickers
            .background(TypewriterTheme.Colors.Characters.background)
            .navigationTitle("CREATE CHARACTER")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TypewriterTheme.Colors.Characters.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        dismiss() 
                    }
                    .foregroundColor(TypewriterTheme.Colors.typewriterGray)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        newCharacter.characterImageData = selectedImageData
                        characters.append(newCharacter)
                        dismiss()
                    }
                    .disabled(newCharacter.basicInfo.name.isEmpty)
                    .foregroundColor(TypewriterTheme.Colors.Characters.primary)
                    .fontWeight(.semibold)
                }
                // ✨ NEW: Add Done button for keyboard
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                    .foregroundColor(TypewriterTheme.Colors.Characters.primary)
                }
            }
            .onChange(of: selectedPhoto) {
                Task {
                    guard let photoItem = selectedPhoto else { return }
                    if let data = try? await photoItem.loadTransferable(type: Data.self) {
                        selectedImageData = data
                        // Trigger the analysis after the image data is loaded.
                        analyzeImage(imageData: data)
                    }
                }
            }
        }
    }
    
    /// Enhanced image analysis using the user's preferred AI provider from Settings.
    private func analyzeImage(imageData: Data) {
        // --- CHANGED: Determine the provider from SecureStorage, not local state. ---
        let preferredProvider = secureStorage.preferredCharacterAnalysisProvider
        let apiKey = secureStorage.getAPIKey(for: preferredProvider)
        
        guard !apiKey.isEmpty else {
            analysisError = "\(preferredProvider.rawValue) API Key is not set. Please configure it in Settings."
            return
        }
        
        isAnalyzing = true
        analysisError = ""
        
        analysisService.analyzeCharacter(
            imageData: imageData,
            provider: preferredProvider, // Pass the correct provider to the service
            apiKey: apiKey
        ) { result in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                switch result {
                case .success(let analyzedCharacter):
                    // Preserve the existing ID and name if one was already typed.
                    let originalID = self.newCharacter.id
                    let originalName = self.newCharacter.basicInfo.name
                    
                    self.newCharacter = analyzedCharacter
                    self.newCharacter.id = originalID
                    
                    if !originalName.isEmpty {
                        self.newCharacter.basicInfo.name = originalName
                    }
                    
                    self.analysisError = ""
                    
                    // Track usage
                    self.secureStorage.incrementCharactersAnalyzed()
                    
                case .failure(let error):
                    if let analysisError = error as? CharacterAnalysisError {
                        switch analysisError {
                        case .serviceNotImplemented(let service):
                            self.analysisError = "\(service) analysis coming soon! Try another provider in Settings."
                        default:
                            self.analysisError = "Analysis failed: \(error.localizedDescription)"
                        }
                    } else {
                        self.analysisError = "Analysis failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    /// Generate a preview of how this character will appear in AI prompts
    private func generateCharacterPreview(_ character: Character) -> String {
        // Use the same logic as our enhanced prompt generation
        var description = character.basicInfo.name
        
        // Build comprehensive physical description
        var physicalDetails: [String] = []
        
        // Basic demographics
        if !character.basicInfo.age.isEmpty {
            physicalDetails.append("\(character.basicInfo.age)")
        }
        
        if !character.basicInfo.gender.isEmpty {
            physicalDetails.append(character.basicInfo.gender)
        }
        
        if !character.basicInfo.ethnicity.isEmpty {
            physicalDetails.append(character.basicInfo.ethnicity)
        }
        
        // Physical build and height
        var buildDesc: [String] = []
        if !character.body.height.isEmpty {
            buildDesc.append(character.body.height)
        }
        if !character.body.build.isEmpty {
            buildDesc.append(character.body.build)
        }
        if !buildDesc.isEmpty {
            physicalDetails.append(buildDesc.joined(separator: ", "))
        }
        
        // Hair
        var hairDesc: [String] = []
        if !character.hair.color.isEmpty { hairDesc.append(character.hair.color) }
        if !character.hair.length.isEmpty { hairDesc.append(character.hair.length) }
        if !character.hair.style.isEmpty { hairDesc.append(character.hair.style) }
        if !hairDesc.isEmpty {
            physicalDetails.append("\(hairDesc.joined(separator: " ")) hair")
        }
        
        // Key distinctive features
        if !character.facialFeatures.distinctiveFeatures.isEmpty {
            physicalDetails.append(character.facialFeatures.distinctiveFeatures)
        }
        
        // Accessories
        if !character.clothing.accessories.isEmpty {
            physicalDetails.append("wearing \(character.clothing.accessories)")
        }
        
        // Combine everything
        if !physicalDetails.isEmpty {
            description += " (" + physicalDetails.joined(separator: "; ") + ")"
        }
        
        return description
    }
}
