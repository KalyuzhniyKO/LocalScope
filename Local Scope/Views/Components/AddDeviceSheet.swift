//
//  AddDeviceSheet.swift
//  Local Scope
//

import SwiftUI

struct AddDeviceSheet: View {
    let serviceType: ServiceType
    let onAdd: (String, String) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var deviceName: String = ""
    @State private var ipAddress: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
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
                    Text("Add Device")
                        .font(.title2.bold())
                    Text("Enter a name and IP address. Ports will be scanned automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Device Name", systemImage: "tag")
                        .font(.headline)
                    TextField("Enter device name", text: $deviceName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("IP Address", systemImage: "network")
                        .font(.headline)
                    TextField("192.168.1.100", text: $ipAddress)
                        .textFieldStyle(.roundedBorder)
                }
                
                if showError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Add Device") {
                    if validateInput() {
                        onAdd(deviceName, ipAddress.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(serviceType.color)
                .disabled(ipAddress.isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
    
    private func validateInput() -> Bool {
        let parts = ipAddress.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ".")
        guard parts.count == 4 else {
            errorMessage = "Invalid IP address format"
            showError = true
            return false
        }
        
        for part in parts {
            guard let num = Int(part), num >= 0, num <= 255 else {
                errorMessage = "Invalid IP address format"
                showError = true
                return false
            }
        }
        
        showError = false
        return true
    }
}
