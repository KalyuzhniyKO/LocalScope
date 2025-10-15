//
//  PortScanner.swift
//  Local Scope
//

import Foundation
import Network

actor PortScanner {
    
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
    
    private func scanDevice(_ device: Device) async -> Device {
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
    
    private func isPortOpen(ip: String, port: Int) async -> Bool {
        await withCheckedContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host(ip),
                port: NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port)),
                using: .tcp
            )
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.cancel()
                    continuation.resume(returning: true)
                case .failed, .waiting:
                    connection.cancel()
                    continuation.resume(returning: false)
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                if connection.state != .ready && connection.state != .failed {
                    connection.cancel()
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
