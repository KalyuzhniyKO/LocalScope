//
//  Device.swift
//  Local Scope
//

import Foundation

struct Device: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var ip: String
    var mac: String?
    var type: String
    var lastSeen: Date
    var availableServices: [ServiceType]
    var favoriteServices: Set<ServiceType>
    
    init(
        id: UUID = UUID(),
        name: String,
        ip: String,
        mac: String? = nil,
        type: String,
        lastSeen: Date = Date(),
        availableServices: [ServiceType] = [],
        favoriteServices: Set<ServiceType> = []
    ) {
        self.id = id
        self.name = name
        self.ip = ip
        self.mac = mac
        self.type = type
        self.lastSeen = lastSeen
        self.availableServices = availableServices
        self.favoriteServices = favoriteServices
    }
    
    mutating func addToFavorites(_ service: ServiceType) {
        favoriteServices.insert(service)
    }
    
    mutating func removeFromFavorites(_ service: ServiceType) {
        favoriteServices.remove(service)
    }
    
    mutating func toggleFavorite(_ service: ServiceType) {
        if favoriteServices.contains(service) {
            favoriteServices.remove(service)
        } else {
            favoriteServices.insert(service)
        }
    }
}
