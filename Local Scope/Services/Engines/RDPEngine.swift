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
            summary: "Пока что для RDP доступен безопасный in-app probe режим. Нативный клиент будет подключён отдельным engine-адаптером."
        )
    }
}
