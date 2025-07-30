import Foundation
import SwiftUI

// This class handles the secure storage and retrieval of API keys and user settings.
// Shared types (AIProvider, AIModel, AITaskType) are imported from SharedAITypes.swift
class SecureStorage: ObservableObject {
    
    static let shared = SecureStorage()
    
    // MARK: - API Keys
    @AppStorage("openAI_api_key") var openAIKey: String = ""
    @AppStorage("claude_api_key") var claudeKey: String = ""
    @AppStorage("gemini_api_key") var geminiKey: String = ""
    
    // MARK: - AI Provider Preferences
    @AppStorage("preferred_script_generation_provider") var preferredScriptGenerationProvider: AIProvider = .claude
    @AppStorage("preferred_script_parsing_provider") var preferredScriptParsingProvider: AIProvider = .claude
    @AppStorage("preferred_character_analysis_provider") var preferredCharacterAnalysisProvider: AIProvider = .openAI
    @AppStorage("preferred_image_generation_provider") var preferredImageGenerationProvider: AIProvider = .openAI
    
    // MARK: - Cost Tracking
    @AppStorage("openai_monthly_cost") var openAIMonthlySpend: Double = 0.0
    @AppStorage("claude_monthly_cost") var claudeMonthlySpend: Double = 0.0
    //@AppStorage("gemini_monthly_cost") var geminiMonthlySpend: Double = 0.0
    @AppStorage("cost_tracking_reset_date") var costTrackingResetDate: String = ""
    
    // MARK: - Quality vs Cost Preference
    @AppStorage("quality_vs_cost_preference") var qualityVsCostPreference: Double = 0.5 // 0 = cost-focused, 1 = quality-focused
    
    // MARK: - Usage Statistics
    @AppStorage("total_scripts_generated") var totalScriptsGenerated: Int = 0
    @AppStorage("total_characters_analyzed") var totalCharactersAnalyzed: Int = 0
    @AppStorage("total_scenes_created") var totalScenesCreated: Int = 0
    
    init() {
        setupCostTrackingIfNeeded()
    }
    
    // MARK: - API Key Management
    
    /// Get API key for specific provider
    func getAPIKey(for provider: AIProvider) -> String {
        switch provider {
        case .openAI: return openAIKey
        case .claude: return claudeKey
        //case .gemini: return geminiKey
        }
    }
    
    /// Set API key for specific provider
    func setAPIKey(_ key: String, for provider: AIProvider) {
        switch provider {
        case .openAI: openAIKey = key
        case .claude: claudeKey = key
        //case .gemini: geminiKey = key
        }
    }
    
    /// Clear API key for specific provider
    func clearAPIKey(for provider: AIProvider) {
        setAPIKey("", for: provider)
    }
    
    /// Clear all API keys
    func clearAllKeys() {
        openAIKey = ""
        claudeKey = ""
        //geminiKey = ""
    }
    
    /// Check if any API keys are configured
    var hasAnyAPIKey: Bool {
        return !openAIKey.isEmpty || !claudeKey.isEmpty || !geminiKey.isEmpty
    }
    
    /// Get configured providers
    var configuredProviders: [AIProvider] {
        return AIProvider.allCases.filter { $0.isConfigured }
    }
    
    // MARK: - Smart AI Provider Selection
    
    /// Get the best available provider for a specific task
    func getBestProvider(for taskType: AITaskType) -> AIProvider? {
        let recommendedProvider = taskType.recommendedProvider
        
        // If recommended provider is configured, use it
        if recommendedProvider.isConfigured {
            return recommendedProvider
        }
        
        // Otherwise, fall back to any configured provider
        // Prioritize based on quality vs cost preference
        if qualityVsCostPreference > 0.7 {
            // Quality-focused: Claude > OpenAI > Gemini
            if AIProvider.claude.isConfigured { return .claude }
            if AIProvider.openAI.isConfigured { return .openAI }
            //if AIProvider.gemini.isConfigured { return .gemini }
        } else if qualityVsCostPreference < 0.3 {
            // Cost-focused: Gemini > OpenAI > Claude
            //if AIProvider.gemini.isConfigured { return .gemini }
            if AIProvider.openAI.isConfigured { return .openAI }
            if AIProvider.claude.isConfigured { return .claude }
        } else {
            // Balanced: OpenAI > Claude > Gemini
            if AIProvider.openAI.isConfigured { return .openAI }
            if AIProvider.claude.isConfigured { return .claude }
            //if AIProvider.gemini.isConfigured { return .gemini }
        }
        
        return nil
    }
    
    /// Get preferred provider for specific task type
    func getPreferredProvider(for taskType: AITaskType) -> AIProvider {
        switch taskType {
        case .scriptGeneration: return preferredScriptGenerationProvider
        case .scriptParsing: return preferredScriptParsingProvider
        case .characterAnalysis: return preferredCharacterAnalysisProvider
        case .imageGeneration: return preferredImageGenerationProvider
        case .sceneGeneration: return preferredScriptGenerationProvider // Reuse script generation preference
        case .imageAnalysis: return preferredImageGenerationProvider // Reuse image generation preference
        }
    }
    
    /// Set preferred provider for specific task type
    func setPreferredProvider(_ provider: AIProvider, for taskType: AITaskType) {
        switch taskType {
        case .scriptGeneration: preferredScriptGenerationProvider = provider
        case .scriptParsing: preferredScriptParsingProvider = provider
        case .characterAnalysis: preferredCharacterAnalysisProvider = provider
        case .imageGeneration: preferredImageGenerationProvider = provider
        case .sceneGeneration: preferredScriptGenerationProvider = provider
        case .imageAnalysis: preferredImageGenerationProvider = provider
        }
    }
    
    // MARK: - Cost Tracking
    
    private func setupCostTrackingIfNeeded() {
        if costTrackingResetDate.isEmpty {
            resetMonthlyCosts()
        } else {
            checkIfMonthlyResetNeeded()
        }
    }
    
    private func checkIfMonthlyResetNeeded() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        let currentMonth = formatter.string(from: Date())
        if costTrackingResetDate != currentMonth {
            resetMonthlyCosts()
        }
    }
    
    func resetMonthlyCosts() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        openAIMonthlySpend = 0.0
        claudeMonthlySpend = 0.0
        //geminiMonthlySpend = 0.0
        costTrackingResetDate = formatter.string(from: Date())
    }
    
    func addCost(_ amount: Double, for provider: AIProvider) {
        switch provider {
        case .openAI: openAIMonthlySpend += amount
        case .claude: claudeMonthlySpend += amount
        //case .gemini: geminiMonthlySpend += amount
        }
        checkIfMonthlyResetNeeded()
    }
    
    func getTotalMonthlySpend() -> Double {
        return openAIMonthlySpend + claudeMonthlySpend
    }
    
    func getMonthlySpend(for provider: AIProvider) -> Double {
        switch provider {
        case .openAI: return openAIMonthlySpend
        case .claude: return claudeMonthlySpend
        //case .gemini: return geminiMonthlySpend
        }
    }
    
    // MARK: - Usage Statistics
    
    func incrementScriptsGenerated() {
        totalScriptsGenerated += 1
    }
    
    func incrementCharactersAnalyzed() {
        totalCharactersAnalyzed += 1
    }
    
    func incrementScenesCreated() {
        totalScenesCreated += 1
    }
    
    // MARK: - Settings Validation
    
    /// Check if settings are properly configured for multi-AI usage
    var isProperlyConfigured: Bool {
        return hasAnyAPIKey
    }
    
    /// Get configuration status message
    var configurationStatus: String {
        let configuredCount = configuredProviders.count
        let totalCount = AIProvider.allCases.count
        
        if configuredCount == 0 {
            return "No AI providers configured"
        } else if configuredCount == totalCount {
            return "All AI providers configured"
        } else {
            return "\(configuredCount)/\(totalCount) AI providers configured"
        }
    }
}
