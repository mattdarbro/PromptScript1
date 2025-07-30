//
//  ProjectManager.swift
//  PromptScript1
//
//  Created by Matt Darbro on 7/2/25.
//

import Foundation
import SwiftUI

// This class is the central hub for creating, loading, saving, and deleting projects.
// It manages the current project and the list of all available projects.
class ProjectManager: ObservableObject {
    
    // The currently active project. The UI will observe this for changes.
    @Published var currentProject: Project? {
        didSet {
            if let project = currentProject {
                // Auto-save any changes to the current project.
                saveProject(project)
                // Remember this as the last opened project for the next app launch.
                UserDefaults.standard.set(project.id.uuidString, forKey: "lastProjectID")
            }
        }
    }
    
    // A list of all projects found on the device.
    @Published var allProjects: [Project] = []
    
    // The URL for the "Projects" directory within the app's Documents folder.
    private var projectsURL: URL {
        // It's good practice to handle potential errors, though this is unlikely to fail.
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Could not access the documents directory.")
        }
        return documentsURL.appendingPathComponent("Projects")
    }
    
    init() {
        // Create the "Projects" directory if it doesn't already exist.
        do {
            try FileManager.default.createDirectory(at: projectsURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            // If this fails, the app will not be able to save or load projects.
            print("❌ CRITICAL: Failed to create projects directory: \(error.localizedDescription)")
        }
        
        // Load all existing projects from disk.
        loadAllProjects()
        
        // Determine which project to set as the current one.
        if let lastProjectID = UserDefaults.standard.string(forKey: "lastProjectID"),
           let savedProject = allProjects.first(where: { $0.id.uuidString == lastProjectID }) {
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
    
    /// Loads all project files (.json) from the Projects directory.
    func loadAllProjects() {
        allProjects.removeAll()
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: projectsURL, includingPropertiesForKeys: nil)
            let jsonFiles = fileURLs.filter { $0.pathExtension == "json" }
            
            for fileURL in jsonFiles {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let project = try JSONDecoder().decode(Project.self, from: data)
                    allProjects.append(project)
                } catch {
                    print("❌ Failed to load or decode project at \(fileURL.path): \(error.localizedDescription)")
                }
            }
            
            // Sort projects by last modified date, newest first.
            allProjects.sort { $0.lastModified > $1.lastModified }
            
        } catch {
            print("❌ Failed to read contents of projects directory: \(error.localizedDescription)")
        }
    }
    
    /// Creates a new project, saves it to disk, and sets it as the current project.
    func createNewProject(name: String, description: String = "") {
        let newProject = Project(
            name: name,
            description: description
        )
        
        allProjects.insert(newProject, at: 0) // Add to the top of the list.
        saveProject(newProject)
        currentProject = newProject
    }
    
    /// Deletes a project's file from disk and removes it from the `allProjects` array.
    func deleteProject(_ project: Project) {
        let fileURL = projectsURL.appendingPathComponent("\(project.id.uuidString).json")
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            allProjects.removeAll { $0.id == project.id }
            
            // If we deleted the currently active project, switch to another one.
            if currentProject?.id == project.id {
                currentProject = allProjects.first
            }
            
        } catch {
            print("❌ Failed to delete project file: \(error.localizedDescription)")
        }
    }
    
    /// Saves a specific project to a JSON file.
    func saveProject(_ project: Project) {
        let fileURL = projectsURL.appendingPathComponent("\(project.id.uuidString).json")
        
        do {
            var projectToSave = project
            projectToSave.lastModified = Date() // Update the modification date.
            
            let data = try JSONEncoder().encode(projectToSave)
            try data.write(to: fileURL, options: [.atomicWrite]) // Atomic write is safer.
            
            // Ensure the version in our `allProjects` array is also updated.
            if let index = allProjects.firstIndex(where: { $0.id == project.id }) {
                allProjects[index] = projectToSave
            }
            
        } catch {
            print("❌ Failed to save project \(project.name): \(error.localizedDescription)")
        }
    }
    
    /// Sets the given project as the `currentProject`.
    func switchToProject(_ project: Project) {
        currentProject = project
    }
}
