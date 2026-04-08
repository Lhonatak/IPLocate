//
//  UserProfileViewModel.swift
//  IPLocate
//
//  Created by Caitsy on 07/04/2026.
//

import Foundation
import Combine

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var savedLocations: [LocationData] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let storageService: LocationStorageProtocol
    
    init(storageService: LocationStorageProtocol? = nil) {
        self.storageService = storageService ?? DependencyContainer.shared.storageService
    }
    
    func loadSavedLocations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            savedLocations = try await storageService.fetchSavedLocations()
        } catch {
            errorMessage = "Failed to load saved locations: \(error.localizedDescription)"
            savedLocations = []
        }
        
        isLoading = false
    }
    
    func deleteLocation(_ location: LocationData) async {
        do {
            try await storageService.deleteLocation(withIP: location.ip)
            await loadSavedLocations() // Refresh the list
        } catch {
            errorMessage = "Failed to delete location: \(error.localizedDescription)"
        }
    }
    
    func refreshLocations() async {
        await loadSavedLocations()
    }
}
