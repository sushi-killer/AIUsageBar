import XCTest
@testable import AIUsageBar

/// Tests for PRD US-008: Usage ring - circular progress indicator with percentage in center
/// Validates that the panel displays a circular usage ring with status colors and animations
final class UsageRingTests: XCTestCase {

    // MARK: - UsageRing Component Tests

    func testUsageRingFileExists() throws {
        // Verify UsageRing.swift exists
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let fileManager = FileManager.default
        XCTAssertTrue(
            fileManager.fileExists(atPath: ringPath),
            "UsageRing.swift must exist for circular progress indicator (PRD US-008)"
        )
    }

    func testUsageRingIsSwiftUIView() throws {
        // Verify UsageRing conforms to View protocol
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("struct UsageRing: View"),
            "UsageRing must be a SwiftUI View"
        )
    }

    func testUsageRingAcceptsPercentage() throws {
        // Verify UsageRing takes a percentage parameter
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("let percentage: Double"),
            "UsageRing must accept a percentage parameter (PRD US-008)"
        )
    }

    func testUsageRingAcceptsProviderColor() throws {
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("let providerColor: Color"),
            "UsageRing must accept a providerColor parameter for ring color"
        )
    }

    // MARK: - Circular Progress Indicator Tests

    func testUsageRingUsesCircleShape() throws {
        // Verify UsageRing uses Circle for the progress indicator
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("Circle()"),
            "UsageRing must use Circle shape for circular progress indicator (PRD US-008)"
        )
    }

    func testUsageRingHasBackgroundRing() throws {
        // Verify UsageRing has a background ring (stroke with low opacity)
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".stroke(") && content.contains("opacity"),
            "UsageRing must have a background ring with opacity"
        )
    }

    func testUsageRingUsesTrimmingForProgress() throws {
        // Verify UsageRing uses trim modifier for progress indication
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".trim(from:"),
            "UsageRing must use trim modifier for circular progress"
        )
    }

    func testUsageRingStartsFromTop() throws {
        // Verify UsageRing rotates to start from top (-90 degrees)
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".rotationEffect(.degrees(-90))"),
            "UsageRing should rotate -90 degrees to start progress from top"
        )
    }

    // MARK: - Percentage Display Tests

    func testUsageRingDisplaysPercentageText() throws {
        // Verify UsageRing displays percentage in center
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("%") && content.contains("Text("),
            "UsageRing must display percentage text in center (PRD US-008)"
        )
    }

    func testUsageRingUsesZStackForCenteredText() throws {
        // Verify UsageRing uses ZStack to center text over the ring
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("ZStack"),
            "UsageRing should use ZStack to layer percentage text over the ring"
        )
    }

    func testUsageRingPercentageUsesBoldFont() throws {
        // Verify percentage text uses bold font for visibility
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("weight: .bold"),
            "UsageRing percentage should use bold font for visibility"
        )
    }

    // MARK: - Status Color Tests

    func testUsageRingUsesProviderColor() throws {
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("providerColor,"),
            "UsageRing must use providerColor for ring color"
        )
    }

    func testGreenStatusColor() {
        // Verify green status returns correct color
        let status = UsageStatus.green
        XCTAssertNotNil(status.color, "Green status must have a color")
    }

    func testYellowStatusColor() {
        // Verify yellow status returns correct color
        let status = UsageStatus.yellow
        XCTAssertNotNil(status.color, "Yellow status must have a color")
    }

    func testRedStatusColor() {
        // Verify red status returns correct color
        let status = UsageStatus.red
        XCTAssertNotNil(status.color, "Red status must have a color")
    }

    func testStatusFromPercentageGreen() {
        // Verify percentage below 75% returns green status
        let status = UsageStatus.from(percentage: 50)
        XCTAssertEqual(status, .green, "Percentage 50% should be green status")
    }

    func testStatusFromPercentageYellow() {
        // Verify percentage 75-89% returns yellow status
        let status = UsageStatus.from(percentage: 80)
        XCTAssertEqual(status, .yellow, "Percentage 80% should be yellow status")
    }

    func testStatusFromPercentageRed() {
        // Verify percentage 90%+ returns red status
        let status = UsageStatus.from(percentage: 95)
        XCTAssertEqual(status, .red, "Percentage 95% should be red status")
    }

    // MARK: - Animation Tests

    func testUsageRingHasAnimation() throws {
        // Verify UsageRing animates on value change (PRD US-008)
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".animation("),
            "UsageRing must have animation for value changes (PRD US-008)"
        )
    }

    func testUsageRingUsesEaseInOutAnimation() throws {
        // Verify UsageRing uses easeInOut animation for smooth transitions
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".easeInOut"),
            "UsageRing should use easeInOut animation for smooth transitions"
        )
    }

    func testUsageRingHasAnimatedPercentageState() throws {
        // Verify UsageRing has @State for animated percentage
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("@State") && content.contains("animatedPercentage"),
            "UsageRing should have @State animatedPercentage for animation"
        )
    }

    func testUsageRingRespondsToOnChange() throws {
        // Verify UsageRing updates on percentage change
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".onChange(of: percentage)"),
            "UsageRing should respond to percentage changes with onChange"
        )
    }

    // MARK: - ContentView Integration Tests

    func testContentViewUsesUsageRing() throws {
        // Verify ContentView uses the UsageRing component
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("UsageRing("),
            "ContentView must use UsageRing component (PRD US-008)"
        )
    }

    func testContentViewPassesPercentageToUsageRing() throws {
        // Verify ContentView passes percentage to UsageRing
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("percentage:") && content.contains("UsageRing"),
            "ContentView must pass percentage to UsageRing"
        )
    }

    func testContentViewPassesProviderColorToUsageRing() throws {
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("providerColor:") && content.contains("UsageRing"),
            "ContentView must pass providerColor to UsageRing"
        )
    }

    func testContentViewSetsUsageRingFrame() throws {
        // Verify ContentView sets appropriate frame for UsageRing
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".frame(width:") && content.contains("UsageRing"),
            "ContentView should set frame dimensions for UsageRing"
        )
    }

    // MARK: - Line Width Configuration Tests

    func testUsageRingHasConfigurableLineWidth() throws {
        // Verify UsageRing has configurable line width
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("lineWidth"),
            "UsageRing should have configurable line width"
        )
    }

    func testUsageRingUsesRoundedLineCap() throws {
        // Verify UsageRing uses rounded line cap for better visuals
        let ringPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/UsageRing.swift")

        let content = try String(contentsOfFile: ringPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("lineCap: .round"),
            "UsageRing should use rounded line cap for better visuals"
        )
    }
}
