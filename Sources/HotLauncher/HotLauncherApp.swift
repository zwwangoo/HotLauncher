import AppKit
import SwiftUI

@main
struct HotLauncherApp: App {
    @StateObject private var store = ConfigStore.shared
    @StateObject private var loginItem = LoginItem.shared

    init() {
        // 单实例：已有同 Bundle ID 的实例在运行则直接退出
        if let id = Bundle.main.bundleIdentifier,
            NSRunningApplication.runningApplications(withBundleIdentifier: id).count > 1
        {
            exit(0)
        }
        ConfigStore.shared.start()
    }

    var body: some Scene {
        MenuBarExtra {
            if store.bindings.isEmpty {
                Text("尚无绑定").foregroundStyle(.secondary)
            }
            ForEach(store.bindings) { b in
                Button(b.shortcut.map { "\(b.name)    \($0.display)" } ?? b.name) {
                    store.launch(b)
                }
            }
            Divider()
            Toggle("暂停全部快捷键", isOn: Binding(
                get: { store.paused }, set: { store.setPaused($0) }))
            Button("设置…") { SettingsWindowController.shared.show() }
                .keyboardShortcut(",")
            Toggle("开机自启", isOn: Binding(
                get: { loginItem.enabled }, set: { loginItem.set($0) }))
            Divider()
            Button("退出 HotLauncher") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(nsImage: store.paused ? MenuBarIcon.paused : MenuBarIcon.normal)
        }
        .menuBarExtraStyle(.menu)
    }
}
