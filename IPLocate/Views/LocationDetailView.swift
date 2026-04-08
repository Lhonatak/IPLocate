//
//  LocationDetailView.swift
//  IPLocate
//
//  Created by Caitsy on 07/04/2026.
//

import SwiftUI
import MapKit

struct LocationDetailView: View {
    let locationData: LocationData
    @StateObject private var viewModel: LocationDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(locationData: LocationData) {
        self.locationData = locationData
        self._viewModel = StateObject(wrappedValue: LocationDetailViewModel(locationData: locationData))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                mapView
                locationInfoView
            }
            .padding()
        }
        .navigationTitle("Location Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.toggleSaved()
                    }
                } label: {
                    Image(systemName: viewModel.isSaved ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isSaved ? .red : .gray)
                }
                .disabled(viewModel.isLoading)
            }
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
    
    private var mapView: some View {
        Map(initialPosition: .region(
            MKCoordinateRegion(
                center: locationData.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )) {
            Marker(locationData.displayName, coordinate: locationData.coordinate)
                .tint(.blue)
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var locationInfoView: some View {
        VStack(spacing: 16) {
            InfoCard(title: "IP Information") {
                InfoRow(label: "IP Address", value: locationData.ip)
                InfoRow(label: "ISP", value: locationData.isp)
            }
            
            InfoCard(title: "Location") {
                InfoRow(label: "City", value: locationData.city)
                InfoRow(label: "Region", value: locationData.regionName)
                InfoRow(label: "Country", value: "\(locationData.countryName) (\(locationData.countryCode))")
                InfoRow(label: "Coordinates", value: String(format: "%.4f, %.4f", locationData.latitude, locationData.longitude))
            }
            
            InfoCard(title: "Additional Information") {
                InfoRow(label: "Timezone", value: locationData.timezone)
                InfoRow(label: "Local Time", value: formatDate(locationData.datetime))
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: locationData.timezone)
        return formatter.string(from: date)
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(value)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    NavigationStack {
        LocationDetailView(
            locationData: LocationData(
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
        )
    }
}