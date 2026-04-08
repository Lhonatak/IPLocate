//
//  IPInputViewModel.swift
//  IPLocate
//
//  Created by Caitsy on 07/04/2026.
//

import Foundation
import Combine

@MainActor
final class IPInputViewModel: ObservableObject {
    @Published var ipAddress: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var locationData: LocationData?
    
    private let locationService: LocationServiceProtocol
    
    init(locationService: LocationServiceProtocol? = nil) {
        self.locationService = locationService ?? DependencyContainer.shared.locationService
    }
    
    var isValidIP: Bool {
        !ipAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func fetchLocationData() async {
        let trimmedIP = ipAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedIP.isEmpty else {
            errorMessage = "Please enter an IP address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let location = try await locationService.fetchLocation(for: trimmedIP)
            locationData = location
        } catch {
            errorMessage = error.localizedDescription
            locationData = nil
        }
        
        isLoading = false
    }
    
    func clearData() {
        locationData = nil
        errorMessage = nil
        ipAddress = ""
    }
}