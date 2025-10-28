//
//  SavedSession.swift
//  Local Scope
//

import Foundation

struct SavedSession: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var device: Device
    var serviceType: ServiceType
    var credentials: ConnectionCredentials
    
    init(id: UUID = UUID(), name: String, device: Device, serviceType: ServiceType, credentials: ConnectionCredentials) {
        self.id = id
        self.name = name
        self.device = device
        self.serviceType = serviceType
        self.credentials = credentials
    }
}
