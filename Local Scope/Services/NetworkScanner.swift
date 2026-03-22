//
//  NetworkScanner.swift
//  Local Scope
//

import Foundation
import Network

struct NetworkScanContext: Sendable, Hashable {
    let interfaceName: String
    let localIP: String
    let subnet: String

    var displayName: String {
        "\(interfaceName) • \(subnet).0/24"
    }
}

struct NetworkScanner {
    private static let discoveryPorts = [22, 21, 53, 80, 139, 443, 445, 554, 631, 3389, 5000, 5357, 8009, 8080, 8443, 9100, 32400, 5900]
    private static let hostSuffixes = Array(1...254)
    private static let pingBatchSize = 24
    private static let probeBatchSize = 32
    
    func getLocalIP() async -> String? {
        await activeScanContexts().first?.localIP
    }

    func activeScanContexts() async -> [NetworkScanContext] {
        var contexts: [NetworkScanContext] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0 else { return [] }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee,
                  let addressPointer = interface.ifa_addr else { continue }

            let addrFamily = addressPointer.pointee.sa_family
            guard addrFamily == UInt8(AF_INET) else { continue }

            let flags = Int32(interface.ifa_flags)
            guard (flags & IFF_UP) != 0, (flags & IFF_LOOPBACK) == 0 else { continue }

            let interfaceName = String(cString: interface.ifa_name)

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(
                addressPointer,
                socklen_t(addressPointer.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                socklen_t(0),
                NI_NUMERICHOST
            )

            let localIP = String(cString: hostname)
            guard let subnet = extractSubnet(from: localIP) else { continue }

            contexts.append(
                NetworkScanContext(
                    interfaceName: interfaceName,
                    localIP: localIP,
                    subnet: subnet
                )
            )
        }

        return Array(Set(contexts)).sorted { lhs, rhs in
            Self.scanPriority(for: lhs.interfaceName) < Self.scanPriority(for: rhs.interfaceName)
        }
    }
    
    func extractSubnet(from ip: String) -> String? {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return nil }
        return parts.dropLast().joined(separator: ".")
    }

    private static func scanPriority(for interfaceName: String) -> Int {
        switch interfaceName {
        case "en0":
            return 0
        case "en1":
            return 1
        default:
            return 2
        }
    }
    
    func quickPingSubnet(subnet: String) async {
        for batchStart in stride(from: 0, to: Self.hostSuffixes.count, by: Self.pingBatchSize) {
            let batch = Self.hostSuffixes.dropFirst(batchStart).prefix(Self.pingBatchSize)

            await withTaskGroup(of: Void.self) { group in
                for suffix in batch {
                    group.addTask {
                        let ip = "\(subnet).\(suffix)"
                        let process = Process()
                        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
                        process.arguments = ["-c", "1", "-W", "200", ip]
                        process.standardOutput = Pipe()
                        process.standardError = Pipe()
                        try? process.run()
                        process.waitUntilExit()
                    }
                }
            }
        }
    }

    func discoverHostsByPortSweep(subnet: String, excludeIP: String) async -> [Device] {
        var devices: [Device] = []

        for batchStart in stride(from: 0, to: Self.hostSuffixes.count, by: Self.probeBatchSize) {
            let batch = Self.hostSuffixes.dropFirst(batchStart).prefix(Self.probeBatchSize)

            let batchDevices = await withTaskGroup(of: Device?.self) { group in
                for suffix in batch {
                    let ip = "\(subnet).\(suffix)"
                    guard ip != excludeIP else { continue }

                    group.addTask {
                        guard await Self.hasAnyDiscoveryPortOpen(ip: ip) else { return nil }
                        let deviceName = DeviceDetector.detectType(mac: "", ip: ip)

                        return Device(
                            name: deviceName,
                            ip: ip,
                            mac: nil,
                            type: "Port Probe",
                            lastSeen: Date()
                        )
                    }
                }

                var found: [Device] = []
                for await device in group {
                    if let device {
                        found.append(device)
                    }
                }
                return found
            }

            devices.append(contentsOf: batchDevices)
        }

        return devices
    }
    
    func parseARPTable(subnet: String, excludeIP: String) async -> [Device] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/arp")
        process.arguments = ["-a"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            var devices: [Device] = []
            let lines = output.components(separatedBy: .newlines)
            
            for line in lines {
                guard !line.contains("incomplete") else { continue }
                
                let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                guard components.count >= 4 else { continue }
                
                let ipMatch = components[1].replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                let macAddress = components[3]
                
                // ✅ ФИЛЬТРЫ: пропускаем локальный IP, broadcast, multicast
                guard ipMatch != excludeIP,
                      !ipMatch.hasSuffix(".255"),  // broadcast
                      !ipMatch.hasSuffix(".0"),    // network address
                      macAddress != "ff:ff:ff:ff:ff:ff",  // broadcast MAC
                      macAddress.count > 5,        // валидный MAC
                      ipMatch.starts(with: subnet) else { continue }
                
                let deviceType = DeviceDetector.detectType(mac: macAddress, ip: ipMatch)
                let device = Device(
                    name: deviceType,
                    ip: ipMatch,
                    mac: macAddress,
                    type: "Network Device",
                    lastSeen: Date()
                )
                devices.append(device)
            }
            
            return devices
        } catch {
            return []
        }
    }

    private static func hasAnyDiscoveryPortOpen(ip: String) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            for port in Self.discoveryPorts {
                group.addTask {
                    await Self.isPortReachable(ip: ip, port: port, timeout: 250_000_000)
                }
            }

            for await isOpen in group {
                if isOpen {
                    group.cancelAll()
                    return true
                }
            }

            return false
        }
    }

    private static func isPortReachable(ip: String, port: Int, timeout: UInt64) async -> Bool {
        await withCheckedContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host(ip),
                port: NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port)),
                using: .tcp
            )

            let lock = NSLock()
            var resumed = false

            let finish: (Bool) -> Void = { result in
                lock.lock()
                defer { lock.unlock() }
                guard !resumed else { return }
                resumed = true
                connection.cancel()
                continuation.resume(returning: result)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    finish(true)
                case .failed, .waiting:
                    finish(false)
                default:
                    break
                }
            }

            connection.start(queue: .global())

            DispatchQueue.global().asyncAfter(deadline: .now() + .nanoseconds(Int(timeout))) {
                finish(false)
            }
        }
    }
}
