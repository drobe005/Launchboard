import Foundation

enum SeedData {

    // MARK: – Stable IDs (fixed so group appIDs survive across relaunches)
    static let id_figma      = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let id_sketch     = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let id_xcode      = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    static let id_vscode     = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    static let id_safari     = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
    static let id_spotify    = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
    static let id_slack      = UUID(uuidString: "00000000-0000-0000-0000-000000000007")!
    static let id_notion     = UUID(uuidString: "00000000-0000-0000-0000-000000000008")!
    static let id_photoshop  = UUID(uuidString: "00000000-0000-0000-0000-000000000009")!
    static let id_terminal   = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
    static let id_zoom       = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
    static let id_chrome     = UUID(uuidString: "00000000-0000-0000-0000-000000000012")!
    static let id_obsidian   = UUID(uuidString: "00000000-0000-0000-0000-000000000013")!
    static let id_linear     = UUID(uuidString: "00000000-0000-0000-0000-000000000014")!
    static let id_affinity   = UUID(uuidString: "00000000-0000-0000-0000-000000000015")!

    // MARK: – Apps
    static let apps: [AppItem] = [
        AppItem(id: id_figma,     name: "Figma",      bundleID: "com.figma.Desktop",               category: .design,        isFavorite: true,  hasBadge: false, gradientKey: "c0",  dateAdded: .now),
        AppItem(id: id_sketch,    name: "Sketch",     bundleID: "com.bohemiancoding.sketch3",       category: .design,        isFavorite: true,  hasBadge: false, gradientKey: "c12", dateAdded: .now),
        AppItem(id: id_xcode,     name: "Xcode",      bundleID: "com.apple.dt.Xcode",               category: .development,   isFavorite: false, hasBadge: true,  gradientKey: "c13", dateAdded: .now),
        AppItem(id: id_vscode,    name: "VS Code",    bundleID: "com.microsoft.VSCode",             category: .development,   isFavorite: true,  hasBadge: true,  gradientKey: "c3",  dateAdded: .now),
        AppItem(id: id_safari,    name: "Safari",     bundleID: "com.apple.Safari",                 category: .utilities,     isFavorite: true,  hasBadge: false, gradientKey: "c6",  dateAdded: .now),
        AppItem(id: id_spotify,   name: "Spotify",    bundleID: "com.spotify.client",               category: .media,         isFavorite: false, hasBadge: false, gradientKey: "c2",  dateAdded: .now),
        AppItem(id: id_slack,     name: "Slack",      bundleID: "com.tinyspeck.slackmacgap",        category: .communication, isFavorite: false, hasBadge: false, gradientKey: "c9",  dateAdded: .now),
        AppItem(id: id_notion,    name: "Notion",     bundleID: "notion.id",                        category: .productivity,  isFavorite: true,  hasBadge: false, gradientKey: "c7",  dateAdded: .now),
        AppItem(id: id_photoshop, name: "Photoshop",  bundleID: "com.adobe.Photoshop",              category: .design,        isFavorite: false, hasBadge: false, gradientKey: "c1",  dateAdded: .now),
        AppItem(id: id_terminal,  name: "Terminal",   bundleID: "com.apple.Terminal",               category: .development,   isFavorite: false, hasBadge: false, gradientKey: "c11", dateAdded: .now),
        AppItem(id: id_zoom,      name: "Zoom",       bundleID: "us.zoom.xos",                      category: .communication, isFavorite: true,  hasBadge: false, gradientKey: "c3",  dateAdded: .now),
        AppItem(id: id_chrome,    name: "Chrome",     bundleID: "com.google.Chrome",                category: .utilities,     isFavorite: true,  hasBadge: false, gradientKey: "c1",  dateAdded: .now),
        AppItem(id: id_obsidian,  name: "Obsidian",   bundleID: "md.obsidian",                      category: .productivity,  isFavorite: false, hasBadge: false, gradientKey: "c4",  dateAdded: .now),
        AppItem(id: id_linear,    name: "Linear",     bundleID: "com.linear",                       category: .productivity,  isFavorite: false, hasBadge: false, gradientKey: "c14", dateAdded: .now),
        AppItem(id: id_affinity,  name: "Affinity",   bundleID: "com.seriflabs.affinitydesigner",   category: .design,        isFavorite: false, hasBadge: false, gradientKey: "c10", dateAdded: .now),
    ]

    // MARK: – Groups
    static let groups: [AppGroup] = [
        AppGroup(
            id: UUID(uuidString: "00000000-0000-0000-0001-000000000001")!,
            name: "Design",
            icon: "paintbrush.fill",
            colorHex: "#a78bfa",
            appIDs: [id_figma, id_sketch, id_photoshop, id_affinity]
        ),
        AppGroup(
            id: UUID(uuidString: "00000000-0000-0000-0001-000000000002")!,
            name: "Dev",
            icon: "chevron.left.forwardslash.chevron.right",
            colorHex: "#38bdf8",
            appIDs: [id_xcode, id_vscode, id_terminal]
        ),
        AppGroup(
            id: UUID(uuidString: "00000000-0000-0000-0001-000000000003")!,
            name: "Comms",
            icon: "bubble.left.and.bubble.right.fill",
            colorHex: "#fb923c",
            appIDs: [id_slack, id_zoom]
        ),
        AppGroup(
            id: UUID(uuidString: "00000000-0000-0000-0001-000000000004")!,
            name: "Media",
            icon: "play.rectangle.fill",
            colorHex: "#f43f5e",
            appIDs: [id_spotify]
        ),
        AppGroup(
            id: UUID(uuidString: "00000000-0000-0000-0001-000000000005")!,
            name: "Utilities",
            icon: "wrench.and.screwdriver.fill",
            colorHex: "#94a3b8",
            appIDs: [id_safari, id_chrome]
        ),
    ]
}
