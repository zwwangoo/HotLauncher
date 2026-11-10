import AppKit

enum AppLauncher {
    /// 触发一条绑定。未运行→启动；运行中→置前；已在前台且开启「再次按下隐藏」→隐藏。
    /// 找不到应用或启动失败时调用 onFailure。
    @MainActor
    static func trigger(_ binding: AppBinding, onFailure: @escaping @MainActor () -> Void) {
        guard let url = binding.resolveURL() else {
            onFailure()
            return
        }

        let isFrontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == binding.bundleID
        if isFrontmost, binding.hideOnRepeat,
            let running = NSRunningApplication.runningApplications(
                withBundleIdentifier: binding.bundleID).first
        {
            running.hide()
            return
        }
        if isFrontmost { return }

        // 对已运行的应用，openApplication 同样会把它带到前台，
        // 比 NSRunningApplication.activate 在后台应用中更可靠（macOS 14 起的协作式激活限制）。
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, error in
            if error != nil {
                Task { @MainActor in onFailure() }
            }
        }
    }
}
