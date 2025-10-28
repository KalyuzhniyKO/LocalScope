//
//  FTPClient.swift
//  Local Scope
//

import Foundation
import SwiftUI
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
        self.port = port
        self.username = username
        self.password = password
        self.useSFTP = useSFTP
    }
    
    @MainActor
    func connect() {
        connectionStatus = "🔄 Connecting FTP..."
        
        let command: String
        if useSFTP {
            command = "sftp -P \(port) \(username)@\(host)"
        } else {
            command = "ftp \(host) \(port)"
        }
        
        executeInTerminal(command: command)
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            isConnected = true
            connectionStatus = "✅ FTP opened"
        }
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
