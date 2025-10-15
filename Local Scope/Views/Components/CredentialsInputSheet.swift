//
//  CredentialsInputSheet.swift
//  Local Scope
//
//  ОКНО ВВОДА ЛОГИНА И ПАРОЛЯ
//

import SwiftUI

struct CredentialsInputSheet: View {
    let device: Device
    let serviceType: ServiceType
    let onConnect: (ConnectionCredentials) -> Void
    let onSaveSession: (String, ConnectionCredentials) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var saveCredentials: Bool = false
    @State private var saveAsSession: Bool = false
    @State private var sessionName: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // HEADER
            HStack {
                ZStack {
                    Circle()
                        .fill(serviceType.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: serviceType.icon)
                        .font(.title2)
                        .foregroundStyle(serviceType.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connect to \(device.name)")
                        .font(.headline)
                    Text("\(device.ip) • \(serviceType.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // FORM
            Form {
                Section("Credentials") {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    
                    Toggle("Remember credentials", isOn: $saveCredentials)
                }
                
                Section("Save as Session") {
                    Toggle("Save as session", isOn: $saveAsSession)
                    
                    if saveAsSession {
                        TextField("Session name", text: $sessionName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // BUTTONS
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button(saveAsSession ? "Save & Connect" : "Connect") {
                    let credentials = ConnectionCredentials(
                        username: username,
                        password: password,
                        saveCredentials: saveCredentials
                    )
                    
                    if saveAsSession && !sessionName.isEmpty {
                        onSaveSession(sessionName, credentials)
                    } else {
                        onConnect(credentials)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(serviceType.color)
                .disabled(username.isEmpty || password.isEmpty || (saveAsSession && sessionName.isEmpty))
            }
            .padding()
        }
        .frame(width: 500, height: 450)
        .onAppear {
            sessionName = "\(device.name) - \(serviceType.rawValue)"
        }
    }
}
