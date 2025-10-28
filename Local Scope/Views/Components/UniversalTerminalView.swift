//
//  UniversalTerminalView.swift
//  Local Scope
//
//  ✅ УНИВЕРСАЛЬНЫЙ ТЕРМИНАЛ (как MobaXterm)
//

import SwiftUI
import AppKit

struct UniversalTerminalView: View {
    let device: Device
    let serviceType: ServiceType
    let credentials: ConnectionCredentials?
    @Environment(\.dismiss) var dismiss
    
    // ✅ КЛИЕНТЫ ПРОТОКОЛОВ (теперь используем @State вместо @StateObject)
    @State private var rdpClient: RDPClient
    @State private var sshClient: SSHClient
    @State private var vncClient: VNCClient
    @State private var ftpClient: FTPClient
    
    @State private var selectedProtocol: ConnectionMethod = .auto
    @State private var connectionStatus: String = "Готов к подключению"
    
    enum ConnectionMethod: String, CaseIterable, Identifiable {
        case auto = "Автовыбор"
        case ssh = "SSH (встроенный)"
        case rdpNative = "RDP (собственный)"
        case rdpFree = "RDP (FreeRDP)"
        case rdpWeb = "RDP (Web Client)"
        case vnc = "VNC (Screen Sharing)"
        case ftp = "FTP/SFTP"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .auto: return "wand.and.stars"
            case .ssh: return "terminal"
            case .rdpNative, .rdpFree, .rdpWeb: return "desktopcomputer"
            case .vnc: return "display"
            case .ftp: return "folder"
            }
        }
        
        var color: Color {
            switch self {
            case .auto: return .purple
            case .ssh: return .green
            case .rdpNative, .rdpFree, .rdpWeb: return .blue
            case .vnc: return .orange
            case .ftp: return .yellow
            }
        }
    }
    
    // ✅ ИНИЦИАЛИЗАЦИЯ (теперь обычная инициализация без StateObject)
    init(device: Device, serviceType: ServiceType, credentials: ConnectionCredentials?) {
        self.device = device
        self.serviceType = serviceType
        self.credentials = credentials
        
        let creds = credentials ?? ConnectionCredentials(username: "", password: "", saveCredentials: false)
        
        // Инициализируем клиенты напрямую
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
                Image(systemName: selectedProtocol.icon)
                    .foregroundStyle(selectedProtocol.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.headline)
                    Text("\(device.ip) • \(serviceType.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Menu {
                    ForEach(ConnectionMethod.allCases) { method in
                        Button {
                            selectedProtocol = method
                        } label: {
                            Label(method.rawValue, systemImage: method.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedProtocol.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedProtocol.color.opacity(0.15))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
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
                            .fill(selectedProtocol.color.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: selectedProtocol.icon)
                            .font(.system(size: 48))
                            .foregroundStyle(selectedProtocol.color)
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
                    
                    HStack(spacing: 16) {
                        QuickConnectButton(
                            title: "SSH",
                            icon: "terminal.fill",
                            color: .green
                        ) {
                            selectedProtocol = .ssh
                            connectSSH()
                        }
                        
                        QuickConnectButton(
                            title: "RDP",
                            icon: "desktopcomputer",
                            color: .blue
                        ) {
                            selectedProtocol = .rdpFree
                            connectRDP()
                        }
                        
                        QuickConnectButton(
                            title: "VNC",
                            icon: "display",
                            color: .orange
                        ) {
                            selectedProtocol = .vnc
                            connectVNC()
                        }
                        
                        QuickConnectButton(
                            title: "FTP",
                            icon: "folder.fill",
                            color: .yellow
                        ) {
                            selectedProtocol = .ftp
                            connectFTP()
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Установка дополнительных инструментов:")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        
                        Text("• FreeRDP: brew install freerdp")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Text("• RDesktop: brew install rdesktop")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(40)
            }
        }
        .frame(width: 1200, height: 800)
        .onAppear {
            autoConnect()
        }
    }
    
    private func autoConnect() {
        switch serviceType {
        case .ssh:
            selectedProtocol = .ssh
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                connectSSH()
            }
        case .rdp:
            selectedProtocol = .rdpFree
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                connectRDP()
            }
        case .ftp, .sftp:
            selectedProtocol = .ftp
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                connectFTP()
            }
        case .vnc:
            selectedProtocol = .vnc
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                connectVNC()
            }
        }
    }
    
    private func connectSSH() {
        Task { @MainActor in
            await sshClient.connect()
            connectionStatus = sshClient.connectionStatus
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            dismiss()
        }
    }
    
    private func connectRDP() {
        guard let creds = credentials else {
            connectionStatus = "❌ Требуются учётные данные"
            return
        }
        
        connectionStatus = "🖥️ Подключение RDP..."
        
        let command: String
        
        switch selectedProtocol {
        case .rdpFree:
            command = """
            if ! command -v xfreerdp &> /dev/null; then
                echo "❌ FreeRDP не установлен"
                echo ""
                echo "📦 Установите: brew install freerdp"
                read -p "Enter для выхода..."
                exit 1
            fi
            
            xfreerdp /v:\(device.ip):3389 /u:'\(creds.username)' /p:'\(creds.password)' /w:1920 /h:1080 /cert:ignore /dynamic-resolution +clipboard
            """
            
        case .rdpNative:
            command = """
            if ! command -v rdesktop &> /dev/null; then
                echo "❌ rdesktop не установлен"
                echo ""
                echo "📦 Установите: brew install rdesktop"
                read -p "Enter для выхода..."
                exit 1
            fi
            
            rdesktop -u '\(creds.username)' -p '\(creds.password)' \(device.ip):3389 -g 1920x1080 -a 32
            """
            
        default:
            command = "echo 'Выберите метод RDP'"
        }
        
        executeInTerminal(command: command, title: "RDP - \(device.name)")
        
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            dismiss()
        }
    }
    
    private func connectVNC() {
        Task { @MainActor in
            await vncClient.connect()
            connectionStatus = vncClient.connectionStatus
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            dismiss()
        }
    }
    
    private func connectFTP() {
        Task { @MainActor in
            await ftpClient.connect()
            connectionStatus = ftpClient.connectionStatus
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            dismiss()
        }
    }
    
    private func executeInTerminal(command: String, title: String = "Local Scope") {
        let escapedCommand = command.replacingOccurrences(of: "\"", with: "\\\"")
        
        let script = """
        tell application "Terminal"
            activate
            set newTab to do script "\(escapedCommand)"
            set custom title of newTab to "\(title)"
        end tell
        """
        
        if let scriptObject = NSAppleScript(source: script) {
            var error: NSDictionary?
            scriptObject.executeAndReturnError(&error)
            
            if let error = error {
                connectionStatus = "❌ Ошибка: \(error["NSAppleScriptErrorMessage"] ?? "Unknown")"
            } else {
                connectionStatus = "✅ Терминал открыт"
            }
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
