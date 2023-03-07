//
//  LocationManager.swift
//  Walking Buddy
//
//  Singleton class to manage all location operations
//

import UIKit
import CoreLocation

public class LocationManager: NSObject, CLLocationManagerDelegate {
	
	//Reference for other classes
	public static let shared = LocationManager()
	
	//The location manager object
	private var manager: CLLocationManager = CLLocationManager()
	
	//Latest location of user
	private var latestLocation: CLLocation = CLLocation()
	
	//Called once, when the shared variable is accessed
	private override init() {
		super.init()
		self.manager.delegate = self
		self.manager.desiredAccuracy = kCLLocationAccuracyBest
		self.manager.requestWhenInUseAuthorization()
	}
	
	//Request permission to use location
	public func requestLocationUsage() {
		manager.requestWhenInUseAuthorization()
	}
	
	public func startUpdatingLocation() {
		manager.startUpdatingLocation()
	}
	
	public func stopUpdatingLocation() {
		manager.stopUpdatingLocation()
	}
	
	//Returns true if permission to use location was given, false otherwise.
	public func locationUsageAllowed() -> Bool {
		return manager.authorizationStatus == .authorizedWhenInUse
	}
	
	//Returns true if app is allowed to use precise location, false otherwise.
	public func locationUsingBestAccuracy() -> Bool {
		return manager.accuracyAuthorization == .fullAccuracy
	}
	
	//Returns true if device has location services enabled, false otherwise.
	public func locationServicesEnabled() -> Bool {
		return CLLocationManager.locationServicesEnabled()
	}
	
	//Reuturns the coordinate of tha latest location
	public func getLatestCoordinate() -> CLLocationCoordinate2D {
		return latestLocation.coordinate
	}
	
	//Returns true if current location is within a 20m distance from photo location, false otherwise.
	public func isInsideRegion(currentLocation: CLLocationCoordinate2D, photoLocation: CLLocationCoordinate2D) -> Bool {
		let region = CLCircularRegion(center: photoLocation, radius: 20, identifier: "photoRegion")
		
		return region.contains(currentLocation)
	}
	
	//Called when manager successfully gets location
	public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		latestLocation = locations.last! //Array always has at least one item
	}
	
	//Called when manager could not get location
	public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
	
	//Called when user changes location permissions
	public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {}
	
	//Enum for throwing errors
	public enum LocationError: Error {
		case locationNotRecieved
		case locationNotInRegion
	}
}
