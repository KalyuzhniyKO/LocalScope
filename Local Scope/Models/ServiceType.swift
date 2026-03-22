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
        engineProfile.currentState == .integrated
    }

    var preferredOpenSourceEngine: String? {
        engineProfile.preferredOpenSourceEngine
    }

    var engineProfile: ProtocolEngineProfile {
        switch self {
        case .ssh:
            return ProtocolEngineProfile(
                currentEngineName: "Embedded SSH Shell",
                currentState: .integrated,
                preferredOpenSourceEngine: "libssh2",
                adoptionNotes: "Сейчас используется встроенная shell-сессия Local Scope через системный ssh; оптимальный следующий шаг для нативного SSH-движка — libssh2."
            )
        case .ftp:
            return ProtocolEngineProfile(
                currentEngineName: "Embedded FTP Shell",
                currentState: .integrated,
                preferredOpenSourceEngine: nil,
                adoptionNotes: "Сейчас используется встроенная shell-сессия Local Scope через системный ftp."
            )
        case .sftp:
            return ProtocolEngineProfile(
                currentEngineName: "Embedded SFTP Shell",
                currentState: .integrated,
                preferredOpenSourceEngine: "libssh2",
                adoptionNotes: "Сейчас используется встроенная shell-сессия Local Scope через системный sftp; оптимальный следующий шаг для нативного SFTP/SSH-движка — libssh2."
            )
        case .rdp:
            return ProtocolEngineProfile(
                currentEngineName: "Internal RDP Probe",
                currentState: .planned,
                preferredOpenSourceEngine: "FreeRDP",
                adoptionNotes: "Пока что выполняется только внутренняя проверка RDP-порта. Оптимальный полноценный in-app движок для RDP — FreeRDP."
            )
        case .vnc:
            return ProtocolEngineProfile(
                currentEngineName: "Internal VNC Probe",
                currentState: .planned,
                preferredOpenSourceEngine: "LibVNCClient",
                adoptionNotes: "Пока что выполняется только внутренняя проверка VNC-порта. Технически оптимальный кандидат для полноценного VNC-клиента — LibVNCClient, но его лицензию нужно отдельно оценить перед внедрением."
            )
        }
    }

    var runtimeProcedure: ProtocolRuntimeProcedure {
        switch self {
        case .ssh:
            return ProtocolRuntimeProcedure(
                worksOutOfBoxOnMac: true,
                supportsFullInAppSession: true,
                primaryActionTitle: "Connect",
                userFacingMessage: "На macOS должен работать из коробки через встроенную shell-сессию и системный ssh."
            )
        case .ftp:
            return ProtocolRuntimeProcedure(
                worksOutOfBoxOnMac: true,
                supportsFullInAppSession: true,
                primaryActionTitle: "Connect",
                userFacingMessage: "На macOS должен работать из коробки через встроенную shell-сессию и системный ftp."
            )
        case .sftp:
            return ProtocolRuntimeProcedure(
                worksOutOfBoxOnMac: true,
                supportsFullInAppSession: true,
                primaryActionTitle: "Connect",
                userFacingMessage: "На macOS должен работать из коробки через встроенную shell-сессию и системный sftp."
            )
        case .rdp:
            return ProtocolRuntimeProcedure(
                worksOutOfBoxOnMac: false,
                supportsFullInAppSession: false,
                primaryActionTitle: "Check",
                userFacingMessage: "Полноценный RDP-сеанс без сторонних приложений ещё не встроен: сейчас доступна только внутренняя проверка порта."
            )
        case .vnc:
            return ProtocolRuntimeProcedure(
                worksOutOfBoxOnMac: false,
                supportsFullInAppSession: false,
                primaryActionTitle: "Check",
                userFacingMessage: "Полноценный VNC-сеанс без сторонних приложений ещё не встроен: сейчас доступна только внутренняя проверка порта."
            )
        }
    }
}
