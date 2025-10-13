//
//  SettingsView.swift
//  Local Scope
//

import SwiftUI

struct SettingsView: View {
    let onReload: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundStyle(.gray)
                Text("Settings")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            Form {
                Section("History") {
                    Button(action: onReload) {
                        Label("Reload History", systemImage: "arrow.clockwise")
                    }
                    
                    Button(action: onClear) {
                        Label("Clear History", systemImage: "trash")
                    }
                    .foregroundStyle(.red)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2025.01")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            
            Spacer()
        }
    }
}
