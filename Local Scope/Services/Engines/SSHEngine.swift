//
//  SSHEngine.swift
//  Local Scope
//

import Foundation

struct SSHEngine: ProtocolEngine {
    let serviceType: ServiceType = .ssh

    func makePlan(device: Device, credentials: ConnectionCredentials?) -> ProtocolExecutionPlan {
        let username = credentials?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let command = username.isEmpty ? nil : "ssh -tt -o StrictHostKeyChecking=accept-new -p 22 \(shellQuoted("\(username)@\(device.ip)"))"

        return ProtocolExecutionPlan(
            serviceType: .ssh,
            mode: .embeddedShell,
            title: "SSH",
            command: command,
            probePort: nil,
            summary: username.isEmpty
                ? "Для SSH нужен логин, чтобы открыть системный ssh в Terminal."
                : "Системный ssh будет открыт через Terminal."
        )
    }

    private func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
