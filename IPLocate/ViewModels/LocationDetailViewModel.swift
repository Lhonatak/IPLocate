//
//  LocationDetailViewModel.swift
//  IPLocate
//
//  Created by Caitsy on 07/04/2026.
//

import Foundation
import Combine

@MainActor
final class LocationDetailViewModel: ObservableObject {
    @Published var isSaved: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    let locationData: LocationData
    private let storageService: LocationStorageProtocol
    
    init(locationData: LocationData, storageService: LocationStorageProtocol? = nil) {
        self.locationData = locationData
        self.storageService = storageService ?? DependencyContainer.shared.storageService
        
        Task {
            await checkIfSaved()
        }
    }
    
    func toggleSaved() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if isSaved {
                try await storageService.deleteLocation(withIP: locationData.ip)
                isSaved = false
            } else {
                try await storageService.saveLocation(locationData)
                isSaved = true
            }
        } catch {
            errorMessage = "Failed to save location: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func checkIfSaved() async {
        isSaved = await storageService.isLocationSaved(ip: locationData.ip)
    }
}
