//
//  VNCClient.swift
//  Local Scope
//

import Foundation
import AppKit
import SwiftUI
import Observation

@Observable
final class VNCClient {
    var isConnected = false
    var connectionStatus = "Disconnected"
    
    let host: String
    let port: UInt16
    let username: String?
    let password: String?
    
    init(host: String, username: String? = nil, password: String? = nil, port: UInt16 = 5900) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
    }
    
    @MainActor
    func connect() {
        connectionStatus = "🖥️ Connecting VNC..."
        
        let vncURL: String
        if let user = username, let pass = password {
            vncURL = "vnc://\(user):\(pass)@\(host):\(port)"
        } else {
            vncURL = "vnc://\(host):\(port)"
        }
        
        if let url = URL(string: vncURL) {
            NSWorkspace.shared.open(url)
            
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000)
                isConnected = true
                connectionStatus = "✅ VNC opened"
            }
        } else {
            connectionStatus = "❌ Invalid URL"
        }
    }
}
