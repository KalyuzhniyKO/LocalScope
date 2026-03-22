//
//  VNCEngine.swift
//  Local Scope
//

import Foundation

struct VNCEngine: ProtocolEngine {
    let serviceType: ServiceType = .vnc

    func makePlan(device: Device, credentials: ConnectionCredentials?) -> ProtocolExecutionPlan {
        let bridgeSummary = VNCNativeBridge.shared.status.summary

        return ProtocolExecutionPlan(
            serviceType: .vnc,
            mode: .probeOnly,
            title: "VNC",
            command: nil,
            probePort: 5900,
            summary: "VNC будет открыт через Screen Sharing или нативный bridge, если он подключён. \(bridgeSummary)"
        )
    }
}
