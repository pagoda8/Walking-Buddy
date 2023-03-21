//
//  AppDelegate.swift
//  Walking Buddy
//
//  Created by Wojtek on 28/10/2022.
//
//	AppDelegate class

import UIKit
import CoreData
import CoreLocation
import MapKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

	//ID of current user
	private var currentUser = String()
	
	//Stack (array) with storyboard ID's of caller view controllers, used for back actions
	private var navigationStack: [String] = []
	//Index of the tab that should be opened (main tab bar)
	private var desiredTabIndex = 1
	//Index of the tab that should be opened (requests tab bar)
	private var desiredRequestsTabIndex = 0
	
	//ID of user profile for opening a profile page
	private var userProfileToOpen = String()
	//ID of photo record for opening photo details
	private var photoToOpen = String()
	
	//Center of map region most recently shown
	private var currentMapCenterCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
	//Most recent map view span
	private var currentMapViewSpan: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
	//Most recent user location coordinate
	private var recentUserLocation: CLLocationCoordinate2D?
	
	//Indicates if the mapview should zoom to user's location when it appears
	private var zoomToUserLocationBool = true
	//Indicates if the user logs in the first time in app session
	private var firstLoginBool = true

	//When the app launches
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		//Setup OpenAI API client
		OpenAICaller.shared.setup()
		return true
	}
	
	//Clears cache when device gets memory warning. Used for map view.
	func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
		URLCache.shared.removeAllCachedResponses()
	}

	// MARK: - UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}

	// MARK: - Core Data stack

	lazy var persistentContainer: NSPersistentCloudKitContainer = {
	    /*
	     The persistent container for the application. This implementation
	     creates and returns a container, having loaded the store for the
	     application to it. This property is optional since there are legitimate
	     error conditions that could cause the creation of the store to fail.
	    */
	    let container = NSPersistentCloudKitContainer(name: "Walking_Buddy")
	    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
	        if let error = error as NSError? {
	            // Replace this implementation with code to handle the error appropriately.
	            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	             
	            /*
	             Typical reasons for an error here include:
	             * The parent directory does not exist, cannot be created, or disallows writing.
	             * The persistent store is not accessible, due to permissions or data protection when the device is locked.
	             * The device is out of space.
	             * The store could not be migrated to the current model version.
	             Check the error message to determine what the actual problem was.
	             */
	            fatalError("Unresolved error \(error), \(error.userInfo)")
	        }
	    })
	    return container
	}()

	// MARK: - Core Data Saving support

	func saveContext () {
	    let context = persistentContainer.viewContext
	    if context.hasChanges {
	        do {
	            try context.save()
	        } catch {
	            // Replace this implementation with code to handle the error appropriately.
	            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	            let nserror = error as NSError
	            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
	        }
	    }
	}
	
	// MARK: - Getters
	
	//Returns reference to AppDelegate
	static func get() -> AppDelegate {
		return UIApplication.shared.delegate as! AppDelegate
	}
	
	//Returns logged in user
	func getCurrentUser() -> String {
		return currentUser
	}
	
	//Returns the desired tab index
	func getDesiredTabIndex() -> Int {
		return desiredTabIndex
	}
	
	//Returns the desired requests tab index
	func getDesiredRequestsTabIndex() -> Int {
		return desiredRequestsTabIndex
	}
	
	//Returns the ID of the user profile to open
	func getUserProfileToOpen() -> String {
		return userProfileToOpen
	}
	
	//Returns and removes the last storyboard ID in the navigation stack
	func getVCIDOfCaller() -> String {
		let vcid = navigationStack.popLast() ?? "tabController"
		//Reset stack if user goes back to one of main tabs
		if vcid == "tabController" {
			navigationStack.removeAll()
		}
		return vcid
	}
	
	//Returns the last storyboard ID in the navigation stack without removing it
	func fetchVCIDOfCaller() -> String {
		return navigationStack.last ?? "tabController"
	}
	
	//Returns the current map center coordinate
	func getCurrentMapCenterCoordinate() -> CLLocationCoordinate2D {
		return currentMapCenterCoordinate
	}
	
	//Returns the current map view span
	func getCurrentMapViewSpan() -> MKCoordinateSpan {
		return currentMapViewSpan
	}
	
	//Returns true if user is logging in first time in app session
	func getFirstLoginBool() -> Bool {
		return firstLoginBool
	}
	
	//Returns true if the map view should zoom to user's location
	func getZoomToUserLocationBool() -> Bool {
		return zoomToUserLocationBool
	}
	
	//Returns the recent user location coordinate
	func getRecentUserLocation() -> CLLocationCoordinate2D? {
		return recentUserLocation
	}
	
	//Returns the photo record ID of photo to open
	func getPhotoToOpen() -> String {
		return photoToOpen
	}
	
	// MARK: - Setters
	
	//Sets current user
	func setCurrentUser(_ id: String) {
		self.currentUser = id
	}
	
	//Sets the desired tab index
	func setDesiredTabIndex(_ i: Int) {
		self.desiredTabIndex = i
	}
	
	//Sets the desired requests tab index
	func setDesiredRequestsTabIndex(_ i: Int) {
		self.desiredRequestsTabIndex = i
	}
	
	//Sets the user profile to open
	func setUserProfileToOpen(_ id: String) {
		self.userProfileToOpen = id
	}
	
	//Adds a storyboard ID to the navigation stack
	func setVCIDOfCaller(_ id: String) {
		self.navigationStack.append(id)
	}
	
	//Sets the current map center coordinate
	func setCurrentMapCenterCoordinate(_ coordinate: CLLocationCoordinate2D) {
		self.currentMapCenterCoordinate = coordinate
	}
	
	//Sets the current map view span
	func setCurrentMapViewSpan(_ span: MKCoordinateSpan) {
		self.currentMapViewSpan = span
	}
	
	//Sets the first login bool
	func setFirstLoginBool(_ bool: Bool) {
		self.firstLoginBool = bool
	}
	
	//Sets the zoom to user location bool
	func setZoomToUserLocationBool(_ bool: Bool) {
		self.zoomToUserLocationBool = bool
	}
	
	//Sets the ID of photo record for photo to open
	func setPhotoToOpen(_ id: String) {
		self.photoToOpen = id
	}
	
	//Sets the coordinate of the recent user's location
	func setRecentUserLocation(_ coordinate: CLLocationCoordinate2D?) {
		self.recentUserLocation = coordinate
	}
}
