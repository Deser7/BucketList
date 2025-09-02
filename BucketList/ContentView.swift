//
//  ContentView.swift
//  BucketList
//
//  Created by Наташа Спиридонова on 03.09.2025.
//

import MapKit
import SwiftUI

struct ContentView: View {
    let startPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 56, longitude: -3),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
    )
    
    @State private var locations: [Location] = []
    
    var body: some View {
        MapReader { proxy in
            Map(initialPosition: startPosition) {
                ForEach(locations) { location in
                    Marker(location.name, coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                }
            }
            .onTapGesture { position in
                if let coordinate = proxy.convert(position, from: .local) {
                    let newLocation = Location(
                        name: "New location",
                        description: "",
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                    locations.append(newLocation)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
