/// Tests for FSEventsWatcher: debounce coalescing and rapid-event deduplication.
import XCTest
@testable import LaunchboardKit

final class FSEventsWatcherTests: XCTestCase {

    // MARK: - Rapid events coalesce into one emission

    func testRapidEventsProduceSingleEmission() async throws {
        let watcher = FSEventsWatcher(debounceInterval: 0.2)

        // Feed 10 rapid events via the internal actor method (bypasses FSEvents for determinism)
        for i in 0..<10 {
            await watcher.receive(paths: ["/Applications/App\(i).app"])
        }

        let emissions = try await collectEmissions(from: watcher.changeStream, window: 0.6)

        XCTAssertEqual(emissions.count, 1, "10 rapid events should coalesce into exactly 1 emission")
        XCTAssertEqual(emissions.first?.count, 10, "All 10 distinct paths should be in the single emission")
    }

    // MARK: - Two separated bursts produce two distinct emissions

    func testTwoBurstsProduceTwoEmissions() async throws {
        let watcher = FSEventsWatcher(debounceInterval: 0.1)

        await watcher.receive(paths: ["/Applications/Alpha.app"])

        // Let the first debounce window expire
        try await Task.sleep(for: .seconds(0.3))

        await watcher.receive(paths: ["/Applications/Beta.app"])

        let emissions = try await collectEmissions(from: watcher.changeStream, window: 0.4)
        XCTAssertEqual(emissions.count, 2)
        XCTAssertTrue(emissions[0].contains("/Applications/Alpha.app"))
        XCTAssertTrue(emissions[1].contains("/Applications/Beta.app"))
    }

    // MARK: - Empty path list never triggers emission

    func testEmptyPathsDoNotTriggerEmission() async throws {
        let watcher = FSEventsWatcher(debounceInterval: 0.1)
        await watcher.receive(paths: [])
        let emissions = try await collectEmissions(from: watcher.changeStream, window: 0.3)
        XCTAssertTrue(emissions.isEmpty, "Empty path list must not yield to the stream")
    }

    // MARK: - Duplicate paths within one burst are deduplicated

    func testDuplicatePathsAreDeduped() async throws {
        let watcher = FSEventsWatcher(debounceInterval: 0.15)

        for _ in 0..<5 {
            await watcher.receive(paths: ["/Applications/Figma.app"])
        }

        let emissions = try await collectEmissions(from: watcher.changeStream, window: 0.5)
        XCTAssertEqual(emissions.count, 1)
        XCTAssertEqual(emissions.first?.count, 1, "Five identical paths should deduplicate to one")
    }

    // MARK: - Helpers

    /// Collects all AsyncStream emissions within `window` seconds, then returns them.
    /// Uses a cancellable Task so the for-await loop doesn't block indefinitely when no emissions arrive.
    private func collectEmissions(
        from stream: AsyncStream<[String]>,
        window: TimeInterval
    ) async throws -> [[String]] {
        let collector = EmissionCollector()

        let consumeTask = Task {
            for await emission in stream {
                await collector.add(emission)
            }
        }

        try await Task.sleep(for: .seconds(window))
        consumeTask.cancel()
        return await collector.results()
    }
}

// Thread-safe collector used by collectEmissions
private actor EmissionCollector {
    private var _results: [[String]] = []
    func add(_ emission: [String]) { _results.append(emission) }
    func results() -> [[String]] { _results }
}
