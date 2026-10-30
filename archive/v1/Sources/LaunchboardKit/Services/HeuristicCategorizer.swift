/// Buckets a list of AppEntry objects into suggested groups using LSApplicationCategoryType
/// and bundleIdentifier prefix heuristics. Pure function — no side effects.
import Foundation

// MARK: - Output type

public struct SuggestedBucket: Identifiable, Sendable {
    /// Stable string ID derived from the bucket name — safe to use across multiple categorize() calls.
    public let id: String
    public let name: String
    public let emoji: String
    public let appBundleIDs: [String]
}

// MARK: - Categorizer

public enum HeuristicCategorizer {

    /// Returns exactly 6 buckets (one per BucketKind) in display order.
    /// Buckets with zero apps are included; callers may choose to hide or disable them.
    public static func categorize(apps: [AppEntry]) -> [SuggestedBucket] {
        var assignment: [BucketKind: [String]] = Dictionary(
            uniqueKeysWithValues: BucketKind.displayOrder.map { ($0, [String]()) }
        )
        for app in apps {
            let kind = classify(app)
            assignment[kind, default: []].append(app.bundleIdentifier)
        }
        return BucketKind.displayOrder.map { kind in
            SuggestedBucket(
                id: kind.stableID,
                name: kind.displayName,
                emoji: kind.emoji,
                appBundleIDs: assignment[kind] ?? []
            )
        }
    }

    // MARK: - Classification

    /// Two-phase classification: category string (authoritative) then bundleID prefix (heuristic).
    private static func classify(_ app: AppEntry) -> BucketKind {
        let cat = (app.category ?? "").lowercased()
        let bun = app.bundleIdentifier.lowercased()

        // Phase 1 — LSApplicationCategoryType match (priority order matters)
        if !cat.isEmpty {
            for rule in rules where rule.categorySubstrings.contains(where: { cat.contains($0) }) {
                return rule.bucket
            }
        }

        // Phase 2 — bundleIdentifier prefix match
        for rule in rules where rule.bundlePrefixes.contains(where: { bun.hasPrefix($0) }) {
            return rule.bucket
        }

        return .utilities
    }

    // MARK: - Rule table

    private struct Rule {
        let bucket: BucketKind
        /// Matched against entry.category?.lowercased() via contains(_:).
        let categorySubstrings: [String]
        /// Matched against entry.bundleIdentifier.lowercased() via hasPrefix(_:).
        let bundlePrefixes: [String]
    }

    // Rules are checked in order — most specific first to avoid false-positives.
    private static let rules: [Rule] = [
        Rule(
            bucket: .development,
            categorySubstrings: ["developer-tools"],
            bundlePrefixes: [
                "com.apple.dt.", "com.apple.simulator",
                "com.jetbrains.", "com.microsoft.vscode",
                "com.googlecode.iterm2", "com.sublimetext.",
                "com.panic.", "com.tokyocabinet.",
                "io.cursor.", "com.github.",
                "com.sourcetreeapp.", "com.tower.",
                "com.fournova.tower", "com.charlesproxy.",
            ]
        ),
        Rule(
            bucket: .design,
            categorySubstrings: ["graphics-design", "photography"],
            bundlePrefixes: [
                "com.figma.", "com.bohemiancoding.sketch3",
                "com.adobe.", "com.pixelmator.",
                "io.affinity.", "com.serif.",
                "com.relative-wave.", "com.canva.",
                "com.zeplin.", "com.invisionapp.",
            ]
        ),
        Rule(
            bucket: .communication,
            categorySubstrings: ["social-networking"],
            bundlePrefixes: [
                "com.apple.mail", "com.apple.ichat",
                "com.apple.facetime", "com.apple.messages",
                "com.hnc.discord", "com.tinyspeck.",
                "com.twitterdev.", "com.tapbots.",
                "ph.telegra.", "us.zoom.",
                "com.microsoft.teams", "com.skype.",
                "ru.keepcoder.", "com.airmail.",
                "com.readdle.smartmail", "com.mimestream.",
                "com.basecamp.", "com.linear.",
            ]
        ),
        Rule(
            bucket: .media,
            categorySubstrings: ["music", "video", "entertainment"],
            bundlePrefixes: [
                "com.spotify.", "org.videolan.",
                "com.colliderli.iina", "com.apple.itunes",
                "com.apple.music", "com.apple.tv",
                "tv.plex.", "com.plex.",
                "com.reeder.", "com.netnewswire.",
                "com.apple.quicktimeplayer", "com.apple.podcasts",
                "com.apple.photos", "com.apple.photoslibrary",
                "com.overcast.", "com.marco.overcast",
            ]
        ),
        Rule(
            bucket: .productivity,
            categorySubstrings: ["productivity", "business", "finance", "education"],
            bundlePrefixes: [
                "com.apple.pages", "com.apple.numbers",
                "com.apple.keynote", "com.apple.notes",
                "com.apple.calendar", "com.apple.reminders",
                "com.microsoft.word", "com.microsoft.excel",
                "com.microsoft.powerpoint", "com.microsoft.outlook",
                "com.notion.", "com.culturedcode.",
                "com.omnigroup.", "com.airtable.",
                "com.todoist.", "com.1password.",
                "com.agilebits.", "com.flexibits.",
                "com.craft.", "md.ia.writer",
            ]
        ),
        // Utilities is the implicit catch-all — no rule needed; classify() returns .utilities when no rule matches.
    ]
}

// MARK: - Bucket metadata

private enum BucketKind: CaseIterable {
    case productivity, development, design, media, communication, utilities

    /// Order shown in the 2×3 grid (row-major: Productivity, Development, Design / Media, Communication, Utilities).
    static let displayOrder: [BucketKind] = [
        .productivity, .development, .design,
        .media, .communication, .utilities,
    ]

    var stableID: String { displayName }

    var displayName: String {
        switch self {
        case .productivity:   return "Productivity"
        case .development:    return "Development"
        case .design:         return "Design"
        case .media:          return "Media"
        case .communication:  return "Communication"
        case .utilities:      return "Utilities"
        }
    }

    var emoji: String {
        switch self {
        case .productivity:   return "💼"
        case .development:    return "💻"
        case .design:         return "🎨"
        case .media:          return "🎵"
        case .communication:  return "💬"
        case .utilities:      return "🔧"
        }
    }
}
