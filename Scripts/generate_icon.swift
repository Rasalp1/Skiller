#!/usr/bin/env swift
import Cocoa

// ── 1. SVG Source ─────────────────────────────────────────────────────
// Official FontAwesome 6 'pen-fancy' fountain pen vector from Iconify
let svgString = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <path fill="black" d="M373.5 27.1C388.5 9.9 410.2 0 433 0c43.6 0 79 35.4 79 79c0 22.8-9.9 44.6-27.1 59.6L277.7 319l-10.3-10.3l-64-64l-10.4-10.4zM170.3 256.9l10.4 10.4l64 64l10.4 10.4l-19.2 83.4c-3.9 17.1-16.9 30.7-33.8 35.4L24.3 510.3l95.4-95.4c2.6.7 5.4 1.1 8.3 1.1c17.7 0 32-14.3 32-32s-14.3-32-32-32s-32 14.3-32 32c0 2.9.4 5.6 1.1 8.3L1.7 487.6L51.5 310c4.7-16.9 18.3-29.9 35.4-33.8l83.4-19.2z"/>
</svg>
"""

guard let svgData = svgString.data(using: .utf8),
      let svgImage = NSImage(data: svgData) else {
    fatalError("Failed to parse SVG")
}

// ── 2. Render 1024×1024 transparent PNG ───────────────────────────────
// Use NSBitmapImageRep directly (not lockFocus, which produces @2x on Retina).
// Match the exact format of the working Workflow icon: 1024×1024, 72 DPI, sRGB.
func renderTransparentPNG(size: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)  // 72 DPI (pixels == points)

    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    // Fully transparent clear
    let cgCtx = ctx.cgContext
    cgCtx.clear(CGRect(x: 0, y: 0, width: size, height: size))

    // Draw SVG centered with ~10% padding on each side
    let padding = Int(Double(size) * 0.10)
    let drawSize = size - 2 * padding
    let drawRect = CGRect(x: padding, y: padding, width: drawSize, height: drawSize)
    svgImage.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)

    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])!
}

let scriptPath = URL(fileURLWithPath: #filePath)
let repoRoot = scriptPath.deletingLastPathComponent().deletingLastPathComponent()
let resourcesDir = repoRoot.appendingPathComponent("Sources/Skiller/Resources").path

// Save master 1024×1024 PNG
let masterPng = renderTransparentPNG(size: 1024)
let pngPath = "\(resourcesDir)/AppIcon.png"
try! masterPng.write(to: URL(fileURLWithPath: pngPath))
print("✅ Saved AppIcon.png (1024×1024, 72 DPI, transparent)")

// Verify: check corner pixel is fully transparent
let verifyImg = NSImage(data: masterPng)!
if let verifyRep = NSBitmapImageRep(data: verifyImg.tiffRepresentation!) {
    let cornerAlpha = verifyRep.colorAt(x: 0, y: 0)?.alphaComponent ?? -1
    let centerAlpha = verifyRep.colorAt(x: 512, y: 512)?.alphaComponent ?? -1
    print("   Corner alpha: \(cornerAlpha), Center alpha: \(centerAlpha)")
}

// Save pen.svg
try! svgString.write(toFile: "\(resourcesDir)/pen.svg", atomically: true, encoding: .utf8)

// ── 3. Create .iconset with all sizes ─────────────────────────────────
let iconsetDir = "/tmp/Skiller.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try! FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, pixelSize) in sizes {
    let png = renderTransparentPNG(size: pixelSize)
    try! png.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(name)"))
}
print("✅ Created iconset with \(sizes.count) sizes")

// ── 4. Compile .icns via iconutil ─────────────────────────────────────
let icnsPath = "\(resourcesDir)/AppIcon.icns"
let iconutilProc = Process()
iconutilProc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutilProc.arguments = ["-c", "icns", iconsetDir, "-o", icnsPath]
try! iconutilProc.run()
iconutilProc.waitUntilExit()
guard iconutilProc.terminationStatus == 0 else {
    fatalError("iconutil failed")
}
print("✅ Compiled AppIcon.icns via iconutil")

// Verify icns size
let icnsSize = try! FileManager.default.attributesOfItem(atPath: icnsPath)[.size] as! Int
print("   icns file size: \(icnsSize) bytes")
