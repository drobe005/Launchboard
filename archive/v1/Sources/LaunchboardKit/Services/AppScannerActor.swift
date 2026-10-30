/// Actor responsible for scanning disk locations and returning discovered AppEntry objects.
import Foundation
import AppKit
import SwiftData

public actor AppScannerActor {
    public init() {}

    public func scan(locations: [URL]) async -> [AppEntry] {
        // 1. Collect bundle URLs serially (directory listings are fast).
        var allBundles: [URL] = []
        for location in locations {
            allBundles.append(contentsOf: appBundles(in: location))
        }

        // 2. Process bundles in parallel using a Sendable intermediate type.
        //    makeSpec is nonisolated static so tasks run off the actor concurrently.
        let specs = await withTaskGroup(of: AppSpec?.self, returning: [AppSpec].self) { group in
            for bundleURL in allBundles {
                group.addTask { AppScannerActor.makeSpec(bundleURL: bundleURL) }
            }
            var result = [AppSpec]()
            result.reserveCapacity(allBundles.count)
            for await spec in group {
                if let spec { result.append(spec) }
            }
            return result
        }

        // 3. Convert to AppEntry (last-write-wins on duplicate bundle IDs).
        //    iconData is intentionally nil — IconCache loads it lazily per-tile.
        var discovered = [String: AppEntry](minimumCapacity: specs.count)
        for spec in specs {
            discovered[spec.bundleIdentifier] = AppEntry(
                bundleIdentifier: spec.bundleIdentifier,
                displayName:      spec.displayName,
                iconData:         nil,
                bundleURL:        spec.bundleURL,
                installedAt:      spec.installedAt,
                fileSize:         spec.fileSize,
                version:          spec.version,
                isAppleBuiltIn:   spec.isAppleBuiltIn,
                category:         spec.category
            )
        }
        return Array(discovered.values)
    }

    // MARK: - Bundle discovery

    private func appBundles(in directory: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ))?.filter { $0.pathExtension == "app" } ?? []
    }

    // MARK: - Per-bundle processing (nonisolated — runs concurrently off the actor)

    private nonisolated static func makeSpec(bundleURL: URL) -> AppSpec? {
        let fm = FileManager.default
        let plistURL = bundleURL.appendingPathComponent("Contents/Info.plist")

        guard
            let plistData = fm.contents(atPath: plistURL.path),
            let plist = try? PropertyListSerialization.propertyList(
                from: plistData, format: nil
            ) as? [String: Any],
            let bundleID = plist["CFBundleIdentifier"] as? String
        else { return nil }

        let displayName = (plist["CFBundleDisplayName"] as? String)
            ?? (plist["CFBundleName"] as? String)
            ?? bundleURL.deletingPathExtension().lastPathComponent

        let version  = plist["CFBundleShortVersionString"] as? String ?? ""
        let category = plist["LSApplicationCategoryType"] as? String

        let attrs = try? fm.attributesOfItem(atPath: bundleURL.path)
        let installedAt = attrs?[.creationDate] as? Date ?? Date()

        // Single resource-value call replaces recursive file enumeration.
        let fileSize = Int64(
            (try? bundleURL.resourceValues(forKeys: [.totalFileSizeKey]))?.totalFileSize ?? 0
        )

        return AppSpec(
            bundleIdentifier: bundleID,
            displayName:      displayName,
            bundleURL:        bundleURL,
            installedAt:      installedAt,
            fileSize:         fileSize,
            version:          version,
            isAppleBuiltIn:   bundleID.hasPrefix("com.apple."),
            category:         category
        )
    }
}

// MARK: - Sendable intermediate (no @Model baggage; safe across task boundaries)

private struct AppSpec: Sendable {
    let bundleIdentifier: String
    let displayName: String
    let bundleURL: URL
    let installedAt: Date
    let fileSize: Int64
    let version: String
    let isAppleBuiltIn: Bool
    let category: String?
}

// MARK: - SwiftData persistence

extension AppScannerActor {
    /// Scans locations, then upserts/deletes entries in the provided ModelContext.
    public func scanAndPersist(locations: [URL], context: ModelContext) async throws {
        let fresh = await scan(locations: locations)
        let freshByID = Dictionary(uniqueKeysWithValues: fresh.map { ($0.bundleIdentifier, $0) })

        let existing = try context.fetch(FetchDescriptor<AppEntry>())
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.bundleIdentifier, $0) })

        for (bundleID, newEntry) in freshByID {
            if let stored = existingByID[bundleID] {
                stored.displayName    = newEntry.displayName
                stored.bundleURL      = newEntry.bundleURL
                stored.fileSize       = newEntry.fileSize
                stored.version        = newEntry.version
                stored.isAppleBuiltIn = newEntry.isAppleBuiltIn
                stored.category       = newEntry.category
                // iconData intentionally not updated — stays nil; IconCache handles icons.
            } else {
                newEntry.recentlyAddedAt = Date()
                context.insert(newEntry)
            }
        }

        for (bundleID, stored) in existingByID where freshByID[bundleID] == nil {
            context.delete(stored)
        }

        try context.save()
    }
}
