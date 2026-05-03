import Foundation

/// Saves and loads library state to ~/Library/Application Support/Launchboard/.
/// All operations are synchronous and safe to call from any thread.
final class PersistenceService: Sendable {

    static let shared = PersistenceService()

    private let baseURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let hasCompletedSetup = "com.launchboard.hasCompletedSetup"
        static let hiddenAppIDs      = "com.launchboard.hiddenAppIDs"
    }

    init() {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        baseURL = support.appendingPathComponent("Launchboard", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: baseURL,
            withIntermediateDirectories: true
        )
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy  = .iso8601
        decoder.dateDecodingStrategy  = .iso8601
    }

    /// Designated init for testing — writes to `baseURL` instead of app support.
    init(baseURL: URL) {
        self.baseURL = baseURL
        try? FileManager.default.createDirectory(
            at: baseURL,
            withIntermediateDirectories: true
        )
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy  = .iso8601
        decoder.dateDecodingStrategy  = .iso8601
    }

    // MARK: – Apps

    /// Saves apps, stripping iconData to keep the file small.
    /// Icons are reloaded from the system on next launch.
    func saveApps(_ apps: [AppItem]) {
        let stripped = apps.map { item -> AppItem in
            var copy = item
            copy.iconData = nil
            return copy
        }
        write(stripped, to: "apps.json")
    }

    func loadApps() -> [AppItem]? {
        read([AppItem].self, from: "apps.json")
    }

    // MARK: – Groups

    func saveGroups(_ groups: [AppGroup]) {
        write(groups, to: "groups.json")
    }

    func loadGroups() -> [AppGroup]? {
        read([AppGroup].self, from: "groups.json")
    }

    // MARK: – Settings

    func saveSettings(_ settings: AppSettings) {
        write(settings, to: "settings.json")
    }

    func loadSettings() -> AppSettings? {
        read(AppSettings.self, from: "settings.json")
    }

    // MARK: – Setup flag

    func saveHasCompletedSetup(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Key.hasCompletedSetup)
    }

    func loadHasCompletedSetup() -> Bool {
        UserDefaults.standard.bool(forKey: Key.hasCompletedSetup)
    }

    // MARK: – Hidden apps

    func saveHiddenAppIDs(_ ids: Set<UUID>) {
        let strings = ids.map(\.uuidString)
        UserDefaults.standard.set(strings, forKey: Key.hiddenAppIDs)
    }

    func loadHiddenAppIDs() -> Set<UUID> {
        let strings = UserDefaults.standard.stringArray(forKey: Key.hiddenAppIDs) ?? []
        return Set(strings.compactMap(UUID.init))
    }

    // MARK: – Generic helpers

    private func write<T: Encodable>(_ value: T, to filename: String) {
        let url = baseURL.appendingPathComponent(filename)
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[Persistence] Failed to save \(filename): \(error)")
        }
    }

    private func read<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        let url = baseURL.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("[Persistence] Failed to load \(filename): \(error)")
            return nil
        }
    }
}
