//
//  ProjectListView.swift
//  PromptScript1
//
//  Created by Matt Darbro on 7/2/25.
//

import SwiftUI

// This view displays the list of all projects.
// It allows the user to create new projects, delete existing ones,
// and navigate to the detail view for a selected project.
struct ProjectListView: View {
    // @ObservedObject is used because this view receives an existing instance of ProjectManager.
    @ObservedObject var projectManager: ProjectManager
    
    // State for managing the "New Project" sheet.
    @State private var showingNewProjectSheet = false
    @State private var newProjectName = ""
    @State private var newProjectDescription = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(projectManager.allProjects) { project in
                    // This NavigationLink takes the user to the main content view for the selected project.
                    NavigationLink(destination: ProjectContentView(projectManager: projectManager, project: project)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(project.name)
                                    .font(.headline)
                                Spacer()
                                // Display a "Current" tag if this is the active project.
                                if project.id == projectManager.currentProject?.id {
                                    Text("Current")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            
                            if !project.description.isEmpty {
                                Text(project.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            HStack {
                                Text("\(project.characters.count) characters")
                                Text("•")
                                Text("\(project.scenes.count) scenes")
                                Spacer()
                                // Show how long ago the project was last modified.
                                Text(project.lastModified, style: .relative)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteProjects)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PROJECTS")
                        .font(.custom("Courier New", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewProjectSheet = true }) {
                        Image(systemName: "plus")
                            .font(.custom("Courier New", size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                }
            }
            .sheet(isPresented: $showingNewProjectSheet) {
                // Sheet for creating a new project.
                NavigationView {
                    Form {
                        Section("Project Details") {
                            TextField("Project Name", text: $newProjectName)
                            TextField("Description (optional)", text: $newProjectDescription, axis: .vertical)
                                .lineLimit(3...6)
                        }
                    }
                    .navigationTitle("New Project")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingNewProjectSheet = false
                                newProjectName = ""
                                newProjectDescription = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                projectManager.createNewProject(
                                    name: newProjectName,
                                    description: newProjectDescription
                                )
                                showingNewProjectSheet = false
                                newProjectName = ""
                                newProjectDescription = ""
                            }
                            .disabled(newProjectName.isEmpty)
                        }
                    }
                }
            }
            .onAppear {
                // Reload projects when the view appears to catch any external changes.
                projectManager.loadAllProjects()
            }
        }
    }
    
    /// Deletes projects from the list based on the provided IndexSet.
    private func deleteProjects(offsets: IndexSet) {
        for index in offsets {
            let project = projectManager.allProjects[index]
            projectManager.deleteProject(project)
        }
    }
}
