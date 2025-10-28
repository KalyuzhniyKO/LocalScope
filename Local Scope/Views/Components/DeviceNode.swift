//
//  DeviceNode.swift
//  Local Scope
//

import SwiftUI

struct DeviceNode: View {
    let device: Device
    
    var body: some View {
        VStack(spacing: 2) {
            Text(getDeviceEmoji(for: device.name))
                .font(.system(size: 20))
            
            Text(cleanDeviceName(device.name))
                .font(.system(size: 8, weight: .semibold))
                .lineLimit(1)
            
            Text(device.ip)
                .font(.system(size: 7))
                .foregroundStyle(.blue)
            
            if let mac = device.mac {
                Text(mac)
                    .font(.system(size: 6, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            if !device.availableServices.isEmpty {
                HStack(spacing: 2) {
                    ForEach(device.availableServices, id: \.self) { service in
                        Circle()
                            .fill(service.color)
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
        .frame(width: 110, height: 85)
        .background(getDeviceColor(for: device.name).opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(getDeviceColor(for: device.name).opacity(0.7), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 3)
    }
    
    private func cleanDeviceName(_ name: String) -> String {
        name.replacingOccurrences(of: "🌐 ", with: "")
            .replacingOccurrences(of: "📱 ", with: "")
            .replacingOccurrences(of: "📺 ", with: "")
            .replacingOccurrences(of: "🧺 ", with: "")
            .replacingOccurrences(of: "🏠 ", with: "")
            .replacingOccurrences(of: "🎮 ", with: "")
            .replacingOccurrences(of: "🖥️ ", with: "")
            .replacingOccurrences(of: "🍓 ", with: "")
            .replacingOccurrences(of: "💾 ", with: "")
            .replacingOccurrences(of: "🖨️ ", with: "")
            .replacingOccurrences(of: "💻 ", with: "")
            .replacingOccurrences(of: "❓ ", with: "")
    }
    
    private func getDeviceColor(for name: String) -> Color {
        if name.contains("Router") { return .orange }
        if name.contains("Apple") { return .gray }
        if name.contains("Android") { return .green }
        if name.contains("Smart TV") { return .purple }
        if name.contains("Raspberry") { return .pink }
        if name.contains("NAS") { return .indigo }
        return .blue
    }
    
    private func getDeviceEmoji(for name: String) -> String {
        if name.contains("Router") { return "🌐" }
        if name.contains("Apple") { return "📱" }
        if name.contains("Android") { return "📱" }
        if name.contains("Smart TV") { return "📺" }
        if name.contains("Raspberry") { return "🍓" }
        if name.contains("NAS") { return "💾" }
        return "💻"
    }
}
