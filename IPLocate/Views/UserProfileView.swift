//
//  UserProfileView.swift
//  IPLocate
//
//  Created by Caitsy on 07/04/2026.
//

import SwiftUI

struct UserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading saved locations...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.savedLocations.isEmpty {
                    emptyStateView
                } else {
                    locationsList
                }
            }
            .navigationTitle("Saved Locations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await viewModel.refreshLocations()
                        }
                    }
                }
            }
            .task {
                await viewModel.loadSavedLocations()
            }
            .refreshable {
                await viewModel.refreshLocations()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Saved Locations")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Locations you save will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var locationsList: some View {
        List {
            ForEach(viewModel.savedLocations) { location in
                NavigationLink {
                    LocationDetailView(locationData: location)
                } label: {
                    LocationRowView(location: location)
                }
            }
            .onDelete(perform: deleteLocations)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteLocations(offsets: IndexSet) {
        for index in offsets {
            let location = viewModel.savedLocations[index]
            Task {
                await viewModel.deleteLocation(location)
            }
        }
    }
}

struct LocationRowView: View {
    let location: LocationData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(location.ip)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    
                    Text("Saved \(formatRelativeDate(location.savedDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "location")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            
            Divider()
                .opacity(0)
        }
        .padding(.vertical, 4)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    UserProfileView()
}