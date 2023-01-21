//
//  AccountCreationViewController.swift
//  Walking Buddy
//
//  Created by Wojtek on 20/01/2023.
//

import UIKit

class AccountCreationViewController: UIViewController {
	
	@IBOutlet weak var username: UITextField!
	@IBOutlet weak var bio: UITextView!
	@IBOutlet weak var segmentedControl: UISegmentedControl!
	
	@IBAction func segmentChange(_ sender: UISegmentedControl) {
		switch sender.selectedSegmentIndex {
		case 0:
			break
		case 1:
			break
		case 2:
			break
		case 3:
			break
		case 4:
			break
		default:
			break
		}
	}
	
	@IBAction func continueTapped(_ sender: Any) {
		if (username.text?.isEmpty == false) {
			//proceed
		}
		else {
			showAlert(title: "Username cannot be empty", message: "Please input a username")
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		//Tap anywhere to hide keyboard
		let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
		view.addGestureRecognizer(tap)
		
		segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: UIControl.State.normal)
		segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: UIControl.State.selected)
    }
	
	//Shows storyboard with given identifier
	private func showStoryboard(identifier: String) {
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
