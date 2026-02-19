//
//  GravyService.swift
//  Server Monitor
//
//  Created by Gandalf on 1/31/26.
//

//
//  GravyService.swift
//  Server Monitor
//
//  Created by Gandalf on 1/31/26.
//

import Foundation
import SwiftUI
import Combine
import Network
import Security
import os

@MainActor
class GravyService: ObservableObject {
        
    @Published var provisionalToken: String? = nil
    @Published var discountPlanResponse = [DiscountPlanResponse]()
    @Published var isServerHealthy: Bool = true
    @Published var errorMessage: String = ""
    
    @AppStorage("lastHealthState") private var lastHealthStateStorage: Int = -1
    @AppStorage("checkIntervalSeconds") var checkIntervalSeconds: Double = 3600
    @AppStorage("lastCheckTimestamp") private var lastCheckTimestampStorage: Double = 0
    @AppStorage("notifyOnAllGood") private var notifyOnAllGood: Bool = false

    var lastCheckDate: Date? {
        lastCheckTimestampStorage > 0 ? Date(timeIntervalSince1970: lastCheckTimestampStorage) : nil
    }
    
    private var lastHealthState: Bool? {
        get {
            switch lastHealthStateStorage {
            case 0: return false
            case 1: return true
            default: return nil
            }
        }
        set {
            if let newValue {
                lastHealthStateStorage = newValue ? 1 : 0
            } else {
                lastHealthStateStorage = -1
            }
        }
    }
    
    func getPlans() async {
        
        lastCheckTimestampStorage = Date().timeIntervalSince1970

        errorMessage = ""
        isServerHealthy = false

        await getProvisionalToken()

        guard let token = provisionalToken, !token.isEmpty else {
            self.errorMessage = self.errorMessage
            self.isServerHealthy = false
            
            lastHealthState = false

            NotificationManager.shared.notifyAfterCheck(
                isHealthy: false,
                statusCode: nil,
                details: self.errorMessage
            )
            return
        }

        let path = "/gravy/discountplan/register"
        var request = NetworkManager.getRequest(path: path, method: "GET")
        request.setValue(token, forHTTPHeaderField: "Authorization")

        do {
            let (data, resp) = try await NetworkManager.session.data(for: request)

            guard let http = resp as? HTTPURLResponse else {
                self.errorMessage = "Invalid server response."
                self.isServerHealthy = false
                lastHealthState = false

                NotificationManager.shared.notifyAfterCheck(
                    isHealthy: false,
                    statusCode: nil,
                    details: self.errorMessage
                )
                return
            }

            let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"

            guard (200...299).contains(http.statusCode) else {
                self.errorMessage = "Failed to fetch plans (HTTP \(http.statusCode)). \(body)"
                self.isServerHealthy = false
                lastHealthState = false

                NotificationManager.shared.notifyAfterCheck(
                    isHealthy: false,
                    statusCode: http.statusCode,
                    details: String(body.prefix(160)).trimmingCharacters(in: .whitespacesAndNewlines)
                )
                return
            }

            // success (HTTP 2xx)
            do {
                let response = try JSONDecoder().decode([DiscountPlanResponse].self, from: data)

                guard !response.isEmpty else {
                    self.errorMessage = "No plans returned from server."
                    self.isServerHealthy = false
                    lastHealthState = false

                    NotificationManager.shared.notifyAfterCheck(
                        isHealthy: false,
                        statusCode: http.statusCode,
                        details: self.errorMessage
                    )
                    return
                }

                self.discountPlanResponse = response
                self.errorMessage = ""
                self.isServerHealthy = true
                lastHealthState = true

                NotificationManager.shared.notifyAfterCheck(
                    isHealthy: true,
                    statusCode: http.statusCode,
                    details: nil
                )

            } catch {
                let detail = describeDecodingError(error)
                self.errorMessage = "Failed to decode plans. \(detail)"
                self.isServerHealthy = false
                lastHealthState = false

                NotificationManager.shared.notifyAfterCheck(
                    isHealthy: false,
                    statusCode: http.statusCode,
                    details: String(detail.prefix(160))
                )
                return
            }

        } catch {
            self.errorMessage = "Failed to fetch plans: \(error.localizedDescription)"
            self.isServerHealthy = false
            lastHealthState = false

            NotificationManager.shared.notifyAfterCheck(
                isHealthy: false,
                statusCode: nil,
                details: String(error.localizedDescription.prefix(160))
            )
            return
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
            .replacingOccurrences(of: ".[", with: "[") // clean up ".[" -> "["
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

    func getProvisionalToken() async {
        
        let path = "/gravy/token/provisional"
        let request = NetworkManager.getRequest(path: path, method: "POST")
        
        do {
            let (data, response) = try await NetworkManager.session.data(for: request)
            
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
                throw NSError(
                    domain: "ProvisionalTokenHTTP",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(body)"]
                )
            }
            
            let decoded = try JSONDecoder().decode(ProvisionalUserResponse.self, from: data)
            
            let token = decoded.accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !token.isEmpty else {
                throw NSError(
                    domain: "ProvisionalTokenDecode",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Empty accessToken in response"]
                )
            }

            provisionalToken = token
            errorMessage = ""

        } catch {
            Log.app.error("provisional token error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
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
        #if DEBUG
        print("[\(label)] HTTP \(http.statusCode) \(http.url?.absoluteString ?? "")")
        #endif
        if !(200...299).contains(http.statusCode) {
            throw HTTPError(status: http.statusCode, url: http.url?.absoluteString ?? "", body: bodyStr)
        }
        return (data, http)
    }
}

extension Data {
    init?(base64URLEncoded s: String) {
        var str = s.replacingOccurrences(of: "-", with: "+")
                   .replacingOccurrences(of: "_", with: "/")
        let pad = 4 - (str.count % 4)
        if pad < 4 { str.append(String(repeating: "=", count: pad)) }
        self.init(base64Encoded: str)
    }
    
    var b64: String { self.base64EncodedString() }
}
