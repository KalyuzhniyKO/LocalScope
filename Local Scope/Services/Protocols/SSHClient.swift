//
//  SSHClient.swift
//  Local Scope
//

import Foundation
import AppKit
import Observation

@Observable
final class SSHClient {
    var isConnected = false
    var connectionStatus = "Disconnected"

    let host: String
    let port: UInt16
    let username: String
    let password: String

    init(host: String, username: String, password: String, port: UInt16 = 22) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
    }

    @MainActor
    func connect() async {
        let normalizedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedUser.isEmpty else {
            connectionStatus = "❌ Укажите имя пользователя для SSH"
            isConnected = false
            return
        }

        connectionStatus = "🔄 Открытие SSH в Terminal..."

        let target = shellQuoted("\(normalizedUser)@\(host)")
        let command = "ssh -tt -o StrictHostKeyChecking=accept-new -p \(port) \(target)"
        let opened = executeInTerminal(command: command)

        try? await Task.sleep(nanoseconds: 500_000_000)
        isConnected = opened
        connectionStatus = opened
            ? "✅ SSH открыт в Terminal"
            : "❌ Не удалось открыть Terminal для SSH"
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
