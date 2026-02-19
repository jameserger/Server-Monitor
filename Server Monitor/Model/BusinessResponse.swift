//
//  BusinessResponse.swift
//  Gravy Customer
//
//  Created by Gandalf on 3/25/25.
//

import Foundation
import MapKit
import SwiftData

@Model
class BusinessResponse: Codable, Identifiable {
    var id: Int
    var businessName: String
    var address: String
    var city: String
    var state: String
    var zip: String
    var latitude: Double?
    var longitude: Double?
    var location: LocationResponse?
    var discounts: [DiscountResponse]?
    var webSite: String
    
    init(id: Int, businessName: String, address: String, city: String, state: String, zip: String, latitude: Double?, longitude: Double?, webSite: String) {
        self.id = id
        self.businessName = businessName
        self.address = address
        self.city = city
        self.state = state
        self.zip = zip
        self.latitude = latitude
        self.longitude = longitude
        self.webSite = webSite
    }
    
    enum CodingKeys: String, CodingKey {
        case id, businessName, address, city, state, zip, latitude, longitude, location, discounts, webSite
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        businessName = try container.decode(String.self, forKey: .businessName)
        address = try container.decode(String.self, forKey: .address)
        city = try container.decode(String.self, forKey: .city)
        state = try container.decode(String.self, forKey: .state)
        zip = try container.decode(String.self, forKey: .zip)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        location = try container.decodeIfPresent(LocationResponse.self, forKey: .location)
        discounts = try container.decodeIfPresent([DiscountResponse].self, forKey: .discounts)
        webSite = try container.decode(String.self, forKey: .webSite)
    }

    // Custom Encodable method
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(businessName, forKey: .businessName)
        try container.encode(address, forKey: .address)
        try container.encode(city, forKey: .city)
        try container.encode(state, forKey: .state)
        try container.encode(zip, forKey: .zip)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(discounts, forKey: .discounts)
        try container.encode(webSite, forKey: .webSite)
    }
    
    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude ?? 0, longitude: longitude ?? 0)
    }
}
