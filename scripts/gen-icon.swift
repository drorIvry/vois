// Generates assets/AppIcon.icns: macOS-style rounded-rect gradient tile with
// a white waveform SF Symbol. Run: swift scripts/gen-icon.swift
import AppKit

let canvas: CGFloat = 1024
let image = NSImage(size: NSSize(width: canvas, height: canvas))
image.lockFocus()

// Apple icon grid: ~824pt content tile centered on 1024 canvas, r ≈ 185.
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let path = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
NSGradient(colors: [
    NSColor(calibratedRed: 0.35, green: 0.35, blue: 0.95, alpha: 1),
    NSColor(calibratedRed: 0.55, green: 0.25, blue: 0.85, alpha: 1),
])!.draw(in: path, angle: -60)

let config = NSImage.SymbolConfiguration(pointSize: 460, weight: .medium)
if let symbol = NSImage(systemSymbolName: "waveform", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) {
    let tinted = NSImage(size: symbol.size)
    tinted.lockFocus()
    NSColor.white.set()
    let r = NSRect(origin: .zero, size: symbol.size)
    symbol.draw(in: r)
    r.fill(using: .sourceAtop)
    tinted.unlockFocus()
    let s = tinted.size
    tinted.draw(in: NSRect(x: (canvas - s.width) / 2, y: (canvas - s.height) / 2,
                           width: s.width, height: s.height))
}
image.unlockFocus()

// Write iconset PNGs.
let fm = FileManager.default
let iconset = "assets/AppIcon.iconset"
try? fm.removeItem(atPath: iconset)
try! fm.createDirectory(atPath: iconset, withIntermediateDirectories: true)

func write(_ px: Int, _ name: String) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: px, height: px))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: "\(iconset)/\(name).png"))
}
for size in [16, 32, 128, 256, 512] {
    write(size, "icon_\(size)x\(size)")
    write(size * 2, "icon_\(size)x\(size)@2x")
}

let task = Process()
task.launchPath = "/usr/bin/iconutil"
task.arguments = ["-c", "icns", iconset, "-o", "assets/AppIcon.icns"]
try! task.run()
task.waitUntilExit()
try? fm.removeItem(atPath: iconset)
print(task.terminationStatus == 0 ? "wrote assets/AppIcon.icns" : "iconutil failed")
