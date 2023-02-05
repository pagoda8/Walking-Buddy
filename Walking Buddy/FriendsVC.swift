//
//  FriendsVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 03/02/2023.
//

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
	@IBOutlet var tableView: UITableView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//Set up table view
		tableView.delegate = self
		tableView.dataSource = self
		tableView.showsVerticalScrollIndicator = false
		
		//Set up refresh control
		tableView.refreshControl = refreshControl
		tableView.backgroundView = refreshControl
		refreshControl.addTarget(self, action: #selector(refreshTable(_:)), for: .valueChanged)
		refreshControl.tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
		
		fetchData()
	}
	
	//When "+" button is tapped
	@IBAction func addTapped(_ sender: Any) {
		
	}
	
	//When My profile button is tapped
	@IBAction func myProfile(_ sender: Any) {
		AppDelegate.get().setDesiredTabIndex(4)
		showVC(identifier: "tabController")
	}
	
	//Gets user's friends data from db and adds to friendsArray. Reloads table view.
	private func fetchData() {
		var fetchedFriendsArray: [CKRecord] = []
		let group = DispatchGroup()
		
		let id = AppDelegate.get().getCurrentUser()
		let predicate = NSPredicate(format: "id == %@", id)
		let query = CKQuery(recordType: "Friends", predicate: predicate)
		
		//Get record with friends
		group.enter()
		self.db.getRecords(query: query) { returnedRecords in
			let friendsRecord = returnedRecords[0]
			let friendsIDArray = (friendsRecord["friends"] as? [String]) ?? []
			
			//Loop over friends id's
			for friendID in friendsIDArray {
				let predicate = NSPredicate(format: "id == %@", friendID)
				let query = CKQuery(recordType: "Profiles", predicate: predicate)
				
				//Get record with friend's profile
				group.enter()
				self.db.getRecords(query: query) { returnedRecords in
					let profileRecord = returnedRecords[0]
					fetchedFriendsArray.append(profileRecord)
					group.leave()
				}
			}
			group.leave()
		}
		
		//After fetching completes
		group.notify(queue: .main) {
			//Sort by XP
			fetchedFriendsArray = fetchedFriendsArray.sorted { ($0.value(forKey: "xp") as! Int64) > ($1.value(forKey: "xp") as! Int64) }
			self.friendsArray = fetchedFriendsArray
			self.tableView.reloadData()
			self.refreshControl.endRefreshing()
		}
	}
	
	//Objective-C function to refresh the table view. Used for refreshControl.
	@objc private func refreshTable(_ sender: Any) {
		fetchData()
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
	
//Table view setup

extension FriendsVC: UITableViewDelegate {
	//When row in table is tapped
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		//TODO go to friend profile page
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	//Returns the row height
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 65
	}
}

extension FriendsVC: UITableViewDataSource {
	//Returns the number of rows for the table
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return friendsArray.count
	}
	
	//Creates and returns a cell
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		//Create cell from reusable cell
		let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath) as! FriendsTableVC
		let profileRecord = friendsArray[indexPath.row]
		
		let imageAsset = profileRecord["photo"] as? CKAsset
		if let imageUrl = imageAsset?.fileURL,
		   let data = try? Data(contentsOf: imageUrl),
		   let image = UIImage(data: data) {
			cell.profileImgView.image = image
		}
		
		cell.nameLabel.text = (profileRecord["firstName"] as! String) + " " + (profileRecord["lastName"] as! String)
		cell.xpLabel.text = String(profileRecord["xp"] as! Int64) + " XP"
		
		//cell.textLabel?.textColor = UIColor.black
		
		//Set selection highlight colour
		let bgColourView = UIView()
		bgColourView.backgroundColor = UIColor.lightGray
		cell.selectedBackgroundView = bgColourView
		
		return cell
	}
}
