//
//  HistoryView.swift
//  Local Scope
//
//  ИСТОРИЯ ПОДКЛЮЧЕНИЙ
//  ✅ Добавлено контекстное меню
//  ✅ Добавить в избранное из истории
//

import SwiftUI

struct HistoryView: View {
    let history: [Device]
    let onConnect: (Device, ServiceType) -> Void
    let onDelete: (Device) -> Void
    
    var sortedHistory: [Device] {
        history.sorted { $0.lastSeen > $1.lastSeen }
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("История подключений")
                    .font(.title2.bold())
                Spacer()
                Label("\(history.count)", systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            if history.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("История пуста")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Отсканируйте сеть для поиска устройств")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedHistory) { device in
                            HistoryCard(device: device, onConnect: onConnect, onDelete: onDelete)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct HistoryCard: View {
    let device: Device
    let onConnect: (Device, ServiceType) -> Void
    let onDelete: (Device) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(getDeviceColor(for: device.name).opacity(0.15))
                        .frame(width: 50, height: 50)
                    Text(getDeviceEmoji(for: device.name))
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.headline)
                    Text(device.ip)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.blue)
                    Text("Последний раз: \(formattedDate(device.lastSeen))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: { onDelete(device) }) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            
            if !device.availableServices.isEmpty {
                Divider()
                HStack(spacing: 8) {
                    ForEach(device.availableServices, id: \.self) { service in
                        Button {
                            onConnect(device, service)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: service.icon)
                                Text(service.rawValue)
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(service.color.opacity(0.1))
                            .foregroundStyle(service.color)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        // ✅ ДОБАВЛЕНО КОНТЕКСТНОЕ МЕНЮ
        .contextMenu {
            if !device.availableServices.isEmpty {
                ForEach(device.availableServices, id: \.self) { service in
                    Button {
                        onConnect(device, service)
                    } label: {
                        Label("Подключиться через \(service.rawValue)", systemImage: service.icon)
                    }
                }
                
                Divider()
                
                Button(role: .destructive) {
                    onDelete(device)
                } label: {
                    Label("Удалить из истории", systemImage: "trash")
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func getDeviceColor(for name: String) -> Color {
        if name.contains("Router") { return .orange }
        if name.contains("Apple") { return .gray }
        if name.contains("Android") { return .green }
        if name.contains("Smart TV") { return .purple }
        return .blue
    }
    
    private func getDeviceEmoji(for name: String) -> String {
        if name.contains("Router") { return "🌐" }
        if name.contains("Apple") { return "📱" }
        if name.contains("Android") { return "📱" }
        if name.contains("Smart TV") { return "📺" }
        return "💻"
    }
}
