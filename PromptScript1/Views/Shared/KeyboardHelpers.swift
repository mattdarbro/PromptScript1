//
//  KeyboardHelpers.swift
//  PromptScript1
//
//  Created by Matt Darbro on 7/28/25.
//

import SwiftUI

// MARK: - Basic Keyboard Dismissal Extensions
extension View {
    /// Dismisses the keyboard programmatically
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Adds tap-to-dismiss keyboard functionality to any view
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            dismissKeyboard()
        }
    }
}

// MARK: - Toolbar with Done Button
struct KeyboardToolbar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}
