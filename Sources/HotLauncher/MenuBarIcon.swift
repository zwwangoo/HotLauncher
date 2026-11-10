import AppKit

/// 菜单栏图标：圆角键帽里一道闪电；暂停时闪电换成暂停符号。
/// 用模板图像（只取 alpha），系统会按深浅色菜单栏自动着色。
enum MenuBarIcon {
    static let normal = make(isPaused: false)
    static let paused = make(isPaused: true)

    private static func make(isPaused: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.set()

            let cap = NSBezierPath(
                roundedRect: NSRect(x: 1.25, y: 1.25, width: 15.5, height: 15.5),
                xRadius: 4.5, yRadius: 4.5)
            cap.lineWidth = 1.5
            cap.stroke()

            let glyph = NSBezierPath()
            if isPaused {
                glyph.appendRoundedRect(NSRect(x: 5.9, y: 5.6, width: 2.2, height: 6.8), xRadius: 0.8, yRadius: 0.8)
                glyph.appendRoundedRect(NSRect(x: 9.9, y: 5.6, width: 2.2, height: 6.8), xRadius: 0.8, yRadius: 0.8)
            } else {
                glyph.move(to: NSPoint(x: 10.6, y: 14.2))
                glyph.line(to: NSPoint(x: 5.6, y: 8.0))
                glyph.line(to: NSPoint(x: 8.8, y: 8.0))
                glyph.line(to: NSPoint(x: 7.4, y: 3.8))
                glyph.line(to: NSPoint(x: 12.4, y: 10.0))
                glyph.line(to: NSPoint(x: 9.2, y: 10.0))
                glyph.close()
                glyph.lineJoinStyle = .round  // 圆角描边，让闪电的尖角不那么刺
                glyph.lineWidth = 0.7
                glyph.stroke()
            }
            glyph.fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
