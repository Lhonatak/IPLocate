//
//  LocationData.swift
//  IPLocate
//
//  Created by Caitsy on 07/04/2026.
//

import Foundation
import CoreLocation

// MARK: - API Response Models
struct LocationAPIResponse: Codable {
    let status: String
    let description: String
    let data: LocationResponseData
}

struct LocationResponseData: Codable {
    let geo: LocationGeoData
}

struct LocationGeoData: Codable {
    let host: String
    let ip: String
    let asn: Int
    let isp: String
    let countryName: String
    let countryCode: String
    let regionName: String
    let regionCode: String
    let city: String
    let postalCode: String?
    let continentName: String
    let continentCode: String
    let latitude: Double
    let longitude: Double
    let metroCode: String?
    let timezone: String
    let datetime: String
    
    enum CodingKeys: String, CodingKey {
        case host, ip, asn, isp
        case countryName = "country_name"
        case countryCode = "country_code"
        case regionName = "region_name"
        case regionCode = "region_code"
        case city
        case postalCode = "postal_code"
        case continentName = "continent_name"
        case continentCode = "continent_code"
        case latitude, longitude
        case metroCode = "metro_code"
        case timezone, datetime
    }
}

// MARK: - App Domain Model
struct LocationData: Identifiable, Equatable {
    let id = UUID()
    let ip: String
    let city: String
    let regionName: String
    let countryName: String
    let countryCode: String
    let latitude: Double
    let longitude: Double
    let isp: String
    let timezone: String
    let datetime: Date
    let savedDate: Date
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var displayName: String {
        "\(city), \(regionName), \(countryName)"
    }
    
    init(from geoData: LocationGeoData, savedDate: Date = Date()) {
        self.ip = geoData.ip
        self.city = geoData.city
        self.regionName = geoData.regionName
        self.countryName = geoData.countryName
        self.countryCode = geoData.countryCode
        self.latitude = geoData.latitude
        self.longitude = geoData.longitude
        self.isp = geoData.isp
        self.timezone = geoData.timezone
        self.savedDate = savedDate
        
        // Parse datetime string
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: geoData.timezone)
        self.datetime = formatter.date(from: geoData.datetime) ?? Date()
    }
    
    // For creating from Core Data
    init(ip: String, city: String, regionName: String, countryName: String, countryCode: String,
         latitude: Double, longitude: Double, isp: String, timezone: String, datetime: Date, savedDate: Date) {
        self.ip = ip
        self.city = city
        self.regionName = regionName
        self.countryName = countryName
        self.countryCode = countryCode
        self.latitude = latitude
        self.longitude = longitude
        self.isp = isp
        self.timezone = timezone
        self.datetime = datetime
        self.savedDate = savedDate
    }
}