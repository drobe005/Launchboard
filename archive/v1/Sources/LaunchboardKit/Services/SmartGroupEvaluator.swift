/// Pure-Swift smart group rule evaluator: no UI, no SwiftData context required.
import Foundation

// MARK: - Combinator

public enum Combinator: Sendable {
    /// Every rule must match (logical AND).
    case all
    /// At least one rule must match (logical OR).
    case any
}

// MARK: - Evaluator

public enum SmartGroupEvaluator {

    /// Returns the subset of `apps` that satisfies `rules` under `combinator`.
    /// Returns an empty array when `rules` is empty (no rules → no match).
    public static func evaluate(
        rules: [SmartGroupRule],
        combinator: Combinator,
        apps: [AppEntry]
    ) -> [AppEntry] {
        guard !rules.isEmpty else { return [] }
        return apps.filter { entry in
            let outcomes = rules.map { matches(entry, rule: $0) }
            switch combinator {
            case .all: return outcomes.allSatisfy { $0 }
            case .any: return outcomes.contains { $0 }
            }
        }
    }

    // MARK: - Dispatch

    private static func matches(_ entry: AppEntry, rule: SmartGroupRule) -> Bool {
        switch rule.field {
        case .name:       return evaluateName(entry.displayName, op: rule.op, value: rule.value)
        case .lastOpened: return evaluateLastOpened(entry.lastOpenedAt, op: rule.op, value: rule.value)
        case .fileSize:   return evaluateFileSize(entry.fileSize, op: rule.op, value: rule.value)
        case .source:     return evaluateSource(entry, op: rule.op, value: rule.value)
        case .category:   return evaluateCategory(entry.category, op: rule.op, value: rule.value)
        }
    }

    // MARK: - Name

    // Supported: equals, notEquals, contains, startsWith
    private static func evaluateName(_ name: String, op: RuleOperator, value: String) -> Bool {
        guard !value.isEmpty else { return false }
        let lhs = name.lowercased()
        let rhs = value.lowercased()
        switch op {
        case .equals:     return lhs == rhs
        case .notEquals:  return lhs != rhs
        case .contains:   return lhs.contains(rhs)
        case .startsWith: return lhs.hasPrefix(rhs)
        default:          return false
        }
    }

    // MARK: - Last Opened

    // greaterThan / lessThan: value is a number of days from now.
    // equals:                 value is an ISO 8601 full-date string (yyyy-MM-dd).
    // nil lastOpenedAt → always false (app has never been opened).
    private static func evaluateLastOpened(
        _ opened: Date?,
        op: RuleOperator,
        value: String
    ) -> Bool {
        guard let opened else { return false }

        switch op {
        case .greaterThan, .lessThan:
            guard let days = Double(value) else { return false }
            let cutoff = Date().addingTimeInterval(-days * 86_400)
            return op == .greaterThan ? opened >= cutoff : opened < cutoff

        case .equals:
            // Parse value as a local-timezone calendar date ("yyyy-MM-dd").
            // ISO8601DateFormatter returns UTC midnight which shifts day boundaries —
            // DateFormatter with .current timezone gives the correct local-day comparison.
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            fmt.timeZone = .current
            guard let target = fmt.date(from: value) else { return false }
            return Calendar.current.isDate(opened, inSameDayAs: target)

        default:
            return false
        }
    }

    // MARK: - File Size

    // value is in megabytes (decimal: "100" → 100 × 1 048 576 bytes).
    // equals uses exact byte-level comparison after MB→bytes conversion.
    private static func evaluateFileSize(
        _ fileSize: Int64,
        op: RuleOperator,
        value: String
    ) -> Bool {
        guard let mb = Double(value) else { return false }
        let bytes = Int64(mb * 1_048_576)
        switch op {
        case .equals:      return fileSize == bytes
        case .greaterThan: return fileSize > bytes
        case .lessThan:    return fileSize < bytes
        default:           return false
        }
    }

    // MARK: - Source

    // Recognised values (case-insensitive): "Apple", "Mac App Store", "Other".
    // Supported operators: equals, notEquals.
    private static func evaluateSource(
        _ entry: AppEntry,
        op: RuleOperator,
        value: String
    ) -> Bool {
        let entrySource = deriveSource(entry)
        switch op {
        case .equals:    return entrySource.caseInsensitiveCompare(value) == .orderedSame
        case .notEquals: return entrySource.caseInsensitiveCompare(value) != .orderedSame
        default:         return false
        }
    }

    // MARK: - Category

    // value is an LSApplicationCategoryType string (case-insensitive).
    // nil category → always false.
    private static func evaluateCategory(
        _ category: String?,
        op: RuleOperator,
        value: String
    ) -> Bool {
        guard let category, !value.isEmpty else { return false }
        switch op {
        case .equals:    return category.caseInsensitiveCompare(value) == .orderedSame
        case .notEquals: return category.caseInsensitiveCompare(value) != .orderedSame
        default:         return false
        }
    }

    // MARK: - Source detection

    /// Derives the source label for an app entry.
    /// Priority: Apple built-in → Mac App Store receipt → Other.
    private static func deriveSource(_ entry: AppEntry) -> String {
        if entry.isAppleBuiltIn { return "Apple" }
        let receipt = entry.bundleURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("_MASReceipt")
            .appendingPathComponent("receipt")
        return FileManager.default.fileExists(atPath: receipt.path) ? "Mac App Store" : "Other"
    }
}
