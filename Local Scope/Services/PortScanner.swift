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

actor PortScanner {
    
    // ✅ ПУБЛИЧНЫЙ метод для сканирования всех устройств
    func scanServicesForDevices(_ devices: [Device]) async -> [Device] {
        await withTaskGroup(of: Device.self) { group -> [Device] in
            for device in devices {
                group.addTask {
                    await self.scanDevice(device)
                }
            }
            
            var scannedDevices: [Device] = []
            for await device in group {
                scannedDevices.append(device)
            }
            return scannedDevices
        }
    }
    
    // ✅ ПУБЛИЧНЫЙ метод для сканирования одного устройства
    func scanDevice(_ device: Device) async -> Device {
        var updatedDevice = device
        var services: [ServiceType] = []
        
        let portsToCheck: [(ServiceType, Int)] = [
            (.ssh, 22),
            (.rdp, 3389),
            (.ftp, 21),
            (.vnc, 5900)
        ]
        
        for (service, port) in portsToCheck {
            if await isPortOpen(ip: device.ip, port: port) {
                services.append(service)
            }
        }
        
        updatedDevice.availableServices = services
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
            
            let completion = PortScanCompletion()
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    completion.resumeOnce(connection: connection, continuation: continuation, returning: true)
                    
                case .failed, .waiting:
                    completion.resumeOnce(connection: connection, continuation: continuation, returning: false)
                    
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                completion.resumeOnce(connection: connection, continuation: continuation, returning: false)
            }
        }
    }
}

private final class PortScanCompletion: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false

    func resumeOnce(
        connection: NWConnection,
        continuation: CheckedContinuation<Bool, Never>,
        returning result: Bool
    ) {
        lock.lock()
        guard !didResume else {
            lock.unlock()
            return
        }
        didResume = true
        lock.unlock()

        connection.cancel()
        continuation.resume(returning: result)
    }
}
