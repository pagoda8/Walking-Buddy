//
//  AppDelegate.swift
//  Walking Buddy
//
//  Created by Wojtek on 28/10/2022.
//

import UIKit
import CoreData
import CoreLocation
import MapKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

	//ID of current user
	private var currentUser = String()
	//Index of the tab that should be opened (main tab bar)
	private var desiredTabIndex = 1
	//Index of the tab that should be opened (requests tab bar)
	private var desiredRequestsTabIndex = 0
	//ID of user for opening a profile page
	private var userProfileToOpen = String()
	//Storyboard ID of the caller view controller
	//Used for back actions
	private var VCIDOfCaller = String()
	//Center of map region most recently shown
	private var currentMapCenterCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
	//Most recent map view span
	private var currentMapViewSpan: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
	

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		return true
	}

	// MARK: UISceneSession Lifecycle

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
	
	//Returns logged in user
	func getCurrentUser() -> String {
		return currentUser
	}
	
	//Sets current user
	func setCurrentUser(_ id: String) {
		self.currentUser = id
	}
	
	//Returns the desired tab index
	func getDesiredTabIndex() -> Int {
		return desiredTabIndex
	}
	
	//Sets the desired tab index
	func setDesiredTabIndex(_ i: Int) {
		self.desiredTabIndex = i
	}
	
	//Returns the desired requests tab index
	func getDesiredRequestsTabIndex() -> Int {
		return desiredRequestsTabIndex
	}
	
	//Sets the desired requests tab index
	func setDesiredRequestsTabIndex(_ i: Int) {
		self.desiredRequestsTabIndex = i
	}
	
	func getUserProfileToOpen() -> String {
		return userProfileToOpen
	}
	
	func setUserProfileToOpen(_ id: String) {
		self.userProfileToOpen = id
	}
	
	func getVCIDOfCaller() -> String {
		return VCIDOfCaller
	}
	
	func setVCIDOfCaller(_ id: String) {
		self.VCIDOfCaller = id
	}
	
	func getCurrentMapCenterCoordinate() -> CLLocationCoordinate2D {
		return currentMapCenterCoordinate
	}
	
	func setCurrentMapCenterCoordinate(_ coordinate: CLLocationCoordinate2D) {
		self.currentMapCenterCoordinate = coordinate
	}
	
	func getCurrentMapViewSpan() -> MKCoordinateSpan {
		return currentMapViewSpan
	}
	
	func setCurrentMapViewSpan(_ span: MKCoordinateSpan) {
		self.currentMapViewSpan = span
	}
	
	//Returns reference to AppDelegate
	static func get() -> AppDelegate {
		return UIApplication.shared.delegate as! AppDelegate
	}

}

