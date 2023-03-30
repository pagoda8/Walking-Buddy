//
//  FriendsVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 03/02/2023.
//
//	Implements the Friends View Controller

import UIKit
import CloudKit

class FriendsVC: UIViewController {
	
	//Reference to db manager
	private let db = DBManager.shared
	
	//Stores records with profiles of user's friends
	private var friendsArray: [CKRecord] = []
	
	//Controls refreshing of table view
	private let refreshControl = UIRefreshControl()
	
	//Shows a list of user's friends
	@IBOutlet weak var tableView: UITableView!
	
	//Label shown when user has no friends
	@IBOutlet weak var noFriendsLabel: UILabel!
	
	// MARK: - View functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//Set up table view
		tableView.delegate = self
		tableView.dataSource = self
		
		//Set up refresh control
		tableView.refreshControl = refreshControl
		tableView.backgroundView = refreshControl
		refreshControl.addTarget(self, action: #selector(refreshTable(_:)), for: .valueChanged)
		refreshControl.tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
		
		fetchData()
	}
	
	// MARK: - IBActions
	
	//When "+" button is tapped (to add new friend)
	@IBAction func addTapped(_ sender: Any) {
		tableView.isUserInteractionEnabled = false
		let ourID = AppDelegate.get().getCurrentUser()
		
		showUsernameAlert() { [weak self] enteredUsername in
			if enteredUsername == nil {
				//Cancel tapped
				self?.tableView.isUserInteractionEnabled = true
				return
			}
			else if enteredUsername!.isEmpty {
				//Username empty
				self?.tableView.isUserInteractionEnabled = true
				self?.showAlert(title: "Invalid username", message: "The entered username cannot be empty")
				return
			}
			else {
				self?.getCurrentUserUsername() { [weak self] myUsername in
					if enteredUsername == myUsername {
						//Username is same as ours
						DispatchQueue.main.async {
							self?.tableView.isUserInteractionEnabled = true
							self?.showAlert(title: "Invalid username", message: "The entered username cannot be your username")
							return
						}
					}
					else {
						let predicate = NSPredicate(format: "username == %@", enteredUsername!)
						let query = CKQuery(recordType: "Profiles", predicate: predicate)
						
						self?.db.getRecords(query: query) { [weak self] returnedRecords in
							if returnedRecords.isEmpty {
								//No such user exists
								DispatchQueue.main.async {
									self?.tableView.isUserInteractionEnabled = true
									self?.showAlert(title: "Invalid username", message: "A person with the entered username does not exist")
									return
								}
							}
							else {
								let profileRecord = returnedRecords[0]
								let profileID = profileRecord["id"] as! String
								
								//Get our Friends record (containing our friends)
								let predicate2 = NSPredicate(format: "id == %@", ourID)
								let query2 = CKQuery(recordType: "Friends", predicate: predicate2)
								
								self?.db.getRecords(query: query2) { [weak self] returnedRecords2 in
									let friendsRecord = returnedRecords2[0]
									let ourFriendsArray = (friendsRecord["friends"] as? [String]) ?? []
									
									if ourFriendsArray.contains(profileID) {
										//The person is already our friend
										DispatchQueue.main.async {
											self?.tableView.isUserInteractionEnabled = true
											self?.showAlert(title: "Invalid username", message: "You are already friends with this person")
											return
										}
									}
									else {
										//Go to person's profile
										DispatchQueue.main.async {
											AppDelegate.get().setVCIDOfCaller("friends")
											AppDelegate.get().setUserProfileToOpen(profileID)
											self?.showVC(identifier: "strangerProfile")
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
	//When My profile button is tapped
	@IBAction func myProfile(_ sender: Any) {
		AppDelegate.get().setDesiredTabIndex(3)
		showVC(identifier: "tabController")
	}
	
	// MARK: - Functions
	
	//Gets user's friends from db and adds to friendsArray. Reloads table view.
	private func fetchData() {
		noFriendsLabel.isHidden = true
		let group = DispatchGroup()
		let id = AppDelegate.get().getCurrentUser()
		var fetchedFriendsArray: [CKRecord] = []
		
		//Get record with user's friends
		let predicate = NSPredicate(format: "id == %@", id)
		let query = CKQuery(recordType: "Friends", predicate: predicate)
		group.enter()
		self.db.getRecords(query: query) { [weak self] returnedRecords in
			let friendsRecord = returnedRecords[0]
			var friendsIDArray = (friendsRecord["friends"] as? [String]) ?? []
			friendsIDArray = self?.removeUnfriendedFriends(friendsIDArray) ?? []
			
			//Loop over friends id's
			for friendID in friendsIDArray {
				//Get record with friend's profile
				let predicate = NSPredicate(format: "id == %@", friendID)
				let query = CKQuery(recordType: "Profiles", predicate: predicate)
				group.enter()
				self?.db.getRecords(query: query) { returnedRecords in
					let profileRecord = returnedRecords[0]
					fetchedFriendsArray.append(profileRecord)
					group.leave()
				}
			}
			group.leave()
		}
		
		//After fetching completes
		group.notify(queue: .main) {
			//Sort by XP (descending)
			fetchedFriendsArray = fetchedFriendsArray.sorted { ($0.value(forKey: "xp") as! Int64) > ($1.value(forKey: "xp") as! Int64) }
			self.friendsArray = fetchedFriendsArray
			self.tableView.reloadData()
			self.refreshControl.endRefreshing()
			self.noFriendsLabel.isHidden = !self.friendsArray.isEmpty
		}
	}
	
	//Get username of current user and return as completion
	private func getCurrentUserUsername(completion: @escaping (String) -> Void) {
		let id = AppDelegate.get().getCurrentUser()
		let predicate = NSPredicate(format: "id == %@", id)
		let query = CKQuery(recordType: "Profiles", predicate: predicate)
		
		db.getRecords(query: query) { returnedRecords in
			let profileRecord = returnedRecords[0]
			completion(profileRecord["username"] as! String)
		}
	}
	
	//Removes recently unfriended friends from the friendsIDArray
	private func removeUnfriendedFriends(_ friendsIDArray: [String]) -> [String] {
		var localFriendsIDArray = friendsIDArray
		if !localFriendsIDArray.isEmpty {
			var i = 0
			for id in localFriendsIDArray {
				DispatchQueue.main.async {
					if AppDelegate.get().isUnfriendInProgress(id) {
						localFriendsIDArray.remove(at: i)
					}
					else {
						i += 1
					}
				}
			}
		}
		return localFriendsIDArray
	}
	
	// MARK: - Custom alerts
	
	//Shows alert prompting the user to input the username of user to add
	private func showUsernameAlert(completion: @escaping (String?) -> Void) {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Enter username", message: "Enter the username of the person you want to add as a friend", preferredStyle: .alert)
		alert.addTextField() { textField in
			textField.placeholder = "username"
		}
		let goToProfile = UIAlertAction(title: "Go to Profile", style: .default) { _ in
			let textField = alert.textFields![0]
			if (textField.text?.isEmpty == true) {
				completion("")
			} else {
				completion(textField.text!)
			}
		}
		let cancel = UIAlertAction(title: "Cancel", style: .default) { _ in
			completion(nil)
		}
		
		alert.addAction(cancel)
		alert.addAction(goToProfile)
		self.present(alert, animated: true)
	}
	
	// MARK: - Other
	
	//Objective-C function to refresh the table view. Used for refreshControl.
	@objc private func refreshTable(_ sender: Any) {
		fetchData()
	}
	
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
	
	//Shows alert with given title and message
	private func showAlert(title: String, message: String) {
		vibrate(style: .light)
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		self.present(alert, animated: true)
	}
}
	
// MARK: - Table view setup

extension FriendsVC: UITableViewDataSource, UITableViewDelegate {
	//When row in table is tapped
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let friendRecord = friendsArray[indexPath.row]
		let id = friendRecord["id"] as! String
		
		AppDelegate.get().setUserProfileToOpen(id)
		AppDelegate.get().setVCIDOfCaller("friends")
		showVC(identifier: "friendProfile")
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	//Returns the row height
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 65
	}
	
	//Returns the number of rows for the table
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return friendsArray.count
	}
	
	//Creates and returns a cell
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		//Create cell from reusable cell
		let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath) as! FriendsTableVC
		let profileRecord = friendsArray[indexPath.row]
		
		//Set profile image
		let imageAsset = profileRecord["photo"] as? CKAsset
		if let imageUrl = imageAsset?.fileURL,
		   let data = try? Data(contentsOf: imageUrl),
		   let image = UIImage(data: data) {
			cell.profileImgView.image = image
		}
		
		//Set cell labels
		cell.nameLabel.text = (profileRecord["firstName"] as! String) + " " + (profileRecord["lastName"] as! String)
		cell.xpLabel.text = String(profileRecord["xp"] as! Int64) + " XP"
		
		//Set selection highlight colour
		let bgColourView = UIView()
		bgColourView.backgroundColor = UIColor.lightGray
		cell.selectedBackgroundView = bgColourView
		
		return cell
	}
}
