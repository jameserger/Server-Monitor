//
//  GravyService.swift
//  Server Monitor
//
//  Created by Gandalf on 1/31/26.
//


import Foundation
import SwiftUI
import Combine
import os

@MainActor
class BusinessService: ObservableObject {

    @Published var adminToken: String? = nil
    @Published var user: User? = nil
    @Published var business: Business? = nil
    @Published var errorMessage: String = ""
    @Published var updatedLatitude: Double? = nil
    @Published var updatedLongitude: Double? = nil
    @Published var businessList: [BusinessResponse] = []
    
    var pass = "131#S*nsetDr1ve"

    func updateLatLong(businessId: Int, lat: Double, long: Double) async {
        
        await getAdminToken()

        guard let token = adminToken, !token.isEmpty else {
            errorMessage = "Missing admin token."
            return
        }

        let path = "/gravy/business"
        var request = NetworkManager.getRequest(path: path, method: "PUT")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        do {
            let payload = BusinessUpdatePayload(id: businessId, latitude: lat, longitude: long)
            request.httpBody = try JSONEncoder().encode(payload)

            let (data, _) = try await doRequest(request, label: "UpdateBusiness")

            let updated = try JSONDecoder().decode(BusinessUpdateResponse.self, from: data)

            // If you already have a SwiftData Business loaded, update it in-place:
            if let existing = business {
                existing.latitude = updated.latitude
                existing.longitude = updated.longitude
            }
            updatedLatitude = updated.latitude
            updatedLongitude = updated.longitude
           
            errorMessage = ""

        } catch {
            if error is DecodingError {
                errorMessage = "Failed to decode business update response. \(describeDecodingError(error))"
            } else {
                errorMessage = "Failed to update business: \(error.localizedDescription)"
            }
        }
    }

    struct BusinessUpdatePayload: Codable {
        let id: Int
        let latitude: Double
        let longitude: Double
    }
    
    struct BusinessUpdateResponse: Codable {
        let id: Int
        let latitude: Double
        let longitude: Double
    }
    
    func getAdminToken() async {
        let path = "/gravy/token"
        var request = NetworkManager.getRequest(path: path, method: "POST")
        
        let adminUser = User(
            username: "admin",
            password: pass,
            tokenRole: "ADMIN"
        )

        do {
            request.httpBody = try JSONEncoder().encode(adminUser)
            
            let (data, _) = try await doRequest(request, label: "AdminToken")

            let decoded = try JSONDecoder().decode(ProvisionalUserResponse.self, from: data)
            let token = decoded.accessToken.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !token.isEmpty else {
                errorMessage = "Empty accessToken in response"
                adminToken = nil
                return
            }

            adminToken = token            

        } catch {
            Log.app.error("admin token error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            adminToken = nil
        }
    }

    func getAllBusinesses() async {

        await getAdminToken()

        guard let token = adminToken, !token.isEmpty else {
            errorMessage = "Missing admin token."
            return
        }

        let path = "/gravy/business/all"
        var request = NetworkManager.getRequest(path: path, method: "GET")
        request.setValue(token, forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await doRequest(request, label: "All Businesses")

            let decoded = try JSONDecoder().decode([BusinessResponse].self, from: data)
            businessList = decoded
            errorMessage = ""

        } catch {
            errorMessage = "Failed to load businesses: \(error.localizedDescription)"
        }
    }
    
    private func describeDecodingError(_ error: Error) -> String {
        guard let decodingError = error as? DecodingError else {
            return error.localizedDescription
        }

        func pathString(_ path: [CodingKey]) -> String {
            path.map { key in
                if let i = key.intValue { return "[\(i)]" }
                return ".\(key.stringValue)"
            }
            .joined()
            .replacingOccurrences(of: ".[", with: "[")
        }

        switch decodingError {
        case .dataCorrupted(let context):
            return "DecodingError.dataCorrupted at \(pathString(context.codingPath)): \(context.debugDescription)"

        case .keyNotFound(let key, let context):
            return "DecodingError.keyNotFound '\(key.stringValue)' at \(pathString(context.codingPath)): \(context.debugDescription)"

        case .typeMismatch(let type, let context):
            return "DecodingError.typeMismatch \(type) at \(pathString(context.codingPath)): \(context.debugDescription)"

        case .valueNotFound(let type, let context):
            return "DecodingError.valueNotFound \(type) at \(pathString(context.codingPath)): \(context.debugDescription)"

        @unknown default:
            return "Unknown DecodingError: \(decodingError)"
        }
    }

    private struct HTTPError: LocalizedError {
        let status: Int
        let url: String
        let body: String
        var errorDescription: String? { "HTTP \(status) for \(url): \(body)" }
    }

    @discardableResult
    private func doRequest(_ req: URLRequest, label: String) async throws -> (Data, HTTPURLResponse) {
        let (data, resp) = try await NetworkManager.session.data(for: req)

        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let bodyStr = String(data: data, encoding: .utf8) ?? "<non-utf8 \(data.count) bytes>"
        print("[\(label)] HTTP \(http.statusCode) \(http.url?.absoluteString ?? "")")

        if !(200...299).contains(http.statusCode) {
            throw HTTPError(status: http.statusCode, url: http.url?.absoluteString ?? "", body: bodyStr)
        }

        return (data, http)
    }
}
