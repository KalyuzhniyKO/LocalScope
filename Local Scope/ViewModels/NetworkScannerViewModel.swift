//
//  NetworkScannerViewModel.swift
//  Local Scope
//

import SwiftUI
import Foundation
import Combine

@MainActor
final class NetworkScannerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var devices: [Device] = []
    @Published var history: [Device] = []
    @Published var localIP: String = "Detecting..."
    @Published var scanning = false
    @Published var progress: Double = 0.0
    @Published var syncStatus: String = ""
    @Published var savedSessions: [SavedSession] = []
    
    // MARK: - Private Properties
    private let networkScanner = NetworkScanner()
    private let portScanner = PortScanner()
    private let historyManager = HistoryManager()
    private let connectionManager = ConnectionManager()
    private var credentialsStorage: [String: ConnectionCredentials] = [:]
    
    // MARK: - Initialization
    init() {
        Task {
            await initialize()
        }
    }
    
    private func initialize() async {
        localIP = await networkScanner.getLocalIP() ?? "Unavailable"
        await loadHistory()
        loadSessions()
    }
    
    // MARK: - Network Scanning
    func scanNetwork() {
        guard !scanning else {
            scanning = false
            return
        }
        
        Task {
            scanning = true
            progress = 0.0
            
            // Сохраняем избранное перед очисткой
            let favoriteDevices = devices.filter { !$0.favoriteServices.isEmpty }
            devices.removeAll()
            
            guard let local = await networkScanner.getLocalIP(),
                  let subnet = networkScanner.extractSubnet(from: local) else {
                scanning = false
                syncStatus = "❌ Failed to detect local IP"
                return
            }
            
            syncStatus = "🔍 Pinging subnet..."
            await networkScanner.quickPingSubnet(subnet: subnet)
            progress = 0.5
            
            syncStatus = "📡 Reading ARP table..."
            var arpDevices = await networkScanner.parseARPTable(subnet: subnet, excludeIP: local)
            progress = 0.7
            
            syncStatus = "🔎 Scanning services..."
            arpDevices = await portScanner.scanServicesForDevices(arpDevices)
            progress = 0.9
            
            // Восстанавливаем избранное
            for i in 0..<arpDevices.count {
                if let favorite = favoriteDevices.first(where: { $0.ip == arpDevices[i].ip }) {
                    arpDevices[i].favoriteServices = favorite.favoriteServices
                }
            }
            
            devices = arpDevices
            scanning = false
            progress = 1.0
            syncStatus = "✅ Found \(devices.count) device(s)"
            
            // Обновление истории
            for device in devices {
                history = await historyManager.updateDevice(device, in: history)
            }
            await saveHistory()
        }
    }
    
    // MARK: - History Management
    func loadHistory() async {
        history = await historyManager.loadHistory()
        
        // Восстанавливаем избранное в devices
        for i in 0..<devices.count {
            if let historyDevice = history.first(where: { $0.ip == devices[i].ip }) {
                devices[i].favoriteServices = historyDevice.favoriteServices
            }
        }
    }
    
    private func saveHistory() async {
        let success = await historyManager.saveHistory(history)
        if !success {
            syncStatus = "❌ Failed to save history"
        }
    }
    
    func clearHistory() {
        Task {
            let success = await historyManager.clearHistory()
            history.removeAll()
            syncStatus = success ? "✅ History cleared" : "❌ Failed to clear history"
        }
    }
    
    func deleteFromHistory(device: Device) {
        Task {
            history.removeAll { $0.ip == device.ip }
            await saveHistory()
            syncStatus = "🗑️ Removed \(device.name) from history"
        }
    }
    
    // MARK: - Manual Device Management
    func addManualDevice(_ device: Device) {
        Task {
            history = await historyManager.updateDevice(device, in: history)
            
            if !devices.contains(where: { $0.ip == device.ip }) {
                devices.append(device)
            }
            
            await saveHistory()
            syncStatus = "✅ Device \(device.ip) added manually"
        }
    }
    
    // MARK: - Connection
    func connectToDevice(_ device: Device, service: ServiceType) {
        Task {
            syncStatus = "🔗 Connecting to \(device.ip) via \(service.rawValue)..."
            
            let result = await connectionManager.connect(to: device, using: service)
            syncStatus = result.success ? "✅ \(result.message)" : "❌ \(result.message)"
        }
    }
    
    // MARK: - Favorites Management
    func toggleFavorite(device: Device, service: ServiceType) {
        Task {
            // Обновляем в history
            if let index = history.firstIndex(where: { $0.ip == device.ip }) {
                var updatedDevice = history[index]
                
                if updatedDevice.favoriteServices.contains(service) {
                    updatedDevice.favoriteServices.removeAll { $0 == service }
                    syncStatus = "⭐ Removed \(service.rawValue) from favorites"
                } else {
                    updatedDevice.favoriteServices.append(service)
                    syncStatus = "⭐ Added \(service.rawValue) to favorites"
                }
                
                history[index] = updatedDevice
                
                // Обновляем в devices
                if let deviceIndex = devices.firstIndex(where: { $0.ip == device.ip }) {
                    devices[deviceIndex].favoriteServices = updatedDevice.favoriteServices
                }
                
                await saveHistory()
            }
        }
    }
    
    // MARK: - Credentials Management
    func saveCredentials(_ credentials: ConnectionCredentials, for device: Device, service: ServiceType) {
        let key = "\(device.ip)_\(service.rawValue)"
        credentialsStorage[key] = credentials
    }
    
    func getCredentials(for device: Device, service: ServiceType) -> ConnectionCredentials? {
        let key = "\(device.ip)_\(service.rawValue)"
        return credentialsStorage[key]
    }
    
    // MARK: - Sessions Management
    func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "savedSessions"),
           let sessions = try? JSONDecoder().decode([SavedSession].self, from: data) {
            savedSessions = sessions
        }
    }
    
    func saveSessions() {
        if let data = try? JSONEncoder().encode(savedSessions) {
            UserDefaults.standard.set(data, forKey: "savedSessions")
        }
    }
    
    func addSession(_ session: SavedSession) {
        savedSessions.append(session)
        saveSessions()
        syncStatus = "✅ Session '\(session.name)' saved"
    }
    
    func deleteSession(_ session: SavedSession) {
        savedSessions.removeAll { $0.id == session.id }
        saveSessions()
        syncStatus = "🗑️ Session '\(session.name)' deleted"
    }
}

// MARK: - Connection Credentials
struct ConnectionCredentials: Codable {
    var username: String
    var password: String
    var saveCredentials: Bool
}

// MARK: - Saved Session
struct SavedSession: Identifiable, Codable {
    let id: UUID
    let name: String
    let device: Device
    let serviceType: ServiceType
    let credentials: ConnectionCredentials
    
    init(id: UUID = UUID(), name: String, device: Device, serviceType: ServiceType, credentials: ConnectionCredentials) {
        self.id = id
        self.name = name
        self.device = device
        self.serviceType = serviceType
        self.credentials = credentials
    }
}
