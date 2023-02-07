//
//  FriendRequestsVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 06/02/2023.
//

import UIKit
import CloudKit

class FriendRequestsVC: UIViewController {

	//Reference to db manager
	private let db = DBManager.shared
	
	//Stores records with profiles that have sent a friend request
	private var profileArray: [CKRecord] = []
	
	//Controls refreshing of table view
	private let refreshControl = UIRefreshControl()
	
	//Shows a list of profiles that have sent a friend request
	@IBOutlet var tableView: UITableView!
	
	@IBOutlet weak var noRequestsLabel: UILabel!
	
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
	
	//Gets profiles that have sent a friend request from db and adds to profileArray. Reloads table view.
	private func fetchData() {
		noRequestsLabel.isHidden = true
		
		var fetchedProfileArray: [CKRecord] = []
		let group = DispatchGroup()
		
		let id = AppDelegate.get().getCurrentUser()
		let predicate = NSPredicate(format: "receiverID == %@", id)
		let query = CKQuery(recordType: "FriendRequests", predicate: predicate)
		
		//Get records with requests
		group.enter()
		self.db.getRecords(query: query) { returnedRecords in
			//Loop over requests
			for request in returnedRecords {
				let profileID = request["senderID"] as! String
				let predicate = NSPredicate(format: "id == %@", profileID)
				let query = CKQuery(recordType: "Profiles", predicate: predicate)
				
				//Get record with sender's profile
				group.enter()
				self.db.getRecords(query: query) { returnedRecords in
					let profileRecord = returnedRecords[0]
					fetchedProfileArray.append(profileRecord)
					group.leave()
				}
			}
			group.leave()
		}
		
		//After fetching completes
		group.notify(queue: .main) {
			//Sort by creation date
			fetchedProfileArray = fetchedProfileArray.sorted { ($0.value(forKey: "creationDate") as! Date) > ($1.value(forKey: "creationDate") as! Date) }
			self.profileArray = fetchedProfileArray
			self.tableView.reloadData()
			self.refreshControl.endRefreshing()
			self.noRequestsLabel.isHidden = !self.profileArray.isEmpty
		}
	}
	
	//Objective-C function to refresh the table view. Used for refreshControl.
	@objc private func refreshTable(_ sender: Any) {
		fetchData()
	}
	
	//When My profile button is tapped
	@IBAction func myProfile(_ sender: Any) {
		AppDelegate.get().setDesiredTabIndex(4)
		showVC(identifier: "tabController")
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

extension FriendRequestsVC: UITableViewDelegate {
	//When row in table is tapped
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let profileRecord = profileArray[indexPath.row]
		let id = profileRecord["id"] as! String
		
		AppDelegate.get().setUserProfileToOpen(id)
		AppDelegate.get().setVCIDOfCaller("requestsTabController")
		AppDelegate.get().setDesiredRequestsTabIndex(1)
		showVC(identifier: "strangerProfile")
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	//Returns the row height
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 65
	}
}

extension FriendRequestsVC: UITableViewDataSource {
	//Returns the number of rows for the table
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return profileArray.count
	}
	
	//Creates and returns a cell
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		//Create cell from reusable cell
		let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath) as! FriendRequestsTableVC
		let profileRecord = profileArray[indexPath.row]
		
		let imageAsset = profileRecord["photo"] as? CKAsset
		if let imageUrl = imageAsset?.fileURL,
		   let data = try? Data(contentsOf: imageUrl),
		   let image = UIImage(data: data) {
			cell.profileImgView.image = image
		}
		
		cell.nameLabel.text = (profileRecord["firstName"] as! String) + " " + (profileRecord["lastName"] as! String)
		cell.xpLabel.text = String(profileRecord["xp"] as! Int64) + " XP"
		
		//Set selection highlight colour
		let bgColourView = UIView()
		bgColourView.backgroundColor = UIColor.lightGray
		cell.selectedBackgroundView = bgColourView
		
		return cell
	}
}