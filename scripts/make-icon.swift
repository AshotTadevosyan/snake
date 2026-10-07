import AppKit
import Foundation

let output = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
for (name, size) in [("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64), ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512), ("icon_512x512", 512), ("icon_512x512@2x", 1024)] {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let scale = CGFloat(size) / 1024
    let transform = AffineTransform(scale: scale)
    (transform as NSAffineTransform).concat()
    NSColor(srgbRed: 0.08, green: 0.13, blue: 0.10, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 40, y: 40, width: 944, height: 944), xRadius: 214, yRadius: 214).fill()
    let body = NSBezierPath()
    body.move(to: NSPoint(x: 302, y: 300))
    body.line(to: NSPoint(x: 638, y: 300))
    body.curve(to: NSPoint(x: 638, y: 514), controlPoint1: NSPoint(x: 790, y: 300), controlPoint2: NSPoint(x: 790, y: 514))
    body.line(to: NSPoint(x: 390, y: 514))
    body.curve(to: NSPoint(x: 390, y: 728), controlPoint1: NSPoint(x: 238, y: 514), controlPoint2: NSPoint(x: 238, y: 728))
    body.line(to: NSPoint(x: 552, y: 728))
    body.lineWidth = 110
    body.lineCapStyle = .round
    body.lineJoinStyle = .round
    NSColor(srgbRed: 0.69, green: 0.94, blue: 0.48, alpha: 1).setStroke()
    body.stroke()
    NSColor(srgbRed: 0.05, green: 0.09, blue: 0.06, alpha: 1).setFill()
    for y in [705, 749] { NSBezierPath(ovalIn: NSRect(x: 527, y: y - 9, width: 18, height: 18)).fill() }
    NSColor(srgbRed: 1, green: 0.47, blue: 0.36, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 694, y: 681, width: 94, height: 94)).fill()
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(output)/\(name).png"))
}

func bigEndian(_ value: Int) -> Data {
    var integer = UInt32(value).bigEndian
    return withUnsafeBytes(of: &integer) { Data($0) }
}
var chunks = Data()
for (kind, name) in [("icp4", "icon_16x16"), ("icp5", "icon_32x32"), ("icp6", "icon_32x32@2x"), ("ic07", "icon_128x128"), ("ic08", "icon_256x256"), ("ic09", "icon_512x512"), ("ic10", "icon_512x512@2x")] {
    let png = try Data(contentsOf: URL(fileURLWithPath: "\(output)/\(name).png"))
    chunks.append(kind.data(using: .ascii)!)
    chunks.append(bigEndian(png.count + 8))
    chunks.append(png)
}
var icon = "icns".data(using: .ascii)!
icon.append(bigEndian(chunks.count + 8))
icon.append(chunks)
try icon.write(to: URL(fileURLWithPath: "Resources/Snake.icns"))
