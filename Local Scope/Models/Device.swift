//
//  Device.swift
//  Local Scope
//

import Foundation

struct Device: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var ip: String
    var mac: String?
    var type: String
    var lastSeen: Date
    var availableServices: [ServiceType]
    var favoriteServices: [ServiceType]
    
    init(id: UUID = UUID(), name: String, ip: String, mac: String?, type: String, lastSeen: Date, availableServices: [ServiceType] = [], favoriteServices: [ServiceType] = []) {
        self.id = id
        self.name = name
        self.ip = ip
        self.mac = mac
        self.type = type
        self.lastSeen = lastSeen
        self.availableServices = availableServices
        self.favoriteServices = favoriteServices
    }
    
    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
