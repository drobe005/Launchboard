#!/usr/bin/env swift
/// Generates Launchboard's app icon set and menu-bar template PDF.
///
/// Usage:
///   swift scripts/generate_icons.swift
///
/// Writes PNG files into Sources/Launchboard/Assets.xcassets/AppIcon.appiconset/
/// and a PDF into Sources/Launchboard/Assets.xcassets/MenuBarIcon.imageset/
import AppKit
import CoreGraphics
import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Colour helpers
// ─────────────────────────────────────────────────────────────────────────────

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

func hex(_ h: UInt32, a: CGFloat = 1) -> CGColor {
    rgb(CGFloat((h >> 16) & 0xFF), CGFloat((h >> 8) & 0xFF), CGFloat(h & 0xFF), a: a)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Gradient helpers
// ─────────────────────────────────────────────────────────────────────────────

func makeGradient(cs: CGColorSpace, stops: [(CGColor, CGFloat)]) -> CGGradient {
    let colors = stops.map(\.0) as CFArray
    let locs   = stops.map(\.1)
    return CGGradient(colorsSpace: cs, colors: colors, locations: locs)!
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - App icon renderer
// ─────────────────────────────────────────────────────────────────────────────

func renderAppIcon(px: Int) -> Data {
    let s = CGFloat(px)
    let cs = CGColorSpaceCreateDeviceRGB()

    let ctx = CGContext(
        data: nil, width: px, height: px,
        bitsPerComponent: 8, bytesPerRow: px * 4,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                  | CGBitmapInfo.byteOrder32Little.rawValue
    )!

    // ── Background ───────────────────────────────────────────────────────────

    let corner   = s * 0.225
    let fullRect = CGRect(origin: .zero, size: CGSize(width: s, height: s))
    let bgPath   = CGPath(roundedRect: fullRect, cornerWidth: corner, cornerHeight: corner, transform: nil)

    ctx.addPath(bgPath)
    ctx.clip()

    // Base gradient: sky-blue top-left → deep indigo bottom-right
    let bgGrad = makeGradient(cs: cs, stops: [
        (hex(0x5B9FFF), 0.0),
        (hex(0x2255E0), 0.55),
        (hex(0x1238AA), 1.0),
    ])
    ctx.drawLinearGradient(bgGrad,
        start: CGPoint(x: s * 0.15, y: s * 0.92),
        end:   CGPoint(x: s * 0.85, y: s * 0.08),
        options: [])

    // Soft radial fill — centres the eye on the grid
    let glowGrad = makeGradient(cs: cs, stops: [
        (rgb(255, 255, 255, a: 0.11), 0.0),
        (rgb(255, 255, 255, a: 0.00), 1.0),
    ])
    ctx.drawRadialGradient(glowGrad,
        startCenter: CGPoint(x: s * 0.50, y: s * 0.52),
        startRadius: 0,
        endCenter:   CGPoint(x: s * 0.50, y: s * 0.52),
        endRadius:   s * 0.46,
        options: [])

    // ── 3 × 3 tile grid ──────────────────────────────────────────────────────

    let margin = s * 0.17
    let grid   = s - margin * 2
    let gap    = s * 0.043
    let tw     = (grid - gap * 2) / 3      // tile width/height
    let tr     = tw * 0.22                 // tile corner radius

    // Tile accent colours (vivid, all recognisable from macOS palette)
    // Laid out top-left → bottom-right, row-major.
    let tileAccent: [CGColor] = [
        hex(0xFF6B6B),          // coral
        hex(0x48DBFB),          // sky
        hex(0x1DD1A1),          // mint
        hex(0xFFC312),          // amber
        rgb(255, 255, 255, a: 0.93), // white (centre focal tile)
        hex(0xA29BFE),          // lavender
        hex(0xFF9F43),          // tangerine
        hex(0x54A0FF),          // blue
        hex(0xFD79A8),          // rose
    ]

    for row in 0..<3 {
        for col in 0..<3 {
            let x  = margin + CGFloat(col) * (tw + gap)
            // CG y is bottom-up; visually row 0 is at the top
            let y  = margin + CGFloat(2 - row) * (tw + gap)
            let idx = row * 3 + col

            // Centre tile gets a small upward lift for the "launch" hint
            let lift: CGFloat = (idx == 4) ? s * 0.008 : 0
            let tileRect = CGRect(x: x, y: y + lift, width: tw, height: tw)
            let tilePath = CGPath(roundedRect: tileRect, cornerWidth: tr, cornerHeight: tr, transform: nil)

            // Drop shadow (deeper for centre tile)
            ctx.saveGState()
            let shadowAlpha: CGFloat = (idx == 4) ? 0.45 : 0.28
            let shadowBlur:  CGFloat = (idx == 4) ? s * 0.038 : s * 0.022
            ctx.setShadow(
                offset: CGSize(width: 0, height: -(shadowBlur * 0.5)),
                blur:   shadowBlur,
                color:  rgb(0, 10, 40, a: shadowAlpha)
            )
            ctx.addPath(tilePath)
            ctx.setFillColor(tileAccent[idx])
            ctx.fillPath()
            ctx.restoreGState()

            // Inner shimmer — top-edge highlight
            ctx.saveGState()
            ctx.addPath(tilePath)
            ctx.clip()
            let shimmer = makeGradient(cs: cs, stops: [
                (rgb(255, 255, 255, a: 0.35), 0.0),
                (rgb(255, 255, 255, a: 0.00), 0.50),
            ])
            ctx.drawLinearGradient(shimmer,
                start: CGPoint(x: x + tw * 0.5, y: y + lift + tw),
                end:   CGPoint(x: x + tw * 0.5, y: y + lift + tw * 0.50),
                options: [])
            ctx.restoreGState()
        }
    }

    // ── Rim highlight — upper arc ─────────────────────────────────────────────

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    let rim = makeGradient(cs: cs, stops: [
        (rgb(255, 255, 255, a: 0.20), 0.0),
        (rgb(255, 255, 255, a: 0.00), 1.0),
    ])
    ctx.drawLinearGradient(rim,
        start: CGPoint(x: s * 0.5, y: s),
        end:   CGPoint(x: s * 0.5, y: s * 0.58),
        options: [])
    ctx.restoreGState()

    // ── Export ────────────────────────────────────────────────────────────────

    let cgImage = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: cgImage)
    rep.size = NSSize(width: px, height: px)
    return rep.representation(using: .png, properties: [.interlaced: false])!
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Menu-bar template icon (PDF, 16 × 16 pt, all-black paths)
// ─────────────────────────────────────────────────────────────────────────────
// Draws a compact 3 × 3 grid of rounded squares.  The NSImage.isTemplate flag
// applied in MenuBarController handles colouring / dark-mode inversion.

func renderMenuBarPDF() -> Data {
    let size: CGFloat = 18   // 18pt is the standard menu-bar icon canvas
    let mutable = NSMutableData()
    var box = CGRect(origin: .zero, size: CGSize(width: size, height: size))

    let consumer = CGDataConsumer(data: mutable)!
    let ctx = CGContext(consumer: consumer, mediaBox: &box, nil)!

    ctx.beginPDFPage(nil)

    // 3 × 3 grid of tiny rounded squares
    let pad:  CGFloat = 1.5
    let grid  = size - pad * 2
    let gap:  CGFloat = 1.0
    let tw    = (grid - gap * 2) / 3
    let tr    = tw * 0.20

    ctx.setFillColor(CGColor.black)

    for row in 0..<3 {
        for col in 0..<3 {
            let x = pad + CGFloat(col) * (tw + gap)
            let y = pad + CGFloat(row) * (tw + gap)
            let r = CGRect(x: x, y: y, width: tw, height: tw)
            ctx.addPath(CGPath(roundedRect: r, cornerWidth: tr, cornerHeight: tr, transform: nil))
            ctx.fillPath()
        }
    }

    ctx.endPDFPage()
    ctx.closePDF()

    return mutable as Data
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - File layout
// ─────────────────────────────────────────────────────────────────────────────

let projectRoot = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()   // scripts/
    .deletingLastPathComponent()   // project root

let iconsetDir = projectRoot
    .appendingPathComponent("Sources/Launchboard/Assets.xcassets/AppIcon.appiconset")
let menuBarDir = projectRoot
    .appendingPathComponent("Sources/Launchboard/Assets.xcassets/MenuBarIcon.imageset")

try FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: menuBarDir, withIntermediateDirectories: true)

// Pixel sizes → (filename, points-label, scale-label) entries for Contents.json
// Some pixel sizes are shared between a @1x and a @2x entry.
struct IconSpec {
    let px: Int
    let filename: String
    // One file may cover multiple Contents.json entries
    let entries: [(size: String, scale: String)]
}

let specs: [IconSpec] = [
    IconSpec(px: 16,   filename: "icon_16x16.png",       entries: [("16x16",   "1x")]),
    IconSpec(px: 32,   filename: "icon_32x32.png",       entries: [("16x16",   "2x"), ("32x32", "1x")]),
    IconSpec(px: 64,   filename: "icon_64x64.png",       entries: [("32x32",   "2x")]),
    IconSpec(px: 128,  filename: "icon_128x128.png",     entries: [("128x128", "1x")]),
    IconSpec(px: 256,  filename: "icon_256x256.png",     entries: [("128x128", "2x"), ("256x256", "1x")]),
    IconSpec(px: 512,  filename: "icon_512x512.png",     entries: [("256x256", "2x"), ("512x512", "1x")]),
    IconSpec(px: 1024, filename: "icon_512x512@2x.png",  entries: [("512x512", "2x")]),
]

// Render and write PNGs
for spec in specs {
    let data = renderAppIcon(px: spec.px)
    let url  = iconsetDir.appendingPathComponent(spec.filename)
    try data.write(to: url)
    print("✓  \(spec.filename)  (\(spec.px)×\(spec.px) px)")
}

// Build Contents.json
var images: [[String: String]] = []
for spec in specs {
    for entry in spec.entries {
        images.append([
            "filename": spec.filename,
            "idiom":    "mac",
            "scale":    entry.scale,
            "size":     entry.size,
        ])
    }
}
let contentsJSON: [String: Any] = [
    "images": images,
    "info":   ["author": "xcode", "version": 1],
]
let contentsData = try JSONSerialization.data(withJSONObject: contentsJSON, options: [.prettyPrinted, .sortedKeys])
try contentsData.write(to: iconsetDir.appendingPathComponent("Contents.json"))
print("✓  Contents.json")

// Render and write menu-bar PDF
let pdfData = renderMenuBarPDF()
try pdfData.write(to: menuBarDir.appendingPathComponent("MenuBarIcon.pdf"))
print("✓  MenuBarIcon.pdf  (18×18 pt template)")

// MenuBarIcon Contents.json
let menuBarContents: [String: Any] = [
    "images": [
        ["filename": "MenuBarIcon.pdf", "idiom": "mac", "scale": "1x"],
    ],
    "info":       ["author": "xcode", "version": 1],
    "properties": ["preserves-vector-representation": true, "template-rendering-intent": "template"],
]
let menuBarContentsData = try JSONSerialization.data(
    withJSONObject: menuBarContents, options: [.prettyPrinted, .sortedKeys])
try menuBarContentsData.write(to: menuBarDir.appendingPathComponent("Contents.json"))
print("✓  MenuBarIcon imageset Contents.json")

print("\nDone. Asset catalog written to Sources/Launchboard/Assets.xcassets/")
