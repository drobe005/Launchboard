/// FSEvents-backed directory watcher that debounces rapid filesystem changes before emitting a scan trigger.
import Foundation
import CoreServices

// MARK: - Public actor

public actor FSEventsWatcher {
    /// Async stream of changed .app paths, emitted after the debounce window elapses.
    public let changeStream: AsyncStream<[String]>
    private let continuation: AsyncStream<[String]>.Continuation

    private var pendingPaths: Set<String> = []
    private var debounceTask: Task<Void, Never>?
    private let debounceInterval: TimeInterval

    // Bridge owns the FSEventStreamRef and calls back into this actor.
    private var bridge: FSEventsBridge?

    public init(debounceInterval: TimeInterval = 0.5) {
        self.debounceInterval = debounceInterval
        var cont: AsyncStream<[String]>.Continuation!
        changeStream = AsyncStream { cont = $0 }
        continuation = cont
    }

    // MARK: - Start / Stop

    public func start(watching paths: [String]) {
        stopBridge()

        let newBridge = FSEventsBridge()
        bridge = newBridge
        newBridge.onPaths = { [weak self] receivedPaths in
            guard let self else { return }
            Task { await self.receive(paths: receivedPaths) }
        }
        newBridge.start(watching: paths)
    }

    public func stop() {
        debounceTask?.cancel()
        debounceTask = nil
        stopBridge()
    }

    private func stopBridge() {
        bridge?.stop()
        bridge = nil
    }

    // MARK: - Internal: called by bridge on every event batch

    func receive(paths: [String]) {
        pendingPaths.formUnion(paths)
        debounceTask?.cancel()
        debounceTask = Task {
            do {
                try await Task.sleep(for: .seconds(debounceInterval))
            } catch {
                return  // cancelled by a newer event — the newer debounceTask will fire
            }
            let toEmit = Array(pendingPaths)
            pendingPaths.removeAll()
            guard !toEmit.isEmpty else { return }
            continuation.yield(toEmit)
        }
    }
}

// MARK: - FSEventsBridge (manages the C-level FSEventStreamRef)

/// Non-actor class that owns the FSEventStream and bridges its C callback to Swift closures.
private final class FSEventsBridge: @unchecked Sendable {
    var onPaths: (([String]) -> Void)?
    private var streamRef: FSEventStreamRef?
    private var retainedSelf: UnsafeMutableRawPointer?

    func start(watching paths: [String]) {
        let selfPtr = Unmanaged.passRetained(self).toOpaque()
        retainedSelf = selfPtr
        var ctx = FSEventStreamContext(
            version: 0, info: selfPtr,
            retain: nil, release: nil, copyDescription: nil
        )
        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            fsBridgeCallback,
            &ctx,
            paths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.1,
            UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        ) else {
            Unmanaged<FSEventsBridge>.fromOpaque(selfPtr).release()
            retainedSelf = nil
            return
        }
        FSEventStreamSetDispatchQueue(stream, .main)
        FSEventStreamStart(stream)
        streamRef = stream
    }

    func stop() {
        if let stream = streamRef {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            streamRef = nil
        }
        if let ptr = retainedSelf {
            Unmanaged<FSEventsBridge>.fromOpaque(ptr).release()
            retainedSelf = nil
        }
    }
}

// MARK: - C callback

private func fsBridgeCallback(
    _: ConstFSEventStreamRef,
    _ info: UnsafeMutableRawPointer?,
    _: Int,
    _ eventPaths: UnsafeMutableRawPointer,
    _: UnsafePointer<FSEventStreamEventFlags>,
    _: UnsafePointer<FSEventStreamEventId>
) {
    guard let info else { return }
    let bridge = Unmanaged<FSEventsBridge>.fromOpaque(info).takeUnretainedValue()
    guard let cfPaths = unsafeBitCast(eventPaths, to: CFArray.self) as? [String] else { return }
    let appPaths = cfPaths.filter { $0.contains(".app") }
    guard !appPaths.isEmpty else { return }
    bridge.onPaths?(appPaths)
}
