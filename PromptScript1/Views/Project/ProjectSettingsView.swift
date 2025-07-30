//
//  ProjectSettingsView.swift
//  PromptScript1
//
//  Created by Matt Darbro on 7/5/25.
//

import SwiftUI

/// A view for editing project-level settings, such as the default video style.
struct ProjectSettingsView: View {
    @Binding var project: Project
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Default Visual Style") {
                    Picker("Video Style", selection: $project.videoStyle) {
                        ForEach(VideoStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    
                    // Show the custom text field only when 'Custom' is selected.
                    if project.videoStyle == .custom {
                        FormField(label: "Custom Style", placeholder: "e.g., '8-bit pixel art'", value: $project.customVideoStyle)
                    }
                    
                    Text("This style will be used for all scenes in this project by default.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Project Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
