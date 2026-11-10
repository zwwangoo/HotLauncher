import AppKit
import Carbon.HIToolbox

/// 快捷键：keyCode + Carbon 修饰键位（cmdKey / optionKey / controlKey / shiftKey）
struct Shortcut: Codable, Hashable {
    var keyCode: UInt32
    var modifiers: UInt32

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var m: UInt32 = 0
        if flags.contains(.command) { m |= UInt32(cmdKey) }
        if flags.contains(.option) { m |= UInt32(optionKey) }
        if flags.contains(.control) { m |= UInt32(controlKey) }
        if flags.contains(.shift) { m |= UInt32(shiftKey) }
        return m
    }

    /// 例如 "⌃⌥⇧⌘A"
    var display: String {
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { s += "⌘" }
        return s + (Shortcut.keyNames[keyCode] ?? "#\(keyCode)")
    }

    /// 系统保留或极易冲突的组合，禁止录入
    var isReserved: Bool {
        let cmd = UInt32(cmdKey), ctrl = UInt32(controlKey), opt = UInt32(optionKey)
        switch (keyCode, modifiers) {
        case (49, cmd), (49, ctrl):       return true   // ⌘Space Spotlight / ⌃Space 输入法
        case (48, cmd):                   return true   // ⌘Tab
        case (12, cmd):                   return true   // ⌘Q
        case (4, cmd):                    return true   // ⌘H
        case (50, cmd):                   return true   // ⌘`
        case (53, cmd | opt):             return true   // ⌘⌥Esc 强制退出
        default:                          return false
        }
    }

    private static let keyNames: [UInt32: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
        11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
        18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7",
        27: "-", 28: "8", 29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N",
        46: "M", 47: ".", 50: "`",
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
    ]
}

/// 一条「快捷键 → 应用」绑定
struct AppBinding: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var bundleID: String
    var path: String
    var name: String
    var shortcut: Shortcut?
    var enabled: Bool = true
    var hideOnRepeat: Bool = false

    /// 以 Bundle ID 为主，路径兜底；都找不到返回 nil
    func resolveURL() -> URL? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return url
        }
        return FileManager.default.fileExists(atPath: path) ? URL(fileURLWithPath: path) : nil
    }
}

struct Config: Codable {
    var bindings: [AppBinding] = []
    var paused: Bool = false
}
