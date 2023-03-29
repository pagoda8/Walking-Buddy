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
	private var ageRange: String = "15-24"
	
	//Reference to db manager
	private let db = DBManager.shared
	
	@IBOutlet weak var usernameField: UITextField! //Text field to input username
	@IBOutlet weak var bioField: UITextView! //Text field to input bio
	@IBOutlet weak var segmentedControl: UISegmentedControl! //Segmented control to choose age range
	@IBOutlet weak var selectButton: UIButton! //Button to select image
	@IBOutlet weak var imageView: UIImageView! //Image view of chosen photo
	@IBOutlet weak var changeButton: UIButton! //Button to change photo
	@IBOutlet weak var continueButton: UIButton! //Button to continue
	
	// MARK: - View functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//Tap anywhere to hide keyboard
		let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
		view.addGestureRecognizer(tap)
		
		//Segmented control appearance
		segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: UIControl.State.normal)
		segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: UIControl.State.selected)
	}
	
	// MARK: - IBActions
	
	//When user interacts with the segmented control
	@IBAction func segmentChange(_ sender: UISegmentedControl) {
		vibrate(style: .light)
		switch sender.selectedSegmentIndex {
		case 0:
			ageRange = "15-24"
		case 1:
			ageRange = "25-39"
		case 2:
			ageRange = "40-64"
		case 3:
			ageRange = "65+"
		default:
			ageRange = "15-24"
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
		setUserInteraction(false)
		let usernameText = usernameField.text
		let bioText = bioField.text
		
		if (usernameText?.isEmpty == false) {
			let id = AppDelegate.get().getCurrentUser()
			
			//Create photo asset
			let photoAsset = self.createPhotoAsset()
			if photoAsset == nil {
				setUserInteraction(true)
				self.showAlert(title: "Error while setting up profile", message: "Try again later")
				return
			}
			
			//Check if username is taken
			usernameTaken(username: usernameField.text!) { [weak self] taken in
				if !taken {
					var abort = false
					
					self?.createCleanAchievementRecords(userID: id)
					
					//Create a clean friends record
					let friendsRecord = CKRecord(recordType: "Friends")
					friendsRecord["id"] = id
					
					let group = DispatchGroup()
					group.enter()
					self?.db.saveRecord(record: friendsRecord) { saved in
						if !saved {
							abort = true
						}
						group.leave()
					}
					
					//After adding friends record is complete
					group.notify(queue: .main) {
						if abort {
							self?.setUserInteraction(true)
							self?.showAlert(title: "Error while setting up profile", message: "Try again later")
							return
						}
						
						//Get reference to user's profile record
						let predicate = NSPredicate(format: "id == %@", id)
						let query = CKQuery(recordType: "Profiles", predicate: predicate)
						self?.db.getRecords(query: query) { [weak self] returnedRecords in
							let profileRecord = returnedRecords[0]
							
							//Update info
							profileRecord["username"] = usernameText
							profileRecord["bio"] = bioText ?? ""
							profileRecord["ageRange"] = self?.ageRange
							profileRecord["photo"] = photoAsset
							
							self?.db.saveRecord(record: profileRecord) { [weak self] saved in
								if !saved {
									DispatchQueue.main.async {
										self?.setUserInteraction(true)
										self?.showAlert(title: "Error while setting up profile", message: "Try again later")
									}
								}
								else {
									DispatchQueue.main.async {
										AppDelegate.get().setDesiredTabIndex(1)
										self?.showVC(identifier: "tabController")
									}
								}
							}
						}
					}
				}
				else {
					DispatchQueue.main.async {
						self?.setUserInteraction(true)
						self?.showAlert(title: "Username is taken", message: "Input a different username")
					}
				}
			}
		}
		else {
			setUserInteraction(true)
			showAlert(title: "Username cannot be empty", message: "Please input a username")
		}
	}
	
	// MARK: - Functions
	
	//Create clean achievement records in db for user
	private func createCleanAchievementRecords(userID: String) {
		let collectorRecord = CKRecord(recordType: "Achievements")
		collectorRecord["id"] = userID
		collectorRecord["name"] = "collector"
		collectorRecord["amount"] = 0
		collectorRecord["level"] = 0
		db.saveRecord(record: collectorRecord) { _ in }
		
		let competitorRecord = CKRecord(recordType: "Achievements")
		competitorRecord["id"] = userID
		competitorRecord["name"] = "competitor"
		competitorRecord["amount"] = 0
		competitorRecord["level"] = 0
		db.saveRecord(record: competitorRecord) { _ in }
	}
	
	//Returns an asset of the profile photo selected or nil if unsuccessful
	private func createPhotoAsset() -> CKAsset? {
		//Set up photo url
		guard
			let photo = self.imageView.image ?? UIImage(named: "ProfilePic"),
			let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("profilePic.png"),
			let data = photo.pngData()
		else {
			return nil
		}
		
		//Save photo in device cache
		do {
			try data.write(to: url)
		} catch {
			return nil
		}
		
		let photoAsset = CKAsset(fileURL: url)
		return photoAsset
	}
	
	//Sets user interaction enabled on input outlets either true or false
	private func setUserInteraction(_ bool: Bool) {
		usernameField.isUserInteractionEnabled = bool
		bioField.isUserInteractionEnabled = bool
		segmentedControl.isUserInteractionEnabled = bool
		selectButton.isUserInteractionEnabled = bool
		changeButton.isUserInteractionEnabled = bool
		continueButton.isUserInteractionEnabled = bool
	}
	
	//Returns true if a username is taken
	private func usernameTaken(username: String, completion: @escaping (Bool) -> Void) {
		let predicate = NSPredicate(format: "username == %@", username)
		let query = CKQuery(recordType: "Profiles", predicate: predicate)
		
		db.getRecords(query: query) { returnedRecords in
			completion(!returnedRecords.isEmpty)
		}
	}
	
	// MARK: - Permission check functions
	
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
	
	// MARK: - Permission request functions
	
	//Asks user for camera permissions
	private func requestCameraPermission() {
		AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self] allowed in
			if !allowed {
				self?.showPermissionAlert()
			}
		}
	}
	
	//Asks user for gallery permissions
	private func requestGalleryPermission() {
		PHPhotoLibrary.requestAuthorization({ [weak self] authorizationState in
			if authorizationState != .authorized {
				self?.showPermissionAlert()
			}
		})
	}
	
	// MARK: - Custom Alerts
	
	//Opens action sheet to choose photo
	private func openPhotoSelectSheet() {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Select a Photo", message: nil, preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Use Camera", style: .default, handler: { [weak self] _ in
				if self?.cameraPermissionGranted() ?? false {
					self?.openCamera()
				} else {
					self?.requestCameraPermission()
				}
			}))
			alert.addAction(UIAlertAction(title: "Open Gallery", style: .default, handler: { [weak self] _ in
				if self?.galleryPermissionGranted() ?? false {
					self?.openGallery()
				} else {
					self?.requestGalleryPermission()
				}
			}))
			alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
			self.present(alert, animated: true, completion: nil)
	}
	
	//Shows alert regarding camera/gallery permissions
	private func showPermissionAlert() {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Camera/Gallery permission required", message: "Without giving permission you cannot add a photo", preferredStyle: .alert)
		
		let goToSettings = UIAlertAction(title: "Go to Settings", style: .default) { [weak self] _ in
			guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
				self?.showAlert(title: "Error", message: "Cannot open Settings app")
				return
			}
			if (UIApplication.shared.canOpenURL(settingsURL)) {
				UIApplication.shared.open(settingsURL)
			} else {
				self?.showAlert(title: "Error", message: "Cannot open Settings app")
			}
		}
		let cancel = UIAlertAction(title: "Cancel", style: .default)
		
		alert.addAction(cancel)
		alert.addAction(goToSettings)
		self.present(alert, animated: true)
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

// MARK: - Delegate functions

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
		else {
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
		else {
			let alert  = UIAlertController(title: "Error", message: "There occured a problem while trying to open gallery", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	//When user selects a photo from camera/gallery
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		if let selectedImage = info[.originalImage] as? UIImage {
			imageView.image = selectedImage.fixedOrientation
			selectButton.isHidden = true
			imageView.isHidden = false
			changeButton.isHidden = false
		}
		picker.dismiss(animated: true, completion: nil)
	}
}
