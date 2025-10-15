//
//  FTPFileManagerView.swift
//  Local Scope
//
//  ДВУХПАНЕЛЬНЫЙ ФАЙЛОВЫЙ МЕНЕДЖЕР (Total Commander)
//

import SwiftUI

struct FTPFileManagerView: View {
    let device: Device
    let serviceType: ServiceType
    let credentials: ConnectionCredentials?
    @Environment(\.dismiss) var dismiss
    
    @State private var localPath: String = NSHomeDirectory()
    @State private var remotePath: String = "/"
    @State private var localFiles: [FileItem] = []
    @State private var remoteFiles: [FileItem] = []
    @State private var selectedLocalFiles: Set<String> = []
    @State private var selectedRemoteFiles: Set<String> = []
    @State private var connectionStatus: String = "Connecting..."
    @State private var isConnected: Bool = false
    @State private var showRenameAlert: Bool = false
    @State private var renameTarget: String = ""
    @State private var newName: String = ""
    
    private let ftpManager = FTPManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // HEADER
            HStack {
                Image(systemName: serviceType.icon)
                    .foregroundStyle(serviceType.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(serviceType.rawValue) File Manager - \(device.name)")
                        .font(.headline)
                    Text(device.ip)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Circle()
                    .fill(isConnected ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(connectionStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(action: { disconnect() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // ДВУХПАНЕЛЬНЫЙ ИНТЕРФЕЙС
            HSplitView {
                // ЛЕВАЯ ПАНЕЛЬ - Локальные файлы
                FilePanel(
                    title: "Local Files",
                    path: $localPath,
                    files: $localFiles,
                    selectedFiles: $selectedLocalFiles,
                    onRefresh: loadLocalFiles,
                    onNavigate: { path in
                        localPath = path
                        loadLocalFiles()
                    },
                    isLocal: true
                )
                
                // ПРАВАЯ ПАНЕЛЬ - Удалённые файлы
                FilePanel(
                    title: "Remote Files (\(device.ip))",
                    path: $remotePath,
                    files: $remoteFiles,
                    selectedFiles: $selectedRemoteFiles,
                    onRefresh: loadRemoteFiles,
                    onNavigate: { path in
                        remotePath = path
                        loadRemoteFiles()
                    },
                    isLocal: false
                )
            }
            
            Divider()
            
            // ПАНЕЛЬ ИНСТРУМЕНТОВ
            HStack(spacing: 12) {
                ToolButton(icon: "arrow.right", title: "Copy →", color: .blue) {
                    copyToRemote()
                }
                .disabled(selectedLocalFiles.isEmpty)
                
                ToolButton(icon: "arrow.left", title: "← Copy", color: .blue) {
                    copyToLocal()
                }
                .disabled(selectedRemoteFiles.isEmpty)
                
                Spacer()
                
                ToolButton(icon: "trash", title: "Delete", color: .red) {
                    deleteSelected()
                }
                .disabled(selectedLocalFiles.isEmpty && selectedRemoteFiles.isEmpty)
                
                ToolButton(icon: "pencil", title: "Rename", color: .orange) {
                    renameSelected()
                }
                .disabled(selectedLocalFiles.count + selectedRemoteFiles.count != 1)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
        }
        .frame(minWidth: 1000, minHeight: 700)
        .onAppear {
            connect()
        }
        .alert("Rename", isPresented: $showRenameAlert) {
            TextField("New name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                performRename()
            }
        }
    }
    
    // MARK: - Connection
    private func connect() {
        Task {
            connectionStatus = "Connecting..."
            
            if let creds = credentials {
                let result = await ftpManager.connect(to: device.ip, type: serviceType, username: creds.username, password: creds.password)
                
                await MainActor.run {
                    if result.success {
                        isConnected = true
                        connectionStatus = "Connected"
                        loadLocalFiles()
                        loadRemoteFiles()
                    } else {
                        connectionStatus = "Connection failed"
                    }
                }
            } else {
                connectionStatus = "No credentials"
            }
        }
    }
    
    private func disconnect() {
        ftpManager.disconnect()
        dismiss()
    }
    
    // MARK: - Load Files
    private func loadLocalFiles() {
        Task {
            let files = await ftpManager.listLocalFiles(at: localPath)
            await MainActor.run {
                localFiles = files
            }
        }
    }
    
    private func loadRemoteFiles() {
        Task {
            let files = await ftpManager.listRemoteFiles(at: remotePath)
            await MainActor.run {
                remoteFiles = files
            }
        }
    }
    
    // MARK: - File Operations
    private func copyToRemote() {
        Task {
            for file in selectedLocalFiles {
                await ftpManager.upload(localPath: file, remotePath: remotePath)
            }
            selectedLocalFiles.removeAll()
            loadRemoteFiles()
        }
    }
    
    private func copyToLocal() {
        Task {
            for file in selectedRemoteFiles {
                await ftpManager.download(remotePath: file, localPath: localPath)
            }
            selectedRemoteFiles.removeAll()
            loadLocalFiles()
        }
    }
    
    private func deleteSelected() {
        Task {
            for file in selectedLocalFiles {
                try? FileManager.default.removeItem(atPath: file)
            }
            for file in selectedRemoteFiles {
                await ftpManager.deleteRemote(path: file)
            }
            selectedLocalFiles.removeAll()
            selectedRemoteFiles.removeAll()
            loadLocalFiles()
            loadRemoteFiles()
        }
    }
    
    private func renameSelected() {
        if let file = selectedLocalFiles.first {
            renameTarget = file
            newName = URL(fileURLWithPath: file).lastPathComponent
            showRenameAlert = true
        } else if let file = selectedRemoteFiles.first {
            renameTarget = file
            newName = URL(fileURLWithPath: file).lastPathComponent
            showRenameAlert = true
        }
    }
    
    private func performRename() {
        Task {
            if selectedLocalFiles.contains(renameTarget) {
                let newPath = (renameTarget as NSString).deletingLastPathComponent + "/" + newName
                try? FileManager.default.moveItem(atPath: renameTarget, toPath: newPath)
                loadLocalFiles()
            } else if selectedRemoteFiles.contains(renameTarget) {
                await ftpManager.renameRemote(from: renameTarget, to: newName)
                loadRemoteFiles()
            }
            selectedLocalFiles.removeAll()
            selectedRemoteFiles.removeAll()
        }
    }
}

// MARK: - File Panel
struct FilePanel: View {
    let title: String
    @Binding var path: String
    @Binding var files: [FileItem]
    @Binding var selectedFiles: Set<String>
    let onRefresh: () -> Void
    let onNavigate: (String) -> Void
    let isLocal: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                
                Button(action: navigateUp) {
                    Image(systemName: "arrow.up")
                }
                .buttonStyle(.plain)
                .disabled(!canNavigateUp)
                
                TextField("Path", text: $path)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)
                    .onSubmit {
                        onNavigate(path)
                    }
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            List(files, selection: $selectedFiles) { file in
                FileRow(file: file, onDoubleClick: {
                    if file.isDirectory {
                        onNavigate(file.path)
                    }
                })
            }
        }
    }
    
    private var canNavigateUp: Bool {
        path != "/" && path != NSHomeDirectory()
    }
    
    private func navigateUp() {
        let newPath = (path as NSString).deletingLastPathComponent
        if !newPath.isEmpty {
            onNavigate(newPath)
        }
    }
}

// MARK: - File Row
struct FileRow: View {
    let file: FileItem
    let onDoubleClick: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                .foregroundStyle(file.isDirectory ? .blue : .gray)
            Text(file.name)
            Spacer()
            if !file.isDirectory {
                Text(formatFileSize(file.size))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onDoubleClick()
        }
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - Tool Button
struct ToolButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .tint(color)
    }
}

// MARK: - Models
struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let isDirectory: Bool
}

// MARK: - FTP Manager
actor FTPManager {
    private var process: Process?
    
    func connect(to ip: String, type: ServiceType, username: String, password: String) async -> (success: Bool, message: String) {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return (true, "Connected")
    }
    
    func disconnect() {
        process?.terminate()
    }
    
    func listLocalFiles(at path: String) async -> [FileItem] {
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: path)
            return items.map { name in
                let fullPath = (path as NSString).appendingPathComponent(name)
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir)
                let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath)
                let size = attrs?[.size] as? Int64 ?? 0
                return FileItem(name: name, path: fullPath, size: size, isDirectory: isDir.boolValue)
            }.sorted { $0.isDirectory && !$1.isDirectory }
        } catch {
            return []
        }
    }
    
    func listRemoteFiles(at path: String) async -> [FileItem] {
        return [
            FileItem(name: "..", path: (path as NSString).deletingLastPathComponent, size: 0, isDirectory: true),
            FileItem(name: "documents", path: path + "/documents", size: 0, isDirectory: true),
            FileItem(name: "example.txt", path: path + "/example.txt", size: 1024, isDirectory: false)
        ]
    }
    
    func upload(localPath: String, remotePath: String) async {
        // Реализация загрузки через sftp/scp
    }
    
    func download(remotePath: String, localPath: String) async {
        // Реализация скачивания через sftp/scp
    }
    
    func deleteRemote(path: String) async {
        // Реализация удаления
    }
    
    func renameRemote(from: String, to: String) async {
        // Реализация переименования
    }
}
