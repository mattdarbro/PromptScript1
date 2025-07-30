import SwiftUI

// This view is a sheet for editing an existing character's details.
struct EditCharacterSheet: View {
    @Binding var character: Character
    @Environment(\.dismiss) private var dismiss
    
    // A temporary state variable to hold the character's data while editing.
    @State private var editableCharacter = Character()
    
    var body: some View {
        NavigationView {
            Form {
                // UPDATED: Bind to the new nested properties
                Section("Basic Information") {
                    FormField(label: "Name*", placeholder: "Enter character name", value: $editableCharacter.basicInfo.name)
                    FormField(label: "Age", placeholder: "e.g., 30s", value: $editableCharacter.basicInfo.age)
                    FormField(label: "Gender", placeholder: "e.g., Male, Female, Non-binary", value: $editableCharacter.basicInfo.gender)
                    FormField(label: "Ethnicity", placeholder: "e.g., Caucasian, East Asian", value: $editableCharacter.basicInfo.ethnicity)
                }
                
                Section("Detailed Facial Features") {
                    FormField(label: "Face Shape", placeholder: "e.g., oval, round, square, angular", value: $editableCharacter.facialFeatures.faceShape)
                    FormField(label: "Eye Color", placeholder: "e.g., piercing blue, warm brown", value: $editableCharacter.facialFeatures.eyeColor)
                    FormField(label: "Eye Shape", placeholder: "e.g., almond-shaped, wide-set", value: $editableCharacter.facialFeatures.eyeShape)
                    FormField(label: "Eyebrows", placeholder: "e.g., thick, bushy, well-groomed", value: $editableCharacter.facialFeatures.eyebrows)
                    FormField(label: "Nose Shape", placeholder: "e.g., straight, aquiline, button", value: $editableCharacter.facialFeatures.noseShape)
                    FormField(label: "Lip Shape", placeholder: "e.g., full, thin, cupid's bow", value: $editableCharacter.facialFeatures.lipShape)
                    FormField(label: "Skin Tone", placeholder: "e.g., fair, olive, dark", value: $editableCharacter.facialFeatures.skinTone)
                    FormField(label: "Facial Hair", placeholder: "e.g., full beard, mustache, clean-shaven", value: $editableCharacter.facialFeatures.facialHair)
                    FormField(label: "Distinctive Features", placeholder: "e.g., scar over left eye, dimples, freckles", value: $editableCharacter.facialFeatures.distinctiveFeatures, isMultiline: true)
                }
                
                Section("Hair Details") {
                    FormField(label: "Hair Color", placeholder: "e.g., salt-and-pepper, auburn, jet black", value: $editableCharacter.hair.color)
                    FormField(label: "Hair Style", placeholder: "e.g., short and spiky, long ponytail, buzz cut", value: $editableCharacter.hair.style)
                    FormField(label: "Hair Length", placeholder: "e.g., short, shoulder-length, long", value: $editableCharacter.hair.length)
                    FormField(label: "Hair Texture", placeholder: "e.g., curly, straight, wavy, coarse", value: $editableCharacter.hair.texture)
                }
                
                Section("Body & Physical Presence") {
                    FormField(label: "Height", placeholder: "e.g., tall, average, 5'10\", towering", value: $editableCharacter.body.height)
                    FormField(label: "Build", placeholder: "e.g., athletic, slim, stocky, muscular", value: $editableCharacter.body.build)
                    FormField(label: "Posture", placeholder: "e.g., confident stance, slouched, military bearing", value: $editableCharacter.body.posture)
                }
                
                Section("Clothing & Accessories") {
                    FormField(label: "Overall Style", placeholder: "e.g., business casual, bohemian, grunge", value: $editableCharacter.clothing.overallStyle)
                    FormField(label: "Top Wear", placeholder: "e.g., crisp white shirt, leather jacket", value: $editableCharacter.clothing.topWear)
                    FormField(label: "Bottom Wear", placeholder: "e.g., dark tailored pants, ripped jeans", value: $editableCharacter.clothing.bottomWear)
                    FormField(label: "Footwear", placeholder: "e.g., polished oxfords, combat boots, sneakers", value: $editableCharacter.clothing.footwear)
                    FormField(label: "Accessories", placeholder: "e.g., wire-rim glasses, silver watch, gold chain", value: $editableCharacter.clothing.accessories)
                }
                
                Section("Personality & Mannerisms") {
                    FormField(label: "Personality Traits", placeholder: "e.g., witty, cynical, optimistic, brooding", value: $editableCharacter.personality.traits, isMultiline: true)
                    FormField(label: "Voice Description", placeholder: "e.g., deep and gravelly, soft-spoken, commanding", value: $editableCharacter.personality.voiceDescription)
                    FormField(label: "Physical Mannerisms", placeholder: "e.g., adjusts glasses when thinking, slight limp", value: $editableCharacter.personality.mannerisms)
                }
                
                Section("AI Consistency Notes") {
                    FormField(label: "Special notes for AI", placeholder: "e.g., always wears a silver ring on right hand", value: $editableCharacter.consistencyNotes, isMultiline: true)
                }
            }
            // ✨ NEW: Add keyboard dismissal functionality
            .scrollDismissesKeyboard(.interactively)  // Dismiss when scrolling
            // REMOVED: .dismissKeyboardOnTap() - this interferes with pickers
            .navigationTitle("EDIT CHARACTER")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EDIT CHARACTER")
                        .font(.custom("Courier New", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.custom("Courier New", size: 14))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Save the changes back to the original character binding
                        character = editableCharacter
                        dismiss()
                    }
                    .font(.custom("Courier New", size: 14))
                    .disabled(editableCharacter.basicInfo.name.isEmpty)
                }
                // ✨ NEW: Add Done button for keyboard
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                    .font(.custom("Courier New", size: 14))
                }
            }
        }
        .onAppear {
            // When the view appears, copy the original character's data
            // into the editable state variable.
            editableCharacter = character
        }
    }
}
