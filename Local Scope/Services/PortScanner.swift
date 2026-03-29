//
//  PortScanner.swift
//  Local Scope
//
//  ИСПРАВЛЕНО:
//  ✅ Убран дубликат метода scanDevice
//  ✅ Один метод доступен из ViewModel
//

import Foundation
import Network

struct PortScanner {
    private static let deviceBatchSize = 24
    
    // ✅ ПУБЛИЧНЫЙ метод для сканирования всех устройств
    func scanServicesForDevices(_ devices: [Device]) async -> [Device] {
        var scannedDevices: [Device] = []

        for batchStart in stride(from: 0, to: devices.count, by: Self.deviceBatchSize) {
            let batch = devices.dropFirst(batchStart).prefix(Self.deviceBatchSize)

            let batchResults = await withTaskGroup(of: Device.self) { group -> [Device] in
                for device in batch {
                    group.addTask {
                        await scanDevice(device)
                    }
                }

                var localResults: [Device] = []
                for await device in group {
                    localResults.append(device)
                }
                return localResults
            }

            scannedDevices.append(contentsOf: batchResults)
        }

        return scannedDevices
    }
    
    // ✅ ПУБЛИЧНЫЙ метод для сканирования одного устройства
    func scanDevice(_ device: Device) async -> Device {
        var updatedDevice = device
        
        let portsToCheck: [(ServiceType, Int)] = [
            (.ssh, 22),
            (.rdp, 3389),
            (.ftp, 21),
            (.vnc, 5900)
        ]

        let discoveredServices = await withTaskGroup(of: [ServiceType].self) { group -> [ServiceType] in
            for (service, port) in portsToCheck {
                group.addTask {
                    guard await isPortOpen(ip: device.ip, port: port) else { return [] }

                    if service == .ssh {
                        return [.ssh, .sftp]
                    }

                    return [service]
                }
            }

            var services: [ServiceType] = []
            for await foundServices in group {
                services.append(contentsOf: foundServices)
            }
            return services
        }
        
        updatedDevice.availableServices = Array(Set(discoveredServices)).sorted { $0.rawValue < $1.rawValue }
        return updatedDevice
    }
    
    // ✅ ПРИВАТНЫЙ метод для проверки порта
    private func isPortOpen(ip: String, port: Int) async -> Bool {
        await withCheckedContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host(ip),
                port: NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port)),
                using: .tcp
            )
            
            let lock = NSLock()
            var hasResumed = false

            let finish: (Bool) -> Void = { result in
                lock.lock()
                defer { lock.unlock() }
                guard !hasResumed else { return }
                hasResumed = true
                connection.cancel()
                continuation.resume(returning: result)
            }
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    finish(true)
                case .failed:
                    finish(false)
                case .waiting:
                    // waiting может быть временным состоянием на медленной сети —
                    // даём шансу соединению перейти в .ready до таймаута
                    break
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                finish(false)
            }
        }
    }
}
