//
//  ProfileVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 30/01/2023.
//
//	Implements the Profile Tab View Controller

import UIKit
import CloudKit

class ProfileVC: UIViewController {
	
	//Reference to db manager
	private let db = DBManager.shared

	@IBOutlet weak var imageView: UIImageView! //Image view showing profile photo
	@IBOutlet weak var firstName: UILabel! //Label with first name
	@IBOutlet weak var lastName: UILabel! //Label with last name
	@IBOutlet weak var username: UILabel! //Label with username
	@IBOutlet weak var ageRange: UILabel! //Label with age range
	@IBOutlet weak var xp: UILabel! //Label with XP points
	@IBOutlet weak var bio: UITextView! //Text view with bio
	@IBOutlet weak var bellButton: UIButton! //Bell (notifications) button
	
	// MARK: - View functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		fetchData()
		checkPendingRequests()
	}
	
	// MARK: - IBActions
	
	//When notification bell is tapped
	@IBAction func notifications(_ sender: Any) {
		AppDelegate.get().setDesiredRequestsTabIndex(0)
		showVC(identifier: "requestsTabController")
	}
	
	//When achievements (badge) button is tapped
	@IBAction func achievements(_ sender: Any) {
		showVC(identifier: "achievements")
	}
	
	//When My photos button is tapped
	@IBAction func myPhotos(_ sender: Any) {
		AppDelegate.get().setVCIDOfCaller("tabController")
		AppDelegate.get().setDesiredTabIndex(3)
		AppDelegate.get().setDesiredPhotosTabIndex(0)
		showVC(identifier: "photosTabController")
	}
	
	//When My friends button is tapped
	@IBAction func myFriends(_ sender: Any) {
		showVC(identifier: "friends")
	}
	
	//When health tips button is tapped
	@IBAction func healthTips(_ sender: Any) {
		showVC(identifier: "healthTips")
	}
	
	//When Settings button is tapped
	@IBAction func settings(_ sender: Any) {
		
	}
	
	//When Log out button is tapped
	@IBAction func logOut(_ sender: Any) {
		UserDefaults.standard.set(nil, forKey: "userID")
		AppDelegate.get().setCurrentUser("")
		AppDelegate.get().setFirstLoginBool(false)
		AppDelegate.get().setZoomToUserLocationBool(true)
		showVC(identifier: "login")
	}
	
	//When help button is tapped
	@IBAction func help(_ sender: Any) {
		showVC(identifier: "help")
	}
	
	// MARK: - Functions
	
	//Fetch profile data from db
	private func fetchData() {
		let id = AppDelegate.get().getCurrentUser()
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
	
	//Check if there are any pending requests and update bell button
	private func checkPendingRequests() {
		let group = DispatchGroup()
		let id = AppDelegate.get().getCurrentUser()
		var hasRequests = false
		
		//Get records with friend requests
		let predicate = NSPredicate(format: "receiverID == %@", id)
		let query = CKQuery(recordType: "FriendRequests", predicate: predicate)
		group.enter()
		self.db.getRecords(query: query) { returnedRecords in
			if !returnedRecords.isEmpty {
				hasRequests = true
			}
			group.leave()
		}
		
		//Get records with challenge requests
		let predicate3 = NSPredicate(format: "receiverID == %@", id)
		let query3 = CKQuery(recordType: "ChallengeRequests", predicate: predicate3)
		group.enter()
		self.db.getRecords(query: query3) { returnedRecords in
			if !returnedRecords.isEmpty {
				hasRequests = true
			}
			group.leave()
		}
		
		//After checking completes
		group.notify(queue: .main) {
			if hasRequests {
				self.bellButton.setImage(UIImage(systemName: "bell.badge"), for: .normal)
			}
			else {
				self.bellButton.setImage(UIImage(systemName: "bell"), for: .normal)
			}
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
