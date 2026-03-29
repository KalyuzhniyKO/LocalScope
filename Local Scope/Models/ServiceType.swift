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

    var requiresCredentials: Bool {
        switch self {
        case .ssh, .ftp, .sftp:
            return true
        case .rdp, .vnc:
            return false
        }
    }

    var engineName: String {
        engineProfile.currentEngineName
    }

    var engineSummary: String {
        engineProfile.adoptionNotes
    }

    var hasFullInAppEngine: Bool {
        runtimeProcedure.supportsFullInAppSession
    }

    var preferredOpenSourceEngine: String? {
        engineProfile.preferredOpenSourceEngine
    }

    var engineProfile: ProtocolEngineProfile {
        switch self {
        case .ssh:
            return ProtocolEngineProfile(
                currentEngineName: "System SSH Client",
                currentState: .integrated,
                preferredOpenSourceEngine: "libssh2",
                adoptionNotes: "Сейчас SSH открывается через системный ssh в Terminal. Для полностью нативного in-app SSH движка следующим шагом остаётся libssh2."
            )
        case .ftp:
            return ProtocolEngineProfile(
                currentEngineName: "System FTP Handler",
                currentState: .integrated,
                preferredOpenSourceEngine: nil,
                adoptionNotes: "Сейчас FTP открывается через системный macOS handler для ftp:// URL, потому что системный бинарь ftp на современных macOS может отсутствовать."
            )
        case .sftp:
            return ProtocolEngineProfile(
                currentEngineName: "System SFTP Client",
                currentState: .integrated,
                preferredOpenSourceEngine: "libssh2",
                adoptionNotes: "Сейчас SFTP открывается через системный sftp в Terminal; оптимальный следующий шаг для нативного SFTP/SSH-движка — libssh2."
            )
        case .rdp:
            return ProtocolEngineProfile(
                currentEngineName: "Internal RDP Probe",
                currentState: .planned,
                preferredOpenSourceEngine: "FreeRDP",
                adoptionNotes: "Сейчас RDP работает во внутреннем probe-режиме без запуска внешних приложений. Для полноценного in-app RDP-клиента нужен отдельный нативный engine (например FreeRDP)."
            )
        case .vnc:
            return ProtocolEngineProfile(
                currentEngineName: "System VNC Client",
                currentState: .integrated,
                preferredOpenSourceEngine: "LibVNCClient",
                adoptionNotes: "Сейчас VNC открывается через Screen Sharing или нативный bridge, если он будет подключён. Полностью нативный VNC-клиент по-прежнему требует отдельной интеграции LibVNCClient."
            )
        }
    }

    var runtimeProcedure: ProtocolRuntimeProcedure {
        switch self {
        case .ssh:
            return ProtocolRuntimeProcedure(
                worksOutOfBoxOnMac: true,
                supportsFullInAppSession: false,
                primaryActionTitle: "Connect",
                userFacingMessage: "На macOS SSH открывается через системный ssh в Terminal, чтобы подключение реально запускалось."
            )
        case .ftp:
            return ProtocolRuntimeProcedure(
                worksOutOfBoxOnMac: true,
                supportsFullInAppSession: false,
                primaryActionTitle: "Connect",
                userFacingMessage: "На macOS FTP открывается через системный обработчик ftp://, потому что встроенный ftp-бинарь может отсутствовать."
            )
        case .sftp:
            return ProtocolRuntimeProcedure(
                worksOutOfBoxOnMac: true,
                supportsFullInAppSession: false,
                primaryActionTitle: "Connect",
                userFacingMessage: "На macOS SFTP открывается через системный sftp в Terminal."
            )
        case .rdp:
            return ProtocolRuntimeProcedure(
                worksOutOfBoxOnMac: false,
                supportsFullInAppSession: false,
                primaryActionTitle: "Check",
                userFacingMessage: "Для RDP сейчас доступна только внутренняя проверка порта без запуска сторонних приложений."
            )
        case .vnc:
            return ProtocolRuntimeProcedure(
                worksOutOfBoxOnMac: true,
                supportsFullInAppSession: false,
                primaryActionTitle: "Connect",
                userFacingMessage: "На macOS VNC открывается через Screen Sharing или нативный bridge, если он подключён."
            )
        }
    }
}
