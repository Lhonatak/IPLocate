//
//  LocationStorageService.swift
//  IPLocate
//
//  Created by Caitsy on 07/04/2026.
//

import Foundation
import CoreData

// MARK: - Storage Protocol
protocol LocationStorageProtocol {
    func saveLocation(_ location: LocationData) async throws
    func fetchSavedLocations() async throws -> [LocationData]
    func deleteLocation(withIP ip: String) async throws
    func isLocationSaved(ip: String) async -> Bool
}

// MARK: - Core Data Storage Service
final class LocationStorageService: LocationStorageProtocol {
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    func saveLocation(_ location: LocationData) async throws {
        let context = persistenceController.container.newBackgroundContext()
        
        try await context.perform {
            // Check if location already exists
            let fetchRequest: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "ip == %@", location.ip)
            
            if let existingLocation = try context.fetch(fetchRequest).first {
                // Update existing
                self.updateSavedLocation(existingLocation, with: location)
            } else {
                // Create new
                let savedLocation = SavedLocation(context: context)
                self.updateSavedLocation(savedLocation, with: location)
            }
            
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    func fetchSavedLocations() async throws -> [LocationData] {
        let context = persistenceController.container.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SavedLocation.savedDate, ascending: false)]
            
            let savedLocations = try context.fetch(fetchRequest)
            return savedLocations.compactMap { self.locationData(from: $0) }
        }
    }
    
    func deleteLocation(withIP ip: String) async throws {
        let context = persistenceController.container.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "ip == %@", ip)
            
            if let locationToDelete = try context.fetch(fetchRequest).first {
                context.delete(locationToDelete)
                
                if context.hasChanges {
                    try context.save()
                }
            }
        }
    }
    
    func isLocationSaved(ip: String) async -> Bool {
        let context = persistenceController.container.viewContext
        
        do {
            return try await context.perform {
                let fetchRequest: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "ip == %@", ip)
                fetchRequest.fetchLimit = 1
                
                return try context.count(for: fetchRequest) > 0
            }
        } catch {
            return false
        }
    }
    
    // MARK: - Private Helpers
    
    private func updateSavedLocation(_ savedLocation: SavedLocation, with locationData: LocationData) {
        savedLocation.ip = locationData.ip
        savedLocation.city = locationData.city
        savedLocation.regionName = locationData.regionName
        savedLocation.countryName = locationData.countryName
        savedLocation.countryCode = locationData.countryCode
        savedLocation.latitude = locationData.latitude
        savedLocation.longitude = locationData.longitude
        savedLocation.isp = locationData.isp
        savedLocation.timezone = locationData.timezone
        savedLocation.datetime = locationData.datetime
        savedLocation.savedDate = Date()
    }
    
    private func locationData(from savedLocation: SavedLocation) -> LocationData? {
        guard let ip = savedLocation.ip,
              let city = savedLocation.city,
              let regionName = savedLocation.regionName,
              let countryName = savedLocation.countryName,
              let countryCode = savedLocation.countryCode,
              let isp = savedLocation.isp,
              let timezone = savedLocation.timezone,
              let datetime = savedLocation.datetime,
              let savedDate = savedLocation.savedDate else {
            return nil
        }
        
        return LocationData(
            ip: ip,
            city: city,
            regionName: regionName,
            countryName: countryName,
            countryCode: countryCode,
            latitude: savedLocation.latitude,
            longitude: savedLocation.longitude,
            isp: isp,
            timezone: timezone,
            datetime: datetime,
            savedDate: savedDate
        )
    }
}