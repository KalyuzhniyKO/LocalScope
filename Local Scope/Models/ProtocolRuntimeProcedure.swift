//
//  ProtocolRuntimeProcedure.swift
//  Local Scope
//

import Foundation

struct ProtocolRuntimeProcedure: Sendable {
    let worksOutOfBoxOnMac: Bool
    let supportsFullInAppSession: Bool
    let primaryActionTitle: String
    let userFacingMessage: String
}
