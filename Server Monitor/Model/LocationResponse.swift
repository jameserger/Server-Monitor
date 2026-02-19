//
//  LocationResponse.swift
//  Gravy Customer
//
//  Created by Gandalf on 3/25/25.
//
import Foundation
import MapKit
import SwiftData

@Model
class LocationResponse: Codable, Identifiable {
    var id: Int
    var name: String
    var latitude: Double?
    var longitude: Double?
    var latitudeDelta: Double?
    var longitudeDelta: Double?
    var placemarks: [BusinessResponse]? = []
    
    init(name: String, latitude: Double? = nil, longitude: Double? = nil, placemarks: [BusinessResponse]) {
        self.id = 0
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.latitudeDelta = 0.25
        self.longitudeDelta = 0.25
        self.placemarks = placemarks
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, placemarks
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        //latitudeDelta = try container.decodeIfPresent(Double.self, forKey: .latitudeDelta)
        //longitudeDelta = try container.decodeIfPresent(Double.self, forKey: .longitudeDelta)
        placemarks = try container.decodeIfPresent([BusinessResponse].self, forKey: .placemarks) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        //try container.encodeIfPresent(latitudeDelta, forKey: .latitudeDelta)
        //try container.encodeIfPresent(longitudeDelta, forKey: .longitudeDelta)
        try container.encodeIfPresent(placemarks, forKey: .placemarks)
    }
    
    var region: MKCoordinateRegion? {
        if let latitude, let longitude, let latitudeDelta, let longitudeDelta {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            )
        } else {
            return nil
        }
    }
}
