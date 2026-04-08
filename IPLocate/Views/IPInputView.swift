//
//  IPInputView.swift
//  IPLocate
//
//  Created by Caitsy on 07/04/2026.
//

import SwiftUI

struct IPInputView: View {
    @StateObject private var viewModel = IPInputViewModel()
    @State private var showingLocationDetail = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerView
                inputSection
                Spacer()
            }
            .padding()
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("IP Locator")
            .navigationDestination(isPresented: $showingLocationDetail) {
                if let locationData = viewModel.locationData {
                    LocationDetailView(locationData: locationData)
                }
            }
            .onChange(of: viewModel.locationData) { _, newValue in
                showingLocationDetail = newValue != nil
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Enter IP Address")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Get detailed location information for any IP address")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
    
    private var inputSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("IP Address")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("e.g., 8.8.8.8", text: $viewModel.ipAddress)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                hideKeyboard()
                            }
                        }
                    }
                    .onSubmit {
                        Task {
                            await viewModel.fetchLocationData()
                        }
                    }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Button {
                Task {
                    await viewModel.fetchLocationData()
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(viewModel.isLoading ? "Locating..." : "Find Location")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isValidIP ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!viewModel.isValidIP || viewModel.isLoading)
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    IPInputView()
}
