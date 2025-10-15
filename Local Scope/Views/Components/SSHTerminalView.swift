//
//  SSHTerminalView.swift
//  Local Scope
//

import SwiftUI

struct SSHTerminalView: View {
    let device: Device
    let credentials: ConnectionCredentials?
    @Environment(\.dismiss) var dismiss
    
    @State private var output: String = ""
    @State private var command: String = ""
    @State private var isConnected: Bool = false
    @State private var connectionStatus: String = "Connecting..."
    
    private let sshProcess = SSHProcess()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("SSH Terminal - \(device.name)")
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
            
            ScrollView {
                ScrollViewReader { proxy in
                    Text(output)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .id("bottom")
                        .onChange(of: output) { _ in
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                }
            }
            .background(Color.black)
            
            Divider()
            
            HStack {
                Text("$")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.green)
                TextField("Enter command...", text: $command)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.green)
                    .onSubmit {
                        executeCommand()
                    }
                Button(action: executeCommand) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                .disabled(!isConnected)
            }
            .padding()
            .background(Color.black)
        }
        .frame(width: 800, height: 600)
        .onAppear {
            connect()
        }
        .onDisappear {
            disconnect()
        }
    }
    
    private func connect() {
        Task {
            connectionStatus = "Connecting..."
            output += "Connecting to \(device.ip)...\n"
            
            if let creds = credentials {
                output += "Username: \(creds.username)\n"
            }
            
            let result = await sshProcess.connect(to: device.ip, username: credentials?.username)
            
            await MainActor.run {
                if result.success {
                    isConnected = true
                    connectionStatus = "Connected"
                    output += result.message + "\n"
                    output += "Type commands below:\n\n"
                } else {
                    connectionStatus = "Connection failed"
                    output += "Error: \(result.message)\n"
                }
            }
        }
    }
    
    private func executeCommand() {
        guard !command.isEmpty else { return }
        
        output += "$ \(command)\n"
        let cmd = command
        command = ""
        
        Task {
            let result = await sshProcess.execute(cmd)
            await MainActor.run {
                output += result + "\n"
            }
        }
    }
    
    private func disconnect() {
        sshProcess.disconnect()
        dismiss()
    }
}

actor SSHProcess {
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    
    func connect(to ip: String, username: String?) async -> (success: Bool, message: String) {
        let newProcess = Process()
        newProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        
        if let user = username {
            newProcess.arguments = ["-o", "StrictHostKeyChecking=no", "\(user)@\(ip)"]
        } else {
            newProcess.arguments = ["-o", "StrictHostKeyChecking=no", ip]
        }
        
        let input = Pipe()
        let output = Pipe()
        
        newProcess.standardInput = input
        newProcess.standardOutput = output
        newProcess.standardError = output
        
        do {
            try newProcess.run()
            self.process = newProcess
            self.inputPipe = input
            self.outputPipe = output
            
            return (true, "Connected to \(ip)")
        } catch {
            return (false, "Failed to connect: \(error.localizedDescription)")
        }
    }
    
    func execute(_ command: String) async -> String {
        guard let input = inputPipe else {
            return "Error: Not connected"
        }
        
        let data = (command + "\n").data(using: .utf8)!
        
        do {
            try input.fileHandleForWriting.write(contentsOf: data)
            
            try await Task.sleep(nanoseconds: 500_000_000)
            
            guard let output = outputPipe else {
                return ""
            }
            
            let availableData = output.fileHandleForReading.availableData
            return String(data: availableData, encoding: .utf8) ?? ""
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    func disconnect() {
        process?.terminate()
        process = nil
        inputPipe = nil
        outputPipe = nil
    }
}
