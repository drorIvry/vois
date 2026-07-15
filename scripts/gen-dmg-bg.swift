// Generates assets/dmg-background.png (1320x800 @144dpi → 660x400pt) for the
// installer DMG: title, subtle waveform, drag arrow. Run: swift scripts/gen-dmg-bg.swift
import AppKit

let pt = NSSize(width: 660, height: 400)   // Finder window content size
let px = NSSize(width: 1320, height: 800)  // @2x

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(px.width), pixelsHigh: Int(px.height),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
ctx.scaleBy(x: 2, y: 2)  // draw in points

// Soft vertical wash, light neutral with a hint of the brand purple.
NSGradient(colors: [
    NSColor(calibratedRed: 0.97, green: 0.97, blue: 1.00, alpha: 1),
    NSColor(calibratedRed: 0.90, green: 0.90, blue: 0.97, alpha: 1),
])!.draw(in: NSRect(origin: .zero, size: pt), angle: -90)

func draw(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, center: NSPoint) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
    ]
    let s = NSAttributedString(string: text, attributes: attrs)
    let b = s.size()
    s.draw(at: NSPoint(x: center.x - b.width / 2, y: center.y - b.height / 2))
}

let brand = NSColor(calibratedRed: 0.42, green: 0.32, blue: 0.90, alpha: 1)

// Title + tagline.
draw("Vois", size: 44, weight: .bold, color: brand, center: NSPoint(x: 330, y: 330))
draw("Select text anywhere. Press a key. Listen.", size: 15, weight: .regular,
     color: NSColor(white: 0.35, alpha: 1), center: NSPoint(x: 330, y: 292))

// Drag arrow between icon slots (icons at x=165 and x=495, y≈185 in Finder coords).
ctx.saveGState()
ctx.setStrokeColor(brand.withAlphaComponent(0.75).cgColor)
ctx.setLineWidth(5)
ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: 265, y: 185))
ctx.addLine(to: CGPoint(x: 375, y: 185))
ctx.strokePath()
ctx.setFillColor(brand.withAlphaComponent(0.75).cgColor)
ctx.move(to: CGPoint(x: 375, y: 200))
ctx.addLine(to: CGPoint(x: 403, y: 185))
ctx.addLine(to: CGPoint(x: 375, y: 170))
ctx.closePath()
ctx.fillPath()
ctx.restoreGState()

// Hint under the drop zone.
draw("Drag Vois into Applications to install", size: 13, weight: .medium,
     color: NSColor(white: 0.45, alpha: 1), center: NSPoint(x: 330, y: 80))

NSGraphicsContext.restoreGraphicsState()

// 144dpi so Finder renders it at 660x400pt.
rep.size = pt
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: "assets/dmg-background.png"))
print("wrote assets/dmg-background.png")
