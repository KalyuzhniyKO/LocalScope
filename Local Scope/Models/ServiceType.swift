//
//  ServiceType.swift
//  Local Scope
//
//  Типы сервисов для подключения
//

import Foundation
import SwiftUI

enum ServiceType: String, Codable, CaseIterable, Identifiable, Sendable, Hashable {
    case ssh = "SSH"
    case rdp = "RDP"
    case ftp = "FTP"
    case sftp = "SFTP"
    case vnc = "VNC"
    
    var id: String { rawValue }
    
    var port: UInt16 {
        switch self {
        case .ssh: return 22
        case .rdp: return 3389
        case .ftp: return 21
        case .sftp: return 22
        case .vnc: return 5900
        }
    }
    
    var icon: String {
        switch self {
        case .ssh: return "terminal"
        case .rdp: return "desktopcomputer"
        case .ftp, .sftp: return "folder"
        case .vnc: return "display"
        }
    }
    
    var color: Color {
        switch self {
        case .ssh: return .green
        case .rdp: return .blue
        case .ftp, .sftp: return .yellow
        case .vnc: return .orange
        }
    }
}
