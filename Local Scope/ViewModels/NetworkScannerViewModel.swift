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
        loadCredentials()
        loadSessions()
    }
    
    // MARK: - Network Scanning (УСКОРЕННОЕ)
    func scanNetwork() {
        Task {
            scanning = true
            progress = 0.0
            syncStatus = "🔍 Определение активных сетевых интерфейсов..."

            let scanContexts = await networkScanner.activeScanContexts()

            guard !scanContexts.isEmpty else {
                syncStatus = "❌ Не удалось определить активные IPv4 интерфейсы"
                scanning = false
                return
            }

            localIP = scanContexts.first?.localIP ?? ""

            progress = 0.1
            let contextNames = scanContexts.map(\.displayName).joined(separator: ", ")
            syncStatus = "🔍 Быстрое сканирование: \(contextNames)"
            let scanner = networkScanner

            await withTaskGroup(of: Void.self) { group in
                for context in scanContexts {
                    group.addTask {
                        await scanner.quickPingSubnet(context: context)
                    }
                }
            }

            progress = 0.4
            syncStatus = "📋 Поиск устройств несколькими методами..."

            async let arpDevices = discoverDevicesViaARP(in: scanContexts)
            async let probedDevices = discoverDevicesViaPortSweep(in: scanContexts)

            let arpResults = await arpDevices
            let probedResults = await probedDevices
            let mergedDevices = mergeDiscoveredDevices(arpResults, probedResults)
            var foundDevices = mergedDevices
            devices = foundDevices

            progress = 0.6
            syncStatus = "🔍 Проверка портов (\(foundDevices.count) устройств)..."

            foundDevices = await portScanner.scanServicesForDevices(foundDevices)

            devices = foundDevices
            scanning = false
            progress = 1.0
            
            let withPorts = foundDevices.filter { !$0.availableServices.isEmpty }
            syncStatus = "✅ Найдено: \(foundDevices.count) устройств (\(withPorts.count) с портами)"
            
            await saveHistory()
        }
    }

    private func discoverDevicesViaARP(in contexts: [NetworkScanContext]) async -> [Device] {
        let scanner = networkScanner

        return await withTaskGroup(of: [Device].self) { group in
            for context in contexts {
                group.addTask {
                    await scanner.parseARPTable(context: context)
                }
            }

            var allDevices: [Device] = []
            for await batch in group {
                allDevices.append(contentsOf: batch)
            }
            return allDevices
        }
    }

    private func discoverDevicesViaPortSweep(in contexts: [NetworkScanContext]) async -> [Device] {
        let scanner = networkScanner

        return await withTaskGroup(of: [Device].self) { group in
            for context in contexts {
                group.addTask {
                    await scanner.discoverHostsByPortSweep(context: context)
                }
            }

            var allDevices: [Device] = []
            for await batch in group {
                allDevices.append(contentsOf: batch)
            }
            return allDevices
        }
    }

    private func mergeDiscoveredDevices(_ primary: [Device], _ fallback: [Device]) -> [Device] {
        let merged = Dictionary(grouping: primary + fallback, by: { $0.ip })
            .compactMap { _, devices -> Device? in
                devices.max { lhs, rhs in
                    let lhsScore = discoveryScore(for: lhs)
                    let rhsScore = discoveryScore(for: rhs)
                    if lhsScore == rhsScore {
                        return lhs.lastSeen < rhs.lastSeen
                    }
                    return lhsScore < rhsScore
                }
            }

        return merged.sorted { $0.ip < $1.ip }
    }

    private func discoveryScore(for device: Device) -> Int {
        var score = 0
        if device.mac != nil { score += 2 }
        if !device.availableServices.isEmpty { score += 2 }
        if device.type == "Network Device" { score += 1 }
        return score
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

    // MARK: - Sessions
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "savedSessions"),
           let decoded = try? JSONDecoder().decode([SavedSession].self, from: data) {
            savedSessions = decoded
        }
    }

    private func saveSessionsToStorage() {
        if let encoded = try? JSONEncoder().encode(savedSessions) {
            UserDefaults.standard.set(encoded, forKey: "savedSessions")
        }
    }

    func saveSession(name: String, device: Device, service: ServiceType, credentials: ConnectionCredentials) {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let session = SavedSession(
            id: existingSession(for: device, service: service)?.id ?? UUID(),
            name: normalizedName.isEmpty ? "\(device.name) - \(service.rawValue)" : normalizedName,
            device: device,
            serviceType: service,
            credentials: credentials
        )

        savedSessions.removeAll { $0.device.ip == device.ip && $0.serviceType == service }
        savedSessions.insert(session, at: 0)
        saveSessionsToStorage()
    }

    func sessions(for serviceType: ServiceType) -> [SavedSession] {
        savedSessions
            .filter { session in
                if serviceType == .ftp {
                    return session.serviceType == .ftp || session.serviceType == .sftp
                }
                return session.serviceType == serviceType
            }
    }

    func deleteSession(_ session: SavedSession) {
        savedSessions.removeAll { $0.id == session.id }
        saveSessionsToStorage()
    }

    private func existingSession(for device: Device, service: ServiceType) -> SavedSession? {
        savedSessions.first { $0.device.ip == device.ip && $0.serviceType == service }
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
    
    func addManualDevice(_ device: Device) {
        if let index = devices.firstIndex(where: { $0.ip == device.ip }) {
            devices[index] = device
        } else {
            devices.insert(device, at: 0)
        }

        if let historyIndex = history.firstIndex(where: { $0.ip == device.ip }) {
            history[historyIndex] = device
        } else {
            history.insert(device, at: 0)
        }

        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "deviceHistory")
        }
    }
    
    func rescanDevice(_ device: Device) {
        Task {
            let updatedDevice = await portScanner.scanDevice(device)

            if let index = devices.firstIndex(where: { $0.ip == device.ip }) {
                devices[index] = updatedDevice
            } else {
                devices.insert(updatedDevice, at: 0)
            }

            if let historyIndex = history.firstIndex(where: { $0.ip == device.ip }) {
                history[historyIndex] = updatedDevice
            }

            if let encoded = try? JSONEncoder().encode(history) {
                UserDefaults.standard.set(encoded, forKey: "deviceHistory")
            }

            let portsSummary = updatedDevice.availableServices
                .sorted { $0.port < $1.port }
                .map { "\($0.rawValue):\($0.port)" }
                .joined(separator: ", ")
            syncStatus = portsSummary.isEmpty
                ? "⚠️ Порты на \(device.ip) не обнаружены"
                : "✅ \(device.ip): \(portsSummary)"
        }
    }
    
    // MARK: - SSH/RDP/FTP Devices (вместо Sessions)
    func devices(for serviceType: ServiceType) -> [Device] {
        let allDevices = devices + history
        return allDevices.filter { device in
            if serviceType == .ftp {
                return device.availableServices.contains(.ftp) || device.availableServices.contains(.sftp)
            }
            return device.availableServices.contains(serviceType)
        }
    }
}
