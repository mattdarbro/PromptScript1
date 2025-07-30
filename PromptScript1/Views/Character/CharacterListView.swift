import SwiftUI

// This view displays a list of all characters in the current project.
struct CharacterListView: View {
    @Binding var characters: [Character]
    let videoStyle: String
    @State private var showingAddCharacter = false
    
    /// A helper function to create a binding to an individual character in the array.
    /// This is necessary for NavigationLink to pass a binding to the detail view.
    private func bindingForCharacter(_ character: Character) -> Binding<Character> {
        guard let index = characters.firstIndex(where: { $0.id == character.id }) else {
            fatalError("Character not found. This should never happen.")
        }
        return $characters[index]
    }
    
    var body: some View {
        NavigationView {
            Group {
                if characters.isEmpty {
                    // Empty state with typewriter aesthetic
                    VStack(spacing: 20) {
                        Image(systemName: TypewriterIcons.characterPlaceholder)
                            .font(.system(size: 60))
                            .foregroundColor(TypewriterTheme.Colors.Characters.primary)
                        
                        Text("No Characters Yet")
                            .typewriterTitle(size: 24)
                        
                        Text("Start building your cast of characters\nfor your screenplay.")
                            .typewriterText(size: 16, color: TypewriterTheme.Colors.typewriterGray)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showingAddCharacter = true }) {
                            HStack {
                                Image(systemName: TypewriterIcons.add)
                                Text("Create First Character")
                            }
                            .typewriterButton(color: TypewriterTheme.Colors.Characters.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(1.0)
                        .animation(.typewriterBounce, value: showingAddCharacter)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TypewriterTheme.Colors.Characters.background)
                } else {
                    List {
                        ForEach(characters) { character in
                            NavigationLink(destination: CharacterDetailView(character: bindingForCharacter(character), videoStyle: videoStyle)) {
                                CharacterRowView(character: character)
                            }
                            .listRowBackground(Color.white)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteCharacters)
                    }
                    .listStyle(PlainListStyle())
                    .background(TypewriterTheme.Colors.Characters.background)
                }
            }
            .navigationTitle("CAST OF CHARACTERS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TypewriterTheme.Colors.Characters.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CAST OF CHARACTERS")
                        .font(.custom("Courier New", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(TypewriterTheme.Colors.Characters.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCharacter = true }) {
                        Image(systemName: TypewriterIcons.add)
                            .font(.title2)
                            .foregroundColor(TypewriterTheme.Colors.Characters.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddCharacter) {
                AddCharacterSheet(characters: $characters)
            }
        }
    }
    
    /// Deletes characters from the list at the specified offsets.
    private func deleteCharacters(offsets: IndexSet) {
        characters.remove(atOffsets: offsets)
    }
}

// MARK: - Character Row Component
struct CharacterRowView: View {
    let character: Character
    
    var body: some View {
        HStack(spacing: 15) {
            // Character image or colorful placeholder
            if let imageData = character.characterImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(TypewriterTheme.Colors.Characters.primary, lineWidth: 2)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [TypewriterTheme.Colors.Characters.primary.opacity(0.8), 
                                   TypewriterTheme.Colors.Characters.primary.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    Image(systemName: TypewriterIcons.character)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
            }
            
            // Character details
            VStack(alignment: .leading, spacing: 6) {
                Text(character.name.isEmpty ? "Unnamed Character" : character.name)
                    .typewriterText(size: 20, color: TypewriterTheme.Colors.inkBlack)
                    .fontWeight(.bold)
                
                if !character.age.isEmpty || !character.gender.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: TypewriterIcons.characterAge)
                            .foregroundColor(TypewriterTheme.Colors.Characters.secondary)
                            .font(.caption)
                        Text("\(character.age) \(character.gender)".trimmingCharacters(in: .whitespaces))
                            .typewriterText(size: 15, color: TypewriterTheme.Colors.Characters.secondary)
                    }
                }
                
                if !character.hairColor.isEmpty || !character.eyeColor.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: TypewriterIcons.characterFeatures)
                            .foregroundColor(TypewriterTheme.Colors.Characters.accent)
                            .font(.caption)
                        Text("\(character.hairColor) hair, \(character.eyeColor) eyes".trimmingCharacters(in: .whitespaces))
                            .typewriterText(size: 14, color: TypewriterTheme.Colors.Characters.accent)
                    }
                }
                
                // Add a subtle "CAST MEMBER" label
                HStack {
                    Text("CAST MEMBER")
                        .font(TypewriterTheme.Fonts.caption(10))
                        .foregroundColor(.white)
                        .padding(.horizontal, TypewriterTheme.Spacing.small)
                        .padding(.vertical, 2)
                        .background(TypewriterTheme.Colors.Characters.primary)
                        .cornerRadius(TypewriterTheme.CornerRadius.small)
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, TypewriterTheme.Spacing.large)
        .padding(.vertical, TypewriterTheme.Spacing.medium)
        .background(Color.white)
        .cornerRadius(TypewriterTheme.CornerRadius.large)
        .shadow(color: TypewriterTheme.Shadows.light, radius: 1, x: 0, y: 1)
    }
}

