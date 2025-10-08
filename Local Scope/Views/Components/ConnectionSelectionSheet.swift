//
//  ConnectionSelectionSheet.swift
//  Local Scope
//
//  ОКНО ВЫБОРА СЕРВИСА (при двойном клике)
//

import SwiftUI

struct ConnectionSelectionSheet: View {
    let device: Device
    let onConnect: (Device, ServiceType) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // HEADER
            HStack(spacing: 12) {
                Text(getDeviceEmoji(for: device.name))
                    .font(.system(size: 40))
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.title2.bold())
                    Text(device.ip)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    if let mac = device.mac {
                        Text(mac)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // СПИСОК СЕРВИСОВ
            if device.availableServices.isEmpty {
                // НЕТ СЕРВИСОВ
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No services detected")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("This device doesn't have any open ports")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                // ЕСТЬ СЕРВИСЫ
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Available Services")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            ForEach(device.availableServices, id: \.self) { service in
                                ServiceButton(service: service) {
                                    dismiss()
                                    onConnect(device, service)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 500, height: 450)
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
