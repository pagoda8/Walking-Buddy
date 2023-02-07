//
//  FriendProfileVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 06/02/2023.
//

import UIKit
import CloudKit

class FriendProfileVC: UIViewController {

	//Reference to db manager
	private let db = DBManager.shared

	@IBOutlet weak var imageView: UIImageView! //Image view showing profile photo
	@IBOutlet weak var name: UILabel! //Label with first name
	@IBOutlet weak var surname: UILabel! //Label with surname
	@IBOutlet weak var username: UILabel! //Label with username
	@IBOutlet weak var ageRange: UILabel! //Label with age range
	@IBOutlet weak var xp: UILabel!
	@IBOutlet weak var bio: UITextView! //Text view with bio
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)
		fetchData()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
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
	
	//When Photos button is tapped
	@IBAction func photos(_ sender: Any) {
		
	}
	
	//When Unfriend button is tapped
	@IBAction func unfriend(_ sender: Any) {
		
	}
	
	//When request walk button is tapped
	@IBAction func requestWalk(_ sender: Any) {
		
	}
	
	//When start xp challenge button is tapped
	@IBAction func startXPChallenge(_ sender: Any) {
		
	}
	
	//When my profile button is tapped
	@IBAction func myFriends(_ sender: Any) {
		showVC(identifier: "friends")
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