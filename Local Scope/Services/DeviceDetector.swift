//
//  DeviceDetector.swift
//  Local Scope
//
//  УЛУЧШЕННОЕ ОПРЕДЕЛЕНИЕ ТИПА УСТРОЙСТВА
//  ✅ Определяет телефоны
//  ✅ Определяет роутеры
//  ✅ Определяет компьютеры
//

import Foundation

struct DeviceDetector {
    
    static func detectType(mac: String, ip: String) -> String {
        let macPrefix = String(mac.prefix(8)).lowercased()
        
        // РОУТЕРЫ
        if ip.hasSuffix(".1") || ip.hasSuffix(".254") {
            return "🌐 Router"
        }
        
        // APPLE DEVICES
        let appleMACs = ["00:03:93", "00:1e:c2", "04:0c:ce", "08:66:98", "0c:74:c2",
                        "10:dd:b1", "14:10:9f", "18:34:51", "1c:36:bb", "20:c9:d0",
                        "24:f0:94", "28:cf:da", "2c:f0:a2", "30:90:ab", "34:36:3b",
                        "38:0f:4a", "3c:15:c2", "40:6c:8f", "44:d8:84", "48:d7:05",
                        "4c:57:ca", "50:ea:d6", "54:26:96", "58:55:ca", "5c:95:ae",
                        "60:69:44", "64:a3:cb", "68:a8:6d", "6c:94:66", "70:cd:60",
                        "74:e2:f5", "78:31:c1", "7c:d1:c3", "80:e6:50", "84:38:35",
                        "88:66:5a", "8c:85:90", "90:72:40", "94:f6:a3", "98:fe:94",
                        "9c:20:7b", "a0:99:9b", "a4:83:e7", "a8:66:7f", "ac:87:a3",
                        "b0:34:95", "b4:f0:ab", "b8:09:8a", "bc:92:6b", "c0:ce:cd",
                        "c4:b3:01", "c8:69:cd", "cc:08:8d", "d0:03:4b", "d4:9a:20",
                        "d8:00:4d", "dc:2b:2a", "e0:ac:cb", "e4:c6:3d", "e8:80:2e",
                        "ec:85:2f", "f0:18:98", "f4:f1:5a", "f8:1e:df", "fc:25:3f"]
        
        for prefix in appleMACs {
            if macPrefix.hasPrefix(prefix) {
                // ОПРЕДЕЛЯЕМ IPHONE/IPAD/MAC
                if macPrefix.hasPrefix("f0:18:98") || macPrefix.hasPrefix("e8:80:2e") {
                    return "📱 iPhone"
                } else if macPrefix.hasPrefix("a4:83:e7") || macPrefix.hasPrefix("98:fe:94") {
                    return "📱 iPad"
                } else {
                    return "💻 MacBook"
                }
            }
        }
        
        // ANDROID PHONES (Samsung, Xiaomi, Huawei)
        let androidMACs = ["00:08:22", "00:12:fb", "00:13:77", "00:15:b9", "00:16:32",
                          "00:17:c9", "00:18:af", "00:1a:8a", "00:1b:98", "00:1c:43",
                          "00:1d:25", "00:1e:7d", "00:1f:5c", "00:21:4c", "00:23:39",
                          "00:24:54", "00:25:67", "00:26:37", "00:37:6d", "04:fe:31",
                          "08:d4:0c", "0c:b3:19", "10:5f:06", "14:7d:c5", "18:4f:32",
                          "1c:62:b8", "20:64:32", "24:0a:64", "28:b2:bd", "2c:44:01",
                          "30:07:4d", "34:08:04", "38:0b:40", "3c:bd:d8", "40:4d:7f",
                          "44:d6:e8", "48:59:29", "4c:bc:a5", "50:a4:c8", "54:92:be",
                          "58:1f:28", "5c:0a:5b", "60:38:e0", "64:6c:b2", "68:c6:3a",
                          "6c:50:4d", "70:b0:14", "74:5e:1c", "78:7b:8a", "7c:a9:6b",
                          "80:d2:1d", "84:41:67", "88:36:6c", "8c:77:12", "90:b6:86",
                          "94:65:2d", "98:5a:eb", "9c:93:4e", "a0:07:98", "a4:70:d6",
                          "a8:a4:c3", "ac:c1:ee", "b0:72:bf", "b4:07:f9", "b8:27:eb",
                          "bc:76:5e", "c0:7c:d1", "c4:14:3c", "c8:14:79", "cc:c8:f9",
                          "d0:17:6a", "d4:3a:2c", "d8:49:0b", "dc:a9:04", "e0:19:1d",
                          "e4:12:1d", "e8:04:0b", "ec:9b:f3", "f0:08:f1", "f4:28:53",
                          "f8:04:2e", "fc:19:10"]
        
        for prefix in androidMACs {
            if macPrefix.hasPrefix(prefix) {
                return "📱 Android Phone"
            }
        }
        
        // RASPBERRY PI
        if macPrefix.hasPrefix("b8:27:eb") || macPrefix.hasPrefix("dc:a6:32") ||
           macPrefix.hasPrefix("e4:5f:01") {
            return "🍓 Raspberry Pi"
        }
        
        // SMART TV
        let tvMACs = ["00:09:d0", "00:0d:4b", "00:11:d9", "00:12:fb", "00:13:ce",
                     "00:1c:a8", "00:1e:c4", "00:1f:a7", "00:26:5e", "04:52:f3",
                     "08:3e:8e", "0c:b5:67", "10:1f:74", "14:a3:64", "18:40:a3",
                     "1c:66:aa", "20:47:ed", "24:f5:aa", "28:39:5e", "2c:6e:85",
                     "30:cd:a7", "34:a3:95", "38:68:93", "3c:7c:3f", "40:01:7a",
                     "44:48:c1", "48:44:f7", "4c:4e:03", "50:32:75", "54:88:0e",
                     "58:8e:81", "5c:49:7d", "60:02:b4", "64:89:9a", "68:27:37",
                     "6c:29:95", "70:4d:7b", "74:de:2b", "78:47:1d", "7c:f8:a0",
                     "80:46:86", "84:30:95", "88:c2:55", "8c:79:67", "90:00:db",
                     "94:e4:44", "98:6c:f5", "9c:7a:03", "a0:04:60", "a4:08:f5",
                     "a8:23:fe", "ac:5f:3e", "b0:38:29", "b4:4e:7d", "b8:bb:af",
                     "bc:30:7d", "c0:bd:d1", "c4:43:8f", "c8:ba:94", "cc:6e:a4",
                     "d0:66:7b", "d4:64:0a", "d8:97:ba", "dc:71:44", "e0:66:78",
                     "e4:b0:21", "e8:5b:5b", "ec:fa:5c", "f0:77:55", "f4:7b:5e",
                     "f8:77:b8", "fc:03:9f"]
        
        for prefix in tvMACs {
            if macPrefix.hasPrefix(prefix) {
                return "📺 Smart TV"
            }
        }
        
        // NAS
        let nasMACs = ["00:11:32", "00:90:a9", "00:90:fe", "00:11:d8"]
        for prefix in nasMACs {
            if macPrefix.hasPrefix(prefix) {
                return "💾 NAS Storage"
            }
        }
        
        // VMWARE/VIRTUALBOX
        if macPrefix.hasPrefix("00:50:56") || macPrefix.hasPrefix("00:0c:29") {
            return "💻 VMware VM"
        }
        if macPrefix.hasPrefix("08:00:27") {
            return "💻 VirtualBox VM"
        }
        
        // ПО УМОЛЧАНИЮ
        return "💻 Network Device"
    }
}
