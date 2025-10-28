//
//  SSHClient.swift
//  Local Scope
//

import Foundation
import SwiftUI
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
        connectionStatus = "🔄 Connecting SSH..."
        
        let command = "ssh \(username)@\(host) -p \(port)"
        executeInTerminal(command: command)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        isConnected = true
        connectionStatus = "✅ SSH opened"
    }
    
    private func executeInTerminal(command: String) {
        let script = """
        tell application "Terminal"
            activate
            do script "\(command)"
        end tell
        """
        
        if let scriptObject = NSAppleScript(source: script) {
            var error: NSDictionary?
            scriptObject.executeAndReturnError(&error)
        }
    }
}
