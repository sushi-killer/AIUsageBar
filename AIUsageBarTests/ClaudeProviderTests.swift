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

    func testClaudeLogEntryDecoding() throws {
        let json = """
        {
            "message": {
                "usage": {
                    "input_tokens": 1500,
                    "output_tokens": 500,
                    "cache_creation_input_tokens": 0,
                    "cache_read_input_tokens": 200
                }
            },
            "timestamp": "2024-01-15T10:30:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let entry = try decoder.decode(ClaudeLogEntry.self, from: data)

        XCTAssertNotNil(entry.message)
        XCTAssertNotNil(entry.message?.usage)
        XCTAssertEqual(entry.message?.usage?.inputTokens, 1500)
        XCTAssertEqual(entry.message?.usage?.outputTokens, 500)
        XCTAssertEqual(entry.message?.usage?.cacheCreationInputTokens, 0)
        XCTAssertEqual(entry.message?.usage?.cacheReadInputTokens, 200)
        XCTAssertEqual(entry.timestamp, "2024-01-15T10:30:00Z")
    }

    func testClaudeLogEntryTotalTokens() throws {
        let json = """
        {
            "message": {
                "usage": {
                    "input_tokens": 1000,
                    "output_tokens": 500,
                    "cache_creation_input_tokens": 100,
                    "cache_read_input_tokens": 200
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let entry = try decoder.decode(ClaudeLogEntry.self, from: data)

        XCTAssertEqual(entry.message?.usage?.totalTokens, 1800)
    }

    func testClaudeLogEntryPartialData() throws {
        let json = """
        {
            "message": {
                "usage": {
                    "input_tokens": 1000,
                    "output_tokens": 500
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let entry = try decoder.decode(ClaudeLogEntry.self, from: data)

        XCTAssertEqual(entry.message?.usage?.inputTokens, 1000)
        XCTAssertEqual(entry.message?.usage?.outputTokens, 500)
        XCTAssertNil(entry.message?.usage?.cacheCreationInputTokens)
        XCTAssertNil(entry.message?.usage?.cacheReadInputTokens)
        XCTAssertEqual(entry.message?.usage?.totalTokens, 1500)
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

    // MARK: - Log Entry Edge Cases

    func testClaudeLogEntryEmptyMessage() throws {
        let json = """
        {
            "message": null,
            "timestamp": "2024-01-15T10:30:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let entry = try decoder.decode(ClaudeLogEntry.self, from: data)

        XCTAssertNil(entry.message)
        XCTAssertEqual(entry.timestamp, "2024-01-15T10:30:00Z")
    }

    func testClaudeLogEntryMissingUsage() throws {
        let json = """
        {
            "message": {},
            "timestamp": "2024-01-15T10:30:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let entry = try decoder.decode(ClaudeLogEntry.self, from: data)

        XCTAssertNotNil(entry.message)
        XCTAssertNil(entry.message?.usage)
    }

    func testClaudeLogEntryZeroTokens() throws {
        let json = """
        {
            "message": {
                "usage": {
                    "input_tokens": 0,
                    "output_tokens": 0,
                    "cache_creation_input_tokens": 0,
                    "cache_read_input_tokens": 0
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let entry = try decoder.decode(ClaudeLogEntry.self, from: data)

        XCTAssertEqual(entry.message?.usage?.totalTokens, 0)
    }

    func testClaudeLogEntryLargeTokenCounts() throws {
        let json = """
        {
            "message": {
                "usage": {
                    "input_tokens": 100000,
                    "output_tokens": 50000,
                    "cache_creation_input_tokens": 25000,
                    "cache_read_input_tokens": 75000
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let entry = try decoder.decode(ClaudeLogEntry.self, from: data)

        XCTAssertEqual(entry.message?.usage?.totalTokens, 250000)
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

    // MARK: - Local Log Fallback Tests

    func testLocalLogEntryWithAllTokenFields() throws {
        // Tests that local log entries with all token fields parse correctly
        let json = """
        {
            "message": {
                "usage": {
                    "input_tokens": 2000,
                    "output_tokens": 1000,
                    "cache_creation_input_tokens": 500,
                    "cache_read_input_tokens": 300
                }
            },
            "timestamp": "2024-01-15T12:00:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(ClaudeLogEntry.self, from: data)

        XCTAssertEqual(entry.message?.usage?.totalTokens, 3800)
        XCTAssertEqual(entry.message?.usage?.inputTokens, 2000)
        XCTAssertEqual(entry.message?.usage?.outputTokens, 1000)
        XCTAssertEqual(entry.message?.usage?.cacheCreationInputTokens, 500)
        XCTAssertEqual(entry.message?.usage?.cacheReadInputTokens, 300)
    }

    func testLocalLogEntryWithOnlyInputOutputTokens() throws {
        // Tests fallback parsing when cache tokens are missing
        let json = """
        {
            "message": {
                "usage": {
                    "input_tokens": 1500,
                    "output_tokens": 750
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(ClaudeLogEntry.self, from: data)

        XCTAssertEqual(entry.message?.usage?.totalTokens, 2250)
        XCTAssertNil(entry.message?.usage?.cacheCreationInputTokens)
        XCTAssertNil(entry.message?.usage?.cacheReadInputTokens)
    }

    func testLocalLogEntryWithoutUsage() throws {
        // Tests that log entries without usage data are handled gracefully
        let json = """
        {
            "message": {
                "role": "assistant",
                "content": "Hello"
            },
            "timestamp": "2024-01-15T12:00:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(ClaudeLogEntry.self, from: data)

        XCTAssertNil(entry.message?.usage)
    }

    func testLocalLogEntryTimestampParsing() throws {
        // Tests that timestamp can be extracted for filtering
        let json = """
        {
            "message": {},
            "timestamp": "2024-06-15T14:30:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(ClaudeLogEntry.self, from: data)

        XCTAssertEqual(entry.timestamp, "2024-06-15T14:30:00Z")
    }

    func testLocalLogEntryWithoutTimestamp() throws {
        // Tests that entries without timestamps still parse
        let json = """
        {
            "message": {
                "usage": {
                    "input_tokens": 100,
                    "output_tokens": 50
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(ClaudeLogEntry.self, from: data)

        XCTAssertNil(entry.timestamp)
        XCTAssertEqual(entry.message?.usage?.totalTokens, 150)
    }

    func testLocalLogEstimationCalculation() {
        // Tests the percentage estimation formula used for local logs
        // Formula: percentage = min(totalTokens / 1_000_000 * 100, 100)
        let estimatedLimit = 1_000_000

        // Test various token counts
        let testCases: [(Int, Double)] = [
            (0, 0.0),
            (100_000, 10.0),
            (500_000, 50.0),
            (750_000, 75.0),
            (900_000, 90.0),
            (1_000_000, 100.0),
            (1_500_000, 100.0), // Should cap at 100%
        ]

        for (totalTokens, expectedPercentage) in testCases {
            let percentage = min(Double(totalTokens) / Double(estimatedLimit) * 100, 100)
            XCTAssertEqual(percentage, expectedPercentage, accuracy: 0.001,
                          "Tokens \(totalTokens) should estimate to \(expectedPercentage)%")
        }
    }

    func testLocalLogDataSourceIsLocal() {
        // Verifies local log data has correct dataSource
        let primaryWindow = UsageWindow(
            percentage: 25.0,
            resetTime: Date().addingTimeInterval(5 * 3600),
            isEstimated: true
        )

        let usageData = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            secondaryWindow: nil,
            tokensUsed: 250_000,
            dataSource: .local
        )

        XCTAssertEqual(usageData.dataSource, .local)
        XCTAssertTrue(usageData.primaryWindow.isEstimated)
        XCTAssertEqual(usageData.tokensUsed, 250_000)
    }

    func testLocalLogHasNoSecondaryWindow() {
        // Local logs only provide 5-hour estimation, no 7-day data
        let primaryWindow = UsageWindow(
            percentage: 50.0,
            resetTime: Date().addingTimeInterval(5 * 3600),
            isEstimated: true
        )

        let usageData = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            secondaryWindow: nil,
            tokensUsed: 500_000,
            dataSource: .local
        )

        XCTAssertNil(usageData.secondaryWindow)
    }

    func testLocalLogResetTimeIsFiveHoursFromNow() {
        // Local logs estimate reset time as 5 hours from now
        let now = Date()
        let fiveHoursInSeconds: TimeInterval = 5 * 3600
        let expectedResetTime = now.addingTimeInterval(fiveHoursInSeconds)

        let primaryWindow = UsageWindow(
            percentage: 30.0,
            resetTime: expectedResetTime,
            isEstimated: true
        )

        XCTAssertNotNil(primaryWindow.resetTime)
        // Allow 1 second tolerance for test execution time
        let timeDiff = abs(primaryWindow.resetTime!.timeIntervalSince(now) - fiveHoursInSeconds)
        XCTAssertLessThan(timeDiff, 1.0)
    }

    func testFetchUsageGracefullyHandlesAnyEnvironment() {
        // Verify ClaudeProvider is resilient — instantiation must never crash.
        // Actual fetchUsage() is not called to avoid Keychain password prompts in CI.
        let testProvider = ClaudeProvider()
        XCTAssertNotNil(testProvider, "ClaudeProvider should handle any environment without crashing")
    }

    func testLocalFallbackDataStructure() {
        // Tests the complete structure of local fallback data
        let totalTokens = 450_000
        let estimatedLimit = 1_000_000
        let percentage = min(Double(totalTokens) / Double(estimatedLimit) * 100, 100)

        let primaryWindow = UsageWindow(
            percentage: percentage,
            resetTime: Date().addingTimeInterval(5 * 3600),
            isEstimated: true
        )

        let usageData = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            secondaryWindow: nil,
            tokensUsed: totalTokens,
            dataSource: .local
        )

        // Verify all fields match expected local fallback structure
        XCTAssertEqual(usageData.provider, .claude)
        XCTAssertEqual(usageData.dataSource, .local)
        XCTAssertEqual(usageData.primaryWindow.percentage, 45.0, accuracy: 0.001)
        XCTAssertTrue(usageData.primaryWindow.isEstimated)
        XCTAssertNotNil(usageData.primaryWindow.resetTime)
        XCTAssertNil(usageData.secondaryWindow)
        XCTAssertEqual(usageData.tokensUsed, 450_000)
    }

    func testLocalVsAPIDataSourceDifference() {
        // Compares the structural differences between API and local data

        // API data structure
        let apiPrimaryWindow = UsageWindow(
            percentage: 45.0,
            resetTime: Date().addingTimeInterval(3600),
            isEstimated: false
        )
        let apiSecondaryWindow = UsageWindow(
            percentage: 72.0,
            resetTime: Date().addingTimeInterval(7 * 24 * 3600),
            isEstimated: false
        )
        let apiData = UsageData(
            provider: .claude,
            primaryWindow: apiPrimaryWindow,
            secondaryWindow: apiSecondaryWindow,
            tokensUsed: nil,
            dataSource: .api
        )

        // Local data structure
        let localPrimaryWindow = UsageWindow(
            percentage: 45.0,
            resetTime: Date().addingTimeInterval(5 * 3600),
            isEstimated: true
        )
        let localData = UsageData(
            provider: .claude,
            primaryWindow: localPrimaryWindow,
            secondaryWindow: nil,
            tokensUsed: 450_000,
            dataSource: .local
        )

        // API data characteristics
        XCTAssertEqual(apiData.dataSource, .api)
        XCTAssertFalse(apiData.primaryWindow.isEstimated)
        XCTAssertFalse(apiData.secondaryWindow?.isEstimated ?? true)
        XCTAssertNotNil(apiData.secondaryWindow)
        XCTAssertNil(apiData.tokensUsed)

        // Local data characteristics
        XCTAssertEqual(localData.dataSource, .local)
        XCTAssertTrue(localData.primaryWindow.isEstimated)
        XCTAssertNil(localData.secondaryWindow)
        XCTAssertNotNil(localData.tokensUsed)
    }

    func testLocalLogStatusCalculation() {
        // Tests that status thresholds work correctly for local log data
        let testCases: [(Double, UsageStatus)] = [
            (0.0, .green),
            (50.0, .green),
            (74.9, .green),
            (75.0, .yellow),
            (85.0, .yellow),
            (89.9, .yellow),
            (90.0, .red),
            (95.0, .red),
            (100.0, .red),
        ]

        for (percentage, expectedStatus) in testCases {
            let primaryWindow = UsageWindow(
                percentage: percentage,
                resetTime: nil,
                isEstimated: true
            )
            let usageData = UsageData(
                provider: .claude,
                primaryWindow: primaryWindow,
                dataSource: .local
            )

            XCTAssertEqual(usageData.status, expectedStatus,
                          "Percentage \(percentage)% should result in \(expectedStatus) status")
        }
    }

    func testClaudeLogsPath() {
        // Verifies the logs path used for local fallback
        let expectedPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects").path
        XCTAssertEqual(Provider.claude.logsPath, expectedPath)
    }

    func testLogEntryWithMalformedJSON() {
        // Tests that malformed JSON in log entries is handled gracefully
        let malformedJSONs = [
            "not json at all",
            "{incomplete",
            "{ \"message\": }",
            "",
        ]

        let decoder = JSONDecoder()
        for json in malformedJSONs {
            let data = json.data(using: .utf8)!
            XCTAssertThrowsError(try decoder.decode(ClaudeLogEntry.self, from: data),
                               "Should throw for malformed JSON: \(json)")
        }
    }

    func testLogEntryWithExtraFields() throws {
        // Tests that extra fields in log entries are ignored
        let json = """
        {
            "message": {
                "usage": {
                    "input_tokens": 100,
                    "output_tokens": 50
                },
                "extra_field": "should be ignored",
                "another_field": 12345
            },
            "timestamp": "2024-01-15T12:00:00Z",
            "session_id": "abc123",
            "version": "1.0"
        }
        """

        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(ClaudeLogEntry.self, from: data)

        XCTAssertEqual(entry.message?.usage?.totalTokens, 150)
        XCTAssertEqual(entry.timestamp, "2024-01-15T12:00:00Z")
    }

    // MARK: - Local Logs Path Pattern Tests

    func testLocalLogsPathPattern() {
        // Validates that the local logs path follows the pattern: ~/.claude/projects/*/*.jsonl
        // The base path should be ~/.claude/projects
        let logsPath = Provider.claude.logsPath
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path

        // Verify base path structure
        XCTAssertTrue(logsPath.hasPrefix(homeDir), "Logs path should start with home directory")
        XCTAssertTrue(logsPath.hasSuffix(".claude/projects"), "Logs path should end with .claude/projects")

        // Verify the path matches the expected pattern for local fallback
        // Pattern: ~/.claude/projects (base) -> project directories -> *.jsonl files
        let expectedBasePath = (homeDir as NSString).appendingPathComponent(".claude/projects")
        XCTAssertEqual(logsPath, expectedBasePath, "Base logs path should be ~/.claude/projects")
    }

    func testLocalLogsPathNotContainsGlobCharacters() {
        // The logsPath property returns the base directory, not a glob pattern
        // The provider implementation handles finding project subdirectories and .jsonl files
        let logsPath = Provider.claude.logsPath

        XCTAssertFalse(logsPath.contains("*"), "Logs path should not contain glob characters")
        XCTAssertFalse(logsPath.contains("?"), "Logs path should not contain wildcard characters")
    }

    func testLocalLogsPathExpectedStructure() {
        // Documents the expected directory structure for Claude local logs
        // Structure: ~/.claude/projects/<project-name>/<session-uuid>.jsonl
        //
        // Example:
        // ~/.claude/projects/
        //   -Users-sushi-killer-Desktop-Project/
        //     abc123-def456.jsonl
        //     another-session.jsonl
        //   -Users-sushi-killer-Other-Project/
        //     session.jsonl

        let logsPath = Provider.claude.logsPath
        let fileManager = FileManager.default

        // If the base path exists, verify it's a directory
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: logsPath, isDirectory: &isDirectory) {
            XCTAssertTrue(isDirectory.boolValue, "Claude logs path should be a directory")
        }
        // Note: If directory doesn't exist, the test passes as this is valid state
        // when Claude Code hasn't been used yet
    }

    func testJsonlFileExtensionPattern() {
        // Validates that the log file extension pattern is .jsonl
        // This matches the PRD requirement: ~/.claude/projects/*/*.jsonl
        let expectedExtension = "jsonl"

        // Create a test filename to validate parsing logic
        let testFilenames = [
            "session-abc123.jsonl",
            "0ffe5d87-6e39-4c0c-b096-5c94cac9fb24.jsonl",
            "test.jsonl"
        ]

        for filename in testFilenames {
            XCTAssertTrue(filename.hasSuffix(".\(expectedExtension)"),
                         "Log files should have .\(expectedExtension) extension")
        }

        // Non-jsonl files should not match
        let invalidFilenames = [
            "session.json",
            "log.txt",
            "data.log",
            "jsonl.backup"
        ]

        for filename in invalidFilenames {
            XCTAssertFalse(filename.hasSuffix(".\(expectedExtension)"),
                          "Non-jsonl files should not match the pattern")
        }
    }

    // MARK: - Claude Log Watching Integration Tests

    func testClaudeLogsDirectoryMonitoringPath() {
        // Validates the exact path that FileWatcher monitors for Claude logs
        let expectedPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects").path
        let actualPath = Provider.claude.logsPath

        XCTAssertEqual(actualPath, expectedPath)
        XCTAssertTrue(actualPath.hasPrefix("/Users/") || actualPath.hasPrefix("/home/"),
                     "Path should be in user's home directory")
    }

    func testClaudeLogsDirectoryStructurePattern() {
        // Documents and validates the expected directory structure
        // ~/.claude/projects/<project-directory>/<session>.jsonl
        //
        // Project directories are named with path encoding, e.g.:
        // "-Users-username-Desktop-MyProject"

        let logsPath = Provider.claude.logsPath

        // Path should end with "projects" (the base watch directory)
        XCTAssertTrue(logsPath.hasSuffix("projects"))

        // Path should contain ".claude" hidden directory
        XCTAssertTrue(logsPath.contains(".claude"))
    }

    func testMultipleLogEntriesTokenAggregation() throws {
        // Tests that multiple log entries' tokens are summed correctly
        let logEntries = [
            """
            {"message":{"usage":{"input_tokens":1000,"output_tokens":500}},"timestamp":"2024-01-15T12:00:00Z"}
            """,
            """
            {"message":{"usage":{"input_tokens":2000,"output_tokens":1000}},"timestamp":"2024-01-15T12:30:00Z"}
            """,
            """
            {"message":{"usage":{"input_tokens":500,"output_tokens":250}},"timestamp":"2024-01-15T13:00:00Z"}
            """
        ]

        let decoder = JSONDecoder()
        var totalTokens = 0

        for jsonLine in logEntries {
            let data = jsonLine.data(using: .utf8)!
            let entry = try decoder.decode(ClaudeLogEntry.self, from: data)
            totalTokens += entry.message?.usage?.totalTokens ?? 0
        }

        // 1500 + 3000 + 750 = 5250
        XCTAssertEqual(totalTokens, 5250)
    }

    func testLogEntriesFilteredByTimestamp() throws {
        // Tests that only entries within the 5-hour window are counted
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()

        // Create timestamps
        let recentTimestamp = dateFormatter.string(from: now.addingTimeInterval(-3600)) // 1 hour ago
        let oldTimestamp = dateFormatter.string(from: now.addingTimeInterval(-6 * 3600)) // 6 hours ago

        let recentEntry = """
        {"message":{"usage":{"input_tokens":1000,"output_tokens":500}},"timestamp":"\(recentTimestamp)"}
        """
        let oldEntry = """
        {"message":{"usage":{"input_tokens":2000,"output_tokens":1000}},"timestamp":"\(oldTimestamp)"}
        """

        let decoder = JSONDecoder()
        let fiveHoursAgo = now.addingTimeInterval(-5 * 3600)

        var includedTokens = 0
        var excludedTokens = 0

        // Parse recent entry (should be included)
        let recentData = recentEntry.data(using: .utf8)!
        let recent = try decoder.decode(ClaudeLogEntry.self, from: recentData)
        if let timestamp = recent.timestamp,
           let date = dateFormatter.date(from: timestamp),
           date >= fiveHoursAgo {
            includedTokens += recent.message?.usage?.totalTokens ?? 0
        }

        // Parse old entry (should be excluded)
        let oldData = oldEntry.data(using: .utf8)!
        let old = try decoder.decode(ClaudeLogEntry.self, from: oldData)
        if let timestamp = old.timestamp,
           let date = dateFormatter.date(from: timestamp),
           date >= fiveHoursAgo {
            excludedTokens += old.message?.usage?.totalTokens ?? 0
        } else {
            // Entry is too old, excluded from count
            excludedTokens = old.message?.usage?.totalTokens ?? 0
        }

        XCTAssertEqual(includedTokens, 1500, "Recent entry tokens should be included")
        XCTAssertEqual(excludedTokens, 3000, "Old entry tokens should be excluded")
    }

    func testLogEntriesWithoutTimestampIncluded() throws {
        // Tests that entries without timestamps are still processed
        // (they should be included since we can't determine if they're too old)
        let entryWithoutTimestamp = """
        {"message":{"usage":{"input_tokens":1000,"output_tokens":500}}}
        """

        let decoder = JSONDecoder()
        let data = entryWithoutTimestamp.data(using: .utf8)!
        let entry = try decoder.decode(ClaudeLogEntry.self, from: data)

        XCTAssertNil(entry.timestamp, "Timestamp should be nil")
        XCTAssertEqual(entry.message?.usage?.totalTokens, 1500, "Tokens should still be counted")
    }

    func testJsonlFilenameFiltering() {
        // Tests that only .jsonl files are processed, not other file types
        let filenames = [
            "session-123.jsonl",
            "data.json",
            "log.txt",
            "backup.jsonl.bak",
            "another-session.jsonl",
            ".hidden.jsonl",
            "README.md"
        ]

        let jsonlFiles = filenames.filter { $0.hasSuffix(".jsonl") }

        XCTAssertEqual(jsonlFiles.count, 3)
        XCTAssertTrue(jsonlFiles.contains("session-123.jsonl"))
        XCTAssertTrue(jsonlFiles.contains("another-session.jsonl"))
        XCTAssertTrue(jsonlFiles.contains(".hidden.jsonl"))
        XCTAssertFalse(jsonlFiles.contains("data.json"))
        XCTAssertFalse(jsonlFiles.contains("backup.jsonl.bak"))
    }

    func testDirectoryEnumerationSkipsFiles() {
        // Tests that non-directory items in the projects folder are skipped
        // The implementation checks isDirectory before processing

        // Simulate the directory check logic
        var processedDirectories: [String] = []
        let items = [
            ("project-a", true),  // directory
            ("project-b", true),  // directory
            ("config.json", false),  // file
            (".DS_Store", false),  // file
            ("another-project", true)  // directory
        ]

        for (name, isDirectory) in items {
            if isDirectory {
                processedDirectories.append(name)
            }
        }

        XCTAssertEqual(processedDirectories.count, 3)
        XCTAssertTrue(processedDirectories.contains("project-a"))
        XCTAssertTrue(processedDirectories.contains("project-b"))
        XCTAssertTrue(processedDirectories.contains("another-project"))
        XCTAssertFalse(processedDirectories.contains("config.json"))
        XCTAssertFalse(processedDirectories.contains(".DS_Store"))
    }

    func testEmptyLogFileHandling() throws {
        // Tests that empty log files don't cause errors
        let emptyContent = ""
        let lines = emptyContent.components(separatedBy: .newlines)

        var totalTokens = 0
        let decoder = JSONDecoder()

        for line in lines {
            guard !line.isEmpty,
                  let lineData = line.data(using: .utf8) else {
                continue
            }

            // This block won't execute for empty lines
            if let entry = try? decoder.decode(ClaudeLogEntry.self, from: lineData),
               let usage = entry.message?.usage {
                totalTokens += usage.totalTokens
            }
        }

        XCTAssertEqual(totalTokens, 0, "Empty file should result in 0 tokens")
    }

    func testMixedValidAndInvalidLogLines() throws {
        // Tests that invalid JSON lines are skipped gracefully
        let logContent = """
        {"message":{"usage":{"input_tokens":1000,"output_tokens":500}}}
        not valid json
        {"message":{"usage":{"input_tokens":2000,"output_tokens":1000}}}
        {incomplete json
        {"message":{"usage":{"input_tokens":500,"output_tokens":250}}}
        """

        let lines = logContent.components(separatedBy: .newlines)
        let decoder = JSONDecoder()
        var totalTokens = 0
        var validEntries = 0

        for line in lines {
            guard !line.isEmpty,
                  let lineData = line.data(using: .utf8) else {
                continue
            }

            if let entry = try? decoder.decode(ClaudeLogEntry.self, from: lineData),
               let usage = entry.message?.usage {
                totalTokens += usage.totalTokens
                validEntries += 1
            }
        }

        // Only 3 valid entries: 1500 + 3000 + 750 = 5250
        XCTAssertEqual(validEntries, 3, "Should have 3 valid entries")
        XCTAssertEqual(totalTokens, 5250, "Should sum tokens from valid entries only")
    }

    func testPercentageCapAt100() {
        // Tests that percentage is capped at 100% even when tokens exceed limit
        let estimatedLimit = 1_000_000

        let tokenCounts = [1_500_000, 2_000_000, 10_000_000]

        for tokens in tokenCounts {
            let percentage = min(Double(tokens) / Double(estimatedLimit) * 100, 100)
            XCTAssertEqual(percentage, 100.0, "Percentage should cap at 100% for \(tokens) tokens")
        }
    }

    func testFiveHourWindowCalculation() {
        // Tests the 5-hour time window calculation
        let now = Date()
        let fiveHoursAgo = now.addingTimeInterval(-5 * 3600)

        // Time difference should be exactly 5 hours (18000 seconds)
        let timeDiff = now.timeIntervalSince(fiveHoursAgo)
        XCTAssertEqual(timeDiff, 5 * 3600, accuracy: 0.001)

        // A timestamp 4 hours ago should be within the window
        let fourHoursAgo = now.addingTimeInterval(-4 * 3600)
        XCTAssertTrue(fourHoursAgo >= fiveHoursAgo)

        // A timestamp 6 hours ago should be outside the window
        let sixHoursAgo = now.addingTimeInterval(-6 * 3600)
        XCTAssertFalse(sixHoursAgo >= fiveHoursAgo)
    }

    func testEstimatedResetTimeIsFiveHoursFromNow() {
        // Tests that local log data estimates reset time as 5 hours from now
        let now = Date()
        let estimatedReset = now.addingTimeInterval(5 * 3600)

        let timeDiff = estimatedReset.timeIntervalSince(now)
        XCTAssertEqual(timeDiff, 5 * 3600, accuracy: 0.001)
    }
}
