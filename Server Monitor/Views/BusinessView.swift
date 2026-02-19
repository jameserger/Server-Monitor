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
}
