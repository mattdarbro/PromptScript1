import SwiftUI

// This is the final, simplified ExportView.
// It uses only the DefaultPromptFormatter and has a clean, functional UI.

struct ExportView: View {
    // Enum to define the scope of what the user can export.
    enum ExportScope: String, CaseIterable, Identifiable {
        case entireProject = "Entire Project"
        case singleScene = "Single Scene"
        case singleCharacter = "Single Character"
        var id: Self { self }
    }

    // A binding to the project, allowing this view to read project data.
    @Binding var project: Project
    
    // State variables to manage the UI selections and the output text.
    @State private var selectedScope: ExportScope = .entireProject
    @State private var selectedScene: VideoScene?
    @State private var selectedCharacter: Character?
    @State private var exportedText: String = ""
    
    // The single, default formatter for the entire app.
    private let formatter = DefaultPromptFormatter()

    // The main body is broken into smaller computed properties for clarity and performance.
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                configurationForm
                previewArea
                actionButtons
            }
            .navigationTitle("EXPORT")
            .navigationBarTitleDisplayMode(.inline)
            .background(TypewriterTheme.Colors.Export.background.ignoresSafeArea())
            .onAppear(perform: resetSelectionsAndGenerate)
            // ✨ NEW: Add keyboard dismissal functionality
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EXPORT")
                        .font(.custom("Courier New", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(TypewriterTheme.Colors.Export.primary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                }
            }
        }
    }
    
    // MARK: - Child Views
    
    /// The top section of the view containing the pickers for export configuration.
    private var configurationForm: some View {
        Form {
            Section(header: Text("Export Configuration")
                .font(.custom("Courier New", size: 16))
                .foregroundColor(TypewriterTheme.Colors.Export.primary)
                .fontWeight(.medium)) {
                Picker("Scope", selection: $selectedScope) {
                    ForEach(ExportScope.allCases) { Text($0.rawValue) }
                }
                .pickerStyle(SegmentedPickerStyle())
                // FIX: Updated onChange syntax
                .onChange(of: selectedScope) {
                    resetSelectionsAndGenerate()
                }
                
                if selectedScope == .singleScene {
                    Picker("Select Scene", selection: $selectedScene) {
                        Text("None").tag(nil as VideoScene?)
                        ForEach(project.scenes) { scene in
                            Text(scene.title.isEmpty ? "Scene \(project.scenes.firstIndex(of: scene).map { $0 + 1 } ?? 0)" : scene.title)
                                .tag(scene as VideoScene?)
                        }
                    }
                    // FIX: Updated onChange syntax
                    .onChange(of: selectedScene) {
                        generateExportText()
                    }
                }
                
                if selectedScope == .singleCharacter {
                    Picker("Select Character", selection: $selectedCharacter) {
                        Text("None").tag(nil as Character?)
                        ForEach(project.characters) { Text($0.name).tag($0 as Character?) }
                    }
                    // FIX: Updated onChange syntax
                    .onChange(of: selectedCharacter) {
                        generateExportText()
                    }
                }
            }
        }
        // ✨ NEW: Add scroll-to-dismiss for the form
        .scrollDismissesKeyboard(.interactively)
        .frame(height: 150)
    }
    
    /// The text editor area for previewing the generated prompt.
    private var previewArea: some View {
        VStack {
            Text("Export Preview")
                .font(.custom("Courier New", size: 18))
                .foregroundColor(TypewriterTheme.Colors.Export.primary)
                .padding(.top)
            ScrollView {
                Text(exportedText)
                    .font(.monospaced(.body)())
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true) // Allow horizontal wrapping, preserve vertical size
                    .background(TypewriterTheme.Colors.Export.cardBackground)
                    .cornerRadius(8)
                    .shadow(radius: 1)
                    .textSelection(.enabled) // Allow text selection for copying
            }
            .padding()
        }
        // ✨ NEW: Add scroll-to-dismiss for the preview area
        .scrollDismissesKeyboard(.interactively)
        .frame(maxHeight: .infinity)
    }
    
    /// The Copy and Share buttons at the bottom of the view.
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button(action: copyToClipboard) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .padding()
            .background(TypewriterTheme.Colors.Export.primary)
            .foregroundColor(.white)
            .cornerRadius(10)

            ShareLink(item: exportedText, subject: Text("PromptScript Export"), message: Text("Here is the script generated by PromptScript.")) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .padding()
            .background(TypewriterTheme.Colors.Export.secondary)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(.bottom)
        .disabled(exportedText.isEmpty)
    }
    
    // MARK: - Logic
    
    /// Resets the pickers to a default state and generates the initial preview text.
    private func resetSelectionsAndGenerate() {
        if selectedScope == .singleScene {
            selectedScene = project.scenes.first
        } else if selectedScope == .singleCharacter {
            selectedCharacter = project.characters.first
        }
        generateExportText()
    }

    /// Checks if the current selections are valid for generating an export.
    private func isGenerationReady() -> Bool {
        switch selectedScope {
        case .entireProject: return true
        case .singleScene: return selectedScene != nil
        case .singleCharacter: return selectedCharacter != nil
        }
    }

    /// Calls the appropriate formatter method based on the selected scope.
    private func generateExportText() {
        guard isGenerationReady() else {
            exportedText = ""
            return
        }
        
        switch selectedScope {
        case .entireProject:
            exportedText = formatter.format(project: project)
        case .singleScene:
            if let scene = selectedScene {
                // Get characters that are actually referenced in timeline events
                let timelineCharacterIDs = Set(scene.timeline.compactMap { $0.characterID })
                let sceneCharacters = project.characters.filter { timelineCharacterIDs.contains($0.id) }
                exportedText = formatter.format(scene: scene, characters: sceneCharacters, project: project)
            }
        case .singleCharacter:
            if let character = selectedCharacter {
                exportedText = formatter.format(character: character, project: project)
            }
        }
    }
    
    /// Copies the generated prompt text to the system clipboard.
    private func copyToClipboard() {
        UIPasteboard.general.string = exportedText
    }
}
