//
//  Business.swift
//  Server Monitor
//
//  Created by Gandalf on 2/18/26.
//


import SwiftData
import MapKit

@Model
class Business: Identifiable {
    
    var id: UUID
    var name: String
    var address: String
    var city: String
    var state: String
    var zip: String
    var discount: String
    var code: String
    var type: String
    var latitude: Double
    var longitude: Double
    var location: Location?
    var webSite: String
    
    init(name: String, address: String, city: String, state: String, zip: String, discount: String, code: String, type: String, latitude: Double, longitude: Double, webSite: String) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.zip = zip
        self.discount = discount
        self.code = code
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
        self.webSite = webSite
    }
    
    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
    
}
