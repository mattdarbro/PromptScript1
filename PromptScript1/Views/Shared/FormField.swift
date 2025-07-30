//
//  FormField.swift
//  PromptScript1
//
//  Created by Matt Darbro on 7/4/25.
//

import SwiftUI

/// A reusable view for a single field in a form, consisting of a label and a text field.
/// This helps to reduce code duplication in large forms.
struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var value: String
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if isMultiline {
                TextEditor(text: $value)
                    .frame(minHeight: 100, maxHeight: 200)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                TextField(placeholder, text: $value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(.vertical, 4)
    }
}
