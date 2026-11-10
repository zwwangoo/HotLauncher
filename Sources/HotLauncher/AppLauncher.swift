import AppKit

enum AppLauncher {
    /// 触发一条绑定。未运行→启动；运行中→置前（会切到它所在的桌面，含全屏桌面）；
    /// 已在前台且开启「再次按下隐藏」→隐藏。找不到应用或启动失败时调用 onFailure。
    @MainActor
    static func trigger(_ binding: AppBinding, onFailure: @escaping @MainActor () -> Void) {
        guard let url = binding.resolveURL() else {
            onFailure()
            return
        }

        if let running = NSRunningApplication.runningApplications(
            withBundleIdentifier: binding.bundleID).first
        {
            // 「前台」必须是当前桌面上看得见它的窗口：全屏应用在别的桌面时，
            // 系统仍会把它报为前台，若据此跳过或隐藏，就永远唤不出来。
            if running.isActive, hasVisibleWindow(running) {
                if binding.hideOnRepeat { running.hide() }
                return
            }
            // openApplication 只负责带到前台，不一定切换桌面；activate 会切到窗口所在桌面。
            running.unhide()
            if running.activate(options: [.activateAllWindows]) { return }
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, error in
            if error != nil {
                Task { @MainActor in onFailure() }
            }
        }
    }

    /// 当前桌面上是否有该应用的普通窗口
    private static func hasVisibleWindow(_ app: NSRunningApplication) -> Bool {
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
        return windows.contains {
            ($0[kCGWindowOwnerPID as String] as? Int32) == app.processIdentifier
                && ($0[kCGWindowLayer as String] as? Int) == 0
        }
    }
}
