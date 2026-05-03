import AppKit
import Foundation

/// Scans the file system for installed .app bundles and loads their icons.
/// Runs entirely off the main thread as a Swift actor.
actor AppDiscoveryService {

    static let shared = AppDiscoveryService()

    private let scanRoots: [URL] = [
        URL(fileURLWithPath: "/Applications"),
        URL(fileURLWithPath: "/System/Applications"),
        URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications"),
    ]

    // MARK: – Discovery

    /// Returns all discoverable apps across standard scan directories.
    /// Does not set iconData — call loadIcon(for:) separately.
    func discoverApps() -> [AppItem] {
        var seen: Set<String> = []
        var result: [AppItem] = []

        for root in scanRoots {
            scan(directory: root, seen: &seen, result: &result)
        }

        return result.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    private func scan(directory: URL, seen: inout Set<String>, result: inout [AppItem]) {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for entry in entries {
            if entry.pathExtension == "app" {
                if let item = makeItem(url: entry), !seen.contains(item.bundleID) {
                    seen.insert(item.bundleID)
                    result.append(item)
                }
            } else {
                // One level of subdirectory (e.g. /Applications/Utilities/)
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: entry.path, isDirectory: &isDir), isDir.boolValue {
                    scan(directory: entry, seen: &seen, result: &result)
                }
            }
        }
    }

    private func makeItem(url: URL) -> AppItem? {
        guard
            let bundle   = Bundle(url: url),
            let bundleID = bundle.bundleIdentifier
        else { return nil }

        let name: String = {
            if let display = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
               !display.isEmpty { return display }
            if let short = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String,
               !short.isEmpty { return short }
            return url.deletingPathExtension().lastPathComponent
        }()

        return AppItem(
            name:         name,
            bundleID:     bundleID,
            category:     defaultCategory(for: bundleID),
            gradientKey:  deterministicGradient(for: bundleID),
            dateAdded:    .now
        )
    }

    // MARK: – Icon loading

    /// Loads and resizes the icon for a single app. Safe to call concurrently.
    func loadIcon(for item: AppItem) -> Data? {
        let path: String?

        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: item.bundleID) {
            path = url.path
        } else {
            path = nil
        }

        guard let p = path else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: p)
        return icon.pngData(sideLength: 128)
    }

    // MARK: – Helpers

    private func deterministicGradient(for bundleID: String) -> String {
        let total = 15
        let hash  = bundleID.utf8.reduce(0) { ($0 &* 31) &+ Int($1) }
        return "c\(abs(hash) % total)"
    }

    private func defaultCategory(for bundleID: String) -> AppCategory {
        let id = bundleID.lowercased()
        if id.contains("xcode") || id.contains("vscode") || id.contains("terminal")
            || id.contains("simulator") || id.contains("instruments") { return .development }
        if id.contains("figma") || id.contains("sketch") || id.contains("adobe")
            || id.contains("affinity") || id.contains("pixelmator") { return .design }
        if id.contains("slack") || id.contains("zoom") || id.contains("teams")
            || id.contains("discord") || id.contains("facetime") || id.contains("messages") { return .communication }
        if id.contains("spotify") || id.contains("music") || id.contains("vlc")
            || id.contains("quicktime") || id.contains("podcast") { return .media }
        if id.contains("notion") || id.contains("obsidian") || id.contains("linear")
            || id.contains("things") || id.contains("reminders") { return .productivity }
        return .utilities
    }
}
