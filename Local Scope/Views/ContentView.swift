//
//  ContentView.swift
//  Local Scope
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var viewModel = NetworkScannerViewModel()
    @State private var selectedTab = 0
    @State private var selectedDevice: Device?
    @State private var showConnectionSheet = false
    @State private var showAddDeviceSheet = false
    @State private var addDeviceServiceType: ServiceType = .ssh
    
    @State private var showUniversalTerminal = false
    @State private var selectedServiceType: ServiceType = .ssh
    
    @State private var showCredentialsSheet = false
    @State private var pendingConnection: (Device, ServiceType)?
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                NetworkMapView(
                    devices: $viewModel.devices,
                    localIP: $viewModel.localIP,
                    scanning: $viewModel.scanning,
                    progress: $viewModel.progress,
                    onScan: { viewModel.scanNetwork() },
                    onDeviceSelect: { device in
                        handleDeviceSelection(device)
                    },
                    onDeviceConnect: { device, service in
                        handleConnection(device: device, service: service)
                    },
                    onAddToFavorites: { device, service in
                        viewModel.toggleFavorite(device: device, service: service)
                    }
                )
                .tabItem {
                    Label("Network Map", systemImage: "network")
                }
                .tag(0)
                
                ConnectionsView(
                    devices: viewModel.devices(for: .ssh),
                    history: viewModel.history.filter { $0.availableServices.contains(.ssh) },
                    serviceType: ServiceType.ssh,
                    title: "SSH Connections",
                    onConnect: { device, service in
                        handleConnection(device: device, service: service)
                    },
                    onAddManual: {
                        addDeviceServiceType = ServiceType.ssh
                        showAddDeviceSheet = true
                    }
                )
                .tabItem {
                    Label("SSH", systemImage: "terminal")
                }
                .tag(1)
                
                ConnectionsView(
                    devices: viewModel.devices(for: .rdp),
                    history: viewModel.history.filter { $0.availableServices.contains(.rdp) },
                    serviceType: ServiceType.rdp,
                    title: "RDP Connections",
                    onConnect: { device, service in
                        handleConnection(device: device, service: service)
                    },
                    onAddManual: {
                        addDeviceServiceType = ServiceType.rdp
                        showAddDeviceSheet = true
                    }
                )
                .tabItem {
                    Label("RDP", systemImage: "desktopcomputer")
                }
                .tag(2)
                
                ConnectionsView(
                    devices: viewModel.devices(for: .ftp),
                    history: viewModel.history.filter { $0.availableServices.contains(.ftp) },
                    serviceType: ServiceType.ftp,
                    title: "FTP/SFTP Transfers",
                    onConnect: { device, service in
                        handleConnection(device: device, service: service)
                    },
                    onAddManual: {
                        addDeviceServiceType = ServiceType.ftp
                        showAddDeviceSheet = true
                    }
                )
                .tabItem {
                    Label("FTP", systemImage: "folder")
                }
                .tag(3)
                
                HistoryView(
                    history: viewModel.history,
                    onConnect: { device, service in
                        handleConnection(device: device, service: service)
                    },
                    onDelete: { device in
                        viewModel.deleteFromHistory(device: device)
                    }
                )
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(4)
                
                SettingsView(
                    onReload: { viewModel.loadHistory() },
                    onClear: { viewModel.clearHistory() }
                )
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(5)
            }
            
            if !viewModel.syncStatus.isEmpty {
                Text(viewModel.syncStatus)
                    .font(.caption)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(
                        viewModel.syncStatus.contains("✅") || viewModel.syncStatus.contains("⭐")
                        ? Color.green.opacity(0.2)
                        : viewModel.syncStatus.contains("⚠️")
                        ? Color.orange.opacity(0.2)
                        : Color.red.opacity(0.2)
                    )
            }
        }
        .frame(minWidth: 900, minHeight: 650)
        .sheet(isPresented: $showConnectionSheet) {
            if let device = selectedDevice {
                ConnectionSelectionSheet(
                    device: device,
                    onConnect: { dev, service in
                        showConnectionSheet = false
                        handleConnection(device: dev, service: service)
                    }
                )
            }
        }
        .sheet(isPresented: $showAddDeviceSheet) {
            AddDeviceSheet(
                serviceType: addDeviceServiceType,
                onAdd: { device in
                    showAddDeviceSheet = false
                    viewModel.addManualDevice(device)
                }
            )
        }
        .sheet(isPresented: $showCredentialsSheet) {
            if let (device, service) = pendingConnection {
                CredentialsInputSheet(
                    device: device,
                    serviceType: service,
                    onConnect: { credentials in
                        showCredentialsSheet = false
                        performConnectionWithCredentials(device: device, service: service, credentials: credentials)
                    },
                    onSaveSession: { name, credentials in
                        showCredentialsSheet = false
                        // Сохраняем как обычные credentials, без SavedSession
                        performConnectionWithCredentials(device: device, service: service, credentials: credentials)
                    }
                )
            }
        }
        .sheet(isPresented: $showUniversalTerminal) {
            if let device = selectedDevice {
                UniversalTerminalView(
                    device: device,
                    serviceType: selectedServiceType,
                    credentials: viewModel.getCredentials(for: device, service: selectedServiceType)
                )
            }
        }
    }
    
    private func handleDeviceSelection(_ device: Device) {
        if device.name.contains("Router") || device.name.contains("🌐") {
            if let url = URL(string: "http://\(device.ip)") {
                NSWorkspace.shared.open(url)
            }
            return
        }
        
        if !device.availableServices.isEmpty {
            selectedDevice = device
            showConnectionSheet = true
        } else {
            viewModel.syncStatus = "⚠️ У \(device.name) нет открытых портов"
        }
    }
    
    private func handleConnection(device: Device, service: ServiceType) {
        if let savedCreds = viewModel.getCredentials(for: device, service: service) {
            performConnectionWithCredentials(device: device, service: service, credentials: savedCreds)
        } else {
            pendingConnection = (device, service)
            showCredentialsSheet = true
        }
    }
    
    private func performConnectionWithCredentials(device: Device, service: ServiceType, credentials: ConnectionCredentials) {
        if credentials.saveCredentials {
            viewModel.saveCredentials(credentials, for: device, service: service)
        }
        
        selectedDevice = device
        selectedServiceType = service
        showUniversalTerminal = true
    }
}
