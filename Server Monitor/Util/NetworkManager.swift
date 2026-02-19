//
//  Network.swift
//  Server Monitor
//
//  Created by Gandalf on 1/31/26.
//

import Foundation
import OSLog
import Observation


@MainActor
@Observable
final class NetworkManager {

    static let shared = NetworkManager()

    var errorMessage = ""
    var hasError = false

        nonisolated static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    nonisolated static func getRequest(path: String, method: String) -> URLRequest {
        
        //let scheme = "http://"
        //let host   = "localhost"
        //let port   = ":5000"
        
        let scheme = "https://"
        let host   = "exploregravy.com"
        let port   = ""

        let url = URL(string: scheme + host + port + path)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    func handleClientError(_ error: Error) {
        errorMessage = error.localizedDescription
        hasError = true
    }

    func handleServerError(_ statusCode: Int) {
        switch statusCode {
        case 500...599:
            errorMessage = "Something went wrong with our remote server."
        default:
            errorMessage = "Error: Status code \(statusCode)."
        }
        hasError = true
    }
}

