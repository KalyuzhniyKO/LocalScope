//
//  ConnectionsView.swift
//  Local Scope
//

import SwiftUI

struct ConnectionsView: View {
    let devices: [Device]
    let history: [Device]
    let sessions: [SavedSession]
    let serviceType: ServiceType
    let title: String
    let onConnect: (Device, ServiceType) -> Void
    let onConnectSession: (SavedSession) -> Void
    let onDeleteSession: (SavedSession) -> Void
    let onAddManual: () -> Void
    
    var filteredDevices: [Device] {
        let allDevices = devices + history
        let grouped = Dictionary(grouping: allDevices, by: { $0.ip })
        let unique = grouped.compactMap { $0.value.first }
        let filtered = unique.filter { device in
            if serviceType == .ftp {
                return device.availableServices.contains(.ftp) || device.availableServices.contains(.sftp)
            }
            return device.availableServices.contains(serviceType)
        }
        return filtered.sorted { $0.lastSeen > $1.lastSeen }
    }

    private func resolvedServiceType(for device: Device) -> ServiceType {
        if serviceType == .ftp {
            if device.availableServices.contains(.ftp) {
                return .ftp
            }

            if device.availableServices.contains(.sftp) {
                return .sftp
            }
        }

        return serviceType
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: serviceType.icon)
                    .font(.title2)
                    .foregroundStyle(serviceType.color)
                Text(title)
                    .font(.title2.bold())
                Spacer()
                Button(action: onAddManual) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(serviceType.color)
                }
                .buttonStyle(.plain)
                .help("Add device manually")
                Label("\(filteredDevices.count)", systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(serviceType.color.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            if filteredDevices.isEmpty && sessions.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: serviceType.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No \(serviceType.rawValue) devices found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Scan the network or add device manually")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if !sessions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Сохранённые сессии", systemImage: "bookmark.fill")
                                    .font(.headline)
                                    .foregroundStyle(serviceType.color)

                                ForEach(sessions) { session in
                                    SessionCard(session: session, onConnect: onConnectSession, onDelete: onDeleteSession)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if !filteredDevices.isEmpty {
                            Label("Найденные устройства", systemImage: "network")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        ForEach(filteredDevices) { device in
                            ConnectionCard(
                                device: device,
                                serviceType: resolvedServiceType(for: device),
                                onConnect: onConnect
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
