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
				self.bio.text = profile["bio"]
			}
		}
	}
	
	//When My photos button is tapped
	@IBAction func myPhotos(_ sender: Any) {
		
	}
	
	//When My friends button is tapped
	@IBAction func myFriends(_ sender: Any) {
		
	}
	
	//When Settings button is tapped
	@IBAction func settings(_ sender: Any) {
		
	}
	
	//When Log out button is tapped
	@IBAction func logOut(_ sender: Any) {
		AppDelegate.get().setCurrentUser("")
		
		//Go to login screen
		let vc = self.storyboard?.instantiateViewController(withIdentifier: "login")
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}

}
