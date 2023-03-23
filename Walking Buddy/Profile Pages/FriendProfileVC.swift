//
//  FriendProfileVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 06/02/2023.
//
//	Implements the friend profile page view controller

import UIKit
import CloudKit

class FriendProfileVC: UIViewController {

	//Reference to db manager
	private let db = DBManager.shared
	
	//Indicates if a challenge request has been sent to the friend
	private var challengeRequestSent: Bool = false
	
	//Indicates if there is an active challenge with the friend
	private var challengeInProgress: Bool = false

	@IBOutlet weak var imageView: UIImageView! //Image view showing profile photo
	@IBOutlet weak var firstName: UILabel! //Label with first name
	@IBOutlet weak var lastName: UILabel! //Label with last name
	@IBOutlet weak var username: UILabel! //Label with username
	@IBOutlet weak var ageRange: UILabel! //Label with age range
	@IBOutlet weak var xp: UILabel! //Label with XP points
	@IBOutlet weak var bio: UITextView! //Text view with bio
	
	@IBOutlet weak var photosButton: UIButton! //Button to show friend's photos
	@IBOutlet weak var unfriendButton: UIButton! //Button to remove friend
	@IBOutlet weak var requestWalkButton: UIButton! //Button to request walk with friend
	@IBOutlet weak var startChallengeButton: UIButton! //Button to start challenge with friend
	@IBOutlet weak var challengeRequestSentButton: UIButton! //Shown when challenge request was sent
	@IBOutlet weak var challengeInProgressButton: UIButton! //Shown when there is an active challenge
	
	// MARK: - View functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		determineChallengeState()
		fetchData()
	}
	
	// MARK: - IBActions
	
	//When Photos button is tapped
	@IBAction func photos(_ sender: Any) {
		
	}
	
	//When Unfriend button is tapped
	@IBAction func unfriend(_ sender: Any) {
		showUnfriendAlert() { [weak self] proceed in
			if proceed {
				self?.unfriendButton.isUserInteractionEnabled = false
				self?.photosButton.isUserInteractionEnabled = false
				self?.requestWalkButton.isUserInteractionEnabled = false
				self?.startChallengeButton.isUserInteractionEnabled = false
				
				let group = DispatchGroup()
				let ourID = AppDelegate.get().getCurrentUser()
				let profileID = AppDelegate.get().getUserProfileToOpen()
				
				//Delete person from our friends
				let predicate = NSPredicate(format: "id == %@", ourID)
				let query = CKQuery(recordType: "Friends", predicate: predicate)
				group.enter()
				self?.db.getRecords(query: query) { [weak self] returnedRecords in
					let friendsRecord = returnedRecords[0]
					var ourFriendsArray = (friendsRecord["friends"] as? [String]) ?? []
					ourFriendsArray = ourFriendsArray.filter { $0 != profileID }
					friendsRecord["friends"] = ourFriendsArray
					
					group.enter()
					self?.db.saveRecord(record: friendsRecord) { _ in
						group.leave()
					}
					group.leave()
				}
				
				//Delete us from other person's friends
				let predicate2 = NSPredicate(format: "id == %@", profileID)
				let query2 = CKQuery(recordType: "Friends", predicate: predicate2)
				group.enter()
				self?.db.getRecords(query: query2) { [weak self] returnedRecords in
					let friendsRecord = returnedRecords[0]
					var otherFriendsArray = (friendsRecord["friends"] as? [String]) ?? []
					otherFriendsArray = otherFriendsArray.filter { $0 != ourID }
					friendsRecord["friends"] = otherFriendsArray
					
					group.enter()
					self?.db.saveRecord(record: friendsRecord) { _ in
						group.leave()
					}
					group.leave()
				}
				
				group.notify(queue: .main) {
					//After deletion, go to previous view controller
					let vcid = AppDelegate.get().getVCIDOfCaller()
					self?.showVC(identifier: vcid)
				}
			}
		}
	}
	
	//When request walk button is tapped
	@IBAction func requestWalk(_ sender: Any) {
		
	}
	
	//When start challenge button is tapped
	@IBAction func startChallenge(_ sender: Any) {
		let pickerWidth = UIScreen.main.bounds.width - 40
		let pickerHeight = UIScreen.main.bounds.height / 7
		
		let vc = UIViewController()
		vc.preferredContentSize = CGSize(width: pickerWidth, height: pickerHeight + 30)
		let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: pickerWidth, height: pickerHeight))
		
		//HStack with labels (Days, Hours, Minutes)
		let hStack = createHStackForPickerView(width: pickerWidth)
		
		//VStack containing HStack and picker view
		let vStack = UIStackView(frame: CGRect(x: 0, y: 0, width: pickerWidth, height: pickerHeight + 30))
		vStack.axis = .vertical
		vStack.distribution = .fill
		vStack.addArrangedSubview(hStack)
		vStack.addArrangedSubview(pickerView)
		
		vc.view.addSubview(vStack)
		pickerView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
		
		pickerView.dataSource = self
		pickerView.delegate = self
		pickerView.selectRow(0, inComponent: 0, animated: false)
		pickerView.selectRow(0, inComponent: 1, animated: false)
		pickerView.selectRow(0, inComponent: 2, animated: false)
		
		let alert = UIAlertController(title: "Select duration", message: "Select a duration for the challenge", preferredStyle: .actionSheet)
		alert.setValue(vc, forKey: "contentViewController")
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))
		alert.addAction(UIAlertAction(title: "Start challenge", style: .default, handler: { [weak self] _ in
			let days = pickerView.selectedRow(inComponent: 0)
			let hours = pickerView.selectedRow(inComponent: 1)
			let minutes = pickerView.selectedRow(inComponent: 2)
			
			if days == 0 && hours == 0 && minutes == 0 {
				self?.showAlert(title: "Cannot start challenge", message: "Duration must be at least 1 minute long")
			}
			else {
				self?.startChallengeButton.isUserInteractionEnabled = false
				
				let ourID = AppDelegate.get().getCurrentUser()
				let profileID = AppDelegate.get().getUserProfileToOpen()
				let minutesTotal = days * 24 * 60 + hours * 60 + minutes
				
				//Create and save challenge request record
				let requestRecord = CKRecord(recordType: "ChallengeRequests")
				requestRecord["senderID"] = ourID
				requestRecord["receiverID"] = profileID
				requestRecord["minutes"] = minutesTotal
				self?.db.saveRecord(record: requestRecord) { [weak self] saved in
					if !saved {
						DispatchQueue.main.async {
							self?.startChallengeButton.isUserInteractionEnabled = true
							self?.showAlert(title: "Error while sending challenge request", message: "Try again later")
						}
					}
					else {
						DispatchQueue.main.async {
							self?.startChallengeButton.isHidden = true
							self?.challengeRequestSentButton.isHidden = false
						}
					}
				}
			}
		}))
		
		self.present(alert, animated: true, completion: nil)
	}
	
	//When back button is tapped
	@IBAction func back(_ sender: Any) {
		let vcid = AppDelegate.get().getVCIDOfCaller()
		showVC(identifier: vcid)
	}
	
	// MARK: - Functions
	
	//Fetch profile data from db
	private func fetchData() {
		let id = AppDelegate.get().getUserProfileToOpen()
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
	
	//Check if there is an active challenge or a request sent
	private func determineChallengeState() {
		let group = DispatchGroup()
		let userID = AppDelegate.get().getCurrentUser()
		let strangerID = AppDelegate.get().getUserProfileToOpen()
		
		//Check challenge requests
		let predicate = NSPredicate(format: "senderID == %@ AND receiverID == %@", userID, strangerID)
		let query = CKQuery(recordType: "ChallengeRequests", predicate: predicate)
		group.enter()
		self.db.getRecords(query: query) { [weak self] returnedRecords in
			if !returnedRecords.isEmpty {
				DispatchQueue.main.async {
					self?.challengeRequestSent = true
				}
			}
			group.leave()
		}
		
		//Check challenges 1
		let predicate2 = NSPredicate(format: "id1 == %@ AND id2 == %@", userID, strangerID)
		let query2 = CKQuery(recordType: "Challenges", predicate: predicate2)
		group.enter()
		self.db.getRecords(query: query2) { [weak self] returnedRecords in
			if !returnedRecords.isEmpty {
				DispatchQueue.main.async {
					self?.challengeInProgress = true
				}
			}
			group.leave()
		}
		
		//Check challenges 2
		let predicate3 = NSPredicate(format: "id1 == %@ AND id2 == %@", strangerID, userID)
		let query3 = CKQuery(recordType: "Challenges", predicate: predicate3)
		group.enter()
		self.db.getRecords(query: query3) { [weak self] returnedRecords in
			if !returnedRecords.isEmpty {
				DispatchQueue.main.async {
					self?.challengeInProgress = true
				}
			}
			group.leave()
		}
		
		group.notify(queue: .main) {
			self.updateButtonVisibility()
		}
	}

	//Update button visibility
	private func updateButtonVisibility() {
		startChallengeButton.isHidden = challengeInProgress || challengeRequestSent
		challengeRequestSentButton.isHidden = !challengeRequestSent
		challengeInProgressButton.isHidden = !challengeInProgress
	}
	
	//Creates and returns an HStack with (Days, Hours, Minutes) labels
	private func createHStackForPickerView(width: CGFloat) -> UIStackView {
		let hStack = UIStackView(frame: CGRect(x: 0, y: 0, width: width, height: 30))
		hStack.axis = .horizontal
		hStack.distribution = .fillEqually
		
		let daysLabel = UILabel(frame: CGRect(x: 0, y: 0, width: width / 3, height: 30))
		daysLabel.textAlignment = .center
		daysLabel.textColor = UIColor(white: 0.7, alpha: 0.9)
		daysLabel.text = "Days"
		let hoursLabel = UILabel(frame: CGRect(x: 0, y: 0, width: width / 3, height: 30))
		hoursLabel.textAlignment = .center
		hoursLabel.textColor = UIColor(white: 0.7, alpha: 0.9)
		hoursLabel.text = "Hours"
		let minutesLabel = UILabel(frame: CGRect(x: 0, y: 0, width: width / 3, height: 30))
		minutesLabel.textAlignment = .center
		minutesLabel.textColor = UIColor(white: 0.7, alpha: 0.9)
		minutesLabel.text = "Minutes"
		
		hStack.addArrangedSubview(daysLabel)
		hStack.addArrangedSubview(hoursLabel)
		hStack.addArrangedSubview(minutesLabel)
		
		return hStack
	}
	
	// MARK: - Custom alerts
	
	//Shows alert to confirm the unfriend action
	private func showUnfriendAlert(completion: @escaping (Bool) -> Void) {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Confirm action", message: "Are you sure you want to unfriend this person?", preferredStyle: .alert)
		let unfriend = UIAlertAction(title: "Unfriend", style: .default) { _ in
			completion(true)
		}
		let cancel = UIAlertAction(title: "Cancel", style: .default) { _ in
			completion(false)
		}
		alert.addAction(unfriend)
		alert.addAction(cancel)
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

// MARK: - Picker view setup

extension FriendProfileVC: UIPickerViewDelegate, UIPickerViewDataSource {
	//Returns number of components for picker view
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 3
	}
	
	//Returns number of rows for a component
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		switch component {
		case 0: //Days component
			return 8
		case 1: //Hours component
			let selectedDays = pickerView.selectedRow(inComponent: 0)
			if selectedDays == 7 {
				return 1
			}
			else {
				return 24
			}
		case 2: //Minutes component
			let selectedDays = pickerView.selectedRow(inComponent: 0)
			if selectedDays == 7 {
				return 1
			}
			else {
				return 60
			}
		default:
			return 0
		}
	}
	
	//Returns the title for a specific row
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return String(row)
	}
	
	//When row is selected
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		if component == 0 {
			pickerView.reloadComponent(1)
			pickerView.reloadComponent(2)
		}
	}
}
