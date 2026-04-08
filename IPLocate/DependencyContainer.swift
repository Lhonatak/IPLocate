//
//  DependencyContainer.swift
//  IPLocate
//
//  Created by Caitsy on 07/04/2026.
//

import Foundation

// MARK: - Dependency Container
final class DependencyContainer {
    static let shared = DependencyContainer()
    
    // Services
    lazy var locationService: LocationServiceProtocol = LocationAPIService()
    lazy var storageService: LocationStorageProtocol = LocationStorageService()
    
    private init() {}
    
    // For testing - allow injection of mock services
    func configure(
        locationService: LocationServiceProtocol? = nil,
        storageService: LocationStorageProtocol? = nil
    ) {
        if let locationService = locationService {
            self.locationService = locationService
        }
        if let storageService = storageService {
            self.storageService = storageService
        }
    }
}