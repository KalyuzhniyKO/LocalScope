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
    func connect() async {
        let nativeConfiguration = VNCNativeSessionConfiguration(
            host: host,
            port: port,
            password: password
        )

        if VNCNativeBridge.shared.status.isAvailable {
            connectionStatus = "🖥️ Запуск нативной VNC-сессии..."
            let nativeSession = VNCNativeBridge.shared.makeSession(configuration: nativeConfiguration)

            do {
                try await nativeSession.start { _ in }
                isConnected = true
                connectionStatus = "✅ Нативная VNC-сессия запущена"
                return
            } catch {
                isConnected = false
                connectionStatus = "⚠️ Нативный VNC bridge не запустился, выполняется fallback"
            }
        }

        connectionStatus = "🖥️ Открытие Screen Sharing..."

        var components = URLComponents()
        components.scheme = "vnc"
        components.host = host
        components.port = Int(port)

        if let url = components.url {
            NSWorkspace.shared.open(url)
            
            try? await Task.sleep(nanoseconds: 500_000_000)
            isConnected = true
            connectionStatus = "✅ VNC открыт в Screen Sharing"
        } else {
            isConnected = false
            connectionStatus = "❌ Некорректный VNC URL"
        }
    }
}
