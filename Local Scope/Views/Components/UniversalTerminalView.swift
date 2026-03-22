//
//  UniversalTerminalView.swift
//  Local Scope
//
//  ✅ ВСТРОЕННЫЕ СЕССИИ ВНУТРИ ПРИЛОЖЕНИЯ:
//  - SSH / FTP / SFTP → встроенная shell-сессия в окне Local Scope
//  - RDP / VNC → внутренняя проверка доступности и статус подключения
//

import SwiftUI
import AppKit
import Network

struct UniversalTerminalView: View {
    let device: Device
    let serviceType: ServiceType
    let credentials: ConnectionCredentials?
    @Environment(\.dismiss) var dismiss
    
    @State private var connectionStatus: String = "Готов к подключению"
    @State private var isConnecting = false
    @State private var terminalOutput = ""
    @State private var terminalInput = ""
    @State private var sessionIsRunning = false
    @State private var hasStartedInitialFlow = false
    @State private var processSession = EmbeddedProcessSession()
    @State private var vncNativeController: VNCNativeSessionController?
    
    init(device: Device, serviceType: ServiceType, credentials: ConnectionCredentials?) {
        self.device = device
        self.serviceType = serviceType
        self.credentials = credentials
    }

    private var executionPlan: ProtocolExecutionPlan {
        ProtocolEngineFactory.makeEngine(for: serviceType).makePlan(device: device, credentials: credentials)
    }

    var body: some View {
        VStack(spacing: 0) {
            // HEADER
            HStack {
                Image(systemName: serviceType.icon)
                    .foregroundStyle(serviceType.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.headline)
                    Text("\(device.ip) • \(serviceType.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // CONTENT
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(serviceType.color.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: serviceType.icon)
                            .font(.system(size: 48))
                            .foregroundStyle(serviceType.color)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Универсальный терминал")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        
                        Text(connectionStatus)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    VStack(spacing: 8) {
                        Label(serviceType.engineName, systemImage: serviceType.hasFullInAppEngine ? "cpu.fill" : "waveform.path.ecg")
                            .font(.headline)
                            .foregroundStyle(serviceType.hasFullInAppEngine ? .green : .orange)

                        Text(serviceType.engineSummary)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.72))

                        if let preferredEngine = serviceType.preferredOpenSourceEngine {
                            Text("Recommended engine: \(preferredEngine)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        Text(serviceType.runtimeProcedure.userFacingMessage)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(
                                serviceType.runtimeProcedure.worksOutOfBoxOnMac
                                    ? .green.opacity(0.8)
                                    : .orange.opacity(0.85)
                            )

                        Text(executionPlan.summary)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 6) {
                        InfoRow(icon: "server.rack", text: device.ip)
                        if let creds = credentials {
                            InfoRow(icon: "person.fill", text: creds.username)
                        }
                        InfoRow(icon: "network", text: serviceType.rawValue.uppercased())
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    
                    protocolWorkspace

                    HStack(spacing: 16) {
                        QuickConnectButton(
                            title: "SSH",
                            icon: "terminal.fill",
                            color: .green
                        ) {
                            connectSSH()
                        }
                        
                        QuickConnectButton(
                            title: "RDP",
                            icon: "desktopcomputer",
                            color: .blue
                        ) {
                            connectRDP()
                        }
                        
                        QuickConnectButton(
                            title: "VNC",
                            icon: "display",
                            color: .orange
                        ) {
                            connectVNC()
                        }
                        
                        QuickConnectButton(
                            title: "FTP",
                            icon: "folder.fill",
                            color: .yellow
                        ) {
                            connectFTP()
                        }
                    }
                    
                    Spacer()
                }
                .padding(40)
                
                // Индикатор подключения
                if isConnecting {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Подключение...")
                            .foregroundStyle(.white)
                    }
                    .padding(40)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
        .frame(minWidth: 760, idealWidth: 820, minHeight: 520, idealHeight: 580)
        .onAppear {
            if !hasStartedInitialFlow {
                hasStartedInitialFlow = true
                prepareNativeVNCIfNeeded()
                autoConnect()
            }
        }
        .onDisappear {
            processSession.stop()
            if let controller = vncNativeController {
                Task {
                    await controller.disconnect()
                }
            }
        }
    }

    @ViewBuilder
    private var protocolWorkspace: some View {
        if serviceType == .ssh || serviceType == .ftp || serviceType == .sftp {
            VStack(spacing: 12) {
                ScrollView {
                    Text(terminalOutput.isEmpty ? "Ожидание запуска встроенной сессии..." : terminalOutput)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 260)
                .background(Color.black.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                HStack(spacing: 12) {
                    TextField("Введите команду или пароль и нажмите Send", text: $terminalInput)
                        .textFieldStyle(.roundedBorder)

                    Button("Send") {
                        sendInput()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!sessionIsRunning || terminalInput.isEmpty)

                    Button("Stop") {
                        stopSession()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!sessionIsRunning)
                }
            }
        } else if serviceType == .vnc,
                  VNCNativeBridge.shared.status.isAvailable,
                  let controller = vncNativeController {
            VStack(alignment: .leading, spacing: 14) {
                Label("Нативный VNC framebuffer pipeline", systemImage: "display.2")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(controller.connectionStatus)
                    .foregroundStyle(.white.opacity(0.8))

                VNCFrameBufferView(frameBuffer: controller.frameBuffer)
                    .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                HStack(spacing: 12) {
                    Button("Reconnect") {
                        Task {
                            await controller.connect()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Disconnect") {
                        Task {
                            await controller.disconnect()
                        }
                    }
                    .buttonStyle(.bordered)
                }

                if let error = controller.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            VStack(alignment: .leading, spacing: 14) {
                Label("Внешние приложения не используются.", systemImage: "internaldrive")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Для \(serviceType.rawValue) сейчас выполняется внутренняя проверка доступности сервиса и подготовка параметров подключения прямо в окне Local Scope.")
                    .foregroundStyle(.white.opacity(0.8))

                HStack(spacing: 12) {
                    Label("Host: \(device.ip)", systemImage: "server.rack")
                    Label("Port: \(serviceType.port)", systemImage: "network")
                }
                .foregroundStyle(.white.opacity(0.75))

                Text(connectionStatus)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    // MARK: - Auto Connect
    private func autoConnect() {
        if serviceType == .vnc,
           VNCNativeBridge.shared.status.isAvailable,
           let controller = vncNativeController {
            Task {
                await controller.connect()
            }
            return
        }

        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            runCurrentPlan()
        }
    }

    private func prepareNativeVNCIfNeeded() {
        guard serviceType == .vnc, VNCNativeBridge.shared.status.isAvailable else { return }

        vncNativeController = VNCNativeSessionController(
            configuration: VNCNativeSessionConfiguration(
                host: device.ip,
                port: serviceType.port,
                password: credentials?.password
            ),
            bridge: VNCNativeBridge.shared
        )
    }
    
    // MARK: - Connection Methods (ВНУТРИ ПРИЛОЖЕНИЯ)
    private func connectSSH() {
        runCurrentPlan()
    }
    
    private func connectRDP() {
        runCurrentPlan()
    }
    
    private func connectVNC() {
        if VNCNativeBridge.shared.status.isAvailable,
           let controller = vncNativeController {
            Task {
                await controller.connect()
            }
            return
        }

        runCurrentPlan()
    }
    
    private func connectFTP() {
        runCurrentPlan()
    }

    private func runCurrentPlan() {
        Task { @MainActor in
            let plan = executionPlan

            switch plan.mode {
            case .embeddedShell:
                guard let command = plan.command else {
                    connectionStatus = "❌ \(plan.summary)"
                    return
                }
                startEmbeddedSession(title: plan.title, command: command)
            case .probeOnly:
                guard let port = plan.probePort else {
                    connectionStatus = "❌ Для \(plan.title) не настроен probe-порт"
                    return
                }

                isConnecting = true
                connectionStatus = "🔍 \(plan.summary)"
                await probePort(port: port, title: plan.title)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                isConnecting = false
            }
        }
    }

    private func startEmbeddedSession(title: String, command: String) {
        stopSession()

        terminalOutput = "local-scope> \(command)\n"
        connectionStatus = "🔄 Запуск встроенной \(title)-сессии..."
        isConnecting = true

        processSession.start(
            command: command,
            onOutput: { chunk in
                terminalOutput += chunk
            },
            onExit: { code in
                sessionIsRunning = false
                isConnecting = false
                connectionStatus = code == 0
                    ? "✅ Встроенная \(title)-сессия завершена"
                    : "⚠️ Встроенная \(title)-сессия завершилась с кодом \(code)"
            }
        )

        sessionIsRunning = true
        isConnecting = false
        connectionStatus = "✅ Встроенная \(title)-сессия запущена"
    }

    private func sendInput() {
        guard !terminalInput.isEmpty else { return }
        processSession.send(terminalInput + "\n")
        terminalInput = ""
    }

    private func stopSession() {
        processSession.stop()
        sessionIsRunning = false
    }

    private func probePort(port: UInt16, title: String) async {
        let result = await withCheckedContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host(device.ip),
                port: NWEndpoint.Port(rawValue: port) ?? .init(integerLiteral: port),
                using: .tcp
            )

            var resumed = false

            connection.stateUpdateHandler = { state in
                guard !resumed else { return }

                switch state {
                case .ready:
                    resumed = true
                    connection.cancel()
                    continuation.resume(returning: true)
                case .failed, .waiting:
                    resumed = true
                    connection.cancel()
                    continuation.resume(returning: false)
                default:
                    break
                }
            }

            connection.start(queue: .global())

            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                guard !resumed else { return }
                resumed = true
                connection.cancel()
                continuation.resume(returning: false)
            }
        }

        connectionStatus = result
            ? "✅ \(title) сервис отвечает на \(device.ip):\(port). Соединение остаётся внутри Local Scope."
            : "❌ \(title) сервис недоступен на \(device.ip):\(port)"
    }
}

final class EmbeddedProcessSession {
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?

    func start(command: String, onOutput: @escaping (String) -> Void, onExit: @escaping (Int32) -> Void) {
        stop()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/script")
        process.arguments = ["-q", "/dev/null", "/bin/zsh", "-lc", command]

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let emit: (FileHandle) -> Void = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                onOutput(chunk)
            }
        }

        outputPipe.fileHandleForReading.readabilityHandler = emit
        errorPipe.fileHandleForReading.readabilityHandler = emit

        process.terminationHandler = { process in
            DispatchQueue.main.async {
                onExit(process.terminationStatus)
            }
        }

        do {
            try process.run()
            self.process = process
            self.inputPipe = inputPipe
            self.outputPipe = outputPipe
            self.errorPipe = errorPipe
        } catch {
            DispatchQueue.main.async {
                onOutput("❌ Не удалось запустить встроенную сессию: \(error.localizedDescription)\n")
                onExit(-1)
            }
        }
    }

    func send(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        inputPipe?.fileHandleForWriting.write(data)
    }

    func stop() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        if process?.isRunning == true {
            process?.terminate()
        }
        process = nil
        inputPipe = nil
        outputPipe = nil
        errorPipe = nil
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 20)
            Text(text)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
    }
}

// MARK: - Quick Connect Button
struct QuickConnectButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isHovered ? 0.3 : 0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(width: 110, height: 110)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isHovered ? 0.08 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(isHovered ? 0.6 : 0.3), lineWidth: 2)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
