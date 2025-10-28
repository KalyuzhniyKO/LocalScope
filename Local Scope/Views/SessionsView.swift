//
//  SessionsView.swift
//  Local Scope
//
//  ВКЛАДКА СОХРАНЁННЫХ СЕССИЙ (как в MobaXterm)
//

import SwiftUI

struct SessionsView: View {
    let sessions: [SavedSession]
    let onConnect: (SavedSession) -> Void
    let onDelete: (SavedSession) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "bookmark.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("Saved Sessions")
                    .font(.title2.bold())
                Spacer()
                Label("\(sessions.count)", systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            if sessions.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No saved sessions")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Save connection credentials for quick access")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sessions) { session in
                            SessionCard(session: session, onConnect: onConnect, onDelete: onDelete)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct SessionCard: View {
    let session: SavedSession
    let onConnect: (SavedSession) -> Void
    let onDelete: (SavedSession) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(session.serviceType.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: session.serviceType.icon)
                    .font(.title3)
                    .foregroundStyle(session.serviceType.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(session.device.ip)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(session.serviceType.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(session.serviceType.color.opacity(0.1))
                        .foregroundStyle(session.serviceType.color)
                        .cornerRadius(4)
                }
                Text("User: \(session.credentials.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: { onConnect(session) }) {
                Text("Connect")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(session.serviceType.color)
            
            Button(action: { onDelete(session) }) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}
