/// In-memory search index: subsequence inclusion filter + Levenshtein ranking + favorites boost.
import Foundation

// MARK: - Public types

public struct SearchResult {
    public let entry: AppEntry
    /// Lower score = higher rank. Favorites receive a -100 boost.
    public let score: Int
}

// MARK: - SearchIndex

public struct SearchIndex {
    private var entries: [AppEntry] = []
    private var favoriteIDs: Set<String> = []

    public init() {}

    /// Rebuild the index from the current library snapshot. Call after every scan or favorites change.
    public mutating func build(from entries: [AppEntry], favorites: Set<String>) {
        self.entries = entries
        self.favoriteIDs = favorites
    }

    /// Returns up to `limit` results ranked by Levenshtein distance, favorites boosted to the front.
    public func search(_ query: String, limit: Int = 50) -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()

        var results: [SearchResult] = []
        results.reserveCapacity(min(entries.count, limit * 2))

        for entry in entries {
            let name = entry.displayName.lowercased()
            guard isSubsequence(q, in: name) else { continue }

            let distance = levenshtein(q, name)
            let boost = favoriteIDs.contains(entry.bundleIdentifier) ? 100 : 0
            results.append(SearchResult(entry: entry, score: distance - boost))
        }

        results.sort { $0.score < $1.score }
        if results.count > limit { results.removeLast(results.count - limit) }
        return results
    }

    /// Returns the set of all matching bundle IDs (no limit) — used by the view layer for opacity control.
    public func matchingIDs(for query: String) -> Set<String> {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        var ids = Set<String>()
        for entry in entries where isSubsequence(q, in: entry.displayName.lowercased()) {
            ids.insert(entry.bundleIdentifier)
        }
        return ids
    }

    /// Single-pass variant: computes both ranked results (capped at `limit`) and the
    /// full match-ID set in one loop. Use this in views that need both values.
    public func searchCombined(_ query: String, limit: Int = 50) -> SearchCombinedResult {
        guard !query.isEmpty else { return SearchCombinedResult(ranked: [], allMatchIDs: []) }
        let q = query.lowercased()

        var ranked = [SearchResult]()
        var allMatchIDs = Set<String>()
        ranked.reserveCapacity(min(entries.count, limit * 2))

        for entry in entries {
            let name = entry.displayName.lowercased()
            guard isSubsequence(q, in: name) else { continue }
            allMatchIDs.insert(entry.bundleIdentifier)
            let distance = levenshtein(q, name)
            let boost = favoriteIDs.contains(entry.bundleIdentifier) ? 100 : 0
            ranked.append(SearchResult(entry: entry, score: distance - boost))
        }

        ranked.sort { $0.score < $1.score }
        if ranked.count > limit { ranked.removeLast(ranked.count - limit) }
        return SearchCombinedResult(ranked: ranked, allMatchIDs: allMatchIDs)
    }
}

// MARK: - Combined result

public struct SearchCombinedResult {
    /// Top `limit` results sorted by score; favorites boosted to front.
    public let ranked: [SearchResult]
    /// All matching bundle IDs without a count cap (used for opacity control in the full grid).
    public let allMatchIDs: Set<String>
}

// MARK: - Algorithms (module-private)

/// Returns true when every character of `needle` appears in `haystack` in order.
func isSubsequence(_ needle: String, in haystack: String) -> Bool {
    guard !needle.isEmpty else { return true }
    var nIdx = needle.startIndex
    for ch in haystack {
        if ch == needle[nIdx] {
            nIdx = needle.index(after: nIdx)
            if nIdx == needle.endIndex { return true }
        }
    }
    return false
}

/// Classic single-row DP Levenshtein edit distance, O(|a|·|b|) time, O(|b|) space.
func levenshtein(_ a: String, _ b: String) -> Int {
    let aArr = Array(a)
    let bArr = Array(b)
    guard !aArr.isEmpty else { return bArr.count }
    guard !bArr.isEmpty else { return aArr.count }

    var row = Array(0...bArr.count)
    for i in 1...aArr.count {
        var prev = row[0]
        row[0] = i
        for j in 1...bArr.count {
            let temp = row[j]
            row[j] = aArr[i - 1] == bArr[j - 1]
                ? prev
                : Swift.min(prev, Swift.min(row[j - 1], row[j])) + 1
            prev = temp
        }
    }
    return row[bArr.count]
}
