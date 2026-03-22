//
//  RDPClient.swift
//  Local Scope
//

import Foundation
import Network
import AppKit
import Observation

@Observable
final class RDPClient {
    var isConnected = false
    var connectionStatus = "Disconnected"
    var errorMessage: String?
    
    private var connection: NWConnection?
    
    let host: String
    let port: UInt16
    let username: String
    let password: String
    
    init(host: String, username: String, password: String, port: UInt16 = 3389) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
    }
    
    @MainActor
    func testConnection() {
        connectionStatus = "Testing connection..."
        
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: port)
        )
        
        connection = NWConnection(to: endpoint, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                await self?.handleState(state)
            }
        }
        
        connection?.start(queue: .global())
    }
    
    @MainActor
    private func handleState(_ state: NWConnection.State) async {
        switch state {
        case .ready:
            connectionStatus = "✅ Connected"
            isConnected = true
            disconnect()
        case .failed(let error):
            connectionStatus = "❌ Failed"
            errorMessage = error.localizedDescription
            isConnected = false
        case .waiting(let error):
            connectionStatus = "⏳ Waiting"
            errorMessage = error.localizedDescription
        case .cancelled:
            connectionStatus = "Cancelled"
            isConnected = false
        default:
            break
        }
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
    }
    
    @MainActor
    func connect() async {
        connectionStatus = "🖥️ Подготовка RDP подключения..."

        do {
            let fileURL = try createRDPFile()
            NSWorkspace.shared.open(fileURL)

            try? await Task.sleep(nanoseconds: 500_000_000)
            isConnected = true
            connectionStatus = "✅ RDP файл открыт"
        } catch {
            if let fallbackURL = makeLegacyRDPURL() {
                NSWorkspace.shared.open(fallbackURL)
                try? await Task.sleep(nanoseconds: 500_000_000)
                isConnected = true
                connectionStatus = "✅ RDP URL открыт"
            } else {
                isConnected = false
                errorMessage = error.localizedDescription
                connectionStatus = "❌ Не удалось подготовить RDP подключение"
            }
        }
    }

    private func createRDPFile() throws -> URL {
        let usernameLine = username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? ""
            : "username:s:\(username)\n"
        let passwordPromptLine = password.isEmpty ? "prompt for credentials on client:i:1\n" : ""
        let contents = """
        full address:s:\(host):\(port)
        \(usernameLine)\(passwordPromptLine)screen mode id:i:2
        use multimon:i:0
        """

        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectory
            .appendingPathComponent("LocalScope-\(host)-\(port)")
            .appendingPathExtension("rdp")

        try contents.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private func makeLegacyRDPURL() -> URL? {
        var components = URLComponents()
        components.scheme = "rdp"
        components.percentEncodedQueryItems = [
            URLQueryItem(name: "full address", value: "s:\(host):\(port)"),
            URLQueryItem(name: "username", value: username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "s:\(username)")
        ].compactMap { item in
            guard let value = item.value else { return nil }
            return URLQueryItem(name: item.name, value: value)
        }

        return components.url
    }
}
