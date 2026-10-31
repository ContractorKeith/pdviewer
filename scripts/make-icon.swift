#!/usr/bin/env swift
// Renders the app icon: a white page with a folded corner on a blue gradient
// squircle, in every size the macOS asset catalog wants.
// Usage: swift scripts/make-icon.swift pdviewer/Resources/Assets.xcassets/AppIcon.appiconset

import AppKit

let outDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "pdviewer/Resources/Assets.xcassets/AppIcon.appiconset"

func draw(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { return image }
    let s = size / 1024

    // macOS icon grid: 824pt squircle centered in 1024 canvas.
    let inset = 100 * s
    let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let squircle = NSBezierPath(roundedRect: rect, xRadius: 185 * s, yRadius: 185 * s)

    // Shadow under the tile.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12 * s), blur: 24 * s,
                  color: NSColor.black.withAlphaComponent(0.35).cgColor)
    NSColor(calibratedRed: 0.13, green: 0.33, blue: 0.70, alpha: 1).setFill()
    squircle.fill()
    ctx.restoreGState()

    // Gradient tile.
    squircle.addClip()
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.24, green: 0.52, blue: 0.93, alpha: 1),
        NSColor(calibratedRed: 0.09, green: 0.25, blue: 0.58, alpha: 1),
    ])!
    gradient.draw(in: rect, angle: -90)

    // Page with folded corner.
    let pw = 440 * s, ph = 560 * s, fold = 120 * s
    let px = (size - pw) / 2, py = (size - ph) / 2
    let page = NSBezierPath()
    page.move(to: CGPoint(x: px, y: py))
    page.line(to: CGPoint(x: px + pw, y: py))
    page.line(to: CGPoint(x: px + pw, y: py + ph - fold))
    page.line(to: CGPoint(x: px + pw - fold, y: py + ph))
    page.line(to: CGPoint(x: px, y: py + ph))
    page.close()
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -8 * s), blur: 20 * s,
                  color: NSColor.black.withAlphaComponent(0.3).cgColor)
    NSColor.white.setFill()
    page.fill()
    ctx.restoreGState()

    // Fold.
    let foldPath = NSBezierPath()
    foldPath.move(to: CGPoint(x: px + pw - fold, y: py + ph))
    foldPath.line(to: CGPoint(x: px + pw - fold, y: py + ph - fold))
    foldPath.line(to: CGPoint(x: px + pw, y: py + ph - fold))
    foldPath.close()
    NSColor(calibratedWhite: 0.82, alpha: 1).setFill()
    foldPath.fill()

    // Text lines.
    NSColor(calibratedWhite: 0.72, alpha: 1).setFill()
    let lineX = px + 56 * s
    let widths: [CGFloat] = [250, 320, 300, 330, 200].map { $0 * s }
    for (i, w) in widths.enumerated() {
        let y = py + ph - fold - 60 * s - CGFloat(i) * 72 * s
        NSBezierPath(roundedRect: CGRect(x: lineX, y: y, width: w, height: 26 * s),
                     xRadius: 13 * s, yRadius: 13 * s).fill()
    }

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, pixels: Int, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff) else { return }
    // Re-sample to exact pixel size regardless of screen scale.
    let out = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: out)
    NSGraphicsContext.current?.imageInterpolation = .high
    rep.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    try? out.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
}

let master = draw(size: 1024)
let sizes: [(Int, Int)] = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2),
                           (256, 1), (256, 2), (512, 1), (512, 2)]
var entries: [[String: String]] = []
for (pt, scale) in sizes {
    let name = "icon_\(pt)x\(pt)@\(scale)x.png"
    writePNG(master, pixels: pt * scale, to: "\(outDir)/\(name)")
    entries.append(["idiom": "mac", "scale": "\(scale)x", "size": "\(pt)x\(pt)", "filename": name])
}
let json: [String: Any] = ["images": entries, "info": ["author": "xcode", "version": 1]]
let data = try! JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
try! data.write(to: URL(fileURLWithPath: "\(outDir)/Contents.json"))
print("wrote \(entries.count) icons to \(outDir)")
