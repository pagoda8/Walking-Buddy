//
//  PhotoDetailsVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 21/03/2023.
//
//	Implements the photo details view controller

import UIKit

class PhotoDetailsVC: UIViewController {

	@IBOutlet weak var imageView: UIImageView! //Image view showing photo
	@IBOutlet weak var usernameButton: UIButton! //Button showing username of photo author
	@IBOutlet weak var collectionsLabel: UILabel! //Label showing number of photo collections
	@IBOutlet weak var distanceLabel: UILabel! //Label showing distance to photo location
	@IBOutlet weak var walkingTimeLabel: UILabel! //Label showing walking time to photo location
	@IBOutlet weak var collectButton: UIButton! //Button to collect photo
	@IBOutlet weak var messageLabel: UILabel! //Label showing reason why collection is not allowed
	@IBOutlet weak var locationButton: UIButton! //Button to show photo location on map
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		fetchData()
    }
	
	// MARK: - IBActions
	
	//When username button is tapped
	@IBAction func usernameTapped(_ sender: Any) {
		
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
		
	}
	
	// MARK: - Functions
	
	//Fetches photo data from db and updates view
	private func fetchData() {
		
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
