//
//  RDPEngine.swift
//  Local Scope
//

import Foundation

struct RDPEngine: ProtocolEngine {
    let serviceType: ServiceType = .rdp

    func makePlan(device: Device, credentials: ConnectionCredentials?) -> ProtocolExecutionPlan {
        ProtocolExecutionPlan(
            serviceType: .rdp,
            mode: .probeOnly,
            title: "RDP",
            command: nil,
            probePort: 3389,
            summary: "RDP будет открыт через зарегистрированный macOS RDP клиент (.rdp файл / rdp://)."
        )
    }
}
