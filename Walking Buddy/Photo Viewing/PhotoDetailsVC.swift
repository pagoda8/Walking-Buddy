//
//  PhotoDetailsVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 21/03/2023.
//
//	Implements the photo details view controller

import UIKit
import MapKit
import CloudKit

class PhotoDetailsVC: UIViewController {
	
	//Reference to db manager
	private let db = DBManager.shared
	
	//Profile ID of photo author
	private var authorID = String()
	
	//Indicates if photo author is user's friend
	private var authorIsFriend = false
	
	//Coordinate of photo location
	private var photoCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
	
	//Indicates if the user is within 20m of the photo's location
	private var userWithin20m = false
	
	//Dictionary with available messages to show
	private let messages = [
		"distance": "You must be within 20m of the photo's location to collect it",
		"author": "You cannot collect your own photos",
		"location": "You must allow precise location usage to collect photos",
		"time": "You can only collect each photo once every 24h"
	]
	
	//Used to show that photo details are loading
	private let activityIndicator = UIActivityIndicatorView(style: .medium)

	@IBOutlet weak var imageView: UIImageView! //Image view showing photo
	@IBOutlet weak var usernameButton: UIButton! //Button showing username of photo author
	@IBOutlet weak var collectionsLabel: UILabel! //Label showing number of photo collections
	@IBOutlet weak var distanceLabel: UILabel! //Label showing distance to photo location
	@IBOutlet weak var walkingTimeLabel: UILabel! //Label showing walking time to photo location
	@IBOutlet weak var collectButton: UIButton! //Button to collect photo
	@IBOutlet weak var messageLabel: UILabel! //Label showing reason why collection is not allowed
	@IBOutlet weak var locationButton: UIButton! //Button to show photo location on map
	
	@IBOutlet weak var profileIcon: UIImageView! //Image view showing profile icon
	@IBOutlet weak var distanceIcon: UIImageView! //Image view showing distance icon
	@IBOutlet weak var collectionsIcon: UIImageView! //Image view showing collections icon
	@IBOutlet weak var walkTimeIcon: UIImageView! //Image view showing walk time icon
	
	// MARK: - View functions
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		//Set up activity indicator
		view.addSubview(activityIndicator)
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
		activityIndicator.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 30).isActive = true
		activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0)
		activityIndicator.color = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
		activityIndicator.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
		
		fetchData()
    }
	
	// MARK: - IBActions
	
	//When username button is tapped
	@IBAction func usernameTapped(_ sender: Any) {
		//Don't open any profile if we are the author
		let ourID = AppDelegate.get().getCurrentUser()
		if authorID == ourID {
			return
		}
		AppDelegate.get().setUserProfileToOpen(authorID)
		AppDelegate.get().setVCIDOfCaller("photoDetails")
		let vcid = authorIsFriend ? "friendProfile" : "strangerProfile"
		showVC(identifier: vcid)
	}
	
	//When the back button is tapped
	@IBAction func back(_ sender: Any) {
		let vcid = AppDelegate.get().getVCIDOfCaller()
		showVC(identifier: vcid)
	}
	
	//When collect photo button is tapped
	@IBAction func collectPhoto(_ sender: Any) {
		
	}
	
	//When the location button is tapped
	@IBAction func showPhotoLocation(_ sender: Any) {
		let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
		AppDelegate.get().setCurrentMapCenterCoordinate(photoCoordinate)
		AppDelegate.get().setCurrentMapViewSpan(span)
		AppDelegate.get().setDesiredTabIndex(1)
		showVC(identifier: "tabController")
	}
	
	// MARK: - Functions
	
	//Fetches photo data from db and updates view
	private func fetchData() {
		activityIndicator.startAnimating()
		
		
		
		activityIndicator.stopAnimating()
	}
	
	//Unhide main image view and labels after all data is fetched
	private func showPhotoAndLabels() {
		imageView.isHidden = false
		distanceLabel.isHidden = false
		collectionsLabel.isHidden = false
		walkingTimeLabel.isHidden = false
		messageLabel.isHidden = false
	}
	
	//Unhide buttons after fetching all data needed for them
	private func showButtons() {
		usernameButton.isHidden = false
		collectButton.isHidden = false
		locationButton.isHidden = false
	}
	
	//Unhide icons after all data is fetched
	private func showIcons() {
		profileIcon.isHidden = false
		distanceIcon.isHidden = false
		collectionsIcon.isHidden = false
		walkTimeIcon.isHidden = false
	}
	
	//Sets up labels that depend on user's location
	private func setupLocationRelatedInfo(completion: @escaping (Bool) -> Void) {
		let userCoordinate = AppDelegate.get().getRecentUserLocation()
		if userCoordinate == nil {
			distanceLabel.text = ". . ."
			walkingTimeLabel.text = ". . ."
			completion(true)
		}
		else {
			let userLocation = CLLocation(latitude: userCoordinate!.latitude, longitude: userCoordinate!.longitude)
			let photoLocation = CLLocation(latitude: photoCoordinate.latitude, longitude: photoCoordinate.longitude)
			
			let meterDistance = userLocation.distance(from: photoLocation)
			userWithin20m = (meterDistance <= 20)
			distanceLabel.text = createDistanceString(meters: meterDistance)
			
			
			
			completion(true)
		}
	}
	
	//Sets up collect button and message
	private func setupCollectButtonAndMessage(completion: @escaping (Bool) -> Void) {
		
	}
	
	//Checks if photo author is user's friend
	private func checkAuthorFriendStatus(completion: @escaping (Bool) -> Void) {
		let ourID = AppDelegate.get().getCurrentUser()
		let authorID = authorID
		let predicate = NSPredicate(format: "id == %@", ourID)
		let query = CKQuery(recordType: "Friends", predicate: predicate)
		
		db.getRecords(query: query) { [weak self] returnedRecords in
			let friendsRecord = returnedRecords[0]
			let friendsArray = (friendsRecord["friends"] as? [String]) ?? []
			
			if friendsArray.contains(authorID) {
				self?.authorIsFriend = true
				completion(true)
			}
			else {
				self?.authorIsFriend = false
				completion(false)
			}
		}
	}
	
	//Returns the username of the photo's author
	private func getAuthorsUsername(completion: @escaping (String) -> Void) {
		let predicate = NSPredicate(format: "id == %@", authorID)
		let query = CKQuery(recordType: "Profiles", predicate: predicate)
		
		db.getRecords(query: query) { returnedRecords in
			let profileRecord = returnedRecords[0]
			completion(profileRecord["username"] as! String)
		}
	}
	
	//Returns a string with distance in readable format
	private func createDistanceString(meters: CLLocationDistance) -> String {
		if meters <= 999 {
			return String(Int(meters.rounded(.up))) + " m"
		}
		else {
			let km = meters.rounded(.up) / 1000
			return String(Int(km.rounded())) + " km"
		}
	}
	
	// MARK: - Other
	
	//Shows alert with given title and message
	private func showAlert(title: String, message: String) {
		vibrate(style: .light)
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		self.present(alert, animated: true)
	}
	
	//Shows view controller with given identifier
	private func showVC(identifier: String) {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: identifier)
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
	
	//Vibrates phone with given style
	private func vibrate(style: UIImpactFeedbackGenerator.FeedbackStyle) {
		let generator = UIImpactFeedbackGenerator(style: style)
		generator.impactOccurred()
	}
}
