import Foundation

final class FileWatcher {
    private var streams: [FSEventStreamRef] = []
    private var allocatedPointers: [UnsafeMutablePointer<Provider>] = []
    private var debounceWorkItems: [String: DispatchWorkItem] = [:]
    /// Debounce interval for app-level event coalescing.
    /// Combined with FSEvents latency (0.5s), total delay is ~1.0s allowing
    /// processing time within the 2-second update requirement (PRD US-006).
    private let debounceInterval: TimeInterval
    /// FSEvents stream latency for OS-level event coalescing.
    /// Lower values mean faster detection but more CPU usage.
    private let fsEventsLatency: TimeInterval
    private let onChange: (Provider) -> Void
    private var observerRegistered = false

    init(
        onChange: @escaping (Provider) -> Void,
        debounceInterval: TimeInterval = UpdateTiming.fileWatcherDebounce,
        fsEventsLatency: TimeInterval = UpdateTiming.fsEventsLatency
    ) {
        self.onChange = onChange
        self.debounceInterval = debounceInterval
        self.fsEventsLatency = fsEventsLatency
    }

    deinit {
        stop()
    }

    func start() {
        // Register observer once before starting watchers
        if !observerRegistered {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleFileChange(_:)),
                name: .fileWatcherDidDetectChange,
                object: nil
            )
            observerRegistered = true
        }

        for provider in Provider.allCases {
            startWatching(provider: provider)
        }
    }

    func stop() {
        for stream in streams {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        streams.removeAll()

        // Deallocate all provider pointers
        for ptr in allocatedPointers {
            ptr.deinitialize(count: 1)
            ptr.deallocate()
        }
        allocatedPointers.removeAll()

        debounceWorkItems.values.forEach { $0.cancel() }
        debounceWorkItems.removeAll()

        // Remove NotificationCenter observer
        if observerRegistered {
            NotificationCenter.default.removeObserver(self)
            observerRegistered = false
        }
    }

    private func startWatching(provider: Provider) {
        let path = provider.logsPath
        let fileManager = FileManager.default

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: path) {
            try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        }

        let providerPtr = UnsafeMutablePointer<Provider>.allocate(capacity: 1)
        providerPtr.initialize(to: provider)
        allocatedPointers.append(providerPtr)

        var context = FSEventStreamContext(
            version: 0,
            info: UnsafeMutableRawPointer(providerPtr),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let pathsToWatch = [path] as CFArray

        guard let stream = FSEventStreamCreate(
            nil,
            { (streamRef, contextInfo, numEvents, eventPaths, eventFlags, eventIds) in
                guard let contextInfo = contextInfo else { return }
                let providerPtr = contextInfo.assumingMemoryBound(to: Provider.self)
                let provider = providerPtr.pointee

                NotificationCenter.default.post(
                    name: .fileWatcherDidDetectChange,
                    object: nil,
                    userInfo: ["provider": provider]
                )
            },
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            CFTimeInterval(fsEventsLatency),
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        ) else {
            return
        }

        FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .utility))
        FSEventStreamStart(stream)
        streams.append(stream)
    }

    @objc private func handleFileChange(_ notification: Notification) {
        guard let provider = notification.userInfo?["provider"] as? Provider else { return }

        let key = provider.rawValue

        // Cancel existing debounce
        debounceWorkItems[key]?.cancel()

        // Create new debounced work item
        let workItem = DispatchWorkItem { [weak self] in
            self?.onChange(provider)
        }

        debounceWorkItems[key] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
}

extension Notification.Name {
    static let fileWatcherDidDetectChange = Notification.Name("fileWatcherDidDetectChange")
}
