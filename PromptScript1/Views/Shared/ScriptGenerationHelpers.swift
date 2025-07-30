import SwiftUI

// NOTE: All 'enum' and 'struct' data models have been removed from this file.
// They are now correctly centralized in 'SharedAITypesAndModels.swift'.
// This file should now only contain SwiftUI View code.

// MARK: - Character Selection Row
struct CharacterSelectionRow: View {
    let character: Character
    @Binding var selectedCharacterNames: Set<String>
    
    var isSelected: Bool {
        selectedCharacterNames.contains(character.basicInfo.name)
    }
    
    var body: some View {
        Button(action: {
            if isSelected {
                selectedCharacterNames.remove(character.basicInfo.name)
            } else {
                selectedCharacterNames.insert(character.basicInfo.name)
            }
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                if let imageData = character.characterImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading) {
                    Text(character.basicInfo.name.isEmpty ? "Unnamed Character" : character.basicInfo.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text("\(character.basicInfo.age) \(character.basicInfo.gender)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Script Generation Results View
struct ScriptGenerationResultsView: View {
    @Binding var generatedScenes: [VideoScene]
    let project: Project
    let onSaveToProject: ([VideoScene]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generated Script")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("\(generatedScenes.count) scenes • ~60 seconds total")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(Array(generatedScenes.enumerated()), id: \.element.id) { index, scene in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Scene \(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Spacer()
                                Text("~\(60/max(generatedScenes.count, 1)) seconds")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !scene.title.isEmpty {
                                Text(scene.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            if !scene.description.isEmpty {
                                Text(scene.description)
                                    .font(.body)
                            }
                            
                            if !scene.setting.isEmpty {
                                HStack {
                                    Image(systemName: "location")
                                        .foregroundColor(.secondary)
                                    Text(scene.setting)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if !scene.timeline.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(scene.timeline) { event in
                                        HStack(alignment: .top) {
                                            Text(project.characters.first { $0.id == event.characterID }?.basicInfo.name ?? "Narrator")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                            Text("(\(event.eventType.rawValue)):")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("\"\(event.content)\"")
                                                .font(.caption)
                                                .italic()
                                        }
                                    }
                                }
                                .padding(.leading, 8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Generated Script")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to Project") {
                        onSaveToProject(generatedScenes)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

