//
//  HistoryManager.swift
//  Local Scope
//

import Foundation

actor HistoryManager {
    private let fileURL: URL
    
    init() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let appDirectory = homeDirectory.appendingPathComponent(".localscope")
        
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        
        self.fileURL = appDirectory.appendingPathComponent("history.json")
    }
    
    func loadHistory() async -> [Device] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let devices = try JSONDecoder().decode([Device].self, from: data)
            return devices
        } catch {
            print("Failed to load history: \(error)")
            return []
        }
    }
    
    func saveHistory(_ devices: [Device]) async -> Bool {
        do {
            let data = try JSONEncoder().encode(devices)
            try data.write(to: fileURL)
            return true
        } catch {
            print("Failed to save history: \(error)")
            return false
        }
    }
    
    func clearHistory() async -> Bool {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            return true
        } catch {
            print("Failed to clear history: \(error)")
            return false
        }
    }
    
    func updateDevice(_ device: Device, in history: [Device]) async -> [Device] {
        var updatedHistory = history
        
        if let index = updatedHistory.firstIndex(where: { $0.ip == device.ip }) {
            var existingDevice = updatedHistory[index]
            existingDevice.lastSeen = device.lastSeen
            existingDevice.availableServices = device.availableServices
            existingDevice.name = device.name
            updatedHistory[index] = existingDevice
        } else {
            updatedHistory.append(device)
        }
        
        return updatedHistory
    }
}
