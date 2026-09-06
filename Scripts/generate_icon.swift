#!/usr/bin/env swift
import Cocoa

func generateIconFromOpenSourceSVG() {
    // Exact open-source SVG from Iconify (Lucide / Phosphor Pen Nib)
    // Phosphor Pen Nib Fill (viewBox 0 0 256 256)
    let svgContent = """
    <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 256 256">
      <defs>
        <linearGradient id="penGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#60A5FA" />
          <stop offset="50%" stop-color="#3B82F6" />
          <stop offset="100%" stop-color="#1D4ED8" />
        </linearGradient>
        <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
          <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#000000" flood-opacity="0.35"/>
        </filter>
      </defs>
      <g filter="url(#shadow)">
        <path fill="url(#penGrad)" d="m243.31 81.36l-68.68-68.68a16 16 0 0 0-22.63 0l-28.44 28.44l-58 21.76a16.06 16.06 0 0 0-10.2 12.35l-20.77 124.6a4 4 0 0 0 6.77 3.49l57-57a23.85 23.85 0 0 1-2.29-12.08a24 24 0 1 1 13.6 23.4l-57 57a4 4 0 0 0 3.49 6.77l124.61-20.77a16 16 0 0 0 12.35-10.16l21.77-58.07L243.31 104a16 16 0 0 0 0-22.63ZM208 116.68L139.32 48l24-24L232 92.68Z"/>
      </g>
    </svg>
    """
    
    guard let svgData = svgContent.data(using: .utf8),
          let svgImage = NSImage(data: svgData) else {
        fatalError("Failed to load SVG data")
    }
    
    let targetSize = CGSize(width: 1024, height: 1024)
    let finalImage = NSImage(size: targetSize)
    finalImage.lockFocus()
    
    // Draw SVG scaled centered with some padding
    let drawRect = CGRect(x: 80, y: 80, width: 864, height: 864)
    svgImage.draw(in: drawRect, from: .zero, operation: .copy, fraction: 1.0)
    
    finalImage.unlockFocus()
    
    guard let tiffData = finalImage.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to convert image to PNG")
    }
    
    let resourcesDir = "Sources/Skiller/Resources"
    let outPngPath = "\(resourcesDir)/AppIcon.png"
    try? pngData.write(to: URL(fileURLWithPath: outPngPath))
    print("Saved \(outPngPath)")
    
    // Generate iconset
    let iconsetDir = "/tmp/Skiller.iconset"
    try? FileManager.default.removeItem(atPath: iconsetDir)
    try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)
    
    let iconSizes: [(String, CGFloat)] = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]
    
    for (filename, sizeVal) in iconSizes {
        let resized = NSImage(size: CGSize(width: sizeVal, height: sizeVal))
        resized.lockFocus()
        finalImage.draw(in: CGRect(x: 0, y: 0, width: sizeVal, height: sizeVal),
                        from: CGRect(x: 0, y: 0, width: 1024, height: 1024),
                        operation: .copy,
                        fraction: 1.0)
        resized.unlockFocus()
        
        if let rTiff = resized.tiffRepresentation,
           let rRep = NSBitmapImageRep(data: rTiff),
           let rPng = rRep.representation(using: .png, properties: [:]) {
            let outPath = "\(iconsetDir)/\(filename)"
            try? rPng.write(to: URL(fileURLWithPath: outPath))
        }
    }
    
    let icnsPath = "\(resourcesDir)/AppIcon.icns"
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    task.arguments = ["-c", "icns", iconsetDir, "-o", icnsPath]
    try? task.run()
    task.waitUntilExit()
    print("Generated \(icnsPath)")
}

generateIconFromOpenSourceSVG()
