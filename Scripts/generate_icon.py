#!/usr/bin/env python3
import os
import subprocess
from PIL import Image, ImageDraw

def generate_icons():
    src_path = "example-input.jpg"
    resources_dir = "Sources/Skiller/Resources"
    os.makedirs(resources_dir, exist_ok=True)
    
    iconset_dir = "/tmp/Skiller.iconset"
    os.makedirs(iconset_dir, exist_ok=True)
    
    img = Image.open(src_path).convert("RGBA")
    
    # Crop the central squircle icon (approximately 15% to 85%)
    w, h = img.size
    # Center crop to isolate the squircle app icon
    left = int(w * 0.14)
    top = int(h * 0.14)
    right = int(w * 0.86)
    bottom = int(h * 0.86)
    
    cropped = img.crop((left, top, right, bottom))
    base_1024 = cropped.resize((1024, 1024), Image.Resampling.LANCZOS)
    
    # Create a rounded rectangle alpha mask following Apple macOS icon squircle curvature
    mask = Image.new("L", (1024, 1024), 0)
    draw = ImageDraw.Draw(mask)
    corner_radius = 224 # Standard ~22% squircle radius for 1024x1024
    draw.rounded_rectangle([0, 0, 1024, 1024], radius=corner_radius, fill=255)
    
    # Apply alpha mask
    final_icon = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    final_icon.paste(base_1024, (0, 0), mask=mask)
    
    # Save base PNG in Resources
    app_icon_png = os.path.join(resources_dir, "AppIcon.png")
    final_icon.save(app_icon_png, "PNG")
    print(f"Saved {app_icon_png}")
    
    # Generate all required icon sizes for macOS iconutil
    icon_sizes = [
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
    
    for filename, size in icon_sizes:
        resized = final_icon.resize((size, size), Image.Resampling.LANCZOS)
        out_file = os.path.join(iconset_dir, filename)
        resized.save(out_file, "PNG")
    
    # Run iconutil to create .icns
    icns_path = os.path.join(resources_dir, "AppIcon.icns")
    subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", icns_path], check=True)
    print(f"Generated {icns_path}")

if __name__ == "__main__":
    generate_icons()
