//
//  InteractiveNetworkCanvas.swift
//  Local Scope
//

import SwiftUI

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
            
            ZStack {
                // Фоновая сетка
                Canvas { context, size in
                    drawBackground(context: context, size: size, center: center, radius: radius, deviceCount: visibleDevices.count)
                }
                
                // Устройства
                ForEach(visibleDevices.indices, id: \.self) { index in
                    let device = visibleDevices[index]
                    let position = calculatePosition(index: index, total: visibleDevices.count, center: center, radius: radius)
                    
                    DeviceNode(device: device)
                        .position(position)
                        .onTapGesture(count: 2) {
                            onDeviceSelect(device)
                        }
                        .contextMenu {
                            if device.availableServices.isEmpty {
                                Text("No services available")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(device.availableServices, id: \.self) { service in
                                    Button {
                                        onDeviceConnect?(device, service)
                                    } label: {
                                        Label("Connect via \(service.rawValue)", systemImage: service.icon)
                                    }
                                }
                                
                                Divider()
                                
                                ForEach(device.availableServices, id: \.self) { service in
                                    Button {
                                        onAddToFavorites?(device, service)
                                    } label: {
                                        HStack {
                                            Image(systemName: device.favoriteServices.contains(service) ? "star.fill" : "star")
                                            Text("Add \(service.rawValue) to favorites")
                                        }
                                    }
                                }
                            }
                        }
                }
            }
        }
    }
    
    private func drawBackground(context: GraphicsContext, size: CGSize, center: CGPoint, radius: CGFloat, deviceCount: Int) {
        // Пульсирующие круги
        for i in 1...3 {
            let pulseRadius = CGFloat(i) * 20
            let circle = Path { p in
                p.addEllipse(in: CGRect(x: center.x - pulseRadius, y: center.y - pulseRadius, width: pulseRadius * 2, height: pulseRadius * 2))
            }
            context.stroke(circle, with: .color(.blue.opacity(0.15 - Double(i) * 0.04)), lineWidth: 1.5)
        }
        
        // Центральный Mac
        let centerRect = CGRect(x: center.x - 50, y: center.y - 30, width: 100, height: 60)
        context.fill(Path(roundedRect: centerRect, cornerRadius: 12), with: .color(.blue.opacity(0.2)))
        context.stroke(Path(roundedRect: centerRect, cornerRadius: 12), with: .color(.blue.opacity(0.6)), lineWidth: 2.5)
        context.draw(Text("💻").font(.system(size: 24)), at: CGPoint(x: center.x, y: center.y - 8))
        context.draw(Text(localIP).font(.system(size: 10, weight: .bold)).foregroundStyle(.blue), at: CGPoint(x: center.x, y: center.y + 12))
        
        // Линии к устройствам
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
