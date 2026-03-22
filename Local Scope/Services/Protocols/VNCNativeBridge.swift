//
//  VNCNativeBridge.swift
//  Local Scope
//

import Foundation
import CoreGraphics

enum VNCNativeBridgeStatus: Sendable {
    case unavailable
    case linked

    var isAvailable: Bool {
        self == .linked
    }

    var summary: String {
        switch self {
        case .unavailable:
            return "LibVNCClient phase-2 bridge scaffold готов, но сама native C-библиотека ещё не завендорена и не залинкована в macOS target."
        case .linked:
            return "LibVNCClient bridge активен: можно запускать нативную VNC-сессию и framebuffer pipeline."
        }
    }
}

struct VNCNativeSessionConfiguration: Sendable {
    let host: String
    let port: UInt16
    let password: String?
}

struct VNCFrameRegion: Sendable, Equatable {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
}

enum VNCNativeSessionEvent: Sendable {
    case connecting(String)
    case connected(framebufferSize: CGSize)
    case framebufferUpdated(region: VNCFrameRegion, frame: VNCFrameBuffer)
    case clipboardChanged(String)
    case disconnected
    case failed(String)
}

protocol VNCNativeSessionHandle: Sendable {
    func start(eventHandler: @escaping @Sendable (VNCNativeSessionEvent) -> Void) async throws
    func stop() async
    func sendPointerEvent(x: Int, y: Int, buttonMask: UInt8) async
    func sendKeyEvent(keySym: UInt32, down: Bool) async
}

protocol VNCNativeBridgeClient: Sendable {
    var status: VNCNativeBridgeStatus { get }
    func makeSession(configuration: VNCNativeSessionConfiguration) -> VNCNativeSessionHandle
}

struct StubVNCNativeSessionHandle: VNCNativeSessionHandle {
    let configuration: VNCNativeSessionConfiguration

    func start(eventHandler: @escaping @Sendable (VNCNativeSessionEvent) -> Void) async throws {
        eventHandler(.connecting("Подготовка native VNC bridge для \(configuration.host):\(configuration.port)"))
        throw VNCNativeBridgeError.notLinked
    }

    func stop() async {}

    func sendPointerEvent(x: Int, y: Int, buttonMask: UInt8) async {}

    func sendKeyEvent(keySym: UInt32, down: Bool) async {}
}

struct StubVNCNativeBridgeClient: VNCNativeBridgeClient {
    let status: VNCNativeBridgeStatus = .unavailable

    func makeSession(configuration: VNCNativeSessionConfiguration) -> VNCNativeSessionHandle {
        StubVNCNativeSessionHandle(configuration: configuration)
    }
}

enum VNCNativeBridge {
    static let shared: VNCNativeBridgeClient = StubVNCNativeBridgeClient()
}

enum VNCNativeBridgeError: LocalizedError {
    case notLinked

    var errorDescription: String? {
        switch self {
        case .notLinked:
            return "Нативный LibVNCClient bridge пока не подключён к приложению."
        }
    }
}
