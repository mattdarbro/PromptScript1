//
//  ContentView.swift
//  PromptScript1
//
//  Created by Matt Darbro on 7/2/25.
//

import SwiftUI

// This is the root view of the application.
// Its only job is to create the ProjectManager and pass it to the ProjectListView.
struct ContentView: View {
    // @StateObject ensures the ProjectManager is created once and stays alive for the life of the app.
    @StateObject private var projectManager = ProjectManager()
    
    var body: some View {
        ProjectListView(projectManager: projectManager)
    }
}

#Preview {
    ContentView()
}
