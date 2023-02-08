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
	@IBOutlet weak var name: UILabel! //Label with first name
	@IBOutlet weak var surname: UILabel! //Label with surname
	@IBOutlet weak var username: UILabel! //Label with username
	@IBOutlet weak var ageRange: UILabel! //Label with age range
	@IBOutlet weak var xp: UILabel!
	@IBOutlet weak var bio: UITextView! //Text view with bio
	
	@IBOutlet weak var bellButton: UIButton!
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)
		fetchData()
		checkPendingRequests()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	//Fetch profile data
	private func fetchData() {
		let id = AppDelegate.get().getCurrentUser()
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
	
	//Check if there are any pending requests and update bell button
	private func checkPendingRequests() {
		let group = DispatchGroup()
		var hasRequests = false
		
		let id = AppDelegate.get().getCurrentUser()
		let predicate = NSPredicate(format: "receiverID == %@", id)
		let query = CKQuery(recordType: "FriendRequests", predicate: predicate)
		
		//Get records with friend requests
		group.enter()
		self.db.getRecords(query: query) { returnedRecords in
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
	
	//When notification bell is tapped
	@IBAction func notifications(_ sender: Any) {
		AppDelegate.get().setDesiredRequestsTabIndex(0)
		showVC(identifier: "requestsTabController")
	}
	
	//When My photos button is tapped
	@IBAction func myPhotos(_ sender: Any) {
		
	}
	
	//When My friends button is tapped
	@IBAction func myFriends(_ sender: Any) {
		showVC(identifier: "friends")
	}
	
	//When Settings button is tapped
	@IBAction func settings(_ sender: Any) {
		
	}
	
	//When Log out button is tapped
	@IBAction func logOut(_ sender: Any) {
		AppDelegate.get().setCurrentUser("")
		showVC(identifier: "login")
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
