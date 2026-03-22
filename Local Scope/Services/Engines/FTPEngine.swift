//
//  FTPEngine.swift
//  Local Scope
//

import Foundation

struct FTPEngine: ProtocolEngine {
    let serviceType: ServiceType

    init(serviceType: ServiceType) {
        self.serviceType = serviceType
    }

    func makePlan(device: Device, credentials: ConnectionCredentials?) -> ProtocolExecutionPlan {
        let username = credentials?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        switch serviceType {
        case .ftp:
            return ProtocolExecutionPlan(
                serviceType: .ftp,
                mode: .embeddedShell,
                title: "FTP",
                command: "ftp \(shellQuoted(device.ip)) 21",
                probePort: nil,
                summary: "Встроенная FTP shell-сессия будет запущена прямо внутри Local Scope."
            )
        case .sftp:
            let target = username.isEmpty ? shellQuoted(device.ip) : "\(shellQuoted(username))@\(shellQuoted(device.ip))"
            return ProtocolExecutionPlan(
                serviceType: .sftp,
                mode: .embeddedShell,
                title: "SFTP",
                command: "sftp -P 22 \(target)",
                probePort: nil,
                summary: "Встроенная SFTP shell-сессия будет запущена прямо внутри Local Scope."
            )
        default:
            return ProtocolExecutionPlan(
                serviceType: serviceType,
                mode: .probeOnly,
                title: serviceType.rawValue,
                command: nil,
                probePort: serviceType.port,
                summary: "Для этого протокола FTP-движок не применяется."
            )
        }
    }

    private func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
