//
//  ServiceButton.swift
//  Local Scope
//

import SwiftUI

struct ServiceButton: View {
    let service: ServiceType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(service.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: service.icon)
                        .font(.title3)
                        .foregroundStyle(service.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect via \(service.rawValue)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Port \(service.port)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(service.color.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(service.color.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
