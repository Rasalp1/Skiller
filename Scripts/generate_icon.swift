#!/usr/bin/env swift
import Cocoa

// ── 1. SVG Source ─────────────────────────────────────────────────────
// Adapted from Hugeicons' free "language-skill" Stroke Rounded icon.
// See THIRD-PARTY-NOTICES.md; the free icon is MIT licensed.
let svgString = """
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<g fill="none" stroke="black" stroke-width="1.5">
		<path stroke-linecap="round" stroke-linejoin="round" d="M2 12c0 1.052.18 2.062.512 3m10.502-6h8.488M11 15H2.512m18.99-6a9 9 0 0 0-8.488-6c1.6 0 2.909 3.762 2.995 8.5M21.502 9c.278.789.45 1.628.498 2.5M2.512 15A9 9 0 0 0 11 21c-1.544 0-2.816-3.5-2.982-8" />
		<path d="M2 5.297C2 4.2 2 3.65 2.187 3.224c.2-.452.542-.815.968-1.025C3.557 2 4.075 2 5.11 2H6c1.886 0 2.828 0 3.414.62C10 3.243 10 4.24 10 6.24v2.259c0 .871 0 1.307-.264 1.457s-.606-.092-1.29-.576l-.105-.073c-.5-.354-.75-.53-1.034-.621c-.283-.091-.584-.091-1.185-.091h-1.01c-1.037 0-1.555 0-1.957-.199a2.06 2.06 0 0 1-.968-1.025C2 6.945 2 6.396 2 5.297Zm20 12c0-1.098 0-1.647-.187-2.073a2.06 2.06 0 0 0-.968-1.025C20.443 14 19.925 14 18.89 14H18c-1.886 0-2.828 0-3.414.62C14 15.243 14 16.24 14 18.24v2.259c0 .871 0 1.307.264 1.457s.606-.092 1.29-.576l.105-.073c.5-.354.75-.53 1.034-.621c.283-.091.584-.091 1.185-.091h1.01c1.037 0 1.555 0 1.957-.199c.426-.21.769-.573.968-1.025c.187-.426.187-.975.187-2.074Z" />
	</g>
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

// Save MenuBarIcon.png (36×36 px @2x for 18pt menu bar)
let menuBarPng = renderTransparentPNG(size: 36)
let menuBarPath = "\(resourcesDir)/MenuBarIcon.png"
try! menuBarPng.write(to: URL(fileURLWithPath: menuBarPath))
print("✅ Saved MenuBarIcon.png (36×36 px @2x for 18pt menu bar)")

// Verify: check corner pixel is fully transparent
let verifyImg = NSImage(data: masterPng)!
if let verifyRep = NSBitmapImageRep(data: verifyImg.tiffRepresentation!) {
    let cornerAlpha = verifyRep.colorAt(x: 0, y: 0)?.alphaComponent ?? -1
    let centerAlpha = verifyRep.colorAt(x: 512, y: 512)?.alphaComponent ?? -1
    print("   Corner alpha: \(cornerAlpha), Center alpha: \(centerAlpha)")
}

// Save pen.svg and icon.svg
try! svgString.write(toFile: "\(resourcesDir)/pen.svg", atomically: true, encoding: .utf8)
try! svgString.write(toFile: "\(resourcesDir)/icon.svg", atomically: true, encoding: .utf8)

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
