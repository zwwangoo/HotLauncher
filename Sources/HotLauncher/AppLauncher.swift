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

        let running = NSRunningApplication.runningApplications(
            withBundleIdentifier: binding.bundleID).first

        if let running {
            // 「前台」必须是当前桌面上看得见它的窗口：全屏应用在别的桌面时，
            // 系统仍会把它报为前台，若据此跳过或隐藏，就永远唤不出来。
            if running.isActive, hasVisibleWindow(running) {
                if binding.hideOnRepeat { running.hide() }
                return
            }
            // activate 负责切到窗口所在的桌面（含全屏桌面）；openApplication 不负责切桌面。
            running.unhide()
            running.activate(options: [.activateAllWindows])
        }

        // 对已运行的应用，openApplication 等价于点击 Dock 图标，会发「重新打开」事件，
        // 让应用新建窗口或还原最小化窗口；仅 activate 时，无窗口的应用不会有任何反应。
        let config = NSWorkspace.OpenConfiguration()
        config.activates = running == nil
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
