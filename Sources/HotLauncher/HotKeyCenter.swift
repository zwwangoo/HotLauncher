import Carbon.HIToolbox

/// Carbon 全局热键的注册与分发。RegisterEventHotKey 不需要任何系统权限。
@MainActor
final class HotKeyCenter {
    static let shared = HotKeyCenter()

    var onTrigger: ((UUID) -> Void)?

    /// 热键 id（本轮注册的序号）→ 句柄与绑定 id
    private var registered: [UInt32: (ref: EventHotKeyRef, binding: UUID)] = [:]
    private var handlerInstalled = false

    /// 用给定列表整体替换当前注册。
    func register(_ items: [(id: UUID, shortcut: Shortcut)]) {
        installHandlerIfNeeded()
        for (_, entry) in registered { UnregisterEventHotKey(entry.ref) }
        registered.removeAll()

        for (index, item) in items.enumerated() {
            let hotKeyID = EventHotKeyID(signature: 0x484C_4348 /* 'HLCH' */, id: UInt32(index + 1))
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                item.shortcut.keyCode, item.shortcut.modifiers, hotKeyID,
                GetApplicationEventTarget(), 0, &ref)
            if status == noErr, let ref {
                registered[hotKeyID.id] = (ref, item.id)
            } else {
                NSLog("HotLauncher: 注册 \(item.shortcut.display) 失败，status=\(status)")
            }
        }
    }

    fileprivate func fire(_ hotKeyID: UInt32) {
        if let entry = registered[hotKeyID] { onTrigger?(entry.binding) }
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), hotKeyHandler, 1, &spec, nil, nil)
        handlerInstalled = true
    }
}

/// C 回调：热键事件由主线程的应用事件目标派发。
private func hotKeyHandler(
    _: EventHandlerCallRef?, _ event: EventRef?, _: UnsafeMutableRawPointer?
) -> OSStatus {
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
        nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
    guard status == noErr else { return status }
    MainActor.assumeIsolated { HotKeyCenter.shared.fire(hotKeyID.id) }
    return noErr
}
