//
//  AccountCreationViewController.swift
//  Walking Buddy
//
//  Created by Wojtek on 20/01/2023.
//
//	Implements the Account Creation View Controller

import UIKit
import AVFoundation
import Photos
import CloudKit

class AccountCreationViewController: UIViewController {
	
	//The user's selected age range
	private var ageRange: String = ""
	
	@IBOutlet weak var username: UITextField! //Text field to input username
	@IBOutlet weak var bio: UITextView! //Text field to input bio
	@IBOutlet weak var segmentedControl: UISegmentedControl! //Segmented control to choose age range
	@IBOutlet weak var selectButton: UIButton! //Button to select image
	@IBOutlet weak var imageView: UIImageView! //Image view of chosen photo
	@IBOutlet weak var changeButton: UIButton! //Button to change photo
	
	//When user interacts with the segmented control
	@IBAction func segmentChange(_ sender: UISegmentedControl) {
		switch sender.selectedSegmentIndex {
		case 0:
			ageRange = "0-14"
		case 1:
			ageRange = "15-24"
		case 2:
			ageRange = "25-39"
		case 3:
			ageRange = "40-64"
		case 4:
			ageRange = "65+"
		default:
			ageRange = ""
		}
	}
	
	//When Select button is tapped
	@IBAction func selectPhoto(_ sender: Any) {
		openPhotoSelectSheet()
	}
	
	//When Change button is tapped
	@IBAction func changePhoto(_ sender: Any) {
		openPhotoSelectSheet()
	}
	
	//When Countinue button is tapped
	@IBAction func continueTapped(_ sender: Any) {
		if (username.text?.isEmpty == false) {
			//check if username exists
			//if not proceed and save in db, go to main screen
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
		
		//Segmented control appearance
		segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: UIControl.State.normal)
		segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: UIControl.State.selected)
    }
	
	//Opens action sheet to choose image
	private func openPhotoSelectSheet() {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Select a Photo", message: nil, preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Use Camera", style: .default, handler: { _ in
				if self.cameraPermissionGranted() {
					self.openCamera()
				} else {
					self.requestCameraPermission()
				}
			}))
			alert.addAction(UIAlertAction(title: "Open Gallery", style: .default, handler: { _ in
				if self.galleryPermissionGranted() {
					self.openGallery()
				} else {
					self.requestGalleryPermission()
				}
			}))
			alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
			self.present(alert, animated: true, completion: nil)
	}
	
	//Returns a bool whether the user allowed camera access
	private func cameraPermissionGranted() -> Bool {
		if (AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized) {
			return true
		}
		else {
			return false
		}
	}
	
	//Returns a bool whether the user allowed gallery access
	private func galleryPermissionGranted() -> Bool {
		let status = PHPhotoLibrary.authorizationStatus()
		if (status == .authorized) {
			return true
		}
		else {
			return false
		}
	}
	
	//Asks user for camera permissions
	private func requestCameraPermission() {
		AVCaptureDevice.requestAccess(for: AVMediaType.video) { allowed in
			if !allowed {
				self.showPermissionAlert()
			}
		}
	}
	
	//Asks user for gallery permissions
	private func requestGalleryPermission() {
		PHPhotoLibrary.requestAuthorization({ status in
			if status != .authorized {
				self.showPermissionAlert()
			}
		})
	}
	
	//Shows alert regarding permissions
	private func showPermissionAlert() {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Camera/Gallery permission required", message: "Without giving permission you cannot add a photo", preferredStyle: .alert)
		
		let goToSettings = UIAlertAction(title: "Go to Settings", style: .default) { _ in
			guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
				self.showAlert(title: "Error", message: "Cannot open Settings app")
				return
			}
			if (UIApplication.shared.canOpenURL(settingsURL)) {
				UIApplication.shared.open(settingsURL)
			} else {
				self.showAlert(title: "Error", message: "Cannot open Settings app")
			}
		}
		
		let cancel = UIAlertAction(title: "Cancel", style: .default)
		
		alert.addAction(cancel)
		alert.addAction(goToSettings)
		self.present(alert, animated: true)
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

extension AccountCreationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	//Opens user's camera
	public func openCamera() {
		if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
			let imagePicker = UIImagePickerController()
			imagePicker.delegate = self
			imagePicker.sourceType = UIImagePickerController.SourceType.camera
			imagePicker.allowsEditing = false
			self.present(imagePicker, animated: true, completion: nil)
		}
		else
		{
			let alert  = UIAlertController(title: "Error", message: "There occured a problem while trying to open camera", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	//Opens user's photo gallery
	public func openGallery() {
		if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
			let imagePicker = UIImagePickerController()
			imagePicker.delegate = self
			imagePicker.allowsEditing = false
			imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
			self.present(imagePicker, animated: true, completion: nil)
		}
		else
		{
			let alert  = UIAlertController(title: "Error", message: "There occured a problem while trying to open gallery", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	//When user selects a photo from camera/gallery
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		if let selectedImage = info[.originalImage] as? UIImage {
			imageView.image = selectedImage
			selectButton.isHidden = true
			imageView.isHidden = false
			changeButton.isHidden = false
		}
		picker.dismiss(animated: true, completion: nil)
	}
}
