//
//  ProtocolEngineProfile.swift
//  Local Scope
//

import Foundation

enum ProtocolEngineState: String, Codable, Sendable {
    case integrated = "Integrated"
    case planned = "Planned"
}

struct ProtocolEngineProfile: Sendable {
    let currentEngineName: String
    let currentState: ProtocolEngineState
    let preferredOpenSourceEngine: String?
    let adoptionNotes: String
}
