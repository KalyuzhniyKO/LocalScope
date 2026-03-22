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
    @State private var activeCredentials: ConnectionCredentials?
    
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
                    },
                    onScanPorts: { device in
                        viewModel.rescanDevice(device)
                    }
                )
                .tabItem {
                    Label("Network Map", systemImage: "network")
                }
                .tag(0)
                
                ConnectionsView(
                    devices: viewModel.devices(for: .ssh),
                    history: viewModel.history.filter { $0.availableServices.contains(.ssh) },
                    sessions: viewModel.sessions(for: .ssh),
                    serviceType: ServiceType.ssh,
                    title: "SSH Connections",
                    onConnect: { device, service in
                        handleConnection(device: device, service: service)
                    },
                    onConnectSession: { session in
                        connectSavedSession(session)
                    },
                    onDeleteSession: { session in
                        viewModel.deleteSession(session)
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
                    sessions: viewModel.sessions(for: .rdp),
                    serviceType: ServiceType.rdp,
                    title: "RDP Connections",
                    onConnect: { device, service in
                        handleConnection(device: device, service: service)
                    },
                    onConnectSession: { session in
                        connectSavedSession(session)
                    },
                    onDeleteSession: { session in
                        viewModel.deleteSession(session)
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
                    history: viewModel.history.filter { $0.availableServices.contains(.ftp) || $0.availableServices.contains(.sftp) },
                    sessions: viewModel.sessions(for: .ftp),
                    serviceType: ServiceType.ftp,
                    title: "FTP/SFTP Transfers",
                    onConnect: { device, service in
                        handleConnection(device: device, service: service)
                    },
                    onConnectSession: { session in
                        connectSavedSession(session)
                    },
                    onDeleteSession: { session in
                        viewModel.deleteSession(session)
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
        .frame(minWidth: 760, idealWidth: 820, minHeight: 560, idealHeight: 620)
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
                        openConnection(device: device, service: service, credentials: credentials)
                    },
                    onSaveSession: { name, credentials in
                        showCredentialsSheet = false
                        viewModel.saveSession(name: name, device: device, service: service, credentials: credentials)
                        openConnection(device: device, service: service, credentials: credentials)
                    }
                )
            }
        }
        .sheet(isPresented: $showUniversalTerminal) {
            if let device = selectedDevice {
                UniversalTerminalView(
                    device: device,
                    serviceType: selectedServiceType,
                    credentials: activeCredentials
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
            openConnection(device: device, service: service, credentials: savedCreds)
        } else if service.requiresCredentials {
            pendingConnection = (device, service)
            showCredentialsSheet = true
        } else {
            openConnection(device: device, service: service, credentials: nil)
        }
    }
    
    private func connectSavedSession(_ session: SavedSession) {
        openConnection(device: session.device, service: session.serviceType, credentials: session.credentials)
    }

    private func openConnection(device: Device, service: ServiceType, credentials: ConnectionCredentials?) {
        if let credentials, credentials.saveCredentials {
            viewModel.saveCredentials(credentials, for: device, service: service)
        }
        
        selectedDevice = device
        selectedServiceType = service
        activeCredentials = credentials
        showUniversalTerminal = true
    }
}
