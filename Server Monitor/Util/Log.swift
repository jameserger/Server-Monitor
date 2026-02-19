//
//  Log.swift
//  Gravy Business
//
//  Created by Gandalf on 1/14/26.
//

import OSLog

enum Log {
    static let subsystem = "com.exploregravy.business"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let iap = Logger(subsystem: subsystem, category: "iap")
}
