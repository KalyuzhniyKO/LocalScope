//
//  SettingsView.swift
//  Local Scope
//

import SwiftUI

struct SettingsView: View {
    let onReload: () -> Void
    let onClear: () -> Void
    
    @State private var selectedLanguage: LanguageManager.Language = LanguageManager.shared.getCurrentLanguage()
    @State private var showRestartAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundStyle(.gray)
                Text("Настройки")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            Form {
                Section("Язык интерфейса") {
                    Picker("Выберите язык", selection: $selectedLanguage) {
                        ForEach(LanguageManager.Language.allCases, id: \.self) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                            }
                            .tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedLanguage) { oldValue, newValue in
                        LanguageManager.shared.setLanguage(newValue)
                        showRestartAlert = true
                    }
                    
                    if showRestartAlert {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Перезапустите приложение для применения изменений")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                Section("История") {
                    Button(action: onReload) {
                        Label("Перезагрузить историю", systemImage: "arrow.clockwise")
                    }
                    
                    Button(action: onClear) {
                        Label("Очистить историю", systemImage: "trash")
                    }
                    .foregroundStyle(.red)
                }
                
                Section("Настройки сети") {
                    HStack {
                        Text("Таймаут сканирования")
                        Spacer()
                        Text("500ms")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Диапазон портов")
                        Spacer()
                        Text("22, 3389, 21, 5900")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("О программе") {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Сборка")
                        Spacer()
                        Text("2025.01")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Local Scope")
                    .font(.caption.bold())
                Text("Network Management Tool")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 10)
        }
    }
}
