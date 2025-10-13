//
//  SettingsButton.swift
//  Local Scope
//

import SwiftUI

struct SettingsButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)/Users/kalyuzhniyko/Documents/Local Scope/Local Scope/Local Scope/Views/Components
                    .foregroundStyle(color)
                    .frame(width: 24)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
