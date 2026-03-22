//
//  VNCEngine.swift
//  Local Scope
//

import Foundation

struct VNCEngine: ProtocolEngine {
    let serviceType: ServiceType = .vnc

    func makePlan(device: Device, credentials: ConnectionCredentials?) -> ProtocolExecutionPlan {
        let bridgeSummary = VNCNativeBridge.shared.status.summary

        ProtocolExecutionPlan(
            serviceType: .vnc,
            mode: .probeOnly,
            title: "VNC",
            command: nil,
            probePort: 5900,
            summary: "Пока что для VNC доступен безопасный in-app probe режим. \(bridgeSummary)"
        )
    }
}
