//
//  NetworkScannerViewModel.swift
//  Local Scope
//
//  ✅ ВСЕ ИСПРАВЛЕНИЯ:
//  1. Фильтрация broadcast (192.168.0.255 и ff:ff:ff:ff:ff:ff)
//  2. Ускоренное параллельное сканирование
//  3. БЕЗ вкладки Sessions - сессии в SSH/RDP/FTP вкладках
//

import SwiftUI
import Foundation
import Observation

@MainActor
@Observable
final class NetworkScannerViewModel {
    // MARK: - Properties
    var devices: [Device] = []
    var history: [Device] = []
    var scanning = false
    var progress: Double = 0.0
    var syncStatus = ""
    var localIP = ""
    
    // MARK: - Services
    private let networkScanner = NetworkScanner()
    private let portScanner = PortScanner()
    
    // MARK: - Credentials Storage
    private var savedCredentials: [String: ConnectionCredentials] = [:]
    
    // MARK: - Initialization
    init() {
        loadHistory()
        loadCredentials()
    }
    
    // MARK: - Network Scanning (УСКОРЕННОЕ)
    func scanNetwork() {
        Task {
            scanning = true
            progress = 0.0
            syncStatus = "🔍 Получение локального IP..."
            
            guard let localIPAddress = await networkScanner.getLocalIP() else {
                syncStatus = "❌ Не удалось получить локальный IP"
                scanning = false
                return
            }
            
            localIP = localIPAddress
            
            guard let subnet = networkScanner.extractSubnet(from: localIPAddress) else {
                syncStatus = "❌ Не удалось определить подсеть"
                scanning = false
                return
            }
            
            progress = 0.1
            syncStatus = "🔍 Быстрое сканирование \(subnet).0/24..."
            
            // ✅ ПАРАЛЛЕЛЬНЫЙ ПИНГ (~2 секунды)
            await networkScanner.quickPingSubnet(subnet: subnet)
            
            progress = 0.4
            syncStatus = "📋 Поиск устройств..."
            
            // ✅ ПАРСИНГ ARP (без broadcast)
            var foundDevices = await networkScanner.parseARPTable(subnet: subnet, excludeIP: localIPAddress)
            
            progress = 0.6
            syncStatus = "🔍 Проверка портов (\(foundDevices.count) устройств)..."
            
            // ✅ ПАРАЛЛЕЛЬНОЕ СКАНИРОВАНИЕ ПОРТОВ
            foundDevices = await portScanner.scanServicesForDevices(foundDevices)
            
            devices = foundDevices
            scanning = false
            progress = 1.0
            
            let withPorts = foundDevices.filter { !$0.availableServices.isEmpty }
            syncStatus = "✅ Найдено: \(foundDevices.count) устройств (\(withPorts.count) с портами)"
            
            await saveHistory()
        }
    }
    
    // MARK: - History Management
    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "deviceHistory"),
           let decoded = try? JSONDecoder().decode([Device].self, from: data) {
            history = decoded
        }
    }
    
    private func saveHistory() async {
        let allDevices = devices + history
        let uniqueDevices = Dictionary(grouping: allDevices, by: { $0.ip })
            .compactMap { $0.value.max(by: { $0.lastSeen < $1.lastSeen }) }
        history = Array(uniqueDevices.sorted(by: { $0.lastSeen > $1.lastSeen }).prefix(50))
        
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "deviceHistory")
        }
    }
    
    func deleteFromHistory(device: Device) {
        history.removeAll { $0.id == device.id }
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "deviceHistory")
        }
    }
    
    func clearHistory() {
        history.removeAll()
        UserDefaults.standard.removeObject(forKey: "deviceHistory")
    }
    
    // MARK: - Credentials Management
    private func loadCredentials() {
        if let data = UserDefaults.standard.data(forKey: "savedCredentials"),
           let decoded = try? JSONDecoder().decode([String: ConnectionCredentials].self, from: data) {
            savedCredentials = decoded
        }
    }
    
    private func saveCredentialsToStorage() {
        if let encoded = try? JSONEncoder().encode(savedCredentials) {
            UserDefaults.standard.set(encoded, forKey: "savedCredentials")
        }
    }
    
    func getCredentials(for device: Device, service: ServiceType) -> ConnectionCredentials? {
        let key = "\(device.ip)-\(service.rawValue)"
        return savedCredentials[key]
    }
    
    func saveCredentials(_ credentials: ConnectionCredentials, for device: Device, service: ServiceType) {
        let key = "\(device.ip)-\(service.rawValue)"
        savedCredentials[key] = credentials
        saveCredentialsToStorage()
    }
    
    // MARK: - Device Management
    func toggleFavorite(device: Device, service: ServiceType) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index].toggleFavorite(service)
            
            if let historyIndex = history.firstIndex(where: { $0.id == device.id }) {
                history[historyIndex].toggleFavorite(service)
                if let encoded = try? JSONEncoder().encode(history) {
                    UserDefaults.standard.set(encoded, forKey: "deviceHistory")
                }
            }
        }
    }
    
    func addManualDevice(name: String, ip: String, preferredService: ServiceType) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIP = ip.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            syncStatus = "🔍 Scanning ports for \(trimmedIP)..."

            let existingDevice = devices.first(where: { $0.ip == trimmedIP })
                ?? history.first(where: { $0.ip == trimmedIP })
            let provisionalName = trimmedName.isEmpty ? (existingDevice?.name ?? "Manual Device") : trimmedName
            let provisionalDevice = Device(
                id: existingDevice?.id ?? UUID(),
                name: provisionalName,
                ip: trimmedIP,
                mac: existingDevice?.mac,
                type: existingDevice?.type ?? "Manual",
                lastSeen: Date(),
                availableServices: existingDevice?.availableServices ?? [],
                favoriteServices: existingDevice?.favoriteServices ?? []
            )

            let scannedDevice = await portScanner.scanDevice(provisionalDevice)
            upsertDevice(scannedDevice)
            await saveHistory()

            let serviceList = scannedDevice.availableServices.map(\.rawValue).joined(separator: ", ")
            if scannedDevice.availableServices.isEmpty {
                syncStatus = "⚠️ Added device: no known ports open"
            } else if scannedDevice.availableServices.contains(preferredService) {
                syncStatus = "✅ Added device: \(serviceList) found"
            } else {
                syncStatus = "⚠️ Added device: \(serviceList) found; \(preferredService.rawValue) is not available"
            }
        }
    }

    func rescanDevice(_ device: Device) {
        Task {
            syncStatus = "🔍 Scanning ports for \(device.ip)..."
            let updatedDevice = await portScanner.scanDevice(device)
            upsertDevice(updatedDevice)
            await saveHistory()

            if updatedDevice.availableServices.isEmpty {
                syncStatus = "⚠️ \(device.name): no known ports open"
            } else {
                let serviceList = updatedDevice.availableServices.map(\.rawValue).joined(separator: ", ")
                syncStatus = "✅ \(device.name): \(serviceList) found"
            }
        }
    }

    private func upsertDevice(_ device: Device) {
        var updatedDevice = device
        updatedDevice.lastSeen = Date()

        if let index = devices.firstIndex(where: { $0.ip == updatedDevice.ip }) {
            devices[index] = updatedDevice
        } else {
            devices.append(updatedDevice)
        }

        if let historyIndex = history.firstIndex(where: { $0.ip == updatedDevice.ip }) {
            history[historyIndex] = updatedDevice
        }
    }

    // MARK: - SSH/RDP/FTP Devices (вместо Sessions)
    func devices(for serviceType: ServiceType) -> [Device] {
        uniqueDevicesByIP(devices + history)
            .filter { $0.availableServices.contains(serviceType) }
    }

    private func uniqueDevicesByIP(_ allDevices: [Device]) -> [Device] {
        Dictionary(grouping: allDevices, by: { $0.ip })
            .compactMap { $0.value.max(by: { $0.lastSeen < $1.lastSeen }) }
            .sorted(by: { $0.lastSeen > $1.lastSeen })
    }
}
