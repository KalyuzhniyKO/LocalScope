//
//  ProtocolEngine.swift
//  Local Scope
//

import Foundation

enum ProtocolSessionMode: Sendable {
    case embeddedShell
    case probeOnly
}

struct ProtocolExecutionPlan: Sendable {
    let serviceType: ServiceType
    let mode: ProtocolSessionMode
    let title: String
    let command: String?
    let probePort: UInt16?
    let summary: String
}

protocol ProtocolEngine: Sendable {
    var serviceType: ServiceType { get }
    func makePlan(device: Device, credentials: ConnectionCredentials?) -> ProtocolExecutionPlan
}
