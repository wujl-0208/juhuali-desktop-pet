import AppKit
import ImageIO

guard CommandLine.arguments.count == 3 else { fatalError("Usage: MakeIcon.swift atlas.png output.iconset") }
let atlasURL = URL(fileURLWithPath: CommandLine.arguments[1])
let destination = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
guard let source = CGImageSourceCreateWithURL(atlasURL as CFURL, nil),
      let atlas = CGImageSourceCreateImageAtIndex(source, 0, nil),
      let sprite = atlas.cropping(to: CGRect(x: 0, y: 0, width: 192, height: 208)) else {
    fatalError("Unable to read first idle frame")
}

let names: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]
for (name, size) in names {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
    let margin = CGFloat(size) * 0.09
    NSImage(cgImage: sprite, size: NSSize(width: 192, height: 208)).draw(
        in: NSRect(x: margin, y: margin, width: CGFloat(size) - 2 * margin,
                   height: CGFloat(size) - 2 * margin),
        from: .zero, operation: .sourceOver, fraction: 1)
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: destination.appendingPathComponent(name))
}
