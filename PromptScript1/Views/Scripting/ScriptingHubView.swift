import SwiftUI

// Completely redesigned ScriptingHubView with intuitive workflow
// Respects user's AI provider preferences from settings
struct ScriptingHubView: View {
    @Binding var characters: [Character]
    @Binding var scenes: [VideoScene]
    @ObservedObject var secureStorage: SecureStorage
    let project: Project
    
    @State private var scriptText: String = ""
    @State private var currentStep: ScriptingStep = .choose
    @State private var isProcessing = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var showingAIGenerator = false
    
    // Services using user's preferred providers
    private let scriptParser = MultiAIScriptParsingService()
    
    // User's preferred providers (read from actual settings)
    private var preferredScriptGenerator: AIProvider {
        secureStorage.preferredScriptGenerationProvider
    }
    private var preferredScriptParser: AIProvider {
        secureStorage.preferredScriptParsingProvider
    }
    
    enum ScriptingStep {
        case choose
        case inputScript
        case processing
        case results
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressStepView(currentStep: currentStep)
                    .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        switch currentStep {
                        case .choose:
                            ChooseActionView(
                                onGenerateScript: {
                                    showingAIGenerator = true
                                },
                                onImportScript: {
                                    currentStep = .inputScript
                                },
                                preferredGenerator: preferredScriptGenerator,
                                preferredParser: preferredScriptParser,
                                secureStorage: secureStorage
                            )
                            
                        case .inputScript:
                            InputScriptView(
                                scriptText: $scriptText,
                                onContinue: { parseScript() },
                                onBack: { currentStep = .choose },
                                preferredParser: preferredScriptParser,
                                isValid: !scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            )
                            
                        case .processing:
                            ProcessingView(provider: preferredScriptParser)
                            
                        case .results:
                            ResultsView(
                                characters: characters,
                                scenes: scenes,
                                onStartOver: {
                                    currentStep = .choose
                                    scriptText = ""
                                    errorMessage = nil
                                    successMessage = nil
                                }
                            )
                        }
                        
                        // Error/Success messages
                        if let errorMessage = errorMessage {
                            ErrorMessageView(message: errorMessage) {
                                self.errorMessage = nil
                                currentStep = .inputScript
                            }
                        }
                        
                        if let successMessage = successMessage {
                            SuccessMessageView(message: successMessage) {
                                self.successMessage = nil
                            }
                        }
                    }
                    .padding()
                }
                // ✨ NEW: Add keyboard dismissal functionality
                .scrollDismissesKeyboard(.interactively)  // Dismiss when scrolling
            }
            .navigationTitle("SCRIPT HUB")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SCRIPT HUB")
                        .font(.custom("Courier New", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(TypewriterTheme.Colors.Script.primary)
                }
                // ✨ NEW: Add Done button for keyboard
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                }
            }
            .sheet(isPresented: $showingAIGenerator) {
                AIScriptGenerationView(
                    project: project,
                    secureStorage: secureStorage,
                    onScenesGenerated: { generatedScenes in
                        self.scenes.append(contentsOf: generatedScenes)
                        self.currentStep = .results
                        self.successMessage = "Generated \(generatedScenes.count) scenes successfully!"
                    }
                )
            }
        }
    }
    
    private func parseScript() {
        guard preferredScriptParser.isConfigured else {
            errorMessage = "Please configure your \(preferredScriptParser.rawValue) API key in Settings"
            return
        }
        
        currentStep = .processing
        isProcessing = true
        errorMessage = nil
        
        let apiKey = getAPIKey(for: preferredScriptParser)
        
        scriptParser.parseScript(
            scriptText,
            provider: preferredScriptParser,
            apiKey: apiKey
        ) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success(let parseResult):
                    // Add the newly parsed content
                    let newCharacters = parseResult.characters.filter { newChar in
                        !self.characters.contains { $0.basicInfo.name == newChar.basicInfo.name }
                    }
                    let newScenes = parseResult.scenes
                    
                    self.characters.append(contentsOf: newCharacters)
                    self.scenes.append(contentsOf: newScenes)
                    
                    self.currentStep = .results
                    self.successMessage = "Parsed script successfully! Added \(newCharacters.count) characters and \(newScenes.count) scenes."
                    
                case .failure(let error):
                    self.errorMessage = "Failed to parse script: \(error.localizedDescription)"
                    self.currentStep = .inputScript
                }
            }
        }
    }
    
    private func getAPIKey(for provider: AIProvider) -> String {
        switch provider {
        case .openAI: return secureStorage.openAIKey
        case .claude: return secureStorage.claudeKey
        //case .gemini: return secureStorage.geminiKey
        }
    }
}

// MARK: - Step Views

struct ProgressStepView: View {
    let currentStep: ScriptingHubView.ScriptingStep
    
    var body: some View {
        HStack(spacing: 8) {
            StepIndicator(step: 1, title: "Choose", isActive: currentStep == .choose, isCompleted: currentStep.rawValue > 0)
            ConnectorLine(isCompleted: currentStep.rawValue > 1)
            StepIndicator(step: 2, title: "Input", isActive: currentStep == .inputScript, isCompleted: currentStep.rawValue > 1)
            ConnectorLine(isCompleted: currentStep.rawValue > 2)
            StepIndicator(step: 3, title: "Process", isActive: currentStep == .processing, isCompleted: currentStep.rawValue > 2)
            ConnectorLine(isCompleted: currentStep.rawValue > 3)
            StepIndicator(step: 4, title: "Results", isActive: currentStep == .results, isCompleted: false)
        }
        .padding(.horizontal)
    }
}

struct StepIndicator: View {
    let step: Int
    let title: String
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isCompleted ? TypewriterTheme.Colors.Script.primary : (isActive ? TypewriterTheme.Colors.Script.accent : Color.gray.opacity(0.3)))
                .frame(width: 24, height: 24)
                .overlay(
                Text("\(step)")
                        .font(.custom("Courier New", size: 12))
                        .fontWeight(.medium)
                        .foregroundColor(isCompleted || isActive ? .white : .gray)
                )
            
            Text(title)
                .font(.custom("Courier New", size: 12))
                .foregroundColor(isActive ? TypewriterTheme.Colors.Script.primary : .secondary)
        }
    }
}

struct ConnectorLine: View {
    let isCompleted: Bool
    
    var body: some View {
        Rectangle()
            .fill(isCompleted ? TypewriterTheme.Colors.Script.primary : Color.gray.opacity(0.3))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
    }
}

struct ChooseActionView: View {
    let onGenerateScript: () -> Void
    let onImportScript: () -> Void
    let preferredGenerator: AIProvider
    let preferredParser: AIProvider
    let secureStorage: SecureStorage
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What would you like to do?")
                .font(.custom("Courier New", size: 20))
                .foregroundColor(TypewriterTheme.Colors.Script.primary)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Generate Script Option
                ActionCard(
                    icon: "brain.head.profile",
                    title: "Generate New Script",
                    description: "Create a new script using AI",
                    provider: preferredGenerator,
                    isConfigured: preferredGenerator.isConfigured,
                    action: onGenerateScript
                )
                
                // Parse Script Option
                ActionCard(
                    icon: "doc.text.magnifyingglass",
                    title: "Parse Existing Script",
                    description: "Import and analyze an existing script",
                    provider: preferredParser,
                    isConfigured: preferredParser.isConfigured,
                    action: onImportScript
                )
            }
        }
    }
}

struct ActionCard: View {
    let icon: String
    let title: String
    let description: String
    let provider: AIProvider
    let isConfigured: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(TypewriterTheme.Colors.Script.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.custom("Courier New", size: 16))
                            .foregroundColor(.primary)
                        
                        Text(description)
                            .font(.custom("Courier New", size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(provider.rawValue)
                            .font(.custom("Courier New", size: 10))
                            .foregroundColor(TypewriterTheme.Colors.Script.secondary)
                        
                        if isConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(TypewriterTheme.Colors.Script.primary)
                                .font(.caption)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
            .background(TypewriterTheme.Colors.Script.cardBackground)
            .cornerRadius(12)
            .shadow(color: TypewriterTheme.Colors.Script.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .disabled(!isConfigured)
        .opacity(isConfigured ? 1.0 : 0.6)
        .buttonStyle(PlainButtonStyle())
    }
}

struct InputScriptView: View {
    @Binding var scriptText: String
    let onContinue: () -> Void
    let onBack: () -> Void
    let preferredParser: AIProvider
    let isValid: Bool
    
    @State private var showingFilePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(.custom("Courier New", size: 14))
                    }
                    .foregroundColor(.black)
                }
                Spacer()
                Text("Input Script")
                    .font(.custom("Courier New", size: 20))
                    .foregroundColor(TypewriterTheme.Colors.Script.primary)
                    .fontWeight(.semibold)
                Spacer()
                Button("Import File") { showingFilePicker = true }
                    .font(.custom("Courier New", size: 14))
                    .foregroundColor(TypewriterTheme.Colors.Script.primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Paste or import your script:")
                    .font(.custom("Courier New", size: 16))
                    .foregroundColor(TypewriterTheme.Colors.Script.primary)
                
                TextEditor(text: $scriptText)
                    .font(.custom("Courier New", size: 14))
                    .frame(minHeight: 300)
                    .padding(8)
                    .background(TypewriterTheme.Colors.Script.background)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(TypewriterTheme.Colors.Script.primary.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if scriptText.isEmpty {
                                Text("Paste your script here...")
                                    .font(.custom("Courier New", size: 14))
                                    .foregroundColor(.secondary)
                                    .allowsHitTesting(false)
                                    .padding(12)
                            }
                        }, alignment: .topLeading
                    )
                
                HStack {
                    Text("Will be analyzed using: \(preferredParser.rawValue)")
                        .font(.custom("Courier New", size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(!isValid)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                scriptText = content
            } catch {
                // Handle error if needed
            }
            
        case .failure:
            // Handle error if needed
            break
        }
    }
}

struct ProcessingView: View {
    let provider: AIProvider
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing Script")
                .font(.custom("Courier New", size: 20))
                .foregroundColor(TypewriterTheme.Colors.Script.primary)
                .fontWeight(.semibold)
            
            Text("Using \(provider.rawValue) to parse characters, scenes, and dialogue...")
                .font(.custom("Courier New", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("This may take a few moments")
                .font(.custom("Courier New", size: 12))
                .foregroundColor(.secondary)
        }
        .padding(40)
    }
}

struct ResultsView: View {
    let characters: [Character]
    let scenes: [VideoScene]
    let onStartOver: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("✅ Script Processed Successfully!")
                .font(.custom("Courier New", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(TypewriterTheme.Colors.Script.primary)
            
            VStack(spacing: 12) {
                ResultSummaryCard(
                    icon: "person.2.fill",
                    title: "Characters",
                    count: characters.count,
                    description: "characters identified"
                )
                
                ResultSummaryCard(
                    icon: "video.fill",
                    title: "Scenes",
                    count: scenes.count,
                    description: "scenes created"
                )
            }
            
            Button("Process Another Script") {
                onStartOver()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
    }
}

struct ResultSummaryCard: View {
    let icon: String
    let title: String
    let count: Int
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(TypewriterTheme.Colors.Script.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Courier New", size: 16))
                
                Text("\(count) \(description)")
                    .font(.custom("Courier New", size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(count)")
                .font(.custom("Courier New", size: 24))
                .fontWeight(.bold)
                .foregroundColor(TypewriterTheme.Colors.Script.primary)
        }
        .padding()
        .background(TypewriterTheme.Colors.Script.cardBackground)
        .cornerRadius(12)
        .shadow(color: TypewriterTheme.Colors.Script.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ErrorMessageView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Error")
                    .font(.headline)
                    .foregroundColor(.red)
                Spacer()
            }
            
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
            
            Button("Try Again", action: onDismiss)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SuccessMessageView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Success")
                    .font(.headline)
                    .foregroundColor(.green)
                Spacer()
                Button("✕", action: onDismiss)
                    .foregroundColor(.secondary)
            }
            
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

// Extension to make ScriptingStep comparable
extension ScriptingHubView.ScriptingStep {
    var rawValue: Int {
        switch self {
        case .choose: return 0
        case .inputScript: return 1
        case .processing: return 2
        case .results: return 3
        }
    }
}
