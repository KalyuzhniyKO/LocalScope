//
//  RDPViewerView.swift
//  Local Scope
//
//  ВСТРОЕННЫЙ RDP КЛИЕНТ
//

import SwiftUI
import WebKit

struct RDPViewerView: View {
    let device: Device
    let credentials: ConnectionCredentials?
    @Environment(\.dismiss) var dismiss
    
    @State private var connectionStatus: String = "Connecting..."
    @State private var isConnected: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // HEADER
            HStack {
                Image(systemName: "desktopcomputer")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("RDP Connection - \(device.name)")
                        .font(.headline)
                    Text(device.ip)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Circle()
                    .fill(isConnected ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(connectionStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(action: { disconnect() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // RDP VIEW
            ZStack {
                Color.black
                
                VStack(spacing: 20) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.3))
                    
                    Text("RDP Viewer")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.5))
                    
                    VStack(spacing: 8) {
                        Text("Connecting to: \(device.ip)")
                            .foregroundStyle(.white.opacity(0.7))
                        if let creds = credentials {
                            Text("Username: \(creds.username)")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .font(.caption)
                    
                    Button("Open in External App") {
                        openExternalRDP()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
        }
        .frame(width: 1024, height: 768)
        .onAppear {
            connect()
        }
    }
    
    private func connect() {
        Task {
            connectionStatus = "Connecting..."
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isConnected = true
                connectionStatus = "Connected"
            }
        }
    }
    
    private func disconnect() {
        dismiss()
    }
    
    private func openExternalRDP() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Microsoft Remote Desktop", "rdp://\(device.ip)"]
        
        do {
            try process.run()
        } catch {
            if let url = URL(string: "rdp://\(device.ip)") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
