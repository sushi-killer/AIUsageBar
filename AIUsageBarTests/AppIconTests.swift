import XCTest

final class AppIconTests: XCTestCase {

    // MARK: - App Icon Tests

    private var appIconsetPath: String {
        #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Resources/Assets.xcassets/AppIcon.appiconset")
    }

    func testAppIconContentsJsonExists() throws {
        let contentsPath = appIconsetPath + "/Contents.json"
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: contentsPath) else {
            XCTFail("AppIcon.appiconset/Contents.json should exist")
            return
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: contentsPath))
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        XCTAssertNotNil(json as? [String: Any], "Contents.json should be valid JSON")
    }

    func testAppIconContentsJsonHasImages() throws {
        let contentsPath = appIconsetPath + "/Contents.json"
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: contentsPath) else {
            return
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: contentsPath))
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            XCTFail("Contents.json should be valid JSON dictionary")
            return
        }

        guard let images = json["images"] as? [[String: Any]] else {
            XCTFail("Contents.json should have images array")
            return
        }

        XCTAssertEqual(images.count, 10, "macOS app icon should have 10 image entries (5 sizes x 2 scales)")

        // Verify all images have required fields
        for image in images {
            XCTAssertNotNil(image["idiom"], "Each image should have idiom")
            XCTAssertNotNil(image["scale"], "Each image should have scale")
            XCTAssertNotNil(image["size"], "Each image should have size")
            XCTAssertNotNil(image["filename"], "Each image should have filename")
        }
    }

    func testAllAppIconFilesExist() throws {
        let contentsPath = appIconsetPath + "/Contents.json"
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: contentsPath) else {
            return
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: contentsPath))
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let images = json["images"] as? [[String: Any]] else {
            return
        }

        var filenames = Set<String>()
        for image in images {
            if let filename = image["filename"] as? String {
                filenames.insert(filename)
            }
        }

        // Verify all referenced files exist
        for filename in filenames {
            let filePath = appIconsetPath + "/" + filename
            XCTAssertTrue(
                fileManager.fileExists(atPath: filePath),
                "Icon file \(filename) should exist in AppIcon.appiconset"
            )
        }
    }

    func testAppIconFilesAreValidPNGs() throws {
        let contentsPath = appIconsetPath + "/Contents.json"
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: contentsPath) else {
            return
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: contentsPath))
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let images = json["images"] as? [[String: Any]] else {
            return
        }

        var filenames = Set<String>()
        for image in images {
            if let filename = image["filename"] as? String {
                filenames.insert(filename)
            }
        }

        // Verify all files are valid PNG images
        for filename in filenames {
            let filePath = appIconsetPath + "/" + filename
            guard fileManager.fileExists(atPath: filePath) else {
                continue
            }

            let iconData = try Data(contentsOf: URL(fileURLWithPath: filePath))

            // PNG files start with specific magic bytes: 137 80 78 71 13 10 26 10
            let pngMagic: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
            let fileHeader = Array(iconData.prefix(8))

            XCTAssertEqual(
                fileHeader,
                pngMagic,
                "Icon file \(filename) should be a valid PNG file"
            )
        }
    }

    func testAppIconCoversAllRequiredSizes() throws {
        let contentsPath = appIconsetPath + "/Contents.json"
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: contentsPath) else {
            return
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: contentsPath))
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let images = json["images"] as? [[String: Any]] else {
            return
        }

        // Required macOS icon sizes
        let requiredSizeScales = Set([
            "16x16@1x", "16x16@2x",
            "32x32@1x", "32x32@2x",
            "128x128@1x", "128x128@2x",
            "256x256@1x", "256x256@2x",
            "512x512@1x", "512x512@2x"
        ])

        var foundSizeScales = Set<String>()
        for image in images {
            if let size = image["size"] as? String,
               let scale = image["scale"] as? String,
               image["filename"] != nil {
                foundSizeScales.insert("\(size)@\(scale)")
            }
        }

        XCTAssertEqual(
            foundSizeScales,
            requiredSizeScales,
            "App icon should cover all required macOS sizes and scales"
        )
    }
}
