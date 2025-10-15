//
//  NetworkMapView.swift
//  Local Scope
//

import SwiftUI

struct NetworkMapView: View {
    @Binding var devices: [Device]
    @Binding var localIP: String
    @Binding var scanning: Bool
    @Binding var progress: Double
    
    let onScan: () -> Void
    let onDeviceSelect: (Device) -> Void
    let onDeviceConnect: (Device, ServiceType) -> Void
    let onAddToFavorites: (Device, ServiceType) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // HEADER
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Local Network Map")
                        .font(.title.bold())
                    HStack(spacing: 4) {
                        Image(systemName: "network")
                            .foregroundStyle(.blue)
                        Text("Local IP: \(localIP)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Scan Button
                Button(action: onScan) {
                    HStack {
                        if scanning {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(scanning ? "Scanning..." : "Start Scan")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(scanning)
                
                // Device Count
                Label("\(devices.count)", systemImage: "laptopcomputer")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding()
            
            Divider()
            
            // Progress Bar
            if scanning {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            // Network Canvas
            if devices.isEmpty && !scanning {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "network.slash")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("No devices found")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Click 'Start Scan' to discover devices on your network")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                InteractiveNetworkCanvas(
                    devices: devices,
                    localIP: localIP,
                    onDeviceSelect: onDeviceSelect,
                    onDeviceConnect: onDeviceConnect,
                    onAddToFavorites: onAddToFavorites
                )
                .padding()
            }
        }
    }
}
