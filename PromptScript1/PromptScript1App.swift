//
//  PromptScript1App.swift
//  PromptScript1
//
//  Created by Matt Darbro on 7/2/25.
//

import SwiftUI
import SwiftData

@main
struct PromptScript1App: App {
    
    init() {
        setupGlobalNavigationAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // Force light mode for typewriter aesthetic
        }
        .modelContainer(for: [Project.self, Character.self, VideoScene.self])
    }
    
    // MARK: - Global Navigation Styling
    
    private func setupGlobalNavigationAppearance() {
        // Configure navigation bar appearance globally
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Make back button completely black with no text
        appearance.backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.clear
        ]
        appearance.backButtonAppearance.highlighted.titleTextAttributes = [
            .foregroundColor: UIColor.clear
        ]
        
        // Use black chevron for back button
        let backImage = UIImage(systemName: "chevron.left")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
            .withTintColor(.black, renderingMode: .alwaysOriginal)
        
        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        
        // Apply globally to all navigation bars
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor.black
        
        // Also set the global tint color for the entire app
        UIView.appearance(whenContainedInInstancesOf: [UINavigationController.self]).tintColor = UIColor.black
    }
}
