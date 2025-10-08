import SwiftUI

struct Device: Identifiable {
    let id = UUID()
    let ip: String
    let mac: String?
    let type: String
    let connection: String
}

struct ContentView: View {
    @State private var devices: [Device] = []
    @State private var isScanning = false
    @State private var selectedTheme = "System"
    let themes = ["System", "Light", "Dark", "Neon"]
    @State private var history: [String] = []
    private let historyFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".localscope/history.json").path

    var body: some View {
        TabView {
            VStack {
                Text("SSH Tab - Coming Soon")
                    .font(.title)
            }
            .tabItem { Label("SSH", systemImage: "terminal") }

            VStack {
                Text("RDP Tab - Coming Soon")
                    .font(.title)
            }
            .tabItem { Label("RDP", systemImage: "desktopcomputer") }

            VStack {
                Text("SFTP Tab - Coming Soon")
                    .font(.title)
            }
            .tabItem { Label("SFTP", systemImage: "folder") }

            VStack {
                Button(action: scanNetwork) {
                    Text(isScanning ? "Scanning..." : "Scan Network")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isScanning ? .gray : .blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isScanning)

                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    context.fill(Circle().path(in: CGRect(x: center.x - 20, y: center.y - 20, width: 40, height: 40)), with: .color(.green))
                    context.draw(Text("My Mac\n\(getLocalIP() ?? "Unknown")"), at: CGPoint(x: center.x, y: center.y - 30))

                    for (index, device) in devices.enumerated() {
                        let angle = Double(index) * (2 * .pi / Double(max(devices.count, 1)))
                        let radius = min(size.width, size.height) / 3
                        let x = center.x + radius * cos(angle)
                        let y = center.y + radius * sin(angle)

                        context.stroke(Path { path in
                            path.move(to: center)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }, with: .color(device.connection == "Ethernet" ? .black : .gray), style: StrokeStyle(lineWidth: 2, dash: device.connection == "Wi-Fi" ? [5, 5] : []))

                        let color = device.type == "Phone" ? .blue : device.type == "PC" ? .red : .purple
                        context.fill(Circle().path(in: CGRect(x: x - 15, y: y - 15, width: 30, height: 30)), with: .color(color))
                        context.draw(Text("\(device.ip)\n\(device.type)"), at: CGPoint(x: x, y: y - 25))
                    }
                }
                .frame(width: 400, height: 400)
                .background(.gray.opacity(0.1))
                .cornerRadius(10)

                List(devices, id: \.id) { device in
                    Text("\(device.ip) - \(device.type) (\(device.connection))")
                }
            }
            .tabItem { Label("Network Map", systemImage: "network") }

            VStack {
                Text("Settings")
                    .font(.title)
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(themes, id: \.self) { theme in
                        Text(theme)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()

                Text("Selected Theme: \(selectedTheme)")
                    .padding()
            }
            .tabItem { Label("Settings", systemImage: "gear") }
        }
        .frame(minWidth: 500, minHeight: 600)
        .preferredColorScheme(selectedTheme == "System" ? nil : selectedTheme == "Dark" ? .dark : .light)
        .onAppear(perform: loadHistory)
        .onChange(of: devices) { _ in syncHistory() }
    }

    func scanNetwork() {
        guard !isScanning else { return }
        isScanning = true
        devices.removeAll()

        // Simulate network scan (replace with MMLanScan later)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            devices = [
                Device(ip: "192.168.1.100", mac: "00:14:22:01:23:45", type: "Phone", connection: "Wi-Fi"),
                Device(ip: "192.168.1.101", mac: "00:16:17:04:56:78", type: "PC", connection: "Ethernet"),
                Device(ip: "192.168.1.102", mac: "00:18:19:07:89:01", type: "TV", connection: "Wi-Fi")
            ]
            isScanning = false
            syncHistory()
        }
    }

    func getLocalIP() -> String? {
        var address: String?
        if let interfaces = Host.current().addresses {
            for interface in interfaces {
                if interface.contains("192.168.") || interface.contains("10.") || interface.contains("172.") {
                    address = interface
                    break
                }
            }
        }
        return address
    }

    func loadHistory() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: historyFile) {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: historyFile)),
               let saved = try? JSONDecoder().decode([String].self, from: data) {
                history = saved
            }
        }
    }

    func syncHistory() {
        let currentDevices = devices.map { $0.ip }
        history.append(contentsOf: currentDevices.filter { !history.contains($0) })
        if let data = try? JSONEncoder().encode(history) {
            try? data.write(to: URL(fileURLWithPath: historyFile))
            syncToGitHub()
        }
    }

    func syncToGitHub() {
        let repoPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".localscope").path
        if !FileManager.default.fileExists(atPath: repoPath) {
            try? FileManager.default.createDirectory(atPath: repoPath, withIntermediateDirectories: true)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["init", repoPath]
            try? process.run()
            process.waitUntilExit()
            process.arguments = ["remote", "add", "origin", "https://github.com/KalyuzhniyKO/LocalScope.git"]
            try? process.run()
            process.waitUntilExit()
            try? Data("Initial config\n".utf8).write(to: URL(fileURLWithPath: repoPath + "/README.md"))
            process.arguments = ["add", "."]
            try? process.run()
            process.waitUntilExit()
            process.arguments = ["commit", "-m", "Initial commit"]
            try? process.run()
            process.waitUntilExit()
            process.arguments = ["push", "-u", "origin", "main"]
            try? process.run()
            process.waitUntilExit()
        } else {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.currentDirectoryURL = URL(fileURLWithPath: repoPath)
            process.arguments = ["add", "."]
            try? process.run()
            process.waitUntilExit()
            process.arguments = ["commit", "-m", "Update history: \(Date())"]
            try? process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                process.arguments = ["push"]
                try? process.run()
                process.waitUntilExit()
            }
        }
    }
}

#Preview {
    ContentView()
}
