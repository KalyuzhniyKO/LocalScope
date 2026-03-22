//
//  InteractiveNetworkCanvas.swift
//  Local Scope
//

import SwiftUI
import AppKit

struct InteractiveNetworkCanvas: View {
    let devices: [Device]
    let localIP: String
    let onDeviceSelect: (Device) -> Void
    let onDeviceConnect: ((Device, ServiceType) -> Void)?
    let onAddToFavorites: ((Device, ServiceType) -> Void)?
    let onScanPorts: ((Device) -> Void)?

    private let ringCapacity = 12
    private let ringSpacing: CGFloat = 112

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let baseRadius = max(90, min(geometry.size.width, geometry.size.height) / 5)
            let totalRings = max(1, Int(ceil(Double(max(devices.count, 1)) / Double(ringCapacity))))

            ZStack {
                Canvas { context, size in
                    drawBackground(
                        context: context,
                        size: size,
                        center: center,
                        baseRadius: baseRadius,
                        totalRings: totalRings
                    )
                }

                ForEach(devices) { device in
                    let position = calculatePosition(
                        index: index(of: device),
                        total: devices.count,
                        center: center,
                        baseRadius: baseRadius
                    )

                    DeviceNode(device: device)
                        .position(position)
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                        .zIndex(1)
                        .onTapGesture(count: 2) {
                            handleDoubleClick(device)
                        }
                        .contextMenu {
                            Button {
                                copyToPasteboard(device.ip)
                            } label: {
                                Label("Копировать IP: \(device.ip)", systemImage: "doc.on.doc")
                            }

                            if let mac = device.mac {
                                Button {
                                    copyToPasteboard(mac)
                                } label: {
                                    Label("Копировать MAC: \(mac)", systemImage: "doc.on.doc")
                                }
                            }

                            Divider()

                            if device.availableServices.isEmpty {
                                Button {
                                    onScanPorts?(device)
                                } label: {
                                    Label("Проверить порты", systemImage: "magnifyingglass")
                                }
                            } else {
                                Section("Открытые порты") {
                                    ForEach(device.availableServices, id: \.self) { service in
                                        Label("\(service.rawValue) • \(service.port)", systemImage: service.icon)
                                    }
                                }

                                Section("Подключиться") {
                                    ForEach(device.availableServices, id: \.self) { service in
                                        Button {
                                            onDeviceConnect?(device, service)
                                        } label: {
                                            Label(service.rawValue, systemImage: service.icon)
                                        }
                                    }
                                }

                                Section("Избранное") {
                                    ForEach(device.availableServices, id: \.self) { service in
                                        Button {
                                            onAddToFavorites?(device, service)
                                        } label: {
                                            Label(
                                                device.favoriteServices.contains(service)
                                                    ? "☆ Убрать \(service.rawValue)"
                                                    : "★ Добавить \(service.rawValue)",
                                                systemImage: device.favoriteServices.contains(service) ? "star.fill" : "star"
                                            )
                                        }
                                    }
                                }

                                Divider()

                                Button {
                                    onScanPorts?(device)
                                } label: {
                                    Label("Перепроверить порты", systemImage: "arrow.clockwise")
                                }
                            }
                        }
                }
            }
        }
    }

    private func copyToPasteboard(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    private func handleDoubleClick(_ device: Device) {
        if device.name.contains("Router") || device.name.contains("🌐") {
            if let url = URL(string: "http://\(device.ip)") {
                NSWorkspace.shared.open(url)
            }
            return
        }

        if let primaryService = device.availableServices.first(where: { $0 == .rdp })
            ?? device.availableServices.first(where: { $0 == .ssh })
            ?? device.availableServices.first(where: { $0 == .sftp })
            ?? device.availableServices.first(where: { $0 == .ftp })
            ?? device.availableServices.first {
            onDeviceConnect?(device, primaryService)
        } else {
            onDeviceSelect(device)
        }
    }

    private func index(of device: Device) -> Int {
        devices.firstIndex(where: { $0.id == device.id }) ?? 0
    }

    private func drawBackground(
        context: GraphicsContext,
        size: CGSize,
        center: CGPoint,
        baseRadius: CGFloat,
        totalRings: Int
    ) {
        for ringIndex in 0..<max(totalRings, 3) {
            let ringRadius = baseRadius + CGFloat(ringIndex) * ringSpacing
            let circle = Path { path in
                path.addEllipse(
                    in: CGRect(
                        x: center.x - ringRadius,
                        y: center.y - ringRadius,
                        width: ringRadius * 2,
                        height: ringRadius * 2
                    )
                )
            }
            context.stroke(circle, with: .color(.blue.opacity(0.12)), lineWidth: 1.5)
        }

        let centerRect = CGRect(x: center.x - 50, y: center.y - 30, width: 100, height: 60)
        context.fill(Path(roundedRect: centerRect, cornerRadius: 12), with: .color(.blue.opacity(0.2)))
        context.stroke(Path(roundedRect: centerRect, cornerRadius: 12), with: .color(.blue.opacity(0.6)), lineWidth: 2.5)
        context.draw(Text("💻").font(.system(size: 24)), at: CGPoint(x: center.x, y: center.y - 8))
        context.draw(Text(localIP).font(.system(size: 10, weight: .bold)).foregroundStyle(.blue), at: CGPoint(x: center.x, y: center.y + 12))
    }

    private func calculatePosition(index: Int, total: Int, center: CGPoint, baseRadius: CGFloat) -> CGPoint {
        let ringIndex = index / ringCapacity
        let positionInRing = index % ringCapacity
        let devicesBeforeRing = ringIndex * ringCapacity
        let countInRing = min(ringCapacity, max(total - devicesBeforeRing, 1))
        let angle = Double(positionInRing) / Double(countInRing) * 2 * .pi - .pi / 2
        let radius = baseRadius + CGFloat(ringIndex) * ringSpacing

        return CGPoint(
            x: center.x + CGFloat(cos(angle)) * radius,
            y: center.y + CGFloat(sin(angle)) * radius
        )
    }
}
