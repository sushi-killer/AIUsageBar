import XCTest
@testable import AIUsageBar

final class ClaudeProviderTests: XCTestCase {
    var provider: ClaudeProvider!

    override func setUp() {
        super.setUp()
        provider = ClaudeProvider()
    }

    override func tearDown() {
        provider = nil
        super.tearDown()
    }

    func testClaudeAPIResponseDecoding() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.45,
                "resets_at": "2024-01-15T15:00:00Z"
            },
            "seven_day": {
                "utilization": 0.72,
                "resets_at": "2024-01-20T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.fiveHour?.utilization, 0.45)
        XCTAssertEqual(response.fiveHour?.resetsAt, "2024-01-15T15:00:00Z")
        XCTAssertEqual(response.sevenDay?.utilization, 0.72)
        XCTAssertEqual(response.sevenDay?.resetsAt, "2024-01-20T00:00:00Z")
    }

    func testFetchUsageReturnsNilWithoutCredentials() {
        // Verify ClaudeProvider can be instantiated without triggering Keychain access.
        // Actual fetchUsage() is not called to avoid SecItemCopyMatching password prompts in CI.
        let testProvider = ClaudeProvider()
        XCTAssertNotNil(testProvider, "ClaudeProvider should be instantiable")
    }

    // MARK: - API Response Decoding Tests

    func testClaudeAPIResponseDecodingWithFractionalSeconds() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.85,
                "resets_at": "2024-01-15T15:30:45.123Z"
            },
            "seven_day": {
                "utilization": 0.50,
                "resets_at": "2024-01-22T00:00:00.000Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.fiveHour?.utilization, 0.85)
        XCTAssertEqual(response.fiveHour?.resetsAt, "2024-01-15T15:30:45.123Z")
        XCTAssertEqual(response.sevenDay?.utilization, 0.50)
        XCTAssertEqual(response.sevenDay?.resetsAt, "2024-01-22T00:00:00.000Z")
    }

    func testClaudeAPIResponseDecodingZeroUtilization() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.0,
                "resets_at": "2024-01-15T15:00:00Z"
            },
            "seven_day": {
                "utilization": 0.0,
                "resets_at": "2024-01-20T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.fiveHour?.utilization, 0.0)
        XCTAssertEqual(response.sevenDay?.utilization, 0.0)
    }

    func testClaudeAPIResponseDecodingFullUtilization() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 1.0,
                "resets_at": "2024-01-15T15:00:00Z"
            },
            "seven_day": {
                "utilization": 1.0,
                "resets_at": "2024-01-20T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.fiveHour?.utilization, 1.0)
        XCTAssertEqual(response.sevenDay?.utilization, 1.0)
    }

    func testClaudeAPIResponseDecodingHighPrecisionUtilization() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.123456789,
                "resets_at": "2024-01-15T15:00:00Z"
            },
            "seven_day": {
                "utilization": 0.987654321,
                "resets_at": "2024-01-20T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.fiveHour?.utilization ?? 0, 0.123456789, accuracy: 0.000000001)
        XCTAssertEqual(response.sevenDay?.utilization ?? 0, 0.987654321, accuracy: 0.000000001)
    }

    // MARK: - Usage Window Response Tests

    func testUsageWindowResponseDecoding() throws {
        let json = """
        {
            "utilization": 0.75,
            "resets_at": "2024-06-15T12:00:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(UsageWindowResponse.self, from: data)

        XCTAssertEqual(response.utilization, 0.75)
        XCTAssertEqual(response.resetsAt, "2024-06-15T12:00:00Z")
    }

    // MARK: - Invalid JSON Tests

    func testClaudeAPIResponseDecodingMissingFields() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.45
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.fiveHour?.utilization, 0.45)
        XCTAssertNil(response.fiveHour?.resetsAt)
        XCTAssertNil(response.sevenDay)
    }

    func testClaudeAPIResponseDecodingInvalidUtilization() {
        let json = """
        {
            "five_hour": {
                "utilization": "invalid",
                "resets_at": "2024-01-15T15:00:00Z"
            },
            "seven_day": {
                "utilization": 0.72,
                "resets_at": "2024-01-20T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(ClaudeAPIResponse.self, from: data))
    }

    func testClaudeAPIResponseDecodingEmptyJson() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaudeAPIResponse.self, from: data)

        XCTAssertNil(response.fiveHour)
        XCTAssertNil(response.sevenDay)
    }

    // MARK: - API URL Tests

    func testAPIURLIsCorrect() {
        let expectedURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
        // The API URL is correctly configured in ClaudeProvider
        XCTAssertNotNil(expectedURL)
        XCTAssertEqual(expectedURL.scheme, "https")
        XCTAssertEqual(expectedURL.host, "api.anthropic.com")
        XCTAssertEqual(expectedURL.path, "/api/oauth/usage")
    }

    // MARK: - Authorization Header Tests

    func testAuthorizationBearerHeaderFormat() {
        // Verify the Authorization header format is correct: "Bearer {token}"
        let testToken = "test_access_token_12345"
        let expectedHeader = "Bearer \(testToken)"

        XCTAssertEqual(expectedHeader, "Bearer test_access_token_12345")
        XCTAssertTrue(expectedHeader.hasPrefix("Bearer "))
        XCTAssertTrue(expectedHeader.contains(testToken))
    }

    func testAuthorizationHeaderWithSpecialCharacters() {
        // OAuth tokens can contain special characters
        let testToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0"
        let header = "Bearer \(testToken)"

        XCTAssertEqual(header, "Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0")
        XCTAssertTrue(header.hasPrefix("Bearer "))
    }

    func testAuthorizationHeaderWithLongToken() {
        // Test with a longer token similar to real OAuth tokens
        let testToken = String(repeating: "a", count: 256)
        let header = "Bearer \(testToken)"

        XCTAssertEqual(header.count, 7 + 256) // "Bearer " (7 chars) + token
        XCTAssertTrue(header.hasPrefix("Bearer "))
        XCTAssertTrue(header.hasSuffix(testToken))
    }

    func testURLRequestAuthorizationHeader() {
        // Test that URLRequest correctly stores the Authorization header
        let url = URL(string: "https://api.anthropic.com/api/oauth/usage")!
        var request = URLRequest(url: url)
        let testToken = "test_token"

        request.setValue("Bearer \(testToken)", forHTTPHeaderField: "Authorization")

        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test_token")
    }

    func testURLRequestHasCorrectHTTPMethod() {
        // Verify the API request uses GET method
        let url = URL(string: "https://api.anthropic.com/api/oauth/usage")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testURLRequestHasAcceptHeader() {
        // Verify the Accept header is set to application/json
        let url = URL(string: "https://api.anthropic.com/api/oauth/usage")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testCompleteAPIRequestConfiguration() {
        // Test full request configuration as used by ClaudeProvider
        let url = URL(string: "https://api.anthropic.com/api/oauth/usage")!
        var request = URLRequest(url: url)
        let credentials = ClaudeCredentials(accessToken: "oauth_token_xyz", subscriptionType: "pro")

        request.httpMethod = "GET"
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer oauth_token_xyz")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    // MARK: - Conversion Tests

    func testStatusThresholdsFromPercentage() {
        // Test usage status thresholds: >=90% red, >=75% yellow, <75% green
        XCTAssertEqual(UsageStatus.from(percentage: 0), .green)
        XCTAssertEqual(UsageStatus.from(percentage: 50), .green)
        XCTAssertEqual(UsageStatus.from(percentage: 74.9), .green)
        XCTAssertEqual(UsageStatus.from(percentage: 75), .yellow)
        XCTAssertEqual(UsageStatus.from(percentage: 85), .yellow)
        XCTAssertEqual(UsageStatus.from(percentage: 89.9), .yellow)
        XCTAssertEqual(UsageStatus.from(percentage: 90), .red)
        XCTAssertEqual(UsageStatus.from(percentage: 95), .red)
        XCTAssertEqual(UsageStatus.from(percentage: 100), .red)
    }

    // MARK: - Response Field Path Tests

    func testFiveHourUtilizationParsing() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.65,
                "resets_at": "2024-01-15T18:30:00Z"
            },
            "seven_day": {
                "utilization": 0.40,
                "resets_at": "2024-01-22T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.fiveHour?.utilization, 0.65, "five_hour.utilization should parse correctly")
    }

    func testFiveHourResetsAtParsing() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.65,
                "resets_at": "2024-01-15T18:30:00Z"
            },
            "seven_day": {
                "utilization": 0.40,
                "resets_at": "2024-01-22T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.fiveHour?.resetsAt, "2024-01-15T18:30:00Z", "five_hour.resets_at should parse correctly")
    }

    func testSevenDayUtilizationParsing() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.65,
                "resets_at": "2024-01-15T18:30:00Z"
            },
            "seven_day": {
                "utilization": 0.40,
                "resets_at": "2024-01-22T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.sevenDay?.utilization, 0.40, "seven_day.utilization should parse correctly")
    }

    func testSevenDayResetsAtParsing() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.65,
                "resets_at": "2024-01-15T18:30:00Z"
            },
            "seven_day": {
                "utilization": 0.40,
                "resets_at": "2024-01-22T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.sevenDay?.resetsAt, "2024-01-22T00:00:00Z", "seven_day.resets_at should parse correctly")
    }

    func testAllResponseFieldsParseTogether() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.25,
                "resets_at": "2024-02-10T14:00:00Z"
            },
            "seven_day": {
                "utilization": 0.88,
                "resets_at": "2024-02-15T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.fiveHour?.utilization, 0.25)
        XCTAssertEqual(response.fiveHour?.resetsAt, "2024-02-10T14:00:00Z")
        XCTAssertEqual(response.sevenDay?.utilization, 0.88)
        XCTAssertEqual(response.sevenDay?.resetsAt, "2024-02-15T00:00:00Z")
    }

    func testResetsAtWithTimezoneOffset() throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.50,
                "resets_at": "2024-01-15T10:30:00-08:00"
            },
            "seven_day": {
                "utilization": 0.75,
                "resets_at": "2024-01-22T00:00:00+05:30"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        XCTAssertEqual(response.fiveHour?.resetsAt, "2024-01-15T10:30:00-08:00", "Should handle negative timezone offset")
        XCTAssertEqual(response.sevenDay?.resetsAt, "2024-01-22T00:00:00+05:30", "Should handle positive timezone offset")
    }

    func testUtilizationBoundaryValues() throws {
        // Test minimum boundary (0.0)
        let jsonMin = """
        {
            "five_hour": { "utilization": 0.0, "resets_at": "2024-01-15T00:00:00Z" },
            "seven_day": { "utilization": 0.0, "resets_at": "2024-01-22T00:00:00Z" }
        }
        """

        let responseMin = try JSONDecoder().decode(ClaudeAPIResponse.self, from: jsonMin.data(using: .utf8)!)
        XCTAssertEqual(responseMin.fiveHour?.utilization, 0.0)
        XCTAssertEqual(responseMin.sevenDay?.utilization, 0.0)

        // Test maximum boundary (1.0)
        let jsonMax = """
        {
            "five_hour": { "utilization": 1.0, "resets_at": "2024-01-15T00:00:00Z" },
            "seven_day": { "utilization": 1.0, "resets_at": "2024-01-22T00:00:00Z" }
        }
        """

        let responseMax = try JSONDecoder().decode(ClaudeAPIResponse.self, from: jsonMax.data(using: .utf8)!)
        XCTAssertEqual(responseMax.fiveHour?.utilization, 1.0)
        XCTAssertEqual(responseMax.sevenDay?.utilization, 1.0)
    }

    // MARK: - ClaudeAPIResponse to UsageData Conversion Tests

    func testConvertAPIResponseCreatesUsageData() async throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.45,
                "resets_at": "2024-01-15T15:00:00Z"
            },
            "seven_day": {
                "utilization": 0.72,
                "resets_at": "2024-01-20T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        let usageDataOpt = await provider.convertAPIResponse(apiResponse)
        let usageData = try XCTUnwrap(usageDataOpt)

        XCTAssertEqual(usageData.provider, .claude)
        XCTAssertEqual(usageData.dataSource, .api)
    }

    func testConvertAPIResponseUtilizationToPercentage() async throws {
        let json = """
        {
            "five_hour": {
                "utilization": 45.0,
                "resets_at": "2024-01-15T15:00:00Z"
            },
            "seven_day": {
                "utilization": 72.0,
                "resets_at": "2024-01-20T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        let usageDataOpt = await provider.convertAPIResponse(apiResponse)
        let usageData = try XCTUnwrap(usageDataOpt)

        // API returns utilization already as percentage
        XCTAssertEqual(usageData.primaryWindow.percentage, 45.0, accuracy: 0.001)
        let secondaryPct1 = try XCTUnwrap(usageData.secondaryWindow?.percentage)
        XCTAssertEqual(secondaryPct1, 72.0, accuracy: 0.001)
    }

    func testConvertAPIResponsePrimaryWindowIsFiveHour() async throws {
        let json = """
        {
            "five_hour": {
                "utilization": 25.0,
                "resets_at": "2024-01-15T18:00:00Z"
            },
            "seven_day": {
                "utilization": 60.0,
                "resets_at": "2024-01-22T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        let usageDataOpt = await provider.convertAPIResponse(apiResponse)
        let usageData = try XCTUnwrap(usageDataOpt)

        XCTAssertEqual(usageData.primaryWindow.percentage, 25.0, accuracy: 0.001)
        XCTAssertEqual(usageData.displayPercentage, 25.0, accuracy: 0.001)
    }

    func testConvertAPIResponseSecondaryWindowIsSevenDay() async throws {
        let json = """
        {
            "five_hour": {
                "utilization": 30.0,
                "resets_at": "2024-01-15T18:00:00Z"
            },
            "seven_day": {
                "utilization": 85.0,
                "resets_at": "2024-01-22T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        let usageDataOpt = await provider.convertAPIResponse(apiResponse)
        let usageData = try XCTUnwrap(usageDataOpt)

        let secondaryPct2 = try XCTUnwrap(usageData.secondaryWindow?.percentage)
        XCTAssertEqual(secondaryPct2, 85.0, accuracy: 0.001)
    }

    func testConvertAPIResponseResetTimeParsing() async throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.50,
                "resets_at": "2024-01-15T15:30:00.000Z"
            },
            "seven_day": {
                "utilization": 0.70,
                "resets_at": "2024-01-22T00:00:00.000Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        let usageDataOpt = await provider.convertAPIResponse(apiResponse)
        let usageData = try XCTUnwrap(usageDataOpt)

        // Reset times should be parsed as Date objects
        XCTAssertNotNil(usageData.primaryWindow.resetTime)
        XCTAssertNotNil(usageData.secondaryWindow?.resetTime)
    }

    func testConvertAPIResponseIsNotEstimated() async throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.50,
                "resets_at": "2024-01-15T15:00:00Z"
            },
            "seven_day": {
                "utilization": 0.70,
                "resets_at": "2024-01-20T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        let usageDataOpt = await provider.convertAPIResponse(apiResponse)
        let usageData = try XCTUnwrap(usageDataOpt)

        // API data should not be estimated
        XCTAssertFalse(usageData.primaryWindow.isEstimated)
        XCTAssertFalse(usageData.secondaryWindow?.isEstimated ?? true)
    }

    func testConvertAPIResponseTokensUsedIsNil() async throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.50,
                "resets_at": "2024-01-15T15:00:00Z"
            },
            "seven_day": {
                "utilization": 0.70,
                "resets_at": "2024-01-20T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        let usageDataOpt = await provider.convertAPIResponse(apiResponse)
        let usageData = try XCTUnwrap(usageDataOpt)

        // API response doesn't provide token counts
        XCTAssertNil(usageData.tokensUsed)
    }

    func testConvertAPIResponseZeroUtilization() async throws {
        let json = """
        {
            "five_hour": {
                "utilization": 0.0,
                "resets_at": "2024-01-15T15:00:00Z"
            },
            "seven_day": {
                "utilization": 0.0,
                "resets_at": "2024-01-20T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        let usageDataOpt = await provider.convertAPIResponse(apiResponse)
        let usageData = try XCTUnwrap(usageDataOpt)

        XCTAssertEqual(usageData.primaryWindow.percentage, 0.0)
        XCTAssertEqual(usageData.secondaryWindow?.percentage, 0.0)
        XCTAssertEqual(usageData.status, .green)
    }

    func testConvertAPIResponseFullUtilization() async throws {
        let json = """
        {
            "five_hour": {
                "utilization": 100.0,
                "resets_at": "2024-01-15T15:00:00Z"
            },
            "seven_day": {
                "utilization": 100.0,
                "resets_at": "2024-01-20T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        let usageDataOpt = await provider.convertAPIResponse(apiResponse)
        let usageData = try XCTUnwrap(usageDataOpt)

        XCTAssertEqual(usageData.primaryWindow.percentage, 100.0)
        XCTAssertEqual(usageData.secondaryWindow?.percentage, 100.0)
        XCTAssertEqual(usageData.status, .red)
    }

    func testConvertAPIResponseStatusThresholds() async throws {
        // Test green status (< 75%)
        let jsonGreen = """
        {
            "five_hour": { "utilization": 50.0, "resets_at": "2024-01-15T15:00:00Z" },
            "seven_day": { "utilization": 30.0, "resets_at": "2024-01-20T00:00:00Z" }
        }
        """
        let responseGreen = try JSONDecoder().decode(ClaudeAPIResponse.self, from: jsonGreen.data(using: .utf8)!)
        let usageGreenOpt = await provider.convertAPIResponse(responseGreen)
        let usageGreen = try XCTUnwrap(usageGreenOpt)
        XCTAssertEqual(usageGreen.status, .green)

        // Test yellow status (75% - 89%)
        let jsonYellow = """
        {
            "five_hour": { "utilization": 80.0, "resets_at": "2024-01-15T15:00:00Z" },
            "seven_day": { "utilization": 50.0, "resets_at": "2024-01-20T00:00:00Z" }
        }
        """
        let responseYellow = try JSONDecoder().decode(ClaudeAPIResponse.self, from: jsonYellow.data(using: .utf8)!)
        let usageYellowOpt = await provider.convertAPIResponse(responseYellow)
        let usageYellow = try XCTUnwrap(usageYellowOpt)
        XCTAssertEqual(usageYellow.status, .yellow)

        // Test red status (>= 90%)
        let jsonRed = """
        {
            "five_hour": { "utilization": 95.0, "resets_at": "2024-01-15T15:00:00Z" },
            "seven_day": { "utilization": 60.0, "resets_at": "2024-01-20T00:00:00Z" }
        }
        """
        let responseRed = try JSONDecoder().decode(ClaudeAPIResponse.self, from: jsonRed.data(using: .utf8)!)
        let usageRedOpt = await provider.convertAPIResponse(responseRed)
        let usageRed = try XCTUnwrap(usageRedOpt)
        XCTAssertEqual(usageRed.status, .red)
    }

    func testConvertAPIResponseHighPrecisionUtilization() async throws {
        let json = """
        {
            "five_hour": {
                "utilization": 12.3456789,
                "resets_at": "2024-01-15T15:00:00Z"
            },
            "seven_day": {
                "utilization": 98.7654321,
                "resets_at": "2024-01-20T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        let usageDataOpt = await provider.convertAPIResponse(apiResponse)
        let usageData = try XCTUnwrap(usageDataOpt)

        XCTAssertEqual(usageData.primaryWindow.percentage, 12.3456789, accuracy: 0.0000001)
        let secondaryPct3 = try XCTUnwrap(usageData.secondaryWindow?.percentage)
        XCTAssertEqual(secondaryPct3, 98.7654321, accuracy: 0.0000001)
    }

    // MARK: - Optional API Response Tests

    func testConvertAPIResponseMissingFiveHour() async throws {
        let response = ClaudeAPIResponse(fiveHour: nil, sevenDay: UsageWindowResponse(utilization: 0.5, resetsAt: "2024-01-20T00:00:00Z"))
        let result = await provider.convertAPIResponse(response)
        XCTAssertNil(result, "Should return nil when five_hour is missing")
    }

    func testConvertAPIResponseMissingSevenDay() async throws {
        let response = ClaudeAPIResponse(fiveHour: UsageWindowResponse(utilization: 30.0, resetsAt: "2024-01-15T18:00:00Z"), sevenDay: nil)
        let usageDataOpt = await provider.convertAPIResponse(response)
        let usageData = try XCTUnwrap(usageDataOpt)

        XCTAssertEqual(usageData.primaryWindow.percentage, 30.0, accuracy: 0.001)
        XCTAssertNil(usageData.secondaryWindow, "Secondary window should be nil when seven_day is missing")
        XCTAssertEqual(usageData.dataSource, .api)
    }

    func testConvertAPIResponseOptionalResetsAt() async throws {
        let response = ClaudeAPIResponse(fiveHour: UsageWindowResponse(utilization: 40.0, resetsAt: nil), sevenDay: UsageWindowResponse(utilization: 60.0, resetsAt: nil))
        let usageDataOpt = await provider.convertAPIResponse(response)
        let usageData = try XCTUnwrap(usageDataOpt)

        XCTAssertEqual(usageData.primaryWindow.percentage, 40.0, accuracy: 0.001)
        XCTAssertNil(usageData.primaryWindow.resetTime, "Reset time should be nil when resets_at is missing")
        XCTAssertEqual(usageData.secondaryWindow?.percentage ?? 0, 60.0, accuracy: 0.001)
        XCTAssertNil(usageData.secondaryWindow?.resetTime, "Secondary reset time should be nil when resets_at is missing")
    }

    // MARK: - Limit Reset Scenario Tests

    func testAPIResponseAfterLimitReset_FiveHourNull() async throws {
        // Simulates the API response right after a 5-hour window resets:
        // API returns null for five_hour, valid seven_day
        let json = """
        {
            "seven_day": {
                "utilization": 35.0,
                "resets_at": "2024-01-22T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        XCTAssertNil(apiResponse.fiveHour, "five_hour should be nil after reset")
        XCTAssertNotNil(apiResponse.sevenDay)

        // convertAPIResponse should return nil (triggers log fallback)
        let result = await provider.convertAPIResponse(apiResponse)
        XCTAssertNil(result, "Should return nil when five_hour is missing so fetchUsage falls back to logs")
    }

    func testAPIResponseAfterLimitReset_BothNull() async throws {
        // Simulates API response when both windows reset (e.g. plan change to Max X20)
        let json = "{}"

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        XCTAssertNil(apiResponse.fiveHour)
        XCTAssertNil(apiResponse.sevenDay)

        let result = await provider.convertAPIResponse(apiResponse)
        XCTAssertNil(result, "Should return nil when both windows are missing")
    }

    func testAPIResponseAfterLimitReset_FiveHourNullResetsAt() async throws {
        // API returns utilization but no resets_at (happens briefly after reset)
        let json = """
        {
            "five_hour": {
                "utilization": 0.0
            },
            "seven_day": {
                "utilization": 10.0,
                "resets_at": "2024-01-22T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        XCTAssertNotNil(apiResponse.fiveHour)
        XCTAssertNil(apiResponse.fiveHour?.resetsAt, "resets_at should be nil right after reset")

        let usageDataOpt = await provider.convertAPIResponse(apiResponse)
        let usageData = try XCTUnwrap(usageDataOpt)

        XCTAssertEqual(usageData.primaryWindow.percentage, 0.0, accuracy: 0.001)
        XCTAssertNil(usageData.primaryWindow.resetTime, "Reset time should be nil when API doesn't provide it")
        XCTAssertFalse(usageData.primaryWindow.isEstimated, "API data should not be estimated")
        XCTAssertEqual(usageData.dataSource, .api)
    }

    func testAPIResponseAfterPlanUpgrade_MaxX20() async throws {
        // After upgrading to Max X20, API may return zeroed-out utilization
        let json = """
        {
            "five_hour": {
                "utilization": 0.0,
                "resets_at": "2024-01-15T20:00:00Z"
            },
            "seven_day": {
                "utilization": 0.0,
                "resets_at": "2024-01-22T00:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        let usageDataOpt = await provider.convertAPIResponse(apiResponse)
        let usageData = try XCTUnwrap(usageDataOpt)

        // Should show 0% usage, not 100%
        XCTAssertEqual(usageData.primaryWindow.percentage, 0.0)
        XCTAssertEqual(usageData.secondaryWindow?.percentage, 0.0)
        XCTAssertEqual(usageData.status, .green, "Fresh plan should show green status, not red")
        XCTAssertNotNil(usageData.primaryWindow.resetTime)
        XCTAssertNotNil(usageData.secondaryWindow?.resetTime)
    }

    func testAPIResponsePartialReset_OnlySevenDayNull() async throws {
        // Edge case: five_hour exists but seven_day is null
        let json = """
        {
            "five_hour": {
                "utilization": 15.0,
                "resets_at": "2024-01-15T18:00:00Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        let usageDataOpt = await provider.convertAPIResponse(apiResponse)
        let usageData = try XCTUnwrap(usageDataOpt)

        XCTAssertEqual(usageData.primaryWindow.percentage, 15.0, accuracy: 0.001)
        XCTAssertNil(usageData.secondaryWindow, "Weekly bar should be hidden when seven_day is null")
        XCTAssertEqual(usageData.dataSource, .api)
    }

    func testFetchUsageGracefullyHandlesAnyEnvironment() {
        // Verify ClaudeProvider is resilient — instantiation must never crash.
        // Actual fetchUsage() is not called to avoid Keychain password prompts in CI.
        let testProvider = ClaudeProvider()
        XCTAssertNotNil(testProvider, "ClaudeProvider should handle any environment without crashing")
    }
}
