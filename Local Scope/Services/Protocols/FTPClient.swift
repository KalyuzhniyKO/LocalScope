//
//  FTPClient.swift
//  Local Scope
//

import Foundation
import AppKit
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
        if useSFTP {
            connectionStatus = "🔄 Открытие SFTP в Terminal..."
            let normalizedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
            let target = normalizedUser.isEmpty ? shellQuoted(host) : shellQuoted("\(normalizedUser)@\(host)")
            let command = "sftp -P \(port) \(target)"
            let opened = executeInTerminal(command: command)

            try? await Task.sleep(nanoseconds: 500_000_000)
            isConnected = opened
            connectionStatus = opened
                ? "✅ SFTP открыт в Terminal"
                : "❌ Не удалось открыть Terminal для SFTP"
            return
        }

        connectionStatus = "🔄 Открытие FTP через системный обработчик..."
        guard let url = makeFTPURL() else {
            connectionStatus = "❌ Не удалось сформировать FTP URL"
            isConnected = false
            return
        }

        let opened = NSWorkspace.shared.open(url)
        try? await Task.sleep(nanoseconds: 300_000_000)
        isConnected = opened
        connectionStatus = opened
            ? "✅ FTP URL открыт системным обработчиком"
            : "❌ Не удалось открыть FTP URL"
    }

    private func makeFTPURL() -> URL? {
        var components = URLComponents()
        components.scheme = "ftp"
        components.host = host
        components.port = Int(port)

        let normalizedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedUser.isEmpty {
            components.user = normalizedUser
        }

        if !password.isEmpty {
            components.password = password
        }

        return components.url
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
