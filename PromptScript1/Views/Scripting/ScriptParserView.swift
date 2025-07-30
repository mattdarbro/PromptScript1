import SwiftUI

// This view provides the UI for pasting or importing a script
// and initiating the AI parsing process using the multi-AI framework.
struct ScriptParserView: View {
    @Binding var characters: [Character]
    @Binding var scenes: [VideoScene]
    @ObservedObject var secureStorage: SecureStorage
    let project: Project
    
    @State private var scriptText = ""
    @State private var isProcessing = false
    @State private var showingResults = false
    @State private var parseResults: ScriptParseResult?
    @State private var errorMessage = ""
    @State private var showingFilePicker = false
    @State private var showingSettings = false
    @State private var showingScriptGenerator = false
    @State private var selectedProvider: AIProvider = .claude// Default to recommended provider
    
    // Use the multi-AI parsing service
    private let multiAIParser = MultiAIScriptParsingService()
    
    private var isKeySet: Bool {
        return selectedProvider.isConfigured
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("AI Script Parser")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gear")
                            }
                        }
                        
                        // AI Provider Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI Provider")
                                .font(.headline)
                            
                            Picker("Provider", selection: $selectedProvider) {
                                ForEach(AIProvider.allCases, id: \.self) { provider in
                                    HStack {
                                        Text(provider.rawValue)
                                        if !provider.isConfigured {
                                            Image(systemName: "exclamationmark.triangle")
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    .tag(provider)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        if !isKeySet {
                            Text("Set up your \(selectedProvider.rawValue) API Key in Settings to get started.")
                                .foregroundColor(.orange)
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(selectedProvider.rawValue) key configured")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    
                    if isKeySet {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Script Content").font(.headline)
                                Spacer()
                                Button("Import File") { showingFilePicker = true }
                                    .buttonStyle(.bordered)
                            }
                            
                            TextEditor(text: $scriptText)
                                .frame(minHeight: 200)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                .overlay(
                                    Group {
                                        if scriptText.isEmpty {
                                            Text("Paste your script here...")
                                                .foregroundColor(.secondary)
                                                .allowsHitTesting(false)
                                                .padding(8)
                                        }
                                    }, alignment: .topLeading
                                )
                        }
                        .padding(.horizontal)
                    }
                    
                    Button(action: parseScript) {
                        HStack {
                            if isProcessing {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text(isProcessing ? "AI is analyzing..." : "Parse with \(selectedProvider.rawValue)")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(scriptText.isEmpty || isProcessing || !isKeySet)
                    .padding()

                    Button(action: { showingScriptGenerator = true }) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                            Text("Generate AI Script")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(isProcessing || !isKeySet)
                    .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
            }
            // ✨ NEW: Add keyboard dismissal functionality
            .scrollDismissesKeyboard(.interactively)  // Dismiss when scrolling
            .navigationTitle("Script Parser")
            .navigationBarHidden(true)
            .toolbar {
                // ✨ NEW: Add Done button for keyboard
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                }
            }
            .onAppear {
                // Set default provider to the recommended one for script parsing
                selectedProvider = AITaskType.scriptParsing.recommendedProvider
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.plainText, .pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showingResults) {
            if let results = parseResults {
                ScriptParseResultsView(results: results, characters: $characters, scenes: $scenes)
            }
        }
        .sheet(isPresented: $showingSettings) {
            EnhancedSettingsView()
        }
        .sheet(isPresented: $showingScriptGenerator) {
            AIScriptGenerationView(
                project: project,
                secureStorage: secureStorage,
                onScenesGenerated: { generatedScenes in
                    scenes.append(contentsOf: generatedScenes)
                }
            )
        }
    }
    
    /// Handles the result of the file picker.
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Permission denied to access the file."
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                scriptText = content
                errorMessage = "" // Clear any previous errors
            } catch {
                errorMessage = "Could not read file: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            errorMessage = "File import failed: \(error.localizedDescription)"
        }
    }
    
    /// Uses the multi-AI parsing service with the selected provider
    private func parseScript() {
        guard selectedProvider.isConfigured else {
            errorMessage = "Please configure the \(selectedProvider.rawValue) API key in settings"
            return
        }
        
        isProcessing = true
        errorMessage = ""
        
        let apiKey = getAPIKey(for: selectedProvider)
        
        multiAIParser.parseScript(scriptText, provider: selectedProvider, apiKey: apiKey) { result in
            DispatchQueue.main.async {
                isProcessing = false
                switch result {
                case .success(let results):
                    parseResults = results
                    showingResults = true
                case .failure(let error):
                    errorMessage = "Parsing failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func getAPIKey(for provider: AIProvider) -> String {
        switch provider {
        case .openAI:
            return secureStorage.openAIKey
        case .claude:
            return secureStorage.claudeKey
            /*
        case .gemini:
            return secureStorage.geminiKey
             */
        }
    }
}
