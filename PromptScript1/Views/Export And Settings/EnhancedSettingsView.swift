import SwiftUI

struct EnhancedSettingsView: View {
    @ObservedObject private var secureStorage = SecureStorage.shared
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Configuration Status
                Section(header: Text("Configuration Status")
                    .font(.custom("Courier New", size: 16))
                    .foregroundColor(TypewriterTheme.Colors.Settings.primary)
                    .fontWeight(.medium)) {
                    HStack {
                        Circle()
                            .fill(secureStorage.isProperlyConfigured ? .green : .orange)
                            .frame(width: 12, height: 12)
                        Text(secureStorage.configurationStatus)
                            .font(.custom("Courier New", size: 14))
                        Spacer()
                    }
                    
                    if !secureStorage.isProperlyConfigured {
                        Text("Configure at least one AI provider to use all features")
                            .font(.custom("Courier New", size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - API Keys Configuration
                Section(header: Text("AI Provider API Keys")
                    .font(.custom("Courier New", size: 16))
                    .foregroundColor(TypewriterTheme.Colors.Settings.primary)
                    .fontWeight(.medium)) {
                    // OpenAI
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "brain")
                                .foregroundColor(.blue)
                            Text("OpenAI")
                                .font(.custom("Courier New", size: 14))
                            Spacer()
                            if !secureStorage.openAIKey.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        SecureField("Enter OpenAI API Key", text: $secureStorage.openAIKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Best for: Image generation (DALL-E)")
                            .font(.custom("Courier New", size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    // Claude
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.book.closed")
                                .foregroundColor(.purple)
                            Text("Claude (Anthropic)")
                            Spacer()
                            if !secureStorage.claudeKey.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        SecureField("Enter Claude API Key", text: $secureStorage.claudeKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Best for: Script generation, character analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    /*
                    // Gemini
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.orange)
                            Text("Gemini (Google)")
                            Spacer()
                            if !secureStorage.geminiKey.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        SecureField("Enter Gemini API Key", text: $secureStorage.geminiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Best for: Cost-effective script parsing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                     */
                }
                
                // MARK: - AI Provider Preferences
                Section("AI Provider Preferences") {
                    Text("Choose which AI provider to use for each task")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Script Generation
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Script Generation")
                                .fontWeight(.medium)
                            Text("Creative writing tasks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("Script Generation", selection: $secureStorage.preferredScriptGenerationProvider) {
                            ForEach(secureStorage.configuredProviders, id: \.self) { provider in
                                Text(provider.rawValue).tag(provider)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // Character Analysis
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Character Analysis")
                                .fontWeight(.medium)
                            Text("Photo analysis and character creation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("Character Analysis", selection: $secureStorage.preferredCharacterAnalysisProvider) {
                            ForEach(secureStorage.configuredProviders, id: \.self) { provider in
                                Text(provider.rawValue).tag(provider)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // Script Parsing
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Script Parsing")
                                .fontWeight(.medium)
                            Text("Converting traditional scripts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("Script Parsing", selection: $secureStorage.preferredScriptParsingProvider) {
                            ForEach(secureStorage.configuredProviders, id: \.self) { provider in
                                Text(provider.rawValue).tag(provider)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                // MARK: - Quality vs Cost Preference
                Section("Quality vs Cost Preference") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Cost-focused")
                                .font(.caption)
                            Spacer()
                            Text("Quality-focused")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        Slider(value: $secureStorage.qualityVsCostPreference, in: 0...1)
                        
                        Text(qualityPreferenceDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // MARK: - Usage Statistics
                Section("Usage Statistics") {
                    HStack {
                        Text("Scripts Generated")
                        Spacer()
                        Text("\(secureStorage.totalScriptsGenerated)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Characters Analyzed")
                        Spacer()
                        Text("\(secureStorage.totalCharactersAnalyzed)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Scenes Created")
                        Spacer()
                        Text("\(secureStorage.totalScenesCreated)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Cost Tracking
                Section("Monthly AI Costs") {
                    if secureStorage.getTotalMonthlySpend() > 0 {
                        HStack {
                            Text("Total This Month")
                                .fontWeight(.medium)
                            Spacer()
                            Text("$\(secureStorage.getTotalMonthlySpend(), specifier: "%.2f")")
                                .foregroundColor(.primary)
                        }
                        
                        ForEach(AIProvider.allCases, id: \.self) { provider in
                            let cost = secureStorage.getMonthlySpend(for: provider)
                            if cost > 0 {
                                HStack {
                                    Text(provider.rawValue)
                                    Spacer()
                                    Text("$\(cost, specifier: "%.2f")")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Button("Reset Monthly Costs") {
                            secureStorage.resetMonthlyCosts()
                        }
                        .foregroundColor(.red)
                    } else {
                        Text("No costs tracked this month")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Danger Zone
                Section("Danger Zone") {
                    Button("Clear All API Keys") {
                        secureStorage.clearAllKeys()
                    }
                    .foregroundColor(.red)
                }
            }
            // ✨ NEW: Add keyboard dismissal functionality
            .scrollDismissesKeyboard(.interactively)  // Dismiss when scrolling
            .navigationTitle("AI SETTINGS")
            .navigationBarTitleDisplayMode(.inline)
            .background(TypewriterTheme.Colors.Settings.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("AI SETTINGS")
                        .font(.custom("Courier New", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(TypewriterTheme.Colors.Settings.primary)
                }
                // ✨ NEW: Add Done button for keyboard
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                }
            }
        }
    }
    
    private var qualityPreferenceDescription: String {
        let preference = secureStorage.qualityVsCostPreference
        
        if preference < 0.3 {
            return "Prioritizes cost-effective AI providers (Gemini preferred)"
        } else if preference > 0.7 {
            return "Prioritizes high-quality AI providers (Claude preferred)"
        } else {
            return "Balanced approach between cost and quality"
        }
    }
}
