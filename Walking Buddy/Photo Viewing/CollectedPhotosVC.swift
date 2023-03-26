//
//  CollectedPhotosVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 26/03/2023.
//
//	Implements the collected photos view controller

import UIKit

class CollectedPhotosVC: UIViewController {
	
	@IBOutlet weak var titleLabel: UILabel! //Label showing title on top bar
	@IBOutlet weak var noPhotosLabel: UILabel! //Label shown when there are no collected photos

	// MARK: - View functions
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		titleSetup()
	}

	// MARK: - IBActions
	
	//When back button is tapped
	@IBAction func back(_ sender: Any) {
		let vcid = AppDelegate.get().getVCIDOfCaller()
		showVC(identifier: vcid)
	}
	
	// MARK: - Functions
	
	//Sets up title label based on the vcid of caller
	private func titleSetup() {
		let vcidOfCaller = AppDelegate.get().fetchVCIDOfCaller()
		if vcidOfCaller == "tabController" {
			titleLabel.text = "My photos"
		}
		else {
			titleLabel.text = "Photos"
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
