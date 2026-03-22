//
//  AddDeviceSheet.swift
//  Local Scope
//

import SwiftUI
import AppKit

struct AddDeviceSheet: View {
    let serviceType: ServiceType
    let onAdd: (Device) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var deviceName: String = ""
    @State private var ipAddress: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                ZStack {
                    Circle()
                        .fill(serviceType.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: serviceType.icon)
                        .font(.title2)
                        .foregroundStyle(serviceType.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add \(serviceType.rawValue) Device")
                        .font(.title2.bold())
                    Text("Enter device details manually")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Device Name", systemImage: "tag")
                        .font(.headline)
                    TextField("Enter device name", text: $deviceName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("IP Address", systemImage: "network")
                            .font(.headline)
                        Spacer()
                        Button {
                            pasteIPAddress()
                        } label: {
                            Label("Paste", systemImage: "doc.on.clipboard")
                        }
                        .buttonStyle(.bordered)
                    }

                    TextField("192.168.1.100", text: $ipAddress)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: ipAddress) { newValue in
                            let cleaned = sanitizeIPAddress(newValue)
                            if cleaned != newValue {
                                ipAddress = cleaned
                            }
                        }
                }

                if showError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()

            Spacer()

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Add Device") {
                    if validateInput() {
                        let newDevice = Device(
                            name: deviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Manual Device" : deviceName.trimmingCharacters(in: .whitespacesAndNewlines),
                            ip: ipAddress,
                            mac: nil,
                            type: "Manual",
                            lastSeen: Date(),
                            availableServices: [serviceType]
                        )
                        onAdd(newDevice)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(serviceType.color)
                .disabled(ipAddress.isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .onAppear {
            prefillIPAddressFromClipboard()
        }
    }

    private func prefillIPAddressFromClipboard() {
        guard ipAddress.isEmpty,
              let pasted = NSPasteboard.general.string(forType: .string) else { return }

        let candidate = sanitizeIPAddress(pasted)
        if isPotentialIPAddress(candidate) {
            ipAddress = candidate
        }
    }

    private func pasteIPAddress() {
        guard let pasted = NSPasteboard.general.string(forType: .string) else {
            errorMessage = "Clipboard does not contain text"
            showError = true
            return
        }

        let candidate = sanitizeIPAddress(pasted)
        guard isPotentialIPAddress(candidate) else {
            errorMessage = "Clipboard does not contain a valid IPv4 address"
            showError = true
            return
        }

        ipAddress = candidate
        showError = false
    }

    private func sanitizeIPAddress(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { $0.isNumber || $0 == "." }
    }

    private func isPotentialIPAddress(_ value: String) -> Bool {
        let parts = value.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let num = Int(part) else { return false }
            return num >= 0 && num <= 255
        }
    }

    private func validateInput() -> Bool {
        guard isPotentialIPAddress(ipAddress) else {
            errorMessage = "Invalid IP address format"
            showError = true
            return false
        }

        showError = false
        return true
    }
}
