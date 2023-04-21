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
	@IBOutlet weak var collectButtonGray: UIButton! //Info button showing that collection is not allowed
	@IBOutlet weak var collectedButtonGray: UIButton! //Info button showing that photo was collected
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
		activityIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
		activityIndicator.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -40).isActive = true
		activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0)
		activityIndicator.color = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
		activityIndicator.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
		
		fetchData()
    }
	
	// MARK: - IBActions
	
	//When username button is tapped
	@IBAction func usernameTapped(_ sender: Any) {
		let ourID = AppDelegate.get().getCurrentUser()
		if authorID == ourID {
			AppDelegate.get().setDesiredTabIndex(3)
			showVC(identifier: "tabController")
		}
		else {
			AppDelegate.get().setUserProfileToOpen(authorID)
			AppDelegate.get().setVCIDOfCaller("photoDetails")
			let vcid = authorIsFriend ? "friendProfile" : "strangerProfile"
			showVC(identifier: vcid)
		}
	}
	
	//When the back button is tapped
	@IBAction func back(_ sender: Any) {
		let vcid = AppDelegate.get().getVCIDOfCaller()
		showVC(identifier: vcid)
	}
	
	//When collect photo button is tapped
	@IBAction func collectPhotoTapped(_ sender: Any) {
		vibrate(style: .light)
		
		//Update collect button
		collectButton.isHidden = true
		collectedButtonGray.isHidden = false
		
		//Update message and collections
		messageLabel.text = messages["time"]
		updateCollections()
		updateCollectionsLabel()
		
		awardXP()
		updateCollectorAchievement()
		updateChallenges()
		collectPhoto()
	}
	
	//When the location button is tapped
	@IBAction func showPhotoLocation(_ sender: Any) {
		let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
		AppDelegate.get().setCurrentMapCenterCoordinate(photoCoordinate)
		AppDelegate.get().setCurrentMapViewSpan(span)
		AppDelegate.get().setDesiredTabIndex(1)
		showVC(identifier: "tabController")
	}
	
	// MARK: - Functions (View setup)
	
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
		locationButton.isHidden = false
		
		//Show appropriate collect button based on previous checks
		if collectButton.isUserInteractionEnabled {
			collectButton.isHidden = false
		}
		else {
			collectButtonGray.isHidden = false
		}
	}
	
	//Unhide icons after all data is fetched
	private func showIcons() {
		profileIcon.isHidden = false
		distanceIcon.isHidden = false
		collectionsIcon.isHidden = false
		walkTimeIcon.isHidden = false
	}
	
	//Fetches photo data from db and updates view
	private func fetchData() {
		activityIndicator.startAnimating()
		let imageSize = imageView.bounds.size
		
		let photoID = AppDelegate.get().getPhotoToOpen()
		let photoRecordID = CKRecord.ID(recordName: photoID)
		let predicate = NSPredicate(format: "recordID == %@", photoRecordID)
		let query = CKQuery(recordType: "Photos", predicate: predicate)
		
		db.getRecords(query: query) { [weak self] returnedRecords in
			let photoRecord = returnedRecords[0]
			let group = DispatchGroup()
			
			//Set author, location and collections label
			self?.authorID = photoRecord["authorID"] as! String
			let photoLocation = photoRecord["location"] as! CLLocation
			self?.photoCoordinate = photoLocation.coordinate
			let collections = photoRecord["collected"] as! Int64
			DispatchQueue.main.async {
				self?.collectionsLabel.text = self?.createCollectionsString(collections: Int(collections))
			}
			
			//Set main image view
			let photoAsset = photoRecord["photo"] as? CKAsset
			if let imageUrl = photoAsset?.fileURL,
			   let image = ImageTool.downsample(imageAt: imageUrl, to: imageSize) {
				DispatchQueue.main.async {
					self?.imageView.image = image
				}
			}
			
			//Set up username button
			group.enter()
			self?.getAuthorsUsername() { [weak self] authorsUsername in
				DispatchQueue.main.async {
					self?.usernameButton.setTitle("@" + authorsUsername, for: .normal)
				}
				group.leave()
			}
			
			//Determine user-author friend status
			group.enter()
			DispatchQueue.main.async {
				self?.checkAuthorFriendStatus() { _ in
					group.leave()
				}
			}
			
			//Set up location info
			group.enter()
			DispatchQueue.main.async {
				self?.setupLocationRelatedInfo() { _ in
					group.leave()
				}
			}
			
			group.notify(queue: .main) {
				let group2 = DispatchGroup()
				
				//Set up collect button and message
				group2.enter()
				DispatchQueue.main.async {
					self?.setupCollectButtonAndMessage() { _ in
						group2.leave()
					}
				}
				
				group2.notify(queue: .main) {
					DispatchQueue.main.async {
						//Show everything after fetching completes
						self?.activityIndicator.stopAnimating()
						self?.showIcons()
						self?.showPhotoAndLabels()
						self?.showButtons()
					}
				}
			}
		}
	}
	
	//Sets up labels that depend on user's location
	private func setupLocationRelatedInfo(completion: @escaping (Bool) -> Void) {
		let userCoordinate = AppDelegate.get().getRecentUserLocation()
		if userCoordinate == nil {
			//No location data
			distanceLabel.text = "  ?  "
			walkingTimeLabel.text = "  ?  "
			completion(true)
		}
		else {
			let userLocation = CLLocation(latitude: userCoordinate!.latitude, longitude: userCoordinate!.longitude)
			let photoLocation = CLLocation(latitude: photoCoordinate.latitude, longitude: photoCoordinate.longitude)
			
			//Calculate distance
			let meterDistance = userLocation.distance(from: photoLocation)
			userWithin20m = (meterDistance <= 20)
			distanceLabel.text = self.createDistanceString(meters: meterDistance)
			
			//Calculate walk time
			calculateWalkTime(coordinate1: userCoordinate!, coordinate2: photoCoordinate) { [weak self] walkMinutes in
				DispatchQueue.main.async {
					self?.walkingTimeLabel.text = self?.createWalkTimeString(minutes: walkMinutes)
				}
				completion(true)
			}
		}
	}
	
	//Sets up collect button and message
	private func setupCollectButtonAndMessage(completion: @escaping (Bool) -> Void) {
		let ourID = AppDelegate.get().getCurrentUser()
		let photoID = AppDelegate.get().getPhotoToOpen()
		var canCollect = true
		
		if !userWithin20m {
			canCollect = false
			messageLabel.text = self.messages["distance"]
		}
		
		//Check if collected recently
		if AppDelegate.get().wasPhotoRecentlyCollected(photoID) {
			canCollect = false
			messageLabel.text = self.messages["time"]
		}
		
		//Check if already collected today
		let predicate = NSPredicate(format: "userID == %@ AND photoID == %@", ourID, photoID)
		let query = CKQuery(recordType: "CollectedPhotos", predicate: predicate)
		db.getRecords(query: query) { [weak self] returnedRecords in
			if !returnedRecords.isEmpty {
				let collectedPhotoRecord = returnedRecords[0]
				let lastCollectedDate = collectedPhotoRecord["lastCollected"] as! Date
				let currentDate = Date()
				let seconds = currentDate - lastCollectedDate
				let hours = seconds / Double(60) / Double(60)
				
				if hours < 24 {
					canCollect = false
					DispatchQueue.main.async {
						self?.messageLabel.text = self?.messages["time"]
					}
				}
			}
			
			//Check if user is the author
			if ourID == self?.authorID {
				canCollect = false
				DispatchQueue.main.async {
					self?.messageLabel.text = self?.messages["author"]
				}
			}
			
			//Check if user gave location permissions
			DispatchQueue.main.async {
				let userLocation = AppDelegate.get().getRecentUserLocation()
				if userLocation == nil {
					canCollect = false
					self?.messageLabel.text = self?.messages["location"]
				}
			}
			
			if !canCollect {
				//Update button
				DispatchQueue.main.async {
					self?.collectButton.isUserInteractionEnabled = false
				}
				completion(true)
			}
			else {
				completion(true)
			}
		}
	}
	
	//Checks if photo author is user's friend
	private func checkAuthorFriendStatus(completion: @escaping (Bool) -> Void) {
		let ourID = AppDelegate.get().getCurrentUser()
		let authorID = self.authorID
		
		if AppDelegate.get().isUnfriendInProgress(authorID) {
			self.authorIsFriend = false
			completion(false)
			return
		}
		
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
	
	//Calculates the estimated walk time between coordinates and returns it in minutes
	//Returns -1 if unsuccessfull
	private func calculateWalkTime(coordinate1: CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D, completion: @escaping (Int) -> Void) {
		let request = MKDirections.Request()
		request.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinate1, addressDictionary: nil))
		request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate2, addressDictionary: nil))
		request.requestsAlternateRoutes = true
		request.transportType = .walking
		
		let directions = MKDirections(request: request)
		directions.calculate { (response, error) -> Void in
			guard let response = response else {
				if let error = error {
					print("Direction error: \(error)")
				}
				completion(-1)
				return
			}
			
			if response.routes.count > 0 {
				let route = response.routes[0]
				let minutes = Int(route.expectedTravelTime) / 60
				completion(minutes)
			}
			else {
				completion(-1)
			}
		}
	}
	
	// MARK: - Functions (collection)
	
	//Increments collections by 1 in the Photos record
	private func updateCollections() {
		let photoID = AppDelegate.get().getPhotoToOpen()
		let photoRecordID = CKRecord.ID(recordName: photoID)
		let predicate = NSPredicate(format: "recordID == %@", photoRecordID)
		let query = CKQuery(recordType: "Photos", predicate: predicate)
		
		db.getRecords(query: query) { [weak self] returnedRecords in
			let photoRecord = returnedRecords[0]
			let currentCollections = photoRecord["collected"] as! Int64
			photoRecord["collected"] = currentCollections + 1
			
			self?.db.saveRecord(record: photoRecord) { _ in }
		}
	}
	
	//Increments the collections label by 1
	private func updateCollectionsLabel() {
		let stringCollections = collectionsLabel.text
		if stringCollections?.last != "+" {
			let newCollections = (Int(stringCollections!) ?? 0) + 1
			collectionsLabel.text = createCollectionsString(collections: newCollections)
		}
	}
	
	//Award the user with 50 XP points
	private func awardXP() {
		let userID = AppDelegate.get().getCurrentUser()
		let predicate = NSPredicate(format: "id == %@", userID)
		let query = CKQuery(recordType: "Profiles", predicate: predicate)
		
		db.getRecords(query: query) { [weak self] returnedRecords in
			let profileRecord = returnedRecords[0]
			let currentXP = profileRecord["xp"] as! Int64
			profileRecord["xp"] = currentXP + 50
			
			self?.db.saveRecord(record: profileRecord) { _ in }
		}
	}
	
	//Update collector achievement of user when they collect a photo
	private func updateCollectorAchievement() {
		let userID = AppDelegate.get().getCurrentUser()
		let predicate = NSPredicate(format: "id == %@ AND name == %@", userID, "collector")
		let query = CKQuery(recordType: "Achievements", predicate: predicate)
		db.getRecords(query: query) { [weak self] returnedRecords in
			let achievementRecord = returnedRecords[0]
			
			//Update amount
			let currentAmount = achievementRecord["amount"] as! Int64
			let updatedAmount = currentAmount + 1
			achievementRecord["amount"] = updatedAmount
			
			//Update level
			let currentLevel = achievementRecord["level"] as! Int64
			if currentLevel == 0 && updatedAmount == 5 {
				achievementRecord["level"] = 1
			}
			else if currentLevel == 1 && updatedAmount == 15 {
				achievementRecord["level"] = 2
			}
			else if currentLevel == 2 && updatedAmount == 50 {
				achievementRecord["level"] = 3
			}
			
			self?.db.saveRecord(record: achievementRecord) { _ in }
		}
	}
	
	//Adds 50 XP for user in challenges which involve user
	private func updateChallenges() {
		let userID = AppDelegate.get().getCurrentUser()
		let group = DispatchGroup()
		var fetchedChallengesArray: [CKRecord] = []
		
		//Get challenge records 1
		let predicate1 = NSPredicate(format: "id1 == %@", userID)
		let query1 = CKQuery(recordType: "Challenges", predicate: predicate1)
		
		group.enter()
		self.db.getRecords(query: query1) { returnedRecords in
			fetchedChallengesArray.append(contentsOf: returnedRecords)
			group.leave()
		}
		
		//Get challenge records 2
		let predicate2 = NSPredicate(format: "id2 == %@", userID)
		let query2 = CKQuery(recordType: "Challenges", predicate: predicate2)
		
		group.enter()
		self.db.getRecords(query: query2) { returnedRecords in
			fetchedChallengesArray.append(contentsOf: returnedRecords)
			group.leave()
		}
		
		group.notify(queue: .main) {
			//Remove ended challenges from array
			var i = 0
			for challenge in fetchedChallengesArray {
				let endDate = challenge["end"] as! Date
				let currentDate = Date()
				let interval = endDate - currentDate
				
				if interval <= 0 {
					fetchedChallengesArray.remove(at: i)
				}
				else {
					i += 1
				}
			}
			
			//Award 50 XP to user in each challenge
			for challenge in fetchedChallengesArray {
				if (challenge["id1"] as! String) == userID {
					let currentXP = challenge["xp1"] as! Int64
					challenge["xp1"] = currentXP + 50
				}
				else {
					let currentXP = challenge["xp2"] as! Int64
					challenge["xp2"] = currentXP + 50
				}
				self.db.saveRecord(record: challenge) { _ in }
			}
		}
	}
	
	//Creates a CollectedPhotos record with user and photo,
	//or updates last collected date if already exists
	private func collectPhoto() {
		let userID = AppDelegate.get().getCurrentUser()
		let photoID = AppDelegate.get().getPhotoToOpen()
		
		AppDelegate.get().addCollectedPhoto(photoID)
		
		//Get collected photos record
		let predicate = NSPredicate(format: "userID == %@ AND photoID == %@", userID, photoID)
		let query = CKQuery(recordType: "CollectedPhotos", predicate: predicate)
		db.getRecords(query: query) { [weak self] returnedRecords in
			//Check if user already collected this photo
			if !returnedRecords.isEmpty {
				let collectedPhotosRecord = returnedRecords[0]
				collectedPhotosRecord["lastCollected"] = Date()
				self?.db.saveRecord(record: collectedPhotosRecord) { _ in }
			}
			else {
				let collectedPhotosRecord = CKRecord(recordType: "CollectedPhotos")
				collectedPhotosRecord["userID"] = userID
				collectedPhotosRecord["photoID"] = photoID
				collectedPhotosRecord["lastCollected"] = Date()
				self?.db.saveRecord(record: collectedPhotosRecord) { _ in }
			}
		}
	}
	
	// MARK: - String creation
	
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
	
	//Returns a string with walk time in readable format
	private func createWalkTimeString(minutes: Int) -> String {
		if minutes == -1 {
			return "  ?  "
		}
		
		if minutes < 60 {
			return String(minutes) + " min"
		}
		
		var hours = Double(minutes) / Double(60)
		
		if hours > 24 {
			return "24h+"
		}
		
		//Round hours to nearest hour or half hour
		hours = round(hours * 2) / 2
		
		var stringHours = String(format: "%.1f", hours)
		if stringHours.last == "0" {
			//Remove .0
			stringHours.removeLast()
			stringHours.removeLast()
		}
		return stringHours + " h"
	}
	
	//Returns a string with number of photo collections in readable format
	private func createCollectionsString(collections: Int) -> String {
		if collections < 1000 {
			return String(collections)
		}
		else {
			return "999+"
		}
	}
	
	// MARK: - Other
	
	//Shows view controller with given identifier
	private func showVC(identifier: String) {
		AppDelegate.get().filterNavigationStack(identifier)
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
