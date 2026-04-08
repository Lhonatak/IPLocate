//
//  MockLocationService.swift
//  IPLocate
//
//  Created by Caitsy on 07/04/2026.
//

import Foundation

// MARK: - Mock Service for Testing/Preview
final class MockLocationService: LocationServiceProtocol {
    var shouldFail: Bool = false
    var delay: TimeInterval = 1.0
    
    func fetchLocation(for ipAddress: String) async throws -> LocationData {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        if shouldFail {
            throw LocationServiceError.networkError(NSError(domain: "MockError", code: 0))
        }
        
        // Return mock data based on IP
        switch ipAddress {
        case "8.8.8.8":
            return LocationData(
                ip: "8.8.8.8",
                city: "Mountain View",
                regionName: "California",
                countryName: "United States",
                countryCode: "US",
                latitude: 37.4056,
                longitude: -122.0775,
                isp: "Google LLC",
                timezone: "America/Los_Angeles",
                datetime: Date(),
                savedDate: Date()
            )
        case "1.1.1.1":
            return LocationData(
                ip: "1.1.1.1",
                city: "San Francisco",
                regionName: "California",
                countryName: "United States",
                countryCode: "US",
                latitude: 37.7749,
                longitude: -122.4194,
                isp: "Cloudflare",
                timezone: "America/Los_Angeles",
                datetime: Date(),
                savedDate: Date()
            )
        default:
            return LocationData(
                ip: ipAddress,
                city: "London",
                regionName: "England",
                countryName: "United Kingdom",
                countryCode: "GB",
                latitude: 51.5074,
                longitude: -0.1278,
                isp: "Mock ISP",
                timezone: "Europe/London",
                datetime: Date(),
                savedDate: Date()
            )
        }
    }
}