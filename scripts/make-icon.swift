// 生成 Resources/AppIcon.icns（用 scripts/make-icon.sh 调用）。
// 造型与菜单栏图标一致：渐变底板 + 白色键帽 + 闪电。
import AppKit

/// 在 size×size 像素的位图上绘制图标（按 1024 设计稿等比缩放）
func render(pixels size: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let t = NSAffineTransform()
    t.scale(by: CGFloat(size) / 1024)
    t.concat()

    // 底板：macOS 图标网格，824×824 居中，四周留 100 给投影
    let plate = NSBezierPath(
        roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.30)
    shadow.shadowOffset = NSSize(width: 0, height: -14)
    shadow.shadowBlurRadius = 28
    shadow.set()
    NSColor.black.set()
    plate.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGradient(
        starting: NSColor(red: 0.42, green: 0.40, blue: 0.98, alpha: 1),
        ending: NSColor(red: 0.20, green: 0.16, blue: 0.62, alpha: 1))!
        .draw(in: plate, angle: -60)

    // 键帽
    let capRect = NSRect(x: 252, y: 262, width: 520, height: 520)
    let cap = NSBezierPath(roundedRect: capRect, xRadius: 120, yRadius: 120)
    NSGraphicsContext.saveGraphicsState()
    let capShadow = NSShadow()
    capShadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    capShadow.shadowOffset = NSSize(width: 0, height: -22)
    capShadow.shadowBlurRadius = 36
    capShadow.set()
    NSColor.white.set()
    cap.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(
        starting: NSColor.white, ending: NSColor(white: 0.90, alpha: 1))!
        .draw(in: cap, angle: -90)

    // 闪电：坐标沿用菜单栏图标（18×18 设计稿，中心 (9,9)）
    let s: CGFloat = 33
    func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        NSPoint(x: capRect.midX + (x - 9) * s, y: capRect.midY + (y - 9) * s)
    }
    let bolt = NSBezierPath()
    bolt.move(to: p(10.6, 14.2))
    bolt.line(to: p(5.6, 8.0))
    bolt.line(to: p(8.8, 8.0))
    bolt.line(to: p(7.4, 3.8))
    bolt.line(to: p(12.4, 10.0))
    bolt.line(to: p(9.2, 10.0))
    bolt.close()
    bolt.lineJoinStyle = .round
    bolt.lineWidth = 22
    NSColor(red: 0.36, green: 0.32, blue: 0.92, alpha: 1).set()
    bolt.fill()
    bolt.stroke()  // 圆角描边，与菜单栏图标一致

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

// 用法：make-icon <输出 .iconset 目录>
let out = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! render(pixels: base).write(to: out.appendingPathComponent("icon_\(base)x\(base).png"))
    try! render(pixels: base * 2).write(to: out.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
