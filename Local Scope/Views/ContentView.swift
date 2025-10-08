//
//  ContentView.swift
//  Local Scope
//

import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject private var viewModel = NetworkScannerViewModel()
    @State private var selectedTab = 0
    @State private var selectedDevice: Device?
    @State private var showConnectionSheet = false
    @State private var showAddDeviceSheet = false
    @State private var addDeviceServiceType: ServiceType = .ssh
    
    // SSH Terminal
    @State private var showSSHTerminal = false
    @State private var sshDevice: Device?
    @State private var sshCredentials: ConnectionCredentials?
    
    // FTP/SFTP File Manager
    @State private var showFileManager = false
    @State private var ftpDevice: Device?
    @State private var ftpServiceType: ServiceType = .ftp
    @State private var ftpCredentials: ConnectionCredentials?
    
    // RDP
    @State private var showRDP = false
    @State private var rdpDevice: Device?
    @State private var rdpCredentials: ConnectionCredentials?
    
    // Credentials Input
    @State private var showCredentialsSheet = false
    @State private var pendingConnection: (Device, ServiceType)?
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                // MARK: - Network Map Tab
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
                
                // MARK: - SSH Tab
                ConnectionsView(
                    devices: viewModel.devices,
                    history: viewModel.history,
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
                
                // MARK: - RDP Tab
                ConnectionsView(
                    devices: viewModel.devices,
                    history: viewModel.history,
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
                
                // MARK: - FTP Tab
                ConnectionsView(
                    devices: viewModel.devices,
                    history: viewModel.history,
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
                
                // MARK: - History Tab
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
                
                // MARK: - Sessions Tab (НОВАЯ ВКЛАДКА!)
                SessionsView(
                    sessions: viewModel.savedSessions,
                    onConnect: { session in
                        handleSessionConnect(session)
                    },
                    onDelete: { session in
                        viewModel.deleteSession(session)
                    }
                )
                .tabItem {
                    Label("Sessions", systemImage: "bookmark.fill")
                }
                .tag(5)
                
                // MARK: - Settings Tab
                SettingsView(
                    onReload: { Task { await viewModel.loadHistory() } },
                    onClear: { viewModel.clearHistory() }
                )
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(6)
            }
            
            // MARK: - Status Bar
            if !viewModel.syncStatus.isEmpty {
                Text(viewModel.syncStatus)
                    .font(.caption)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(
                        viewModel.syncStatus.contains("✅") || viewModel.syncStatus.contains("⭐")
                        ? Color.green.opacity(0.2)
                        : Color.red.opacity(0.2)
                    )
            }
        }
        .frame(minWidth: 900, minHeight: 650)
        
        // MARK: - Connection Selection Sheet
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
        
        // MARK: - Add Device Sheet
        .sheet(isPresented: $showAddDeviceSheet) {
            AddDeviceSheet(
                serviceType: addDeviceServiceType,
                onAdd: { device in
                    showAddDeviceSheet = false
                    viewModel.addManualDevice(device)
                }
            )
        }
        
        // MARK: - Credentials Input Sheet
        .sheet(isPresented: $showCredentialsSheet) {
            if let (device, service) = pendingConnection {
                CredentialsInputSheet(
                    device: device,
                    serviceType: service,
                    onConnect: { credentials in
                        showCredentialsSheet = false
                        performConnectionWithCredentials(device: device, service: service, credentials: credentials)
                    }
                )
            }
        }
        
        // MARK: - SSH Terminal Sheet
        .sheet(isPresented: $showSSHTerminal) {
            if let device = sshDevice {
                SSHTerminalView(device: device, credentials: sshCredentials)
            }
        }
        
        // MARK: - FTP/SFTP File Manager Sheet
        .sheet(isPresented: $showFileManager) {
            if let device = ftpDevice {
                FTPFileManagerView(device: device, serviceType: ftpServiceType, credentials: ftpCredentials)
            }
        }
        
        // MARK: - RDP Viewer Sheet (НОВЫЙ!)
        .sheet(isPresented: $showRDP) {
            if let device = rdpDevice {
                RDPViewerView(device: device, credentials: rdpCredentials)
            }
        }
    }
    
    // MARK: - Handle Device Selection
    private func handleDeviceSelection(_ device: Device) {
        // Если роутер - открыть в браузере
        if device.name.contains("Router") {
            if let url = URL(string: "http://\(device.ip)") {
                NSWorkspace.shared.open(url)
            }
            return
        }
        
        // Иначе показать окно выбора
        selectedDevice = device
        showConnectionSheet = true
    }
    
    // MARK: - Handle Connection
    private func handleConnection(device: Device, service: ServiceType) {
        // Проверяем, есть ли сохранённые credentials для этого устройства
        if let savedCreds = viewModel.getCredentials(for: device, service: service) {
            performConnectionWithCredentials(device: device, service: service, credentials: savedCreds)
        } else {
            // Запрашиваем credentials
            pendingConnection = (device, service)
            showCredentialsSheet = true
        }
    }
    
    // MARK: - Perform Connection
    private func performConnectionWithCredentials(device: Device, service: ServiceType, credentials: ConnectionCredentials) {
        switch service {
        case .ssh:
            sshDevice = device
            sshCredentials = credentials
            showSSHTerminal = true
            
        case .ftp, .sftp:
            ftpDevice = device
            ftpServiceType = service
            ftpCredentials = credentials
            showFileManager = true
            
        case .rdp:
            rdpDevice = device
            rdpCredentials = credentials
            showRDP = true
            
        case .vnc:
            if let url = URL(string: "vnc://\(device.ip)") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    // MARK: - Handle Session Connect
    private func handleSessionConnect(_ session: SavedSession) {
        performConnectionWithCredentials(
            device: session.device,
            service: session.serviceType,
            credentials: session.credentials
        )
    }
}

// MARK: - Connection Credentials
struct ConnectionCredentials: Codable {
    var username: String
    var password: String
    var saveCredentials: Bool
}

// MARK: - Saved Session
struct SavedSession: Identifiable, Codable {
    let id = UUID()
    let name: String
    let device: Device
    let serviceType: ServiceType
    let credentials: ConnectionCredentials
}
