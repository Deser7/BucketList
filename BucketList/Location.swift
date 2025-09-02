//
//  Location.swift
//  BucketList
//
//  Created by Наташа Спиридонова on 03.09.2025.
//

import Foundation

struct Location: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var description: String
    var latitude: Double
    var longitude: Double
}
