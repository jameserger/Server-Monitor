//
//  BusinessUpdateView.swift
//  Server Monitor
//
//  Created by Gandalf on 2/18/26.
//

import SwiftUI

struct BusinessView: View {
    @StateObject private var service = BusinessService()

    @State private var businessIdText: String = ""
    @State private var latitudeText: String = ""
    @State private var longitudeText: String = ""

    @State private var isSaving: Bool = false
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Update Business Location")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                TextField("Business ID (e.g. 123)", text: $businessIdText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Latitude (e.g. 39.7392)", text: $latitudeText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Longitude (e.g. -104.9903)", text: $longitudeText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }

            Button {
                Task { await save() }
            } label: {
                Text(isSaving ? "Updating..." : "Update Lat/Long")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)

            if !service.errorMessage.isEmpty {
                Text(service.errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let lat = service.updatedLatitude, let lon = service.updatedLongitude {
                Text("Updated to: \(lat), \(lon)")
                    .foregroundStyle(.green)
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider().padding(.vertical, 8)

            Button {
                Task { await loadBusinesses() }
            } label: {
                Text(isLoading ? "Loading Businesses..." : "All Businesses")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)

            if isLoading {
                ProgressView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(service.businessList) { business in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(business.businessName)
                                    .font(.headline)

                                Text("ID: \(business.id)")
                                
                                Text("\(business.city), \(business.state)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Text("Lat: \(business.latitude ?? 0.0)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text("Long: \(business.longitude ?? 0.0)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .onTapGesture {
                                // Autofill fields when tapped
                                businessIdText = String(business.id)
                                latitudeText = String(business.latitude ?? 0.0)
                                longitudeText = String(business.longitude ?? 0.0)
                            }
                        }
                    }
                }
            }

            if !service.errorMessage.isEmpty {
                Text(service.errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
            
        }
        .padding()
        .navigationTitle("Update Business")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func save() async {
        guard let businessId = Int(businessIdText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            service.errorMessage = "Please enter a valid Business ID."
            return
        }
        guard let lat = Double(latitudeText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            service.errorMessage = "Please enter a valid latitude."
            return
        }
        guard let lon = Double(longitudeText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            service.errorMessage = "Please enter a valid longitude."
            return
        }

        isSaving = true
        defer { isSaving = false }

        await service.updateLatLong(businessId: businessId, lat: lat, long: lon)
    }
    
    @MainActor
    private func loadBusinesses() async {
        isLoading = true
        defer { isLoading = false }

        await service.getAllBusinesses()
    }
}
