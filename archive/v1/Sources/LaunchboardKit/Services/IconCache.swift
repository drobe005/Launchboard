/// Thread-safe NSImage cache; loads lazily from NSWorkspace, coalesces concurrent requests per URL.
import AppKit

public final class IconCache: @unchecked Sendable {
    public static let shared = IconCache()

    // NSCache is documented thread-safe — readable from any context without actor isolation.
    private let cache = NSCache<NSString, NSImage>()
    // Actor guards the inflight dictionary so concurrent requests for the same URL share one Task.
    private let coordinator = InflightCoordinator()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 100 * 64 * 64 * 4   // ~25 MB ceiling
    }

    /// Returns a cached image immediately (no suspension) or loads it off the main actor and caches it.
    public func image(for bundleURL: URL) async -> NSImage {
        let key = bundleURL.path as NSString

        // Fast path: NSCache hit — no actor hop needed.
        if let cached = cache.object(forKey: key) { return cached }

        // Slow path: coalesce concurrent loads for the same URL through the coordinator actor.
        let task = await coordinator.task(for: bundleURL.path) { [cache] in
            Task.detached(priority: .utility) {
                let image = NSWorkspace.shared.icon(forFile: bundleURL.path)
                image.size = NSSize(width: 64, height: 64)
                cache.setObject(image, forKey: key, cost: 64 * 64 * 4)
                return image
            }
        }
        let result = await task.value
        await coordinator.finish(key: bundleURL.path)
        return result
    }

    /// Synchronous read — returns a cached image without touching the actor.
    /// Returns nil if the image has not been loaded yet.
    public func cachedImage(for bundleURL: URL) -> NSImage? {
        cache.object(forKey: bundleURL.path as NSString)
    }

    public func evictAll() { cache.removeAllObjects() }
}

// MARK: - Coordinator actor

private actor InflightCoordinator {
    private var inflight: [String: Task<NSImage, Never>] = [:]

    /// Returns an existing in-flight task for `key`, or creates one via `make` and registers it.
    func task(for key: String, make: () -> Task<NSImage, Never>) -> Task<NSImage, Never> {
        if let existing = inflight[key] { return existing }
        let t = make()
        inflight[key] = t
        return t
    }

    func finish(key: String) { inflight.removeValue(forKey: key) }
}
