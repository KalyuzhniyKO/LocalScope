//
//  SSHEngine.swift
//  Local Scope
//

import Foundation

struct SSHEngine: ProtocolEngine {
    let serviceType: ServiceType = .ssh

    func makePlan(device: Device, credentials: ConnectionCredentials?) -> ProtocolExecutionPlan {
        let username = credentials?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let command = username.isEmpty ? nil : "ssh -p 22 \(shellQuoted(username))@\(shellQuoted(device.ip))"

        return ProtocolExecutionPlan(
            serviceType: .ssh,
            mode: .embeddedShell,
            title: "SSH",
            command: command,
            probePort: nil,
            summary: username.isEmpty
                ? "Для SSH нужен логин, чтобы запустить встроенную shell-сессию."
                : "Встроенная SSH shell-сессия будет запущена прямо внутри Local Scope."
        )
    }

    private func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
