import XCTest
@testable import AIUsageBar

final class AIUsageBarTests: XCTestCase {
    override func setUpWithError() throws {
        // Setup code
    }

    override func tearDownWithError() throws {
        // Teardown code
    }

    func testAppSettingsPersistence() throws {
        // Test that AppSettings can be accessed
        let settings = AppSettings.shared
        XCTAssertNotNil(settings)
    }
}
