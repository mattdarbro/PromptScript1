//
//  FormHelperViews.swift
//  PromptScript1
//
//  Created by Matt Darbro on 7/4/25.
//

import SwiftUI

// A reusable picker for cinematography options that supports a "Custom" field.
struct CinematographyPicker: View {
    let label: String
    @Binding var selection: String
    @Binding var customSelection: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker(label, selection: $selection) {
                Text("Not Set").tag("")
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
                Text("Custom").tag("Custom")
            }
            
            if selection == "Custom" {
                TextField("Enter custom value", text: $customSelection)
                    .textFieldStyle(TypewriterTextFieldStyle())
            }
        }
    }
}

// A reusable view for handling character selection and actions in a scene form.
struct CharacterActionRow: View {
    let character: Character
    @Binding var selectedCharacters: Set<String>
    @Binding var characterActions: [String: String]
    @Binding var dialogue: [String: String]
    @Binding var actingNotes: [String: String]
    
    var isSelected: Bool {
        selectedCharacters.contains(character.name)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(character.name)
                    .fontWeight(.medium)
                Spacer()
                Button(action: toggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                }
            }
            
            if isSelected {
                Group {
                    TextField("Action (e.g., walking slowly)", text: binding(for: $characterActions))
                        .textFieldStyle(TypewriterTextFieldStyle())
                    TextField("Dialogue (key lines)", text: binding(for: $dialogue), axis: .vertical)
                        .textFieldStyle(TypewriterTextFieldStyle())
                    TextField("Acting Note (e.g., angry whisper)", text: binding(for: $actingNotes), axis: .vertical)
                        .textFieldStyle(TypewriterTextFieldStyle())
                }
                .font(TypewriterTheme.Fonts.caption())
                .padding(.leading)
            }
        }
        .padding(.vertical, 4)
    }
    
    /// Toggles the selection state for the character.
    private func toggleSelection() {
        if isSelected {
            selectedCharacters.remove(character.name)
            characterActions.removeValue(forKey: character.name)
            dialogue.removeValue(forKey: character.name)
            actingNotes.removeValue(forKey: character.name)
        } else {
            selectedCharacters.insert(character.name)
        }
    }
    
    /// Creates a binding to the dictionary for the specific character.
    private func binding(for dictionary: Binding<[String: String]>) -> Binding<String> {
        return Binding<String>(
            get: { dictionary.wrappedValue[character.name] ?? "" },
            set: { dictionary.wrappedValue[character.name] = $0 }
        )
    }
}
