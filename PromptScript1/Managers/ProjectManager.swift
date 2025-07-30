//
//  ProjectManager.swift
//  PromptScript1
//
//  Created by Matt Darbro on 7/2/25.
//

import Foundation
import SwiftUI
import SwiftData

// This class is the central hub for creating, loading, saving, and deleting projects.
// It manages the current project using SwiftData for persistence.
@MainActor
class ProjectManager: ObservableObject {
    
    // The currently active project. The UI will observe this for changes.
    @Published var currentProject: Project? {
        didSet {
            if let project = currentProject {
                // Update the last modified date
                project.lastModified = Date()
                // Remember this as the last opened project for the next app launch.
                UserDefaults.standard.set(project.id.uuidString, forKey: "lastProjectID")
                // Save context automatically happens with SwiftData
                try? modelContext?.save()
            }
        }
    }
    
    // A list of all projects found in the database.
    @Published var allProjects: [Project] = []
    
    // SwiftData model context
    private var modelContext: ModelContext?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Load all existing projects from SwiftData.
        loadAllProjects()
        
        // Determine which project to set as the current one.
        if let lastProjectID = UserDefaults.standard.string(forKey: "lastProjectID"),
           let lastProjectUUID = UUID(uuidString: lastProjectID),
           let savedProject = allProjects.first(where: { $0.id == lastProjectUUID }) {
            // If a "last opened" project exists, load it.
            self.currentProject = savedProject
        } else if allProjects.isEmpty {
            // If no projects exist at all, create a default one to get the user started.
            createNewProject(name: "My First Script", description: "A great place to start your story.")
        } else {
            // Otherwise, just load the most recently modified project.
            self.currentProject = allProjects.sorted(by: { $0.lastModified > $1.lastModified }).first
        }
    }
    
    // MARK: - Project Management Methods
    
    /// Loads all projects from SwiftData.
    func loadAllProjects() {
        guard let modelContext = modelContext else {
            print("❌ Model context not available")
            return
        }
        
        do {
            let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\Project.lastModified, order: .reverse)])
            allProjects = try modelContext.fetch(descriptor)
        } catch {
            print("❌ Failed to load projects from SwiftData: \(error.localizedDescription)")
            allProjects = []
        }
    }
    
    /// Creates a new project, saves it to SwiftData, and sets it as the current project.
    func createNewProject(name: String, description: String = "") {
        guard let modelContext = modelContext else {
            print("❌ Model context not available")
            return
        }
        
        let newProject = Project(name: name, description: description)
        
        modelContext.insert(newProject)
        
        do {
            try modelContext.save()
            allProjects.insert(newProject, at: 0) // Add to the top of the list.
            currentProject = newProject
        } catch {
            print("❌ Failed to save new project: \(error.localizedDescription)")
        }
    }
    
    /// Deletes a project from SwiftData and removes it from the `allProjects` array.
    func deleteProject(_ project: Project) {
        guard let modelContext = modelContext else {
            print("❌ Model context not available")
            return
        }
        
        modelContext.delete(project)
        
        do {
            try modelContext.save()
            allProjects.removeAll { $0.id == project.id }
            
            // If we deleted the currently active project, switch to another one.
            if currentProject?.id == project.id {
                currentProject = allProjects.first
            }
        } catch {
            print("❌ Failed to delete project: \(error.localizedDescription)")
        }
    }
    
    /// Saves changes to SwiftData (happens automatically, but can be called explicitly).
    func saveChanges() {
        guard let modelContext = modelContext else {
            print("❌ Model context not available")
            return
        }
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save changes: \(error.localizedDescription)")
        }
    }
    
    /// Sets the given project as the `currentProject`.
    func switchToProject(_ project: Project) {
        currentProject = project
    }
}
