import AppKit

// Rasterize an SVG to every PNG slot of a .iconset using NSImage (macOS 13+
// loads SVG natively). Usage: swift rasterize.swift <icon.svg> <out.iconset>

guard CommandLine.arguments.count == 3 else {
    fatalError("usage: rasterize <icon.svg> <out.iconset>")
}
let src = URL(fileURLWithPath: CommandLine.arguments[1])
let outDir = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)

guard let image = NSImage(contentsOf: src) else {
    fatalError("could not load \(src.path)")
}
image.size = NSSize(width: 1024, height: 1024)

let slots: [(name: String, px: Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]

try? FileManager.default.removeItem(at: outDir)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for slot in slots {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: slot.px, pixelsHigh: slot.px,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ) else { fatalError("bitmap alloc failed") }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: slot.px, height: slot.px),
               from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("png encoding failed for \(slot.name)")
    }
    try png.write(to: outDir.appendingPathComponent(slot.name))
    print("wrote \(slot.name) (\(slot.px)px)")
}
