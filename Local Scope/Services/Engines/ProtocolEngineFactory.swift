//
//  ProtocolEngineFactory.swift
//  Local Scope
//

import Foundation

enum ProtocolEngineFactory {
    static func makeEngine(for serviceType: ServiceType) -> ProtocolEngine {
        switch serviceType {
        case .ssh:
            return SSHEngine()
        case .ftp:
            return FTPEngine(serviceType: .ftp)
        case .sftp:
            return FTPEngine(serviceType: .sftp)
        case .rdp:
            return RDPEngine()
        case .vnc:
            return VNCEngine()
        }
    }
}
