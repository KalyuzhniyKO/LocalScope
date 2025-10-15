//
//  ConnectionManager.swift
//  Local Scope
//

import Foundation
import AppKit

actor ConnectionManager {
    
    func connect(to device: Device, using service: ServiceType) async -> (success: Bool, message: String) {
        switch service {
        case .ssh:
            return (true, "Opening SSH terminal for \(device.ip)")
        case .rdp:
            return (true, "Opening RDP viewer for \(device.ip)")
        case .ftp, .sftp:
            return (true, "Opening file manager for \(device.ip)")
        case .vnc:
            return await connectVNC(ip: device.ip)
        }
    }
    
    private func connectVNC(ip: String) async -> (success: Bool, message: String) {
        guard let url = URL(string: "vnc://\(ip)") else {
            return (false, "Invalid VNC URL")
        }
        
        return await MainActor.run {
            NSWorkspace.shared.open(url)
            return (true, "VNC connection opened")
        }
    }
}
