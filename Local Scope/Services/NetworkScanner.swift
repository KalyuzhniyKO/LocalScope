//
//  NetworkScanner.swift
//  Local Scope
//

import Foundation
import Network

actor NetworkScanner {
    
    func getLocalIP() async -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count),
                               nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        return address
    }
    
    func extractSubnet(from ip: String) -> String? {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return nil }
        return parts.dropLast().joined(separator: ".")
    }
    
    func quickPingSubnet(subnet: String) async {
        await withTaskGroup(of: Void.self) { group in
            for i in 1...254 {
                group.addTask {
                    let ip = "\(subnet).\(i)"
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
                guard line.contains(subnet),
                      !line.contains(excludeIP),
                      !line.contains("incomplete") else { continue }
                
                let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                guard components.count >= 4 else { continue }
                
                let ipMatch = components[1].replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                let macAddress = components[3]
                
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
}
