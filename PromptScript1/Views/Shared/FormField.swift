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
                .font(TypewriterTheme.Fonts.caption())
                .foregroundColor(TypewriterTheme.Colors.typewriterGray)
            
            if isMultiline {
                TextEditor(text: $value)
                    .font(TypewriterTheme.Fonts.body())
                    .frame(minHeight: 100, maxHeight: 200)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: TypewriterTheme.CornerRadius.small)
                            .stroke(TypewriterTheme.Colors.lightGray, lineWidth: 1)
                    )
                    .background(TypewriterTheme.Colors.paperWhite)
                    .cornerRadius(TypewriterTheme.CornerRadius.small)
            } else {
                TextField(placeholder, text: $value)
                    .textFieldStyle(TypewriterTextFieldStyle())
            }
        }
        .padding(.vertical, 4)
    }
}
