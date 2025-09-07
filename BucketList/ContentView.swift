//
//  ContentView.swift
//  BucketList
//
//  Created by Наташа Спиридонова on 03.09.2025.
//

import MapKit
import SwiftUI

struct ContentView: View {
    @State private var viewModel = ViewModel()
    
    let startPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 56, longitude: -3),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
    )
    
    var body: some View {
        Group {
            if viewModel.isUnlocked {
                MapReader { proxy in
                    Map(initialPosition: startPosition) {
                        ForEach(viewModel.locations) { location in
                            Annotation(location.name, coordinate: location.coordinate) {
                                Image(systemName: "star.circle")
                                    .resizable()
                                    .foregroundStyle(.red)
                                    .frame(width: 44, height: 44)
                                    .background(.white)
                                    .clipShape(.circle)
                                    .onLongPressGesture {
                                        viewModel.selectedPlace = location
                                    }
                            }
                        }
                    }
                    .mapStyle(viewModel.isStandartMode ? .standard : .hybrid)
                    .safeAreaInset(edge: .top) {
                        HStack {
                            Spacer()
                            Button {
                                viewModel.isStandartMode.toggle()
                            } label: {
                                Image(systemName: "globe")
                                    .imageScale(.large)
                                    .padding(12)
                            }
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.6)
                            )
                        }
                        .padding(.horizontal, 48)
                    }
                    .onTapGesture { position in
                        if let coordinate = proxy.convert(position, from: .local) {
                            viewModel.addLocation(at: coordinate)
                        }
                    }
                    .sheet(item: $viewModel.selectedPlace) { place in
                        EditView(location: place) {
                            viewModel.update(location: $0)
                        }
                    }
                }
            } else {
                Button("Разблокировать места", action: viewModel.authenticate)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(.capsule)
            }
        }
        .alert(viewModel.alertTitle ?? "Ошибка", isPresented: $viewModel.showAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }
}

#Preview {
    ContentView()
}
