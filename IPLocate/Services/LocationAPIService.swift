//
//  LocationAPIService.swift
//  IPLocate
//
//  Created by Caitsy on 07/04/2026.
//

import Foundation

// MARK: - Error Types
enum LocationServiceError: LocalizedError {
    case invalidIP
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidIP:
            return "Invalid IP address format"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .rateLimited:
            return "Rate limit exceeded. Please wait a moment and try again."
        }
    }
}

// MARK: - Service Protocol
protocol LocationServiceProtocol {
    func fetchLocation(for ipAddress: String) async throws -> LocationData
}

// MARK: - Rate Limiter
@MainActor
final class RateLimiter {
    private var lastRequestTime: Date?
    private let minimumInterval: TimeInterval = 1.0/3.0 // 3 requests per second max
    
    func canMakeRequest() -> Bool {
        guard let lastTime = lastRequestTime else {
            return true
        }
        return Date().timeIntervalSince(lastTime) >= minimumInterval
    }
    
    func waitIfNeeded() async {
        guard let lastTime = lastRequestTime else {
            lastRequestTime = Date()
            return
        }
        
        let timeSinceLastRequest = Date().timeIntervalSince(lastTime)
        if timeSinceLastRequest < minimumInterval {
            let waitTime = minimumInterval - timeSinceLastRequest
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        lastRequestTime = Date()
    }
}

// MARK: - URL Session Protocol
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - Location API Service
final class LocationAPIService: LocationServiceProtocol {
    private let session: URLSessionProtocol
    private let rateLimiter = RateLimiter()
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    func fetchLocation(for ipAddress: String) async throws -> LocationData {
        guard isValidIPAddress(ipAddress) else {
            throw LocationServiceError.invalidIP
        }
        
        await rateLimiter.waitIfNeeded()
        
        guard let url = buildURL(for: ipAddress) else {
            throw LocationServiceError.invalidIP
        }
        
        // header with fake user site
        var request = URLRequest(url: url)
        request.setValue("keycdn-tools:https://usr.com", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LocationServiceError.invalidResponse
            }
            
            // Handle rate limiting
            if httpResponse.statusCode == 429 {
                throw LocationServiceError.rateLimited
            }
            
            guard httpResponse.statusCode == 200 else {
                throw LocationServiceError.networkError(
                    NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: nil)
                )
            }
            
            let apiResponse = try JSONDecoder().decode(LocationAPIResponse.self, from: data)
            
            guard apiResponse.status == "success" else {
                throw LocationServiceError.invalidResponse
            }
            
            return LocationData(from: apiResponse.data.geo)
            
        } catch let error as DecodingError {
            throw LocationServiceError.decodingError(error)
        } catch {
            throw LocationServiceError.networkError(error)
        }
    }
    
    private func buildURL(for ipAddress: String) -> URL? {
        guard var components = URLComponents(string: "https://tools.keycdn.com/geo.json") else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "host", value: ipAddress)]
        return components.url
    }
    
    private func isValidIPAddress(_ ip: String) -> Bool {
        // Basic IP validation - could be enhanced
        let ipRegex = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", ipRegex)
        return predicate.evaluate(with: ip)
    }
}
