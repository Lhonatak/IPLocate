//
//  LocationAPIServiceTests.swift
//  IPLocateTests
//
//  Created by Caitsy on 08/04/2026.
//

import XCTest
import Foundation
@testable import IPLocate

final class LocationAPIServiceTests: XCTestCase {
    
    var sut: LocationAPIService!
    var mockSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        sut = LocationAPIService(session: mockSession)
    }
    
    override func tearDown() {
        sut = nil
        mockSession = nil
        super.tearDown()
    }
    
    // MARK: - Valid IP Address Tests
    
    func testFetchLocationWithValidIP() async throws {
        // Given
        let validIP = "8.8.8.8"
        let expectedResponse = createValidLocationResponse()
        mockSession.mockData = try JSONEncoder().encode(expectedResponse)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://tools.keycdn.com/geo.json")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = try await sut.fetchLocation(for: validIP)
        
        // Then
        XCTAssertEqual(result.ip, "8.8.8.8")
        XCTAssertEqual(result.city, "Mountain View")
        XCTAssertEqual(result.countryName, "United States")
        XCTAssertEqual(result.latitude, 37.4056, accuracy: 0.0001)
        XCTAssertEqual(result.longitude, -122.0775, accuracy: 0.0001)
    }
    
    // MARK: - Invalid IP Address Tests
    
    func testFetchLocationWithInvalidIPFormat() async {
        // Given
        let invalidIPs = [
            "256.256.256.256",  // Numbers too high
            "192.168.1",        // Incomplete
            "192.168.1.1.1",    // Too many octets
            "abc.def.ghi.jkl",  // Non-numeric
            "",                 // Empty string
            "192.168.-1.1",     // Negative number
            "192.168.1.256"     // Last octet too high
        ]
        
        for invalidIP in invalidIPs {
            // When/Then
            do {
                _ = try await sut.fetchLocation(for: invalidIP)
                XCTFail("Expected invalidIP error for \(invalidIP)")
            } catch LocationServiceError.invalidIP {
                // Expected error
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    // MARK: - Network Error Tests
    
    func testFetchLocationWithNetworkError() async {
        // Given
        let validIP = "8.8.8.8"
        let networkError = NSError(domain: "TestError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "Network connection lost"])
        mockSession.mockError = networkError
        
        // When/Then
        do {
            _ = try await sut.fetchLocation(for: validIP)
            XCTFail("Expected network error")
        } catch LocationServiceError.networkError(let error) {
            XCTAssertEqual((error as NSError).code, -1009)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - HTTP Status Code Tests
    
    func testFetchLocationWithHTTPErrorStatusCodes() async {
        let testCases = [
            (statusCode: 400, description: "Bad Request"),
            (statusCode: 401, description: "Unauthorized"),
            (statusCode: 403, description: "Forbidden"),
            (statusCode: 404, description: "Not Found"),
            (statusCode: 500, description: "Internal Server Error"),
            (statusCode: 502, description: "Bad Gateway")
        ]
        
        for testCase in testCases {
            // Given
            let validIP = "8.8.8.8"
            mockSession.mockData = "Error response".data(using: .utf8)! // Provide some data
            mockSession.mockResponse = HTTPURLResponse(
                url: URL(string: "https://tools.keycdn.com/geo.json")!,
                statusCode: testCase.statusCode,
                httpVersion: nil,
                headerFields: nil
            )
            mockSession.mockError = nil // Ensure no error is set
            
            // When/Then
            do {
                _ = try await sut.fetchLocation(for: validIP)
                XCTFail("Expected network error for status code \(testCase.statusCode)")
            } catch LocationServiceError.networkError(let error) {
                let nsError = error as NSError
                XCTAssertEqual(nsError.code, testCase.statusCode, "Status code should match for \(testCase.description)")
            } catch {
                XCTFail("Unexpected error type for \(testCase.description): \(error)")
            }
        }
    }
    
    // MARK: - Rate Limiting Tests
    
    func testFetchLocationWithRateLimitError() async {
        // Given
        let validIP = "8.8.8.8"
        mockSession.mockData = "Rate limited".data(using: .utf8)! // Provide some data
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://tools.keycdn.com/geo.json")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        )
        mockSession.mockError = nil // Ensure no error is set
        
        // When/Then
        do {
            _ = try await sut.fetchLocation(for: validIP)
            XCTFail("Expected rate limit error")
        } catch LocationServiceError.rateLimited {
            // Expected error
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - JSON Parsing Tests
    
    func testFetchLocationWithInvalidJSON() async {
        // Given
        let validIP = "8.8.8.8"
        let invalidJSON = "{ invalid json data }"
        mockSession.mockData = invalidJSON.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://tools.keycdn.com/geo.json")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        do {
            _ = try await sut.fetchLocation(for: validIP)
            XCTFail("Expected decoding error")
        } catch LocationServiceError.decodingError {
            // Expected error
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchLocationWithAPIErrorResponse() async {
        // Given
        let validIP = "8.8.8.8"
        let errorResponse = LocationAPIResponse(
            status: "fail",
            description: "Invalid request",
            data: LocationResponseData(geo: createValidGeoData())
        )
        mockSession.mockData = try! JSONEncoder().encode(errorResponse)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://tools.keycdn.com/geo.json")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        do {
            _ = try await sut.fetchLocation(for: validIP)
            XCTFail("Expected invalid response error")
        } catch LocationServiceError.invalidResponse {
            // Expected error
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - URL Building Tests
    
    func testCorrectURLIsBuilt() async {
        // Given
        let validIP = "8.8.8.8"
        let expectedResponse = createValidLocationResponse()
        mockSession.mockData = try! JSONEncoder().encode(expectedResponse)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://tools.keycdn.com/geo.json")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        _ = try? await sut.fetchLocation(for: validIP)
        
        // Then
        XCTAssertNotNil(mockSession.lastRequest)
        XCTAssertEqual(mockSession.lastRequest?.url?.scheme, "https")
        XCTAssertEqual(mockSession.lastRequest?.url?.host, "tools.keycdn.com")
        XCTAssertEqual(mockSession.lastRequest?.url?.path, "/geo.json")
        
        let queryItems = URLComponents(url: mockSession.lastRequest!.url!, resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(queryItems?.first?.name, "host")
        XCTAssertEqual(queryItems?.first?.value, validIP)
    }
    
    func testCorrectHeadersAreSet() async {
        // Given
        let validIP = "8.8.8.8"
        let expectedResponse = createValidLocationResponse()
        mockSession.mockData = try! JSONEncoder().encode(expectedResponse)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://tools.keycdn.com/geo.json")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        _ = try? await sut.fetchLocation(for: validIP)
        
        // Then
        XCTAssertNotNil(mockSession.lastRequest)
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "User-Agent"), "keycdn-tools:https://usr.com")
    }
    
    // MARK: - Helper Methods
    
    private func createValidLocationResponse() -> LocationAPIResponse {
        return LocationAPIResponse(
            status: "success",
            description: "Success",
            data: LocationResponseData(geo: createValidGeoData())
        )
    }
    
    private func createValidGeoData() -> LocationGeoData {
        return LocationGeoData(
            host: "8.8.8.8",
            ip: "8.8.8.8",
            asn: 15169,
            isp: "Google LLC",
            countryName: "United States",
            countryCode: "US",
            regionName: "California",
            regionCode: "CA",
            city: "Mountain View",
            postalCode: "94035",
            continentName: "North America",
            continentCode: "NA",
            latitude: 37.4056,
            longitude: -122.0775,
            metroCode: "807",
            timezone: "America/Los_Angeles",
            datetime: "2026-04-08 12:00:00"
        )
    }
}

// MARK: - Mock URLSession

final class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var lastRequest: URLRequest?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (data, response)
    }
}
