//
//  ContentView.swift
//  PromptScript1
//
//  Created by Matt Darbro on 7/2/25.
//

import SwiftUI
import SwiftData

// This is the root view of the application.
// Its only job is to create the ProjectManager and pass it to the ProjectListView.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var projectManager: ProjectManager?
    
    var body: some View {
        Group {
            if let projectManager = projectManager {
                ProjectListView(projectManager: projectManager)
            } else {
                // Loading view while ProjectManager initializes
                VStack {
                    ProgressView()
                    Text("Loading projects...")
                        .font(.custom("Courier New", size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            if projectManager == nil {
                Task { @MainActor in
                    projectManager = ProjectManager(modelContext: modelContext)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
