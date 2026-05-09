//
//  InteractiveNetworkCanvas.swift
//  Local Scope
//
//  ✅ ПОЛНОСТЬЮ РАБОЧАЯ ВЕРСИЯ
//  ✅ Двойной клик работает
//  ✅ Правая кнопка работает всегда
//  ✅ Копирование IP
//  ✅ Автовыбор RDP → SSH → FTP
//

import SwiftUI

private struct IndexedDevice: Identifiable {
    let index: Int
    let device: Device
    var id: UUID { device.id }
}

struct InteractiveNetworkCanvas: View {
    let devices: [Device]
    let localIP: String
    let onDeviceSelect: (Device) -> Void
    let onDeviceConnect: ((Device, ServiceType) -> Void)?
    let onAddToFavorites: ((Device, ServiceType) -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 3
            let visibleDevices = Array(devices.prefix(16))
            let indexedDevices = visibleDevices.enumerated().map { IndexedDevice(index: $0.offset, device: $0.element) }
            
            ZStack {
                Canvas { context, size in
                    drawBackground(context: context, size: size, center: center, radius: radius, deviceCount: visibleDevices.count)
                }
                
                ForEach(indexedDevices) { indexedDevice in
                    let device = indexedDevice.device
                    let position = calculatePosition(index: indexedDevice.index, total: visibleDevices.count, center: center, radius: radius)
                    
                    DeviceNode(device: device)
                        .frame(width: 110, height: 85)
                        .contentShape(Rectangle())
                        // ✅ ИСПРАВЛЕНО: Используем simultaneousGesture
                        .simultaneousGesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    print("✅ Double click on: \(device.name)")
                                    handleDoubleClick(device)
                                }
                        )
                        .simultaneousGesture(
                            TapGesture(count: 1)
                                .onEnded {
                                    print("Single click on: \(device.name)")
                                }
                        )
                        .contextMenu {
                            // ✅ КОПИРОВАТЬ IP
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(device.ip, forType: .string)
                            } label: {
                                Label("Копировать IP: \(device.ip)", systemImage: "doc.on.doc")
                            }
                            
                            if let mac = device.mac {
                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(mac, forType: .string)
                                } label: {
                                    Label("Копировать MAC: \(mac)", systemImage: "doc.on.doc")
                                }
                            }
                            
                            Divider()
                            
                            if device.availableServices.isEmpty {
                                Text("Сканирование портов...")
                                    .foregroundStyle(.secondary)
                            } else {
                                // ✅ ПОДКЛЮЧИТЬСЯ
                                Section("Подключиться") {
                                    ForEach(device.availableServices, id: \.self) { service in
                                        Button {
                                            print("✅ Connect via \(service.rawValue)")
                                            onDeviceConnect?(device, service)
                                        } label: {
                                            Label(service.rawValue, systemImage: service.icon)
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                // ✅ ДОБАВИТЬ/УБРАТЬ ИЗ ИЗБРАННОГО
                                Section("Избранное") {
                                    ForEach(device.availableServices, id: \.self) { service in
                                        if !device.favoriteServices.contains(service) {
                                            // НЕ В ИЗБРАННОМ - ПОКАЗАТЬ ДОБАВИТЬ
                                            Button {
                                                print("✅ Add to favorites: \(service.rawValue)")
                                                onAddToFavorites?(device, service)
                                            } label: {
                                                Label("★ Добавить \(service.rawValue)", systemImage: "star")
                                            }
                                        } else {
                                            // УЖЕ В ИЗБРАННОМ - ПОКАЗАТЬ УБРАТЬ
                                            Button {
                                                print("✅ Remove from favorites: \(service.rawValue)")
                                                onAddToFavorites?(device, service)
                                            } label: {
                                                Label("☆ Убрать \(service.rawValue)", systemImage: "star.fill")
                                                    .foregroundStyle(.orange)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .position(position)
                }
            }
        }
    }
    
    // ✅ АВТОМАТИЧЕСКИЙ ВЫБОР СЕРВИСА ПО ПРИОРИТЕТУ
    private func handleDoubleClick(_ device: Device) {
        // Роутер - открыть в браузере
        if device.name.contains("Router") || device.name.contains("🌐") {
            if let url = URL(string: "http://\(device.ip)") {
                NSWorkspace.shared.open(url)
            }
            return
        }
        
        // Приоритет: RDP → SSH → FTP → VNC
        if let primaryService = device.availableServices.first(where: { $0 == .rdp })
            ?? device.availableServices.first(where: { $0 == .ssh })
            ?? device.availableServices.first(where: { $0 == .ftp })
            ?? device.availableServices.first {
            print("✅ Auto-connecting via \(primaryService.rawValue)")
            onDeviceConnect?(device, primaryService)
        } else {
            // Нет сервисов - показать окно выбора
            onDeviceSelect(device)
        }
    }
    
    private func drawBackground(context: GraphicsContext, size: CGSize, center: CGPoint, radius: CGFloat, deviceCount: Int) {
        for i in 1...3 {
            let pulseRadius = CGFloat(i) * 20
            let circle = Path { p in
                p.addEllipse(in: CGRect(x: center.x - pulseRadius, y: center.y - pulseRadius, width: pulseRadius * 2, height: pulseRadius * 2))
            }
            context.stroke(circle, with: .color(.blue.opacity(0.15 - Double(i) * 0.04)), lineWidth: 1.5)
        }
        
        let centerRect = CGRect(x: center.x - 50, y: center.y - 30, width: 100, height: 60)
        context.fill(Path(roundedRect: centerRect, cornerRadius: 12), with: .color(.blue.opacity(0.2)))
        context.stroke(Path(roundedRect: centerRect, cornerRadius: 12), with: .color(.blue.opacity(0.6)), lineWidth: 2.5)
        context.draw(Text("💻").font(.system(size: 24)), at: CGPoint(x: center.x, y: center.y - 8))
        context.draw(Text(localIP).font(.system(size: 10, weight: .bold)).foregroundStyle(.blue), at: CGPoint(x: center.x, y: center.y + 12))
        
        for index in 0..<deviceCount {
            let angle = Double(index) / Double(deviceCount) * 2 * .pi - .pi / 2
            let endPoint = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
            var linePath = Path()
            linePath.move(to: center)
            linePath.addLine(to: endPoint)
            context.stroke(linePath, with: .color(.green.opacity(0.4)), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 3]))
        }
    }
    
    private func calculatePosition(index: Int, total: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = Double(index) / Double(total) * 2 * .pi - .pi / 2
        return CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
    }
}
