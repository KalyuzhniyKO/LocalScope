//
//  VNCNativeSessionController.swift
//  Local Scope
//

import Foundation
import Observation
import CoreGraphics

@MainActor
@Observable
final class VNCNativeSessionController {
    var connectionStatus = "Idle"
    var lastError: String?
    var isConnected = false
    var frameBuffer: VNCFrameBuffer = .empty
    var clipboardText = ""

    private let configuration: VNCNativeSessionConfiguration
    private let bridge: VNCNativeBridgeClient
    private var session: VNCNativeSessionHandle?

    init(
        configuration: VNCNativeSessionConfiguration,
        bridge: VNCNativeBridgeClient
    ) {
        self.configuration = configuration
        self.bridge = bridge
    }

    func connect() async {
        lastError = nil
        connectionStatus = "🔄 Подготовка нативной VNC-сессии..."

        let session = bridge.makeSession(configuration: configuration)
        self.session = session
        let applyEvent = self.handle

        do {
            try await session.start { event in
                Task { @MainActor in
                    applyEvent(event)
                }
            }
        } catch {
            isConnected = false
            lastError = error.localizedDescription
            connectionStatus = "❌ \(error.localizedDescription)"
        }
    }

    func disconnect() async {
        await session?.stop()
        session = nil
        isConnected = false
        connectionStatus = "Disconnected"
    }

    func sendPointerEvent(x: Int, y: Int, buttonMask: UInt8) async {
        await session?.sendPointerEvent(x: x, y: y, buttonMask: buttonMask)
    }

    func sendKeyEvent(keySym: UInt32, down: Bool) async {
        await session?.sendKeyEvent(keySym: keySym, down: down)
    }

    private func handle(_ event: VNCNativeSessionEvent) {
        switch event {
        case .connecting(let status):
            connectionStatus = status
        case .connected(let framebufferSize):
            isConnected = true
            connectionStatus = "✅ Нативная VNC-сессия подключена"
            let width = max(Int(framebufferSize.width), 1)
            let height = max(Int(framebufferSize.height), 1)
            frameBuffer = VNCFrameBuffer(
                width: width,
                height: height,
                bytesPerPixel: 4,
                pixels: Array(repeating: 0, count: width * height * 4)
            )
        case .framebufferUpdated(_, let frame):
            frameBuffer = frame
            isConnected = true
        case .clipboardChanged(let text):
            clipboardText = text
        case .disconnected:
            isConnected = false
            connectionStatus = "Disconnected"
        case .failed(let message):
            isConnected = false
            lastError = message
            connectionStatus = "❌ \(message)"
        }
    }
}
