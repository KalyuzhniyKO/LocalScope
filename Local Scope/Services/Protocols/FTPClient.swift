//
//  FTPClient.swift
//  Local Scope
//

import Foundation
import Observation

@Observable
final class FTPClient {
    var isConnected = false
    var connectionStatus = "Disconnected"
    
    let host: String
    let port: UInt16
    let username: String
    let password: String
    let useSFTP: Bool
    
    init(host: String, username: String, password: String, port: UInt16 = 21, useSFTP: Bool = false) {
        self.host = host
        self.port = useSFTP && port == 21 ? 22 : port
        self.username = username
        self.password = password
        self.useSFTP = useSFTP
    }
    
    @MainActor
    func connect() async {
        connectionStatus = useSFTP ? "🔄 Открытие SFTP..." : "🔄 Открытие FTP..."
        
        let command: String
        if useSFTP {
            let target = username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? shellQuoted(host)
                : "\(shellQuoted(username))@\(shellQuoted(host))"
            command = "sftp -P \(port) \(target)"
        } else {
            command = "ftp \(shellQuoted(host)) \(port)"
        }
        
        let opened = executeInTerminal(command: command)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        isConnected = opened
        connectionStatus = opened
            ? (useSFTP ? "✅ SFTP команда отправлена в Terminal" : "✅ FTP команда отправлена в Terminal")
            : "❌ Не удалось открыть Terminal для FTP/SFTP"
    }
    
    private func executeInTerminal(command: String) -> Bool {
        let script = """
        tell application "Terminal"
            activate
            do script "\(escapeAppleScript(command))"
        end tell
        """
        
        if let scriptObject = NSAppleScript(source: script) {
            var error: NSDictionary?
            scriptObject.executeAndReturnError(&error)
            return error == nil
        }

        return false
    }

    private func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func escapeAppleScript(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
