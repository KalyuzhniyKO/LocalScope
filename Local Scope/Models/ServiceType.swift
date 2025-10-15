//
//  ServiceType.swift
//  Local Scope
//

import SwiftUI

enum ServiceType: String, Codable, CaseIterable, Hashable {
    case ssh = "SSH"
    case rdp = "RDP"
    case ftp = "FTP"
    case sftp = "SFTP"
    case vnc = "VNC"
    
    var icon: String {
        switch self {
        case .ssh: return "terminal"
        case .rdp: return "desktopcomputer"
        case .ftp: return "folder"
        case .sftp: return "lock.shield"
        case .vnc: return "tv"
        }
    }
    
    var color: Color {
        switch self {
        case .ssh: return .green
        case .rdp: return .blue
        case .ftp: return .orange
        case .sftp: return .purple
        case .vnc: return .pink
        }
    }
    
    var port: Int {
        switch self {
        case .ssh: return 22
        case .rdp: return 3389
        case .ftp: return 21
        case .sftp: return 22
        case .vnc: return 5900
        }
    }
}
