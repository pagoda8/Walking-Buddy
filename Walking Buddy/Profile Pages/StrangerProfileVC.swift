//
//  StrangerProfileVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 06/02/2023.
//

import UIKit
import CloudKit

class StrangerProfileVC: UIViewController {

	//Reference to db manager
	private let db = DBManager.shared
	//Used to show appropriate buttons
	private var friendRequestReceived: Bool = false
	private var friendRequestSent: Bool = false

	@IBOutlet weak var imageView: UIImageView! //Image view showing profile photo
	@IBOutlet weak var name: UILabel! //Label with first name
	@IBOutlet weak var surname: UILabel! //Label with surname
	@IBOutlet weak var username: UILabel! //Label with username
	@IBOutlet weak var ageRange: UILabel! //Label with age range
	@IBOutlet weak var xp: UILabel!
	@IBOutlet weak var bio: UITextView! //Text view with bio
	
	@IBOutlet weak var addFriendButton: UIButton!
	@IBOutlet weak var friendRequestSentButton: UIButton!
	@IBOutlet weak var acceptFriendRequestButton: UIButton!
	@IBOutlet weak var denyFriendRequestButton: UIButton!
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		determineFriendRequestState()
		fetchData()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	private func updateButtonLayout() {
		addFriendButton.isHidden = friendRequestReceived || friendRequestSent
		friendRequestSentButton.isHidden = !friendRequestSent || friendRequestReceived
		acceptFriendRequestButton.isHidden = !friendRequestReceived || friendRequestSent
		denyFriendRequestButton.isHidden = !friendRequestReceived || friendRequestSent
	}
	
	private func determineFriendRequestState() {
		let userID = AppDelegate.get().getCurrentUser()
		let strangerID = AppDelegate.get().getUserProfileToOpen()
		let group = DispatchGroup()
		
		//Check outgoing requests
		let predicate = NSPredicate(format: "senderID == %@ AND receiverID == %@", userID, strangerID)
		let query = CKQuery(recordType: "FriendRequests", predicate: predicate)
		group.enter()
		self.db.getRecords(query: query) { returnedRecords in
			if !returnedRecords.isEmpty {
				DispatchQueue.main.async {
					self.friendRequestSent = true
				}
			}
			group.leave()
		}
		
		//Check ingoing requests
		let predicate2 = NSPredicate(format: "senderID == %@ AND receiverID == %@", strangerID, userID)
		let query2 = CKQuery(recordType: "FriendRequests", predicate: predicate2)
		group.enter()
		self.db.getRecords(query: query2) { returnedRecords in
			if !returnedRecords.isEmpty {
				DispatchQueue.main.async {
					self.friendRequestReceived = true
				}
			}
			group.leave()
		}
		
		group.notify(queue: .main) {
			self.updateButtonLayout()
		}
	}
	
	//Fetch profile data
	private func fetchData() {
		let id = AppDelegate.get().getUserProfileToOpen()
		let predicate = NSPredicate(format: "id == %@", id)
		let query = CKQuery(recordType: "Profiles", predicate: predicate)
		
		self.db.getRecords(query: query) { returnedRecords in
			let profile = returnedRecords[0]
			
			let imageAsset = profile["photo"] as? CKAsset
			if let imageUrl = imageAsset?.fileURL,
			   let data = try? Data(contentsOf: imageUrl),
			   let image = UIImage(data: data) {
				DispatchQueue.main.async {
					self.imageView.image = image
				}
			}
			
			DispatchQueue.main.async {
				self.name.text = profile["firstName"]
				self.surname.text = profile["lastName"]
				self.username.text = "@" + (profile["username"] as! String)
				self.ageRange.text = (profile["ageRange"] as! String) + " years"
				self.xp.text = String(profile["xp"] as! Int64) + " XP"
				self.bio.text = profile["bio"]
			}
		}
	}
	
	@IBAction func acceptFriendRequest(_ sender: Any) {
		acceptFriendRequestButton.isUserInteractionEnabled = false
		denyFriendRequestButton.isUserInteractionEnabled = false
		let group = DispatchGroup()
		
		let ourID = AppDelegate.get().getCurrentUser()
		let profileID = AppDelegate.get().getUserProfileToOpen()
		
		//Delete friend request
		let predicate = NSPredicate(format: "senderID == %@ AND receiverID == %@", profileID, ourID)
		let query = CKQuery(recordType: "FriendRequests", predicate: predicate)
		group.enter()
		db.getRecords(query: query) { returnedRecords in
			for request in returnedRecords {
				group.enter()
				self.db.deleteRecord(record: request) { _ in
					group.leave()
				}
			}
			group.leave()
		}
		
		//Add to our friends
		let predicate2 = NSPredicate(format: "id == %@", ourID)
		let query2 = CKQuery(recordType: "Friends", predicate: predicate2)
		group.enter()
		db.getRecords(query: query2) { returnedRecords in
			let friendsRecord = returnedRecords[0]
			var ourFriendsArray = (friendsRecord["friends"] as? [String]) ?? []
			ourFriendsArray.append(profileID)
			friendsRecord["friends"] = ourFriendsArray
			
			group.enter()
			self.db.saveRecord(record: friendsRecord) { _ in
				group.leave()
			}
			group.leave()
		}
		
		//Add to other person's friends
		let predicate3 = NSPredicate(format: "id == %@", profileID)
		let query3 = CKQuery(recordType: "Friends", predicate: predicate3)
		group.enter()
		db.getRecords(query: query3) { returnedRecords in
			let friendsRecord = returnedRecords[0]
			var otherFriendsArray = (friendsRecord["friends"] as? [String]) ?? []
			otherFriendsArray.append(ourID)
			friendsRecord["friends"] = otherFriendsArray
			
			group.enter()
			self.db.saveRecord(record: friendsRecord) { _ in
				group.leave()
			}
			group.leave()
		}
		
		group.notify(queue: .main) {
			AppDelegate.get().setUserProfileToOpen(profileID)
			AppDelegate.get().setVCIDOfCaller("requestsTabController")
			AppDelegate.get().setDesiredRequestsTabIndex(1)
			self.showVC(identifier: "friendProfile")
		}
	}
	
	@IBAction func denyFriendRequest(_ sender: Any) {
		denyFriendRequestButton.isUserInteractionEnabled = false
		acceptFriendRequestButton.isUserInteractionEnabled = false
		let group = DispatchGroup()
		var error = false
		
		let ourID = AppDelegate.get().getCurrentUser()
		let profileID = AppDelegate.get().getUserProfileToOpen()
		
		//Delete friend request
		let predicate = NSPredicate(format: "senderID == %@ AND receiverID == %@", profileID, ourID)
		let query = CKQuery(recordType: "FriendRequests", predicate: predicate)
		group.enter()
		db.getRecords(query: query) { returnedRecords in
			for request in returnedRecords {
				group.enter()
				self.db.deleteRecord(record: request) { success in
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
				let vcid = AppDelegate.get().getVCIDOfCaller()
				self.showVC(identifier: vcid)
			}
		}
	}
	
	@IBAction func addFriend(_ sender: Any) {
		addFriendButton.isUserInteractionEnabled = false
		
		let request = CKRecord(recordType: "FriendRequests")
		request["senderID"] = AppDelegate.get().getCurrentUser()
		request["receiverID"] = AppDelegate.get().getUserProfileToOpen()
		
		db.saveRecord(record: request) { saved in
			if !saved {
				DispatchQueue.main.async {
					self.addFriendButton.isUserInteractionEnabled = true
					self.showAlert(title: "Error while sending friend request", message: "Try again later")
				}
			}
			else {
				DispatchQueue.main.async {
					self.addFriendButton.isHidden = true
					self.friendRequestSentButton.isHidden = false
				}
			}
		}
	}
	
	@IBAction func back(_ sender: Any) {
		let vcid = AppDelegate.get().getVCIDOfCaller()
		showVC(identifier: vcid)
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
	
	//Shows alert with given title and message
	private func showAlert(title: String, message: String) {
		vibrate(style: .light)
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		self.present(alert, animated: true)
	}

}
