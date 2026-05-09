//
//  PortScanner.swift
//  Local Scope
//

import Foundation
@preconcurrency import Network

actor PortScanner {
    private let timeout: TimeInterval = 0.5

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

    func scanDevice(_ device: Device) async -> Device {
        let openPorts = await scanSupportedPorts(ip: device.ip)
        var updatedDevice = device
        updatedDevice.availableServices = services(for: openPorts)
        updatedDevice.lastSeen = Date()
        return updatedDevice
    }

    private func scanSupportedPorts(ip: String) async -> Set<UInt16> {
        let ports = Set(ServiceType.allCases.map(\.port))
        let scanTimeout = timeout

        return await withTaskGroup(of: (UInt16, Bool).self) { group in
            for port in ports {
                group.addTask {
                    let isOpen = await Self.isPortOpen(ip: ip, port: port, timeout: scanTimeout)
                    return (port, isOpen)
                }
            }

            var openPorts = Set<UInt16>()
            for await (port, isOpen) in group where isOpen {
                openPorts.insert(port)
            }
            return openPorts
        }
    }

    private func services(for openPorts: Set<UInt16>) -> [ServiceType] {
        ServiceType.allCases.filter { service in
            openPorts.contains(service.port)
        }
    }

    nonisolated private static func isPortOpen(ip: String, port: UInt16, timeout: TimeInterval) async -> Bool {
        await withCheckedContinuation { continuation in
            guard let endpointPort = NWEndpoint.Port(rawValue: port) else {
                continuation.resume(returning: false)
                return
            }

            let connection = NWConnection(
                host: NWEndpoint.Host(ip),
                port: endpointPort,
                using: .tcp
            )
            let completion = PortScanCompletion(connection: connection, continuation: continuation)

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    completion.resume(returning: true)
                case .failed, .waiting:
                    completion.resume(returning: false)
                default:
                    break
                }
            }

            connection.start(queue: .global(qos: .utility))

            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) {
                completion.resume(returning: false)
            }
        }
    }
}

private final class PortScanCompletion: @unchecked Sendable {
    private let lock = NSLock()
    private let connection: NWConnection
    private let continuation: CheckedContinuation<Bool, Never>
    private var didResume = false

    init(connection: NWConnection, continuation: CheckedContinuation<Bool, Never>) {
        self.connection = connection
        self.continuation = continuation
    }

    func resume(returning result: Bool) {
        lock.lock()
        guard !didResume else {
            lock.unlock()
            return
        }
        didResume = true
        lock.unlock()

        connection.stateUpdateHandler = nil
        connection.cancel()
        continuation.resume(returning: result)
    }
}
