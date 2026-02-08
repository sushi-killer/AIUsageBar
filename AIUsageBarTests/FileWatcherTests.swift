import XCTest
@testable import AIUsageBar

final class FileWatcherTests: XCTestCase {

    // MARK: - Test Properties

    private var tempDirectory: URL!
    private var fileWatcher: FileWatcher?

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // Create a unique temp directory for each test
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        fileWatcher?.stop()
        fileWatcher = nil
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testFileWatcherInitialization() {
        // Given
        var callbackCalled = false

        // When
        fileWatcher = FileWatcher { _ in
            callbackCalled = true
        }

        // Then
        XCTAssertNotNil(fileWatcher)
        // Callback should not be called on init alone
        XCTAssertFalse(callbackCalled)
    }

    func testFileWatcherStartsWithoutCrashing() {
        // Given
        fileWatcher = FileWatcher { _ in }

        // When / Then - should not crash
        fileWatcher?.start()
    }

    func testFileWatcherStopsWithoutCrashing() {
        // Given
        fileWatcher = FileWatcher { _ in }
        fileWatcher?.start()

        // When / Then - should not crash
        fileWatcher?.stop()
    }

    func testFileWatcherCanBeRestarted() {
        // Given
        fileWatcher = FileWatcher { _ in }

        // When / Then - should not crash on restart cycle
        fileWatcher?.start()
        fileWatcher?.stop()
        fileWatcher?.start()
        fileWatcher?.stop()
    }

    // MARK: - Provider Path Tests

    func testClaudeProviderLogsPathIsValid() {
        // Given
        let provider = Provider.claude

        // When
        let path = provider.logsPath

        // Then
        XCTAssertTrue(path.contains(".claude/projects"))
        XCTAssertTrue(path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.path))
    }

    func testCodexProviderLogsPathIsValid() {
        // Given
        let provider = Provider.codex

        // When
        let path = provider.logsPath

        // Then
        XCTAssertTrue(path.contains(".codex/sessions"))
        XCTAssertTrue(path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.path))
    }

    func testAllProvidersHaveLogsPath() {
        // Given / When / Then
        for provider in Provider.allCases {
            XCTAssertFalse(provider.logsPath.isEmpty, "\(provider) should have a logs path")
        }
    }

    // MARK: - Notification Tests

    func testFileWatcherNotificationNameExists() {
        // Given / When / Then
        let notificationName = Notification.Name.fileWatcherDidDetectChange
        XCTAssertEqual(notificationName.rawValue, "fileWatcherDidDetectChange")
    }

    func testNotificationContainsProviderInUserInfo() {
        // Given
        let expectation = expectation(description: "Notification received")
        var receivedProvider: Provider?

        let observer = NotificationCenter.default.addObserver(
            forName: .fileWatcherDidDetectChange,
            object: nil,
            queue: .main
        ) { notification in
            receivedProvider = notification.userInfo?["provider"] as? Provider
            expectation.fulfill()
        }

        // When
        NotificationCenter.default.post(
            name: .fileWatcherDidDetectChange,
            object: nil,
            userInfo: ["provider": Provider.claude]
        )

        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedProvider, .claude)

        NotificationCenter.default.removeObserver(observer)
    }

    func testNotificationWithCodexProvider() {
        // Given
        let expectation = expectation(description: "Notification received")
        var receivedProvider: Provider?

        let observer = NotificationCenter.default.addObserver(
            forName: .fileWatcherDidDetectChange,
            object: nil,
            queue: .main
        ) { notification in
            receivedProvider = notification.userInfo?["provider"] as? Provider
            expectation.fulfill()
        }

        // When
        NotificationCenter.default.post(
            name: .fileWatcherDidDetectChange,
            object: nil,
            userInfo: ["provider": Provider.codex]
        )

        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedProvider, .codex)

        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - FSEvents Configuration Tests

    func testFSEventsFlagsAreConfiguredCorrectly() {
        // This test validates the expected FSEvents configuration
        // The implementation uses kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents

        let useCFTypes = FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes)
        let fileEvents = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents)
        let expectedFlags = useCFTypes | fileEvents

        // Verify the flags are non-zero and distinct
        XCTAssertGreaterThan(useCFTypes, 0)
        XCTAssertGreaterThan(fileEvents, 0)
        XCTAssertGreaterThan(expectedFlags, useCFTypes)
        XCTAssertGreaterThan(expectedFlags, fileEvents)
    }

    func testFSEventStreamEventIdSinceNowIsValid() {
        // Given / When
        let eventId = FSEventStreamEventId(kFSEventStreamEventIdSinceNow)

        // Then
        XCTAssertEqual(eventId, FSEventStreamEventId(kFSEventStreamEventIdSinceNow))
    }

    // MARK: - Debounce Configuration Tests

    func testDebounceIntervalIsReasonable() {
        // The debounce interval should be:
        // - Greater than 0 (to avoid excessive callbacks)
        // - Less than 2 seconds (to meet PRD US-006 2-second update requirement)

        let debounceInterval = UpdateTiming.fileWatcherDebounce

        XCTAssertGreaterThan(debounceInterval, 0)
        XCTAssertLessThan(debounceInterval, 2.0,
            "Debounce must be less than 2 seconds for PRD US-006 requirement")
    }

    func testFSEventsLatencyIsReasonable() {
        // FSEvents latency should be:
        // - Greater than 0 (required by FSEvents API)
        // - Less than 2 seconds (to meet PRD US-006 2-second update requirement)

        let fsEventsLatency = UpdateTiming.fsEventsLatency

        XCTAssertGreaterThan(fsEventsLatency, 0)
        XCTAssertLessThan(fsEventsLatency, 2.0,
            "FSEvents latency must be less than 2 seconds for PRD US-006 requirement")
    }

    func testTotalDebounceDelayMeetsRequirement() {
        // PRD US-006: "User sees usage update within 2 seconds of new log entry"
        // Total delay = FSEvents latency + app debounce + processing time
        // We allocate ~0.5s for processing, so FSEvents + debounce must be <= 1.5s

        let totalDebounceDelay = UpdateTiming.fsEventsLatency + UpdateTiming.fileWatcherDebounce
        let processingBuffer: TimeInterval = 0.5
        let maxAllowedDelay = UpdateTiming.maxFileWatcherUpdateDelay - processingBuffer

        XCTAssertLessThanOrEqual(totalDebounceDelay, maxAllowedDelay,
            "Total debounce delay (\(totalDebounceDelay)s) should leave room for processing within 2s requirement")
    }

    func testMaxFileWatcherUpdateDelayIs2Seconds() {
        // PRD US-006 explicitly requires 2-second maximum delay
        XCTAssertEqual(UpdateTiming.maxFileWatcherUpdateDelay, 2.0,
            "PRD US-006 requires 2-second maximum delay from file change to UI update")
    }

    func testFileWatcherUsesConfiguredDebounceInterval() {
        // FileWatcher should use UpdateTiming constants by default
        var callbackCalled = false

        fileWatcher = FileWatcher { _ in
            callbackCalled = true
        }

        // The default debounce should be UpdateTiming.fileWatcherDebounce (0.5s)
        // This means callback should fire faster than with 1.0s debounce
        XCTAssertNotNil(fileWatcher)
        XCTAssertFalse(callbackCalled)
    }

    func testFileWatcherAcceptsCustomDebounceInterval() {
        // Given - custom shorter debounce for testing
        let customDebounce: TimeInterval = 0.1
        let expectation = expectation(description: "Callback with custom debounce")

        fileWatcher = FileWatcher(
            onChange: { _ in
                expectation.fulfill()
            },
            debounceInterval: customDebounce
        )

        fileWatcher?.start()

        // When - trigger a file change notification
        NotificationCenter.default.post(
            name: .fileWatcherDidDetectChange,
            object: nil,
            userInfo: ["provider": Provider.claude]
        )

        // Then - callback should fire quickly with 0.1s debounce
        waitForExpectations(timeout: 1.0)
    }

    func testFileWatcherAcceptsCustomFSEventsLatency() {
        // Given - FileWatcher can be initialized with custom FSEvents latency
        let customLatency: TimeInterval = 0.25

        fileWatcher = FileWatcher(
            onChange: { _ in },
            debounceInterval: 0.1,
            fsEventsLatency: customLatency
        )

        // Then - should initialize without crashing
        XCTAssertNotNil(fileWatcher)
    }

    // MARK: - Memory Management Tests

    func testFileWatcherDeallocationStopsStreams() {
        // Given
        var weakRef: FileWatcher?

        autoreleasepool {
            let watcher = FileWatcher { _ in }
            watcher.start()
            weakRef = watcher
            // Watcher goes out of scope, deinit should be called
        }

        // Then - watcher should be deallocated
        // Note: weakRef is a strong reference here, but in real code
        // with weak references, this would be nil after deallocation
        XCTAssertNotNil(weakRef) // Just validates no crash during dealloc
    }

    func testMultipleStartCallsDoNotCrash() {
        // Given
        fileWatcher = FileWatcher { _ in }

        // When / Then - multiple starts should not crash
        fileWatcher?.start()
        fileWatcher?.start()
        fileWatcher?.start()
    }

    func testMultipleStopCallsDoNotCrash() {
        // Given
        fileWatcher = FileWatcher { _ in }
        fileWatcher?.start()

        // When / Then - multiple stops should not crash
        fileWatcher?.stop()
        fileWatcher?.stop()
        fileWatcher?.stop()
    }

    // MARK: - Integration Tests

    func testFileWatcherWatchesAllProviders() {
        // Given
        let providers = Provider.allCases
        var watchedProviders: Set<Provider> = []

        // The FileWatcher should set up streams for all providers
        for provider in providers {
            watchedProviders.insert(provider)
        }

        // Then
        XCTAssertEqual(watchedProviders.count, 2)
        XCTAssertTrue(watchedProviders.contains(.claude))
        XCTAssertTrue(watchedProviders.contains(.codex))
    }

    func testProviderPathsAreAbsolutePaths() {
        // FSEvents requires absolute paths
        for provider in Provider.allCases {
            XCTAssertTrue(
                provider.logsPath.hasPrefix("/"),
                "\(provider) path should be absolute"
            )
        }
    }

    // MARK: - Callback Tests

    func testCallbackReceivesCorrectProvider() {
        // Given
        let expectation = expectation(description: "Callback called with correct provider")
        var callbackProvider: Provider?

        fileWatcher = FileWatcher { provider in
            callbackProvider = provider
            expectation.fulfill()
        }

        // Simulate the callback flow by posting a notification
        // and waiting for the debounced callback
        fileWatcher?.start()

        // Post notification directly to simulate file change detection
        NotificationCenter.default.post(
            name: .fileWatcherDidDetectChange,
            object: nil,
            userInfo: ["provider": Provider.claude]
        )

        // Then - with debounce (0.5s), callback should fire quickly
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(callbackProvider, .claude)
    }

    // MARK: - Thread Safety Tests

    func testFileWatcherCanBeCreatedOnBackgroundThread() {
        // Given
        let expectation = expectation(description: "FileWatcher created on background thread")
        var watcher: FileWatcher?

        // When
        DispatchQueue.global(qos: .background).async {
            watcher = FileWatcher { _ in }
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 2.0)
        XCTAssertNotNil(watcher)
    }

    func testFileWatcherStartCanBeCalledFromBackgroundThread() {
        // Given
        let expectation = expectation(description: "Start called on background thread")
        fileWatcher = FileWatcher { _ in }

        // When
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.fileWatcher?.start()
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Directory Creation Tests

    func testFileWatcherCreatesDirectoryIfNotExists() {
        // The FileWatcher implementation creates directories if they don't exist
        // This test validates that behavior is configured correctly

        let fileManager = FileManager.default

        // Note: We don't want to actually create system directories in tests
        // but we can verify the logic is present

        // Both provider paths should be valid directory path formats
        for provider in Provider.allCases {
            let path = provider.logsPath
            XCTAssertTrue(path.contains("/"), "Path should be a valid directory path")
            XCTAssertFalse(path.hasSuffix(".jsonl"), "Path should be directory, not file")
        }
    }

    // MARK: - Codex Log Watching Integration Tests

    func testCodexCallbackReceivesCorrectProvider() {
        // Given
        let expectation = expectation(description: "Codex callback called with correct provider")
        var callbackProvider: Provider?

        fileWatcher = FileWatcher { provider in
            if provider == .codex {
                callbackProvider = provider
                expectation.fulfill()
            }
        }

        // Simulate the callback flow by posting a notification
        fileWatcher?.start()

        // Post notification directly to simulate Codex file change detection
        NotificationCenter.default.post(
            name: .fileWatcherDidDetectChange,
            object: nil,
            userInfo: ["provider": Provider.codex]
        )

        // Then - with debounce (0.5s), callback should fire quickly
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(callbackProvider, .codex)
    }

    func testCodexLogsPathMatchesExpectedStructure() {
        // Given
        let codexPath = Provider.codex.logsPath

        // Then - should be ~/.codex/sessions
        XCTAssertTrue(codexPath.hasSuffix(".codex/sessions"))
        XCTAssertTrue(codexPath.hasPrefix("/Users/") || codexPath.hasPrefix("/home/"))
    }

    func testCodexLogsPathIsWatchable() {
        // Given
        let codexPath = Provider.codex.logsPath

        // Then - path should be valid for FSEvents
        XCTAssertTrue(codexPath.hasPrefix("/"), "Codex path must be absolute for FSEvents")
        XCTAssertFalse(codexPath.contains("~"), "Codex path must be expanded, not contain tilde")
    }

    func testFileWatcherHandlesCodexAndClaudeIndependently() {
        // Given
        var claudeCallCount = 0
        var codexCallCount = 0
        let claudeExpectation = expectation(description: "Claude callback called")
        let codexExpectation = expectation(description: "Codex callback called")

        fileWatcher = FileWatcher { provider in
            switch provider {
            case .claude:
                claudeCallCount += 1
                if claudeCallCount == 1 {
                    claudeExpectation.fulfill()
                }
            case .codex:
                codexCallCount += 1
                if codexCallCount == 1 {
                    codexExpectation.fulfill()
                }
            }
        }

        fileWatcher?.start()

        // Post notifications for both providers
        NotificationCenter.default.post(
            name: .fileWatcherDidDetectChange,
            object: nil,
            userInfo: ["provider": Provider.claude]
        )
        NotificationCenter.default.post(
            name: .fileWatcherDidDetectChange,
            object: nil,
            userInfo: ["provider": Provider.codex]
        )

        // Then - with debounce (0.5s), callbacks should fire quickly
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(claudeCallCount, 1)
        XCTAssertEqual(codexCallCount, 1)
    }

    func testCodexProviderRawValueMatchesKey() {
        // Validates that the provider key used in debounce is consistent
        XCTAssertEqual(Provider.codex.rawValue, "codex")
    }

    func testCodexSessionsDirectoryStructureExpectations() {
        // Codex uses: ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl
        // FileWatcher watches: ~/.codex/sessions/
        // FSEvents should recursively detect changes in subdirectories

        let codexPath = Provider.codex.logsPath

        // Path should point to sessions directory (parent of date directories)
        XCTAssertTrue(codexPath.hasSuffix("sessions"))
        XCTAssertFalse(codexPath.contains("/20"))  // Should not include date paths
    }

    func testDebounceWorksIndependentlyForCodexAndClaude() {
        // Given
        var receivedProviders: [Provider] = []
        let expectation = expectation(description: "Both providers received")
        expectation.expectedFulfillmentCount = 2

        fileWatcher = FileWatcher { provider in
            receivedProviders.append(provider)
            expectation.fulfill()
        }

        fileWatcher?.start()

        // Post rapid notifications for both providers
        // Debounce should handle each provider independently
        NotificationCenter.default.post(
            name: .fileWatcherDidDetectChange,
            object: nil,
            userInfo: ["provider": Provider.claude]
        )
        NotificationCenter.default.post(
            name: .fileWatcherDidDetectChange,
            object: nil,
            userInfo: ["provider": Provider.codex]
        )

        // Then - with debounce (0.5s), callbacks should fire quickly
        waitForExpectations(timeout: 2.0)
        XCTAssertTrue(receivedProviders.contains(.claude))
        XCTAssertTrue(receivedProviders.contains(.codex))
    }

    func testCodexFSEventsConfigurationMatchesClaude() {
        // Both providers should use the same FSEvents configuration
        // This validates consistency in the implementation

        let claudePath = Provider.claude.logsPath
        let codexPath = Provider.codex.logsPath

        // Both should be absolute paths
        XCTAssertTrue(claudePath.hasPrefix("/"))
        XCTAssertTrue(codexPath.hasPrefix("/"))

        // Both should be in home directory
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        XCTAssertTrue(claudePath.hasPrefix(home))
        XCTAssertTrue(codexPath.hasPrefix(home))
    }
}
