import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: ConfigStore
    @State private var addError: String?

    var body: some View {
        VStack(spacing: 0) {
            if store.bindings.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "command.square").font(.system(size: 40)).foregroundStyle(.secondary)
                    Text("还没有绑定").font(.headline)
                    Text("点击下方「添加应用」，或把 .app 拖到这里").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.bindings) { binding in
                        BindingRow(binding: binding, store: store)
                    }
                }
                .listStyle(.inset)
            }

            Divider()
            HStack {
                Button { pickApps() } label: { Label("添加应用…", systemImage: "plus") }
                if let addError { Text(addError).font(.caption).foregroundStyle(.red) }
            }
            .padding(10)
        }
        .frame(minWidth: 620, minHeight: 360)
        .dropDestination(for: URL.self) { urls, _ in
            let errors = urls.compactMap { store.add(appURL: $0) }
            addError = errors.first
            return errors.count < urls.count
        }
    }

    private func pickApps() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "添加"
        guard panel.runModal() == .OK else { return }
        addError = panel.urls.compactMap { store.add(appURL: $0) }.first
    }
}

private struct BindingRow: View {
    let binding: AppBinding
    @ObservedObject var store: ConfigStore

    private var missing: Bool { binding.resolveURL() == nil }

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: binding.path))
                .resizable().frame(width: 28, height: 28)
                .opacity(missing ? 0.4 : 1)

            VStack(alignment: .leading, spacing: 1) {
                Text(binding.name).foregroundStyle(missing ? .red : .primary)
                if missing {
                    Text("找不到应用（已卸载或移动）").font(.caption).foregroundStyle(.red)
                }
            }
            Spacer()

            ShortcutRecorder(shortcut: binding.shortcut) { store.setShortcut(id: binding.id, $0) }

            Toggle("再按隐藏", isOn: Binding(
                get: { binding.hideOnRepeat },
                set: { v in store.update(id: binding.id) { $0.hideOnRepeat = v } }))
                .toggleStyle(.checkbox)
                .help("应用已在前台时，再次按下快捷键会隐藏它")

            Toggle("启用", isOn: Binding(
                get: { binding.enabled },
                set: { v in store.update(id: binding.id) { $0.enabled = v } }))
                .toggleStyle(.switch).labelsHidden()
                .help("启用 / 停用")

            Button(role: .destructive) { store.remove(id: binding.id) } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("删除")
        }
        .padding(.vertical, 4)
    }
}

/// 设置窗口：菜单栏应用（LSUIElement）需临时切到 .regular 才能获得焦点，关闭后切回。
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show() {
        NSApp.setActivationPolicy(.regular)
        if window == nil {
            let w = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 680, height: 420),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered, defer: false)
            w.title = "HotLauncher 设置"
            w.contentView = NSHostingView(rootView: SettingsView(store: ConfigStore.shared))
            w.isReleasedWhenClosed = false
            w.delegate = self
            w.center()
            window = w
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
