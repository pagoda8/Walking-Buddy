//
//  LocationFinder.swift
//  Walking Buddy
//
//  Created by Wojtek on 18/03/2023.
//
//	Manages API requests for finding location
//	API used: https://positionstack.com

import Foundation
import CoreLocation

struct Address: Codable {
	let data: [Datum]
}

struct Datum: Codable {
	let latitude: Double
	let longitude: Double
}

class MapAPI: ObservableObject {
	private let BASE_URL = "http://api.positionstack.com/v1/forward"
	private let API_KEY = "4609360ce70c08fa7da332053bbebc6c"
	
	//Returns the coordinate based on the input address
	func getLocation(address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
		let pAddress = address.replacingOccurrences(of: " ", with: "%20")
		let urlString = "\(BASE_URL)?access_key=\(API_KEY)&query=\(pAddress)"
		
		guard let url = URL(string: urlString) else {
			print("Invalid URL")
			completion(nil)
			return
		}
		
		URLSession.shared.dataTask(with: url) { (data, response, error) in
			guard let data = data else {
				print(error!.localizedDescription)
				completion(nil)
				return
			}
			
			guard let newLocation = try? JSONDecoder().decode(Address.self, from: data) else {
				completion(nil)
				return
			}
			
			if newLocation.data.isEmpty {
				print("Cannot find location")
				completion(nil)
				return
			}
			
			//Once location was found successfully, return it
			let details = newLocation.data[0]
			let coordinate = CLLocationCoordinate2D(latitude: details.latitude, longitude: details.longitude)
			completion(coordinate)
			
		}.resume()
	}
}
