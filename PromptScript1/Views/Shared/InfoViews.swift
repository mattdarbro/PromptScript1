//
//  InfoViews.swift
//  PromptScript1
//
//  Created by Matt Darbro on 7/4/25.
//

import SwiftUI

// A helper view to create a consistent section layout in detail views.
struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Courier New", size: 18))
                .fontWeight(.bold)
                .foregroundColor(.green)
            content
        }
    }
}

// A helper view for a consistent label-value row in detail views.
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        if !value.isEmpty {
            HStack(alignment: .top) {
                Text("\(label):")
                    .font(.custom("Courier New", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .frame(width: 100, alignment: .leading)
                Text(value)
                    .font(.custom("Courier New", size: 16))
                    .foregroundColor(.primary)
                Spacer()
            }
        }
    }
}
