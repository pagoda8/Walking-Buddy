//
//  StrangerProfileVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 06/02/2023.
//
//	Implements the stranger profile page view controller

import UIKit
import CloudKit

class StrangerProfileVC: UIViewController {

	//Reference to db manager
	private let db = DBManager.shared
	
	//Indicates if there is an incoming friend request from the stranger
	private var friendRequestReceived: Bool = false
	
	//Indicates if a friend request was sent to the stranger
	private var friendRequestSent: Bool = false

	@IBOutlet weak var imageView: UIImageView! //Image view showing profile photo
	@IBOutlet weak var firstName: UILabel! //Label with first name
	@IBOutlet weak var lastName: UILabel! //Label with last name
	@IBOutlet weak var username: UILabel! //Label with username
	@IBOutlet weak var ageRange: UILabel! //Label with age range
	@IBOutlet weak var xp: UILabel! //Label with XP points
	@IBOutlet weak var bio: UITextView! //Text view with bio
	
	@IBOutlet weak var addFriendButton: UIButton! //Button to send friend request
	@IBOutlet weak var friendRequestSentButton: UIButton! //Shown if friend request was sent
	@IBOutlet weak var acceptFriendRequestButton: UIButton! //Button to accept friend request
	@IBOutlet weak var denyFriendRequestButton: UIButton! //Button to deny friend request
	
	// MARK: - View functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		determineFriendRequestState()
		fetchData()
	}
	
	// MARK: - IBActions
	
	//When accept friend request button is tapped
	@IBAction func acceptFriendRequest(_ sender: Any) {
		vibrate(style: .light)
		acceptFriendRequestButton.isUserInteractionEnabled = false
		denyFriendRequestButton.isUserInteractionEnabled = false
		
		let group = DispatchGroup()
		let ourID = AppDelegate.get().getCurrentUser()
		let profileID = AppDelegate.get().getUserProfileToOpen()
		
		//Delete friend request
		let predicate = NSPredicate(format: "senderID == %@ AND receiverID == %@", profileID, ourID)
		let query = CKQuery(recordType: "FriendRequests", predicate: predicate)
		group.enter()
		db.getRecords(query: query) { [weak self] returnedRecords in
			for requestRecord in returnedRecords {
				group.enter()
				self?.db.deleteRecord(record: requestRecord) { _ in
					group.leave()
				}
			}
			group.leave()
		}
		
		//Add person to our friends
		let predicate2 = NSPredicate(format: "id == %@", ourID)
		let query2 = CKQuery(recordType: "Friends", predicate: predicate2)
		group.enter()
		db.getRecords(query: query2) { [weak self] returnedRecords in
			let friendsRecord = returnedRecords[0]
			var ourFriendsArray = (friendsRecord["friends"] as? [String]) ?? []
			ourFriendsArray.append(profileID)
			friendsRecord["friends"] = ourFriendsArray
			
			group.enter()
			self?.db.saveRecord(record: friendsRecord) { _ in
				group.leave()
			}
			group.leave()
		}
		
		//Add us to other person's friends
		let predicate3 = NSPredicate(format: "id == %@", profileID)
		let query3 = CKQuery(recordType: "Friends", predicate: predicate3)
		group.enter()
		db.getRecords(query: query3) { [weak self] returnedRecords in
			let friendsRecord = returnedRecords[0]
			var otherFriendsArray = (friendsRecord["friends"] as? [String]) ?? []
			otherFriendsArray.append(ourID)
			friendsRecord["friends"] = otherFriendsArray
			
			group.enter()
			self?.db.saveRecord(record: friendsRecord) { _ in
				group.leave()
			}
			group.leave()
		}
		
		group.notify(queue: .main) {
			//After accepting request, open friend's profile page
			AppDelegate.get().setUserProfileToOpen(profileID)
			self.showVC(identifier: "friendProfile")
		}
	}
	
	//When deny friend request button is tapped
	@IBAction func denyFriendRequest(_ sender: Any) {
		vibrate(style: .light)
		denyFriendRequestButton.isUserInteractionEnabled = false
		acceptFriendRequestButton.isUserInteractionEnabled = false
		
		var error = false
		let group = DispatchGroup()
		let ourID = AppDelegate.get().getCurrentUser()
		let profileID = AppDelegate.get().getUserProfileToOpen()
		
		//Delete friend request
		let predicate = NSPredicate(format: "senderID == %@ AND receiverID == %@", profileID, ourID)
		let query = CKQuery(recordType: "FriendRequests", predicate: predicate)
		group.enter()
		db.getRecords(query: query) { [weak self] returnedRecords in
			for requestRecord in returnedRecords {
				group.enter()
				self?.db.deleteRecord(record: requestRecord) { success in
					if !success {
						error = true
					}
					group.leave()
				}
			}
			group.leave()
		}
		
		group.notify(queue: .main) {
			if error {
				self.denyFriendRequestButton.isUserInteractionEnabled = true
				self.acceptFriendRequestButton.isUserInteractionEnabled = true
				self.showAlert(title: "Error while denying friend request", message: "Try again later")
			}
			else {
				//After denying request, open previous VC
				let vcid = AppDelegate.get().getVCIDOfCaller()
				self.showVC(identifier: vcid)
			}
		}
	}
	
	//When add friend button is tapped
	@IBAction func addFriend(_ sender: Any) {
		vibrate(style: .light)
		addFriendButton.isUserInteractionEnabled = false
		
		//Create and save friend request record
		let requestRecord = CKRecord(recordType: "FriendRequests")
		requestRecord["senderID"] = AppDelegate.get().getCurrentUser()
		requestRecord["receiverID"] = AppDelegate.get().getUserProfileToOpen()
		db.saveRecord(record: requestRecord) { [weak self] saved in
			if !saved {
				DispatchQueue.main.async {
					self?.addFriendButton.isUserInteractionEnabled = true
					self?.showAlert(title: "Error while sending friend request", message: "Try again later")
				}
			}
			else {
				DispatchQueue.main.async {
					self?.addFriendButton.isHidden = true
					self?.friendRequestSentButton.isHidden = false
				}
			}
		}
	}
	
	//When back button is tapped
	@IBAction func back(_ sender: Any) {
		let vcid = AppDelegate.get().getVCIDOfCaller()
		showVC(identifier: vcid)
	}
	
	// MARK: - Functions
	
	//Fetch profile data from db
	private func fetchData() {
		let id = AppDelegate.get().getUserProfileToOpen()
		let predicate = NSPredicate(format: "id == %@", id)
		let query = CKQuery(recordType: "Profiles", predicate: predicate)
		
		self.db.getRecords(query: query) { [weak self] returnedRecords in
			let profileRecord = returnedRecords[0]
			
			//Set profile page image
			let imageAsset = profileRecord["photo"] as? CKAsset
			if let imageUrl = imageAsset?.fileURL,
			   let data = try? Data(contentsOf: imageUrl),
			   let image = UIImage(data: data) {
				DispatchQueue.main.async {
					self?.imageView.image = image
				}
			}
			
			//Set profile page info
			DispatchQueue.main.async {
				self?.firstName.text = profileRecord["firstName"]
				self?.lastName.text = profileRecord["lastName"]
				self?.username.text = "@" + (profileRecord["username"] as! String)
				self?.ageRange.text = (profileRecord["ageRange"] as! String) + " years"
				self?.xp.text = String(profileRecord["xp"] as! Int64) + " XP"
				self?.bio.text = profileRecord["bio"]
			}
		}
	}
	
	//Update button visibility
	private func updateButtonVisibility() {
		addFriendButton.isHidden = friendRequestReceived || friendRequestSent
		friendRequestSentButton.isHidden = !friendRequestSent || friendRequestReceived
		acceptFriendRequestButton.isHidden = !friendRequestReceived || friendRequestSent
		denyFriendRequestButton.isHidden = !friendRequestReceived || friendRequestSent
	}
	
	//Check if there is a friend request sent/received
	private func determineFriendRequestState() {
		let group = DispatchGroup()
		let userID = AppDelegate.get().getCurrentUser()
		let strangerID = AppDelegate.get().getUserProfileToOpen()
		
		//Check outgoing requests
		let predicate = NSPredicate(format: "senderID == %@ AND receiverID == %@", userID, strangerID)
		let query = CKQuery(recordType: "FriendRequests", predicate: predicate)
		group.enter()
		self.db.getRecords(query: query) { [weak self] returnedRecords in
			if !returnedRecords.isEmpty {
				DispatchQueue.main.async {
					self?.friendRequestSent = true
				}
			}
			group.leave()
		}
		
		//Check ingoing requests
		let predicate2 = NSPredicate(format: "senderID == %@ AND receiverID == %@", strangerID, userID)
		let query2 = CKQuery(recordType: "FriendRequests", predicate: predicate2)
		group.enter()
		self.db.getRecords(query: query2) { [weak self] returnedRecords in
			if !returnedRecords.isEmpty {
				DispatchQueue.main.async {
					self?.friendRequestReceived = true
				}
			}
			group.leave()
		}
		
		group.notify(queue: .main) {
			self.updateButtonVisibility()
		}
	}
	
	// MARK: - Other
	
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
	
	//Shows alert with given title and message
	private func showAlert(title: String, message: String) {
		vibrate(style: .light)
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		self.present(alert, animated: true)
	}
}
