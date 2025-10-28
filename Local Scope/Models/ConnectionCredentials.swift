//
//  ConnectionCredentials.swift
//  Local Scope
//

import Foundation

struct ConnectionCredentials: Codable, Sendable {
    var username: String
    var password: String
    var saveCredentials: Bool
    
    init(username: String, password: String, saveCredentials: Bool) {
        self.username = username
        self.password = password
        self.saveCredentials = saveCredentials
    }
}
