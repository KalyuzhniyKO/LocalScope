//
//  LanguageManager.swift
//  Local Scope
//
//  УПРОЩЁННАЯ ВЕРСИЯ БЕЗ ФАЙЛОВ ЛОКАЛИЗАЦИИ
//

import Foundation

class LanguageManager {
    static let shared = LanguageManager()
    
    var currentLanguage: String {
        get {
            UserDefaults.standard.string(forKey: "AppLanguage") ?? "ru"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "AppLanguage")
        }
    }
    
    enum Language: String, CaseIterable {
        case russian = "ru"
        case english = "en"
        case ukrainian = "uk"
        case chinese = "zh"
        case french = "fr"
        case italian = "it"
        
        var displayName: String {
            switch self {
            case .russian: return "Русский"
            case .english: return "English"
            case .ukrainian: return "Українська"
            case .chinese: return "中文"
            case .french: return "Français"
            case .italian: return "Italiano"
            }
        }
        
        var flag: String {
            switch self {
            case .russian: return "🇷🇺"
            case .english: return "🇬🇧"
            case .ukrainian: return "🇺🇦"
            case .chinese: return "🇨🇳"
            case .french: return "🇫🇷"
            case .italian: return "🇮🇹"
            }
        }
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language.rawValue
        UserDefaults.standard.synchronize()
    }
    
    func getCurrentLanguage() -> Language {
        return Language(rawValue: currentLanguage) ?? .russian
    }
}
