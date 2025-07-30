import SwiftUI

// This view is a sheet that displays the results of the AI script parsing
// and asks the user to confirm the import.
struct ScriptParseResultsView: View {
    let results: ScriptParseResult
    @Binding var characters: [Character]
    @Binding var scenes: [VideoScene]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("AI Analysis Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    HStack {
                        SummaryItem(value: "\(results.characters.count)", label: "Characters Found")
                        Spacer()
                        SummaryItem(value: "\(results.scenes.count)", label: "Scenes Found")
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                
                VStack(spacing: 12) {
                    Button(action: importAll) {
                        HStack {
                            Image(systemName: "square.and.arrow.down.on.square")
                            Text("Import All Characters & Scenes")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    /// Appends the new characters and scenes from the parsing results
    /// to the project's main arrays.
    private func importAll() {
        characters.append(contentsOf: results.characters)
        scenes.append(contentsOf: results.scenes)
        dismiss()
    }
}

// A helper view for displaying a summary item.
// This is also used in ExportView. We can move it to a shared file later.
struct SummaryItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

