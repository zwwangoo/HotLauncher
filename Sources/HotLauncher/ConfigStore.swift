import AppKit
import ServiceManagement

@MainActor
final class ConfigStore: ObservableObject {
    static let shared = ConfigStore()

    @Published private(set) var bindings: [AppBinding] = []
    @Published private(set) var paused = false

    private var recordingDepth = 0
    private let fileURL: URL

    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HotLauncher", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("config.json")
        load()
    }

    /// 应用启动时调用：接上热键回调并首次注册
    func start() {
        HotKeyCenter.shared.onTrigger = { [weak self] id in self?.trigger(id: id) }
        reapply()
    }

    // MARK: - 持久化

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            let config = try JSONDecoder().decode(Config.self, from: data)
            bindings = config.bindings
            paused = config.paused
        } catch {
            // 文件损坏：备份后以空配置启动
            let bak = fileURL.appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: bak)
            try? FileManager.default.moveItem(at: fileURL, to: bak)
            NSLog("HotLauncher: config.json 损坏，已备份为 config.json.bak：\(error)")
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(Config(bindings: bindings, paused: paused)) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func commit() {
        save()
        reapply()
    }

    // MARK: - 热键同步

    /// 录制快捷键期间临时注销所有热键，否则已绑定的组合会直接触发而无法被录入。
    func beginRecording() {
        recordingDepth += 1
        reapply()
    }

    func endRecording() {
        recordingDepth = max(0, recordingDepth - 1)
        reapply()
    }

    private func reapply() {
        let active: [(id: UUID, shortcut: Shortcut)] =
            (paused || recordingDepth > 0)
            ? []
            : bindings.compactMap { b in
                guard b.enabled, let s = b.shortcut else { return nil }
                return (b.id, s)
            }
        HotKeyCenter.shared.register(active)
    }

    // MARK: - 编辑

    /// 添加应用。失败返回错误文案。
    func add(appURL: URL) -> String? {
        guard appURL.pathExtension == "app", let bundle = Bundle(url: appURL),
            let bundleID = bundle.bundleIdentifier
        else { return "不是有效的应用：\(appURL.lastPathComponent)" }

        let name =
            (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? appURL.deletingPathExtension().lastPathComponent
        bindings.append(AppBinding(bundleID: bundleID, path: appURL.path, name: name))
        commit()
        return nil
    }

    func remove(id: UUID) {
        bindings.removeAll { $0.id == id }
        commit()
    }

    func update(id: UUID, _ change: (inout AppBinding) -> Void) {
        guard let i = bindings.firstIndex(where: { $0.id == id }) else { return }
        change(&bindings[i])
        commit()
    }

    /// 设置快捷键；传 nil 为清除。失败返回错误文案且不修改。
    func setShortcut(id: UUID, _ shortcut: Shortcut?) -> String? {
        if let s = shortcut {
            if s.isReserved { return "\(s.display) 是系统保留快捷键" }
            if let other = bindings.first(where: { $0.id != id && $0.shortcut == s }) {
                return "\(s.display) 已绑定到「\(other.name)」"
            }
        }
        update(id: id) { $0.shortcut = shortcut }
        return nil
    }

    func setPaused(_ value: Bool) {
        paused = value
        commit()
    }

    // MARK: - 触发

    func trigger(id: UUID) {
        guard !paused, let binding = bindings.first(where: { $0.id == id }) else { return }
        launch(binding)
    }

    /// 菜单点击也走这里（不受暂停限制）
    func launch(_ binding: AppBinding) {
        AppLauncher.trigger(binding) { NSSound.beep() }
    }
}

/// 开机自启：状态以系统实际值为准
@MainActor
final class LoginItem: ObservableObject {
    static let shared = LoginItem()
    @Published private(set) var enabled = false

    private init() { refresh() }

    func refresh() { enabled = SMAppService.mainApp.status == .enabled }

    func set(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("HotLauncher: 设置开机自启失败：\(error)")
        }
        refresh()
    }
}
