#!/usr/bin/env swift
/// Generates App Store screenshots for Launchboard at 2880×1800 (Retina @2x).
/// Run: swift scripts/generate_screenshots.swift
/// Output: AppStoreAssets/Screenshots/
import AppKit
import Foundation

// ─── Canvas & window geometry ────────────────────────────────────────────────

let CW: CGFloat = 2880, CH: CGFloat = 1800
let WX: CGFloat = 60,   WY: CGFloat = 60
let WW: CGFloat = 2760, WH: CGFloat = 1680, WR: CGFloat = 20

let TBH: CGFloat = 80   // title-bar height
let SBW: CGFloat = 440  // sidebar width
let TPH: CGFloat = 96   // content top-bar height (title + sort/view)
let FBH: CGFloat = 220  // favorites-bar height

let CTX = WX + SBW      // content left edge = 500
let CTW = WW - SBW      // content width     = 2320
let CTY = WY + TBH      // content top       = 140

// ─── Colors ──────────────────────────────────────────────────────────────────

func cgc(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: a)
}
func nsc(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: a)
}

let cCanvas    = cgc(195, 195, 200)
let cTitlebar  = cgc(236, 236, 236)
let cSidebar   = cgc(241, 241, 241)
let cContent   = cgc(251, 251, 251)
let cDivider   = cgc(206, 206, 206)
let cAccent    = cgc(0, 122, 255)
let cAccentBg  = cgc(0, 122, 255, a: 0.12)
let cPrimary   = cgc(28, 28, 30)
let cSecondary = cgc(108, 108, 112)
let cTertiary  = cgc(174, 174, 178)
let cWhite     = cgc(255, 255, 255)
let cFieldBg   = cgc(225, 225, 225)
let cModalBg   = cgc(252, 252, 252)
let cScrim     = cgc(0, 0, 0, a: 0.50)
let cCardBg    = cgc(246, 246, 246)
let cCardSel   = cgc(232, 241, 255)
let cBorder    = cgc(218, 218, 218)
let cTrafficR  = cgc(255, 95, 87)
let cTrafficY  = cgc(254, 188, 46)
let cTrafficG  = cgc(40, 200, 64)

let nsPrimary   = nsc(28, 28, 30)
let nsSecondary = nsc(108, 108, 112)
let nsTertiary  = nsc(174, 174, 178)
let nsAccent    = nsc(0, 122, 255)
let nsWhite     = nsc(255, 255, 255)

let TILE_COLORS: [CGColor] = [
    cgc(255, 107, 107), cgc(72,  219, 251), cgc(29,  209, 161),
    cgc(255, 195, 18),  cgc(240, 147, 43),  cgc(162, 155, 254),
    cgc(84,  160, 255), cgc(253, 121, 168), cgc(255, 107, 107),
    cgc(72,  219, 251), cgc(29,  209, 161), cgc(255, 195, 18),
    cgc(240, 147, 43),  cgc(162, 155, 254), cgc(84,  160, 255),
    cgc(253, 121, 168), cgc(255, 107, 107), cgc(72,  219, 251),
    cgc(29,  209, 161), cgc(255, 195, 18),  cgc(240, 147, 43),
    cgc(162, 155, 254), cgc(84,  160, 255), cgc(253, 121, 168),
]

// ─── Context ─────────────────────────────────────────────────────────────────

func makeContext() -> (CGContext, NSGraphicsContext) {
    let space = CGColorSpaceCreateDeviceRGB()
    let cg = CGContext(data: nil, width: Int(CW), height: Int(CH),
                       bitsPerComponent: 8, bytesPerRow: Int(CW) * 4, space: space,
                       bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                                 | CGBitmapInfo.byteOrder32Little.rawValue)!
    cg.translateBy(x: 0, y: CH)
    cg.scaleBy(x: 1, y: -1)
    let ns = NSGraphicsContext(cgContext: cg, flipped: true)
    return (cg, ns)
}

func toPNG(_ cg: CGContext) -> Data {
    let rep = NSBitmapImageRep(cgImage: cg.makeImage()!)
    return rep.representation(using: .png, properties: [.interlaced: false])!
}

// ─── Shape primitives ─────────────────────────────────────────────────────────

func fillRR(_ cg: CGContext, _ r: CGRect, radius: CGFloat, _ color: CGColor) {
    cg.setFillColor(color)
    cg.addPath(CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil))
    cg.fillPath()
}

func strokeRR(_ cg: CGContext, _ r: CGRect, radius: CGFloat, _ color: CGColor, lw: CGFloat = 2) {
    cg.setStrokeColor(color); cg.setLineWidth(lw)
    cg.addPath(CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil))
    cg.strokePath()
}

func fillR(_ cg: CGContext, _ r: CGRect, _ color: CGColor) { cg.setFillColor(color); cg.fill(r) }

func hRule(_ cg: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, _ color: CGColor = cgc(206,206,206)) {
    cg.setStrokeColor(color); cg.setLineWidth(1)
    cg.move(to: CGPoint(x: x, y: y)); cg.addLine(to: CGPoint(x: x+w, y: y)); cg.strokePath()
}

func vRule(_ cg: CGContext, x: CGFloat, y: CGFloat, h: CGFloat, _ color: CGColor = cgc(206,206,206)) {
    cg.setStrokeColor(color); cg.setLineWidth(1)
    cg.move(to: CGPoint(x: x, y: y)); cg.addLine(to: CGPoint(x: x, y: y+h)); cg.strokePath()
}

// ─── Text ─────────────────────────────────────────────────────────────────────

func txt(_ s: String, at p: CGPoint, size: CGFloat, weight: NSFont.Weight = .regular,
         color: NSColor, maxW: CGFloat = 0, align: NSTextAlignment = .left,
         ns: NSGraphicsContext) {
    let prev = NSGraphicsContext.current; NSGraphicsContext.current = ns
    let para = NSMutableParagraphStyle()
    para.alignment = align
    para.lineBreakMode = maxW > 0 ? .byTruncatingTail : .byWordWrapping
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: para
    ]
    let str = s as NSString
    if maxW > 0 {
        str.draw(in: NSRect(x: p.x, y: p.y, width: maxW, height: size * 2), withAttributes: attrs)
    } else {
        str.draw(at: p, withAttributes: attrs)
    }
    NSGraphicsContext.current = prev
}

func tsz(_ s: String, size: CGFloat, weight: NSFont.Weight = .regular) -> CGSize {
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight)]
    return (s as NSString).size(withAttributes: attrs)
}

// ─── App tile ─────────────────────────────────────────────────────────────────

struct AppItem { let name: String; let colorIdx: Int; var isNew: Bool = false }

func drawTileIcon(_ cg: CGContext, frame: CGRect, colorIdx: Int, alpha: CGFloat = 1) {
    let color = TILE_COLORS[colorIdx % TILE_COLORS.count]
    cg.saveGState(); cg.setAlpha(alpha)
    fillRR(cg, frame, radius: frame.width * 0.22, color)
    // Inner 3×3 shimmer grid
    let pad = frame.width * 0.18
    let gs  = frame.width - pad * 2
    let cs  = (gs - 4) / 3
    for row in 0..<3 {
        for col in 0..<3 {
            let cx = frame.minX + pad + CGFloat(col) * (cs + 2)
            let cy = frame.minY + pad + CGFloat(row) * (cs + 2)
            fillRR(cg, CGRect(x: cx, y: cy, width: cs, height: cs),
                   radius: 2, cgc(255, 255, 255, a: 0.28))
        }
    }
    cg.restoreGState()
}

func drawAppTile(_ cg: CGContext, ns: NSGraphicsContext, app: AppItem,
                 frame: CGRect, iconSz: CGFloat = 128, alpha: CGFloat = 1) {
    let iconX = frame.midX - iconSz / 2
    let iconRect = CGRect(x: iconX, y: frame.minY, width: iconSz, height: iconSz)
    drawTileIcon(cg, frame: iconRect, colorIdx: app.colorIdx, alpha: alpha)
    if app.isNew {
        cg.saveGState(); cg.setAlpha(alpha)
        cg.setFillColor(cAccent)
        cg.fillEllipse(in: CGRect(x: iconX + iconSz - 22, y: frame.minY + 4, width: 18, height: 18))
        cg.restoreGState()
    }
    let labelY = frame.minY + iconSz + 8
    txt(app.name, at: CGPoint(x: frame.minX, y: labelY),
        size: 21, color: alpha < 1 ? nsTertiary : nsPrimary,
        maxW: frame.width, align: .center, ns: ns)
}

// ─── App grid ─────────────────────────────────────────────────────────────────

func drawAppGrid(_ cg: CGContext, ns: NSGraphicsContext, apps: [AppItem],
                 originX: CGFloat, originY: CGFloat, areaW: CGFloat, areaH: CGFloat,
                 cols: Int = 8, highlight: String? = nil) {
    let iconSz: CGFloat = 120
    let tileH:  CGFloat = 170  // icon + label
    let hGap:   CGFloat = 36
    let vGap:   CGFloat = 24
    let padL:   CGFloat = 48
    let padT:   CGFloat = 36

    for (i, app) in apps.enumerated() {
        let col = CGFloat(i % cols)
        let row = CGFloat(i / cols)
        let x = originX + padL + col * (iconSz + hGap)
        let y = originY + padT + row * (tileH + vGap)
        guard x + iconSz <= originX + areaW, y + tileH <= originY + areaH else { continue }
        let alpha: CGFloat = highlight.map {
            app.name.lowercased().contains($0.lowercased()) ? 1.0 : 0.22
        } ?? 1.0
        drawAppTile(cg, ns: ns, app: app,
                    frame: CGRect(x: x, y: y, width: iconSz, height: tileH),
                    iconSz: iconSz, alpha: alpha)
    }
}

// ─── Favorites bar ────────────────────────────────────────────────────────────

func drawFavBar(_ cg: CGContext, ns: NSGraphicsContext, apps: [AppItem],
                barY: CGFloat, highlight: String? = nil) {
    fillR(cg, CGRect(x: CTX, y: barY, width: CTW, height: FBH), cgc(248, 248, 248))
    hRule(cg, x: CTX, y: barY + FBH - 1, w: CTW)

    let iconSz: CGFloat = 96
    let gap:    CGFloat = 44
    let total   = CGFloat(apps.count) * iconSz + CGFloat(apps.count - 1) * gap
    var x       = CTX + (CTW - total) / 2

    for app in apps {
        let alpha: CGFloat = highlight.map {
            app.name.lowercased().contains($0.lowercased()) ? 1.0 : 0.30
        } ?? 1.0
        let iconY = barY + (FBH - iconSz) / 2 - 14
        drawTileIcon(cg, frame: CGRect(x: x, y: iconY, width: iconSz, height: iconSz),
                     colorIdx: app.colorIdx, alpha: alpha)
        txt(app.name,
            at: CGPoint(x: x - 12, y: iconY + iconSz + 6),
            size: 20, color: alpha < 1 ? nsTertiary : nsSecondary,
            maxW: iconSz + 24, align: .center, ns: ns)
        x += iconSz + gap
    }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

struct SidebarRow {
    let icon: String; let label: String; let count: Int?
    let selected: Bool; let emoji: String?
}
struct SidebarSection { let header: String; let rows: [SidebarRow] }

func drawSidebar(_ cg: CGContext, ns: NSGraphicsContext, sections: [SidebarSection]) {
    fillR(cg, CGRect(x: WX, y: CTY, width: SBW, height: WH - TBH), cSidebar)
    vRule(cg, x: WX + SBW, y: CTY, h: WH - TBH)

    var y = CTY + 24

    for section in sections {
        txt(section.header, at: CGPoint(x: WX + 24, y: y),
            size: 20, weight: .semibold, color: nsTertiary, ns: ns)
        y += 36

        for row in section.rows {
            let rowH: CGFloat = 56
            if row.selected {
                fillRR(cg, CGRect(x: WX + 10, y: y - 4, width: SBW - 20, height: rowH),
                       radius: 8, cAccentBg)
            }
            // Icon
            if let em = row.emoji {
                txt(em, at: CGPoint(x: WX + 22, y: y + 8), size: 26, color: nsPrimary, ns: ns)
            } else {
                let ic = row.selected ? cAccent : cTertiary
                fillRR(cg, CGRect(x: WX + 22, y: y + 12, width: 26, height: 26), radius: 6, ic)
            }
            // Label
            let lc = row.selected ? nsAccent : nsPrimary
            txt(row.label, at: CGPoint(x: WX + 60, y: y + 12),
                size: 26, color: lc, maxW: SBW - 140, ns: ns)
            // Count badge
            if let count = row.count, count > 0 {
                let cs = "\(count)"
                let cw = tsz(cs, size: 22).width
                txt(cs, at: CGPoint(x: WX + SBW - cw - 28, y: y + 14),
                    size: 22, color: nsTertiary, ns: ns)
            }
            y += rowH
        }
        y += 20
    }

    // Settings button pinned at bottom
    let settY = WY + WH - 76
    fillRR(cg, CGRect(x: WX + 10, y: settY - 4, width: SBW - 20, height: 56), radius: 8, cgc(0,0,0,a:0))
    fillRR(cg, CGRect(x: WX + 22, y: settY + 8, width: 26, height: 26), radius: 6, cSecondary)
    txt("Settings", at: CGPoint(x: WX + 60, y: settY + 8), size: 26, color: nsPrimary, ns: ns)
}

// ─── Content top bar (title + sort + view picker) ─────────────────────────────

func drawTopBar(_ cg: CGContext, ns: NSGraphicsContext, title: String, y: CGFloat) {
    fillR(cg, CGRect(x: CTX, y: y, width: CTW, height: TPH), cContent)
    let th = tsz(title, size: 30, weight: .semibold).height
    txt(title, at: CGPoint(x: CTX + 48, y: y + (TPH - th) / 2),
        size: 30, weight: .semibold, color: nsPrimary, ns: ns)
    // Sort picker
    let sortX = CTX + CTW - 360, sortY = y + (TPH - 56) / 2
    fillRR(cg, CGRect(x: sortX, y: sortY, width: 196, height: 56), radius: 8, cFieldBg)
    txt("A–Z  ▾", at: CGPoint(x: sortX + 16, y: sortY + 14), size: 24, color: nsPrimary, ns: ns)
    // View mode
    let vX = sortX + 212
    fillRR(cg, CGRect(x: vX, y: sortY, width: 132, height: 56), radius: 8, cFieldBg)
    fillRR(cg, CGRect(x: vX + 4, y: sortY + 4, width: 60, height: 48), radius: 6, cWhite)
    txt("⊞", at: CGPoint(x: vX + 14, y: sortY + 10), size: 28, color: nsAccent, ns: ns)
    txt("≡", at: CGPoint(x: vX + 78, y: sortY + 10), size: 28, color: nsTertiary, ns: ns)
    hRule(cg, x: CTX, y: y + TPH - 1, w: CTW)
}

// ─── Window chrome (titlebar + search) + canvas background ────────────────────
// Leaves a clip to the window rect active; call finishWindow after all drawing.

func beginWindow(_ cg: CGContext, ns: NSGraphicsContext, searchQuery: String = "") {
    // Canvas background
    fillR(cg, CGRect(x: 0, y: 0, width: CW, height: CH), cCanvas)

    // Window drop shadow
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: 16), blur: 60, color: cgc(0, 0, 0, a: 0.28))
    let winPath = CGPath(roundedRect: CGRect(x: WX, y: WY, width: WW, height: WH),
                         cornerWidth: WR, cornerHeight: WR, transform: nil)
    cg.addPath(winPath); cg.setFillColor(cContent); cg.fillPath()
    cg.restoreGState()

    // Clip all subsequent drawing to rounded window
    cg.saveGState()
    cg.addPath(CGPath(roundedRect: CGRect(x: WX, y: WY, width: WW, height: WH),
                      cornerWidth: WR, cornerHeight: WR, transform: nil))
    cg.clip()

    // Window background
    fillR(cg, CGRect(x: WX, y: WY, width: WW, height: WH), cContent)

    // Title bar
    fillR(cg, CGRect(x: WX, y: WY, width: WW, height: TBH), cTitlebar)

    // Traffic lights
    let tly = WY + TBH / 2
    for (i, c) in [cTrafficR, cTrafficY, cTrafficG].enumerated() {
        cg.setFillColor(c)
        let tlx = WX + 36 + CGFloat(i) * 46
        cg.fillEllipse(in: CGRect(x: tlx - 13, y: tly - 13, width: 26, height: 26))
    }

    // Window title
    let wt = "Launchboard"
    let wts = tsz(wt, size: 26, weight: .semibold)
    txt(wt, at: CGPoint(x: WX + WW / 2 - wts.width / 2, y: WY + TBH / 2 - wts.height / 2),
        size: 26, weight: .semibold, color: nsPrimary, ns: ns)

    // Search field (centred in content column)
    let sfW: CGFloat = 520, sfH: CGFloat = 56
    let sfX = CTX + (CTW - sfW) / 2
    let sfY = WY + TBH / 2 - sfH / 2
    fillRR(cg, CGRect(x: sfX, y: sfY, width: sfW, height: sfH), radius: 10, cFieldBg)
    let qColor = searchQuery.isEmpty ? nsTertiary : nsPrimary
    let qText  = "  🔍  " + (searchQuery.isEmpty ? "Search apps" : searchQuery)
    txt(qText, at: CGPoint(x: sfX + 12, y: sfY + 12), size: 24, color: qColor, ns: ns)

    hRule(cg, x: WX, y: WY + TBH, w: WW)
    // Note: window clip remains active until finishWindow()
}

func finishWindow(_ cg: CGContext) { cg.restoreGState() }

// ─── Modal overlay ────────────────────────────────────────────────────────────

func drawModal(_ cg: CGContext, ns: NSGraphicsContext, rect: CGRect) {
    // Scrim
    fillR(cg, CGRect(x: WX, y: WY, width: WW, height: WH), cScrim)
    // Modal shadow
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: 16), blur: 48, color: cgc(0, 0, 0, a: 0.25))
    cg.addPath(CGPath(roundedRect: rect, cornerWidth: 24, cornerHeight: 24, transform: nil))
    cg.setFillColor(cModalBg); cg.fillPath()
    cg.restoreGState()
    fillRR(cg, rect, radius: 24, cModalBg)
    strokeRR(cg, rect, radius: 24, cDivider, lw: 1)
}

// ─── Standard sidebar data ───────────────────────────────────────────────────

func makeSidebar(allApps: Bool = false, design: Bool = false, smartLarge: Bool = false) -> [SidebarSection] {
    [
        SidebarSection(header: "LIBRARY", rows: [
            SidebarRow(icon: "star",  label: "Favorites",      count: 7,   selected: false, emoji: nil),
            SidebarRow(icon: "clock", label: "Recently Added", count: 3,   selected: false, emoji: nil),
            SidebarRow(icon: "grid",  label: "All Apps",       count: 142, selected: allApps, emoji: nil),
        ]),
        SidebarSection(header: "GROUPS", rows: [
            SidebarRow(icon: "folder", label: "Design",      count: 12, selected: design, emoji: "🎨"),
            SidebarRow(icon: "folder", label: "Dev Tools",   count: 18, selected: false,  emoji: "💻"),
            SidebarRow(icon: "folder", label: "Creative",    count: 9,  selected: false,  emoji: "✏️"),
            SidebarRow(icon: "folder", label: "Media",       count: 11, selected: false,  emoji: "🎵"),
        ]),
        SidebarSection(header: "SMART GROUPS", rows: [
            SidebarRow(icon: "bolt", label: "Recent Adobe", count: nil, selected: false,      emoji: "⚡"),
            SidebarRow(icon: "bolt", label: "Large Apps",   count: nil, selected: smartLarge, emoji: "📦"),
        ]),
    ]
}

let favApps: [AppItem] = [
    AppItem(name: "Safari",   colorIdx: 1),
    AppItem(name: "Mail",     colorIdx: 6),
    AppItem(name: "Messages", colorIdx: 2),
    AppItem(name: "Figma",    colorIdx: 5),
    AppItem(name: "VS Code",  colorIdx: 6),
    AppItem(name: "Slack",    colorIdx: 5),
    AppItem(name: "Spotify",  colorIdx: 2),
]

let allApps: [AppItem] = [
    AppItem(name: "Finder",      colorIdx: 6),
    AppItem(name: "Safari",      colorIdx: 1),
    AppItem(name: "Mail",        colorIdx: 6),
    AppItem(name: "Calendar",    colorIdx: 0),
    AppItem(name: "Notes",       colorIdx: 3),
    AppItem(name: "Reminders",   colorIdx: 2),
    AppItem(name: "Messages",    colorIdx: 2),
    AppItem(name: "Photos",      colorIdx: 0),
    AppItem(name: "Music",       colorIdx: 0),
    AppItem(name: "Podcasts",    colorIdx: 5),
    AppItem(name: "Maps",        colorIdx: 2),
    AppItem(name: "Terminal",    colorIdx: 8),
    AppItem(name: "Xcode",       colorIdx: 6),
    AppItem(name: "Figma",       colorIdx: 5, isNew: true),
    AppItem(name: "Sketch",      colorIdx: 3),
    AppItem(name: "VS Code",     colorIdx: 6),
    AppItem(name: "Slack",       colorIdx: 5),
    AppItem(name: "Notion",      colorIdx: 8),
    AppItem(name: "Discord",     colorIdx: 5),
    AppItem(name: "Spotify",     colorIdx: 2),
    AppItem(name: "1Password",   colorIdx: 3),
    AppItem(name: "Bear",        colorIdx: 0),
    AppItem(name: "Things 3",    colorIdx: 6),
    AppItem(name: "Simulator",   colorIdx: 7),
]

// ════════════════════════════════════════════════════════════════
// MARK: – Screen 1  All Apps + Favorites bar
// ════════════════════════════════════════════════════════════════

func renderScreen1() -> Data {
    let (cg, ns) = makeContext()
    beginWindow(cg, ns: ns)
    drawSidebar(cg, ns: ns, sections: makeSidebar(allApps: true))
    drawTopBar(cg, ns: ns, title: "All Apps", y: CTY)
    drawFavBar(cg, ns: ns, apps: favApps, barY: CTY + TPH)
    let gridY = CTY + TPH + FBH
    drawAppGrid(cg, ns: ns, apps: allApps,
                originX: CTX, originY: gridY,
                areaW: CTW, areaH: WY + WH - gridY)
    finishWindow(cg)
    return toPNG(cg)
}

// ════════════════════════════════════════════════════════════════
// MARK: – Screen 2  Design group
// ════════════════════════════════════════════════════════════════

func renderScreen2() -> Data {
    let (cg, ns) = makeContext()
    beginWindow(cg, ns: ns)
    drawSidebar(cg, ns: ns, sections: makeSidebar(design: true))
    drawTopBar(cg, ns: ns, title: "🎨  Design", y: CTY)
    let designApps: [AppItem] = [
        AppItem(name: "Figma",          colorIdx: 5),
        AppItem(name: "Sketch",         colorIdx: 3),
        AppItem(name: "Illustrator",    colorIdx: 3),
        AppItem(name: "Photoshop",      colorIdx: 6),
        AppItem(name: "After Effects",  colorIdx: 5),
        AppItem(name: "InVision",       colorIdx: 7),
        AppItem(name: "Principle",      colorIdx: 5),
        AppItem(name: "Zeplin",         colorIdx: 3),
        AppItem(name: "Framer",         colorIdx: 8),
        AppItem(name: "Canva",          colorIdx: 5),
        AppItem(name: "Pixelmator Pro", colorIdx: 6),
        AppItem(name: "Vectornator",    colorIdx: 6),
    ]
    drawAppGrid(cg, ns: ns, apps: designApps,
                originX: CTX, originY: CTY + TPH,
                areaW: CTW, areaH: WY + WH - (CTY + TPH), cols: 6)
    finishWindow(cg)
    return toPNG(cg)
}

// ════════════════════════════════════════════════════════════════
// MARK: – Screen 3  Search results (query "fig")
// ════════════════════════════════════════════════════════════════

func renderScreen3() -> Data {
    let (cg, ns) = makeContext()
    beginWindow(cg, ns: ns, searchQuery: "fig")
    drawSidebar(cg, ns: ns, sections: makeSidebar(allApps: true))

    // "FAVORITES" sub-header
    let favHeaderY = CTY + 12
    txt("FAVORITES", at: CGPoint(x: CTX + 48, y: favHeaderY),
        size: 20, weight: .semibold, color: nsTertiary, ns: ns)
    drawFavBar(cg, ns: ns, apps: favApps, barY: favHeaderY + 32, highlight: "fig")

    // "RESULTS" sub-header
    let resY = favHeaderY + 32 + FBH + 4
    txt("RESULTS  ·  3 matches", at: CGPoint(x: CTX + 48, y: resY),
        size: 20, weight: .semibold, color: nsTertiary, ns: ns)

    let searchApps: [AppItem] = [
        AppItem(name: "Finder",      colorIdx: 6),
        AppItem(name: "Safari",      colorIdx: 1),
        AppItem(name: "Figma",       colorIdx: 5),
        AppItem(name: "Calendar",    colorIdx: 0),
        AppItem(name: "Notes",       colorIdx: 3),
        AppItem(name: "Figma FigJam",colorIdx: 5),
        AppItem(name: "Messages",    colorIdx: 2),
        AppItem(name: "Photos",      colorIdx: 0),
        AppItem(name: "Figma Mirror",colorIdx: 5),
        AppItem(name: "Maps",        colorIdx: 2),
        AppItem(name: "Terminal",    colorIdx: 8),
        AppItem(name: "Notion",      colorIdx: 8),
    ]
    let gridY = resY + 36
    drawAppGrid(cg, ns: ns, apps: searchApps,
                originX: CTX, originY: gridY,
                areaW: CTW, areaH: WY + WH - gridY, highlight: "fig")

    finishWindow(cg)
    return toPNG(cg)
}

// ════════════════════════════════════════════════════════════════
// MARK: – Screen 4  Smart Group Editor
// ════════════════════════════════════════════════════════════════

func renderScreen4() -> Data {
    let (cg, ns) = makeContext()
    beginWindow(cg, ns: ns)
    // Dim background
    drawSidebar(cg, ns: ns, sections: makeSidebar(allApps: true))
    drawTopBar(cg, ns: ns, title: "All Apps", y: CTY)

    // Scrim + modal
    let mW: CGFloat = 1440, mH: CGFloat = 1000
    let mX = WX + (WW - mW) / 2, mY = WY + (WH - mH) / 2
    let mr = CGRect(x: mX, y: mY, width: mW, height: mH)
    drawModal(cg, ns: ns, rect: mr)

    // ── Header
    txt("New Smart Group", at: CGPoint(x: mX + 48, y: mY + 30),
        size: 30, weight: .semibold, color: nsPrimary, ns: ns)
    hRule(cg, x: mX, y: mY + 82, w: mW)

    let fW: CGFloat = 688   // form pane width
    let fX = mX

    // ── Name row
    let nY = mY + 108
    fillRR(cg, CGRect(x: fX + 48, y: nY, width: 72, height: 72), radius: 12, cFieldBg)
    txt("📦", at: CGPoint(x: fX + 56, y: nY + 10), size: 38, color: nsPrimary, ns: ns)
    fillRR(cg, CGRect(x: fX + 136, y: nY, width: fW - 188, height: 72), radius: 12, cFieldBg)
    txt("Large Apps", at: CGPoint(x: fX + 154, y: nY + 20),
        size: 28, color: nsPrimary, ns: ns)

    // ── Combinator row
    let cmbY = nY + 94
    txt("Match", at: CGPoint(x: fX + 48, y: cmbY + 12), size: 26, color: nsSecondary, ns: ns)
    fillRR(cg, CGRect(x: fX + 148, y: cmbY, width: 196, height: 56), radius: 8, cFieldBg)
    txt("all  ▾", at: CGPoint(x: fX + 166, y: cmbY + 14), size: 26, color: nsPrimary, ns: ns)
    txt("of the following rules:", at: CGPoint(x: fX + 358, y: cmbY + 12),
        size: 26, color: nsSecondary, ns: ns)

    hRule(cg, x: fX + 24, y: cmbY + 70, w: fW - 48)

    // ── Rule 1: File Size > 500 MB
    let r1Y = cmbY + 90
    for (i, (label, w)) in [("File Size", 216), ("greater than", 216), ("500 MB", 160)].enumerated() {
        let rx = fX + 48 + CGFloat(i) * 232
        fillRR(cg, CGRect(x: rx, y: r1Y, width: CGFloat(w), height: 56), radius: 8, cFieldBg)
        txt(label, at: CGPoint(x: rx + 16, y: r1Y + 14), size: 24, color: nsPrimary, ns: ns)
    }
    cg.setFillColor(cTertiary)
    cg.fillEllipse(in: CGRect(x: fX + 48 + 3*232, y: r1Y + 12, width: 32, height: 32))
    txt("×", at: CGPoint(x: fX + 48 + 3*232 + 9, y: r1Y + 10),
        size: 22, weight: .bold, color: nsWhite, ns: ns)

    // ── Rule 2: Name contains (empty)
    let r2Y = r1Y + 76
    for (i, (label, w)) in [("Name", 216), ("contains", 216), ("", 160)].enumerated() {
        let rx = fX + 48 + CGFloat(i) * 232
        fillRR(cg, CGRect(x: rx, y: r2Y, width: CGFloat(w), height: 56), radius: 8, cFieldBg)
        if !label.isEmpty {
            txt(label, at: CGPoint(x: rx + 16, y: r2Y + 14), size: 24, color: nsPrimary, ns: ns)
        }
    }
    cg.setFillColor(cTertiary)
    cg.fillEllipse(in: CGRect(x: fX + 48 + 3*232, y: r2Y + 12, width: 32, height: 32))

    // ── Add Rule
    txt("+ Add Rule", at: CGPoint(x: fX + 48, y: r2Y + 76),
        size: 26, weight: .medium, color: nsAccent, ns: ns)

    // ── Divider between panes
    vRule(cg, x: mX + fW + 32, y: mY + 82, h: mH - 82 - 82)

    // ── Preview pane
    let pX = mX + fW + 56, pW = mW - fW - 80
    txt("PREVIEW", at: CGPoint(x: pX, y: mY + 102),
        size: 20, weight: .semibold, color: nsTertiary, ns: ns)

    let prevApps: [AppItem] = [
        AppItem(name: "Xcode",       colorIdx: 6),
        AppItem(name: "Instruments", colorIdx: 3),
        AppItem(name: "Final Cut",   colorIdx: 3),
        AppItem(name: "Logic Pro",   colorIdx: 8),
        AppItem(name: "Photoshop",   colorIdx: 6),
        AppItem(name: "After Efx",   colorIdx: 5),
        AppItem(name: "Illustrator", colorIdx: 3),
        AppItem(name: "Simulator",   colorIdx: 7),
    ]
    let pCols = 4; let pSz: CGFloat = 108; let pGapH: CGFloat = 20; let pGapV: CGFloat = 36
    for (i, app) in prevApps.enumerated() {
        let col = i % pCols, row = i / pCols
        let tx = pX + CGFloat(col) * (pSz + pGapH)
        let ty = mY + 140 + CGFloat(row) * (pSz + pGapV + 28)
        drawTileIcon(cg, frame: CGRect(x: tx, y: ty, width: pSz, height: pSz), colorIdx: app.colorIdx)
        txt(app.name, at: CGPoint(x: tx - 4, y: ty + pSz + 4),
            size: 19, color: nsSecondary, maxW: pSz + 8, align: .center, ns: ns)
    }
    let countTxt = "8 apps match · updates live"
    txt(countTxt, at: CGPoint(x: pX, y: mY + mH - 120),
        size: 22, color: nsTertiary, maxW: pW, ns: ns)

    // ── Footer
    hRule(cg, x: mX, y: mY + mH - 84, w: mW)
    txt("Cancel", at: CGPoint(x: mX + mW - 380, y: mY + mH - 58),
        size: 26, color: nsSecondary, ns: ns)
    fillRR(cg, CGRect(x: mX + mW - 236, y: mY + mH - 74, width: 188, height: 56),
           radius: 12, cAccent)
    txt("Save", at: CGPoint(x: mX + mW - 200, y: mY + mH - 58),
        size: 26, weight: .semibold, color: nsWhite, ns: ns)

    finishWindow(cg)
    return toPNG(cg)
}

// ════════════════════════════════════════════════════════════════
// MARK: – Screen 5  First-Time Setup
// ════════════════════════════════════════════════════════════════

func renderScreen5() -> Data {
    let (cg, ns) = makeContext()
    beginWindow(cg, ns: ns)
    drawSidebar(cg, ns: ns, sections: makeSidebar())

    // Modal: 660×520 pt → 1320×1040 px
    let mW: CGFloat = 1320, mH: CGFloat = 1040
    let mX = WX + (WW - mW) / 2, mY = WY + (WH - mH) / 2
    let mr = CGRect(x: mX, y: mY, width: mW, height: mH)
    drawModal(cg, ns: ns, rect: mr)

    // Title
    txt("Let's organize your apps",
        at: CGPoint(x: mX, y: mY + 32),
        size: 34, weight: .semibold, color: nsPrimary,
        maxW: mW, align: .center, ns: ns)
    txt("We've grouped your apps into starting categories. Adjust or skip.",
        at: CGPoint(x: mX + 80, y: mY + 88),
        size: 26, color: nsSecondary,
        maxW: mW - 160, align: .center, ns: ns)

    hRule(cg, x: mX, y: mY + 140, w: mW)

    // 2-row × 3-col group cards
    typealias Card = (emoji: String, name: String, count: Int, selected: Bool)
    let cards: [Card] = [
        ("🎨", "Design",       12, true),
        ("💻", "Dev Tools",    18, true),
        ("🎵", "Media",        15, true),
        ("📊", "Productivity", 10, true),
        ("🌐", "Browsers",      4, true),
        ("⚙️",  "Utilities",    0, false),
    ]
    let cW: CGFloat = 362, cH: CGFloat = 264
    let cGH: CGFloat = 28, cGV: CGFloat = 20
    let gridW = 3 * cW + 2 * cGH
    let gridX = mX + (mW - gridW) / 2
    let gridY = mY + 160

    for (i, card) in cards.enumerated() {
        let col = i % 3, row = i / 3
        let cx = gridX + CGFloat(col) * (cW + cGH)
        let cy = gridY + CGFloat(row) * (cH + cGV)
        let rect = CGRect(x: cx, y: cy, width: cW, height: cH)
        let isEmpty = card.count == 0

        fillRR(cg, rect, radius: 16, card.selected ? cCardSel : cCardBg)
        strokeRR(cg, rect, radius: 16,
                 card.selected ? cAccent : cBorder,
                 lw: card.selected ? 3 : 1)

        // Emoji
        cg.saveGState(); cg.setAlpha(isEmpty ? 0.35 : 1.0)
        txt(card.emoji, at: CGPoint(x: cx + 28, y: cy + 22), size: 52, color: nsPrimary, ns: ns)
        cg.restoreGState()

        // Checkmark circle
        let ckColor = card.selected ? cAccent : cTertiary
        cg.setFillColor(ckColor)
        cg.fillEllipse(in: CGRect(x: cx + cW - 66, y: cy + 22, width: 44, height: 44))
        if card.selected {
            txt("✓", at: CGPoint(x: cx + cW - 56, y: cy + 28),
                size: 26, weight: .bold, color: nsWhite, ns: ns)
        }

        // Name + count
        cg.saveGState(); cg.setAlpha(isEmpty ? 0.35 : 1.0)
        txt(card.name, at: CGPoint(x: cx + 28, y: cy + cH - 90),
            size: 28, weight: .semibold, color: nsPrimary, ns: ns)
        txt(isEmpty ? "No apps" : "\(card.count) apps",
            at: CGPoint(x: cx + 28, y: cy + cH - 52),
            size: 24, color: nsSecondary, ns: ns)
        cg.restoreGState()
    }

    // Page indicators
    let piY = gridY + 2 * cH + 2 * cGV + 20
    cg.setFillColor(cAccent)
    cg.fillEllipse(in: CGRect(x: mX + mW/2 - 22, y: piY, width: 16, height: 16))
    cg.setFillColor(cTertiary)
    cg.fillEllipse(in: CGRect(x: mX + mW/2 + 6,  y: piY, width: 16, height: 16))

    hRule(cg, x: mX, y: mY + mH - 96, w: mW)

    // Footer
    txt("Skip All", at: CGPoint(x: mX + 48, y: mY + mH - 66),
        size: 26, color: nsSecondary, ns: ns)
    txt("Step 1 of 2",
        at: CGPoint(x: mX + mW/2 - 60, y: mY + mH - 66),
        size: 24, color: nsSecondary, ns: ns)
    fillRR(cg, CGRect(x: mX + mW - 380, y: mY + mH - 80, width: 332, height: 60),
           radius: 12, cAccent)
    txt("Accept Selected",
        at: CGPoint(x: mX + mW - 365, y: mY + mH - 64),
        size: 26, weight: .semibold, color: nsWhite, ns: ns)

    finishWindow(cg)
    return toPNG(cg)
}

// ════════════════════════════════════════════════════════════════
// MARK: – Write files
// ════════════════════════════════════════════════════════════════

let root = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let outDir = root.appendingPathComponent("AppStoreAssets/Screenshots")
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let screens: [(String, () -> Data)] = [
    ("01_all_apps.png",          renderScreen1),
    ("02_design_group.png",      renderScreen2),
    ("03_search_results.png",    renderScreen3),
    ("04_smart_group_editor.png",renderScreen4),
    ("05_first_time_setup.png",  renderScreen5),
]
for (name, render) in screens {
    try render().write(to: outDir.appendingPathComponent(name))
    print("✓  \(name)")
}
print("\nDone → AppStoreAssets/Screenshots/")
