//
//  RDPClient.swift
//  Local Scope
//

import Foundation
import Network
import SwiftUI
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
    func connect() {
        testConnection()
    }
}
