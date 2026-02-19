//
//  Location.swift
//  Server Monitor
//
//  Created by Gandalf on 2/18/26.
//


import SwiftData
import MapKit

@Model
class Location {
    var name: String
    var latitude: Double?
    var longitude: Double?
    var latitudeDelta: Double?
    var longitudeDelta: Double?
    @Relationship(deleteRule: .cascade)
    var placemarks: [Business] = []
    
    init(name: String, latitude: Double? = nil, longitude: Double? = nil, latitudeDelta: Double? = nil, longitudeDelta: Double? = nil) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
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

extension Location {
    @MainActor
    static var preview: ModelContainer {
        let container = try! ModelContainer(
            for: Location.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true
            )
        )
        let golden = Location(
            name: "Golden",
            latitude: 39.734241,
            longitude: -105.201088,
            latitudeDelta: 0.25,
            longitudeDelta: 0.25
        )
        container.mainContext.insert(golden)
        var placeMarks: [Business] {
            [
                Business(name: "Woody's Pizza", address: "1305 Washington Ave Golden, CO 80401", city: "Golden", state: "CO", zip: "80401", discount: "10% Off any size pizza", code: "65464", type: "Food", latitude: 39.754459, longitude: -105.220215, webSite: "www.jim.com"),
                /*
                Business(name: "Buffalo Rose", address: "1119 Washington Ave Golden, CO 80401", discount: "$2 Off buffalo burgers", code: "65464", type: "Food", latitude: 39.755746, longitude: -105.221122),
                Business(name: "Fat Sully's Pizza", address: "1100 Washington Ave Golden, CO", discount: "15% Off any size slice", code: "65464", type: "Food",latitude: 39.755897, longitude: -105.222153),
                Business(name: "Trailhead Taphouse & Kitchen", address: "811 12th St Golden, CO 80401", discount: "10% Off beer", code: "65464", type: "Food",latitude: 39.754979, longitude: -105.221523),
                Business(name: "Bob's Atomic Burgers", address: "1310 Ford St, Golden, CO 80401", discount: "3% Off any burger", code: "65464", type: "Food", latitude: 39.75542233319779, longitude: -105.21832769429378),
                Business(name: "Sherpa House", address: "1518 Washington Ave, Golden, CO 80401", discount: "4% Off pigs tails", code: "65464", type: "Food", latitude: 39.75243686834001, longitude: -105.21880694365657),
                Business(name: "Golden City Brewery", address: "920 12th St Building 2, Golden, CO 80401", discount: "$1 Off Stouts", code: "65464",type: "Food", latitude: 39.75504438871115, longitude: -105.22364425161035),
                Business(name: "Cafe 13", address: "1301 Arapahoe St, Golden, CO 80401", discount: "$2 Off scones", code: "65464", type: "Coffee", latitude: 39.75413618243187, longitude: -105.22122277185083),
                 */
            ]
        }
        placeMarks.forEach {placemark in
            golden.placemarks.append(placemark)
        }
        return container
    }
}
