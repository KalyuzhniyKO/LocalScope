//
//  UniversalTerminalView.swift
//  Local Scope
//
//  ✅ ТОЛЬКО ВСТРОЕННЫЕ МЕТОДЫ macOS:
//  - SSH → Terminal.app
//  - RDP → Microsoft Remote Desktop (если установлен) или open rdp://
//  - VNC → Screen Sharing (встроенный)
//  - FTP → Terminal.app + sftp/ftp команды
//
//  ❌ БЕЗ предложений установки FreeRDP/RDesktop
//

import SwiftUI
import AppKit

struct UniversalTerminalView: View {
    let device: Device
    let serviceType: ServiceType
    let credentials: ConnectionCredentials?
    @Environment(\.dismiss) var dismiss
    
    @State private var rdpClient: RDPClient
    @State private var sshClient: SSHClient
    @State private var vncClient: VNCClient
    @State private var ftpClient: FTPClient
    
    @State private var connectionStatus: String = "Готов к подключению"
    @State private var isConnecting = false
    
    init(device: Device, serviceType: ServiceType, credentials: ConnectionCredentials?) {
        self.device = device
        self.serviceType = serviceType
        self.credentials = credentials
        
        let creds = credentials ?? ConnectionCredentials(username: "", password: "", saveCredentials: false)
        
        _rdpClient = State(initialValue: RDPClient(
            host: device.ip,
            username: creds.username,
            password: creds.password
        ))
        
        _sshClient = State(initialValue: SSHClient(
            host: device.ip,
            username: creds.username,
            password: creds.password
        ))
        
        _vncClient = State(initialValue: VNCClient(
            host: device.ip,
            username: creds.username,
            password: creds.password
        ))
        
        _ftpClient = State(initialValue: FTPClient(
            host: device.ip,
            username: creds.username,
            password: creds.password,
            useSFTP: serviceType == .sftp
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // HEADER
            HStack {
                Image(systemName: serviceType.icon)
                    .foregroundStyle(serviceType.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
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
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // CONTENT
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(serviceType.color.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: serviceType.icon)
                            .font(.system(size: 48))
                            .foregroundStyle(serviceType.color)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Универсальный терминал")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        
                        Text(connectionStatus)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    VStack(spacing: 6) {
                        InfoRow(icon: "server.rack", text: device.ip)
                        if let creds = credentials {
                            InfoRow(icon: "person.fill", text: creds.username)
                        }
                        InfoRow(icon: "network", text: serviceType.rawValue.uppercased())
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    
                    // ✅ ТОЛЬКО ВСТРОЕННЫЕ КНОПКИ
                    HStack(spacing: 16) {
                        QuickConnectButton(
                            title: "SSH",
                            icon: "terminal.fill",
                            color: .green
                        ) {
                            connectSSH()
                        }
                        
                        QuickConnectButton(
                            title: "RDP",
                            icon: "desktopcomputer",
                            color: .blue
                        ) {
                            connectRDP()
                        }
                        
                        QuickConnectButton(
                            title: "VNC",
                            icon: "display",
                            color: .orange
                        ) {
                            connectVNC()
                        }
                        
                        QuickConnectButton(
                            title: "FTP",
                            icon: "folder.fill",
                            color: .yellow
                        ) {
                            connectFTP()
                        }
                    }
                    
                    Spacer()
                }
                .padding(40)
                
                // Индикатор подключения
                if isConnecting {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Подключение...")
                            .foregroundStyle(.white)
                    }
                    .padding(40)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
        .frame(width: 900, height: 600)
        .onAppear {
            autoConnect()
        }
    }
    
    // MARK: - Auto Connect
    private func autoConnect() {
        switch serviceType {
        case .ssh:
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                connectSSH()
            }
        case .rdp:
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                connectRDP()
            }
        case .ftp, .sftp:
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                connectFTP()
            }
        case .vnc:
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                connectVNC()
            }
        }
    }
    
    // MARK: - Connection Methods (ТОЛЬКО ВСТРОЕННЫЕ)
    private func connectSSH() {
        Task { @MainActor in
            isConnecting = true
            connectionStatus = "🔄 Открытие SSH..."
            
            await sshClient.connect()
            connectionStatus = sshClient.connectionStatus
            
            try? await Task.sleep(nanoseconds: 500_000_000)
            isConnecting = false
            
            try? await Task.sleep(nanoseconds: 500_000_000)
            dismiss()
        }
    }
    
    private func connectRDP() {
        Task { @MainActor in
            isConnecting = true
            connectionStatus = "🖥️ Открытие RDP..."
            
            guard let creds = credentials else {
                connectionStatus = "❌ Требуются учётные данные"
                isConnecting = false
                return
            }
            
            // ✅ ВСТРОЕННЫЙ СПОСОБ: открываем rdp:// URL
            let rdpURL = "rdp://full%20address=s:\(device.ip):3389&username=s:\(creds.username)"
            
            if let url = URL(string: rdpURL) {
                NSWorkspace.shared.open(url)
                connectionStatus = "✅ RDP открыт (Microsoft Remote Desktop)"
            } else {
                connectionStatus = "❌ Ошибка создания RDP URL"
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isConnecting = false
            dismiss()
        }
    }
    
    private func connectVNC() {
        Task { @MainActor in
            isConnecting = true
            connectionStatus = "🖥️ Открытие VNC..."
            
            await vncClient.connect()
            connectionStatus = vncClient.connectionStatus
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isConnecting = false
            dismiss()
        }
    }
    
    private func connectFTP() {
        Task { @MainActor in
            isConnecting = true
            connectionStatus = "📁 Открытие FTP..."
            
            await ftpClient.connect()
            connectionStatus = ftpClient.connectionStatus
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isConnecting = false
            dismiss()
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 20)
            Text(text)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
    }
}

// MARK: - Quick Connect Button
struct QuickConnectButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isHovered ? 0.3 : 0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(width: 110, height: 110)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isHovered ? 0.08 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(isHovered ? 0.6 : 0.3), lineWidth: 2)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
