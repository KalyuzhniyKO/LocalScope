//
//  NetworkScannerViewModel.swift
//  Local Scope
//
//  ViewModel для управления сканированием сети
//  ✅ Использует @Observable вместо ObservableObject
//  ✅ Совместим с вашими actor-based сервисами
//  ✅ Все методы из ContentView
//

import SwiftUI
import Foundation
import Observation

@MainActor
@Observable
final class NetworkScannerViewModel {
    // MARK: - Published Properties
    var devices: [Device] = []
    var history: [Device] = []
    var savedSessions: [SavedSession] = []
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
        loadSessions()
        loadCredentials()
    }
    
    // MARK: - Network Scanning
    func scanNetwork() {
        Task {
            scanning = true
            progress = 0.0
            syncStatus = "🔍 Сканирование сети..."
            
            // Получаем локальный IP
            guard let localIPAddress = await networkScanner.getLocalIP() else {
                syncStatus = "❌ Не удалось получить локальный IP"
                scanning = false
                return
            }
            
            localIP = localIPAddress
            
            // Извлекаем подсеть
            guard let subnet = await networkScanner.extractSubnet(from: localIPAddress) else {
                syncStatus = "❌ Не удалось определить подсеть"
                scanning = false
                return
            }
            
            syncStatus = "🔍 Пингуем подсеть \(subnet).0/24..."
            
            // Быстрый пинг всей подсети
            await networkScanner.quickPingSubnet(subnet: subnet)
            
            syncStatus = "📋 Парсим ARP таблицу..."
            
            // Парсим ARP таблицу
            var foundDevices = await networkScanner.parseARPTable(subnet: subnet, excludeIP: localIPAddress)
            
            progress = 0.5
            syncStatus = "🔍 Сканирование портов..."
            
            // Сканируем порты найденных устройств
            foundDevices = await portScanner.scanServicesForDevices(foundDevices)
            
            devices = foundDevices
            scanning = false
            progress = 1.0
            syncStatus = "✅ Найдено устройств: \(devices.count)"
            
            // Сохраняем в историю
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
        
        // Удаляем дубликаты по IP
        let uniqueDevices = Dictionary(grouping: allDevices, by: { $0.ip })
            .compactMap { $0.value.max(by: { $0.lastSeen < $1.lastSeen }) }
        
        // Сортируем по времени и берём последние 50
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
    
    // MARK: - Sessions Management
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "savedSessions"),
           let decoded = try? JSONDecoder().decode([SavedSession].self, from: data) {
            savedSessions = decoded
        }
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(savedSessions) {
            UserDefaults.standard.set(encoded, forKey: "savedSessions")
        }
    }
    
    func addSession(_ session: SavedSession) {
        savedSessions.append(session)
        saveSessions()
    }
    
    func deleteSession(_ session: SavedSession) {
        savedSessions.removeAll { $0.id == session.id }
        saveSessions()
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
            
            // Обновляем в истории тоже
            if let historyIndex = history.firstIndex(where: { $0.id == device.id }) {
                history[historyIndex].toggleFavorite(service)
                if let encoded = try? JSONEncoder().encode(history) {
                    UserDefaults.standard.set(encoded, forKey: "deviceHistory")
                }
            }
        }
    }
    
    func addManualDevice(_ device: Device) {
        // Проверяем, нет ли уже такого устройства
        if !devices.contains(where: { $0.ip == device.ip }) {
            devices.append(device)
        }
    }
    
    func rescanDevice(_ device: Device) {
        Task {
            let updatedDevice = await portScanner.scanDevice(device)
            if let index = devices.firstIndex(where: { $0.id == device.id }) {
                devices[index] = updatedDevice
            }
        }
    }
}
