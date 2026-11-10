import AppKit
import SwiftUI

/// 点击后进入录制：按下组合键录入，Esc 取消，⌫ 清除。
/// 使用本地事件监视器，只在自己窗口获得焦点时生效，不需要任何系统权限。
struct ShortcutRecorder: View {
    let shortcut: Shortcut?
    /// 提交新快捷键（nil 为清除）；返回错误文案表示被拒绝
    let onCommit: (Shortcut?) -> String?

    @State private var recording = false
    @State private var monitor: Any?
    @State private var message: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Button { recording ? stop() : start() } label: {
                Text(label)
                    .frame(minWidth: 110)
                    .foregroundStyle(recording ? Color.accentColor : (shortcut == nil ? .secondary : .primary))
            }
            .buttonStyle(.bordered)
            if let message {
                Text(message).font(.caption2).foregroundStyle(.red)
            }
        }
        .onDisappear { stop() }
    }

    private var label: String {
        if recording { return "按下快捷键…" }
        return shortcut?.display ?? "点击录制"
    }

    private func start() {
        message = nil
        recording = true
        ConfigStore.shared.beginRecording()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
            return nil  // 录制期间吞掉所有按键
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        if recording {
            recording = false
            ConfigStore.shared.endRecording()
        }
    }

    private func handle(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        let code = UInt32(event.keyCode)

        if flags.isEmpty {
            switch code {
            case 53: stop()  // Esc 取消
            case 51:  // ⌫ 清除
                stop()
                message = onCommit(nil)
            default: NSSound.beep()
            }
            return
        }
        // 仅 Shift + 字符键会吞掉正常输入，要求至少含 ⌘ ⌥ ⌃ 之一
        guard !flags.intersection([.command, .option, .control]).isEmpty else {
            message = "需包含 ⌘ ⌥ ⌃ 之一"
            NSSound.beep()
            return
        }
        let new = Shortcut(keyCode: code, modifiers: Shortcut.carbonModifiers(from: flags))
        stop()
        message = onCommit(new)
    }
}
