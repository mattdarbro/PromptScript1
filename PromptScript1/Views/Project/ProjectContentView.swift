import SwiftUI

// This is the updated main container view with the correct 5-tab layout.
// Tab order: Characters → Scene → Script → Export → Settings

struct ProjectContentView: View {
    @ObservedObject var projectManager: ProjectManager
    let project: Project
    
    @StateObject private var secureStorage = SecureStorage.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Tab 1: Characters (MOVED TO FIRST)
            CharacterListView(characters: bindingForCharacters(), videoStyle: project.videoStyle.rawValue)
                .tabItem { 
                    Image(systemName: "person.2")
                    Text("Characters")
                }
                .tag(0)
            
            // MARK: - Tab 2: Scene (RENAMED FROM SCENES)
            SceneListView(scenes: bindingForScenes(), characters: project.characters, project: project)
                .tabItem { 
                    Image(systemName: "film.stack")
                    Text("Scene")
                }
                .tag(1)
            
            // MARK: - Tab 3: Script
            ScriptingHubView(
                characters: bindingForCharacters(),
                scenes: bindingForScenes(),
                secureStorage: secureStorage,
                project: project
            )
            .tabItem { 
                Image(systemName: "square.and.pencil")
                Text("Script")
            }
            .tag(2)
            
            // MARK: - Tab 4: Export
            ExportView(project: bindingForProject())
                .tabItem { 
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
                .tag(3)
            
            // MARK: - Tab 5: Settings (FIXED - No parameters needed)
            EnhancedSettingsView()
                .tabItem { 
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(.black)
        .onAppear {
            setupTabBarAppearance()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(project.name)
                    .font(.custom("Courier New", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .onAppear {
            projectManager.switchToProject(project)
        }
    }
    
    // MARK: - Bindings (Your existing functions)
    private func bindingForProject() -> Binding<Project> {
        Binding(
            get: { projectManager.currentProject ?? self.project },
            set: { updatedProject in projectManager.currentProject = updatedProject }
        )
    }
    
    private func bindingForCharacters() -> Binding<[Character]> {
        Binding(
            get: { projectManager.currentProject?.characters ?? [] },
            set: { newCharacters in
                if projectManager.currentProject != nil {
                    projectManager.currentProject?.characters = newCharacters
                }
            }
        )
    }
    
    private func bindingForScenes() -> Binding<[VideoScene]> {
        Binding(
            get: { projectManager.currentProject?.scenes ?? [] },
            set: { newScenes in
                if projectManager.currentProject != nil {
                    projectManager.currentProject?.scenes = newScenes
                }
            }
        )
    }
    
    // MARK: - Tab Bar Styling
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Configure normal state with gray
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont(name: "Courier New", size: 10) ?? UIFont.systemFont(ofSize: 10)
        ]
        
        // Configure selected state with black and slightly larger font
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.black
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont(name: "Courier New", size: 11) ?? UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor.black
    }
    
    // Navigation styling is now handled globally in PromptScript1App.swift
}

// MARK: - UIViewController Extension
extension UIViewController {
    func findTabBarController() -> UITabBarController? {
        if let tabBarController = self as? UITabBarController {
            return tabBarController
        }
        
        for child in children {
            if let tabBarController = child.findTabBarController() {
                return tabBarController
            }
        }
        
        return nil
    }
}
