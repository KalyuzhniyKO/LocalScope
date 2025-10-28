//
//  ConnectionCard.swift
//  Local Scope
//

import SwiftUI

struct ConnectionCard: View {
    let device: Device
    let serviceType: ServiceType
    let onConnect: (Device, ServiceType) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(serviceType.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: serviceType.icon)
                    .font(.title3)
                    .foregroundStyle(serviceType.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
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
            
            if device.favoriteServices.contains(serviceType) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }
            
            Button(action: { onConnect(device, serviceType) }) {
                Text("Connect")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(serviceType.color)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}
